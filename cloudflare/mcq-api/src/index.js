const PROJECT_ID = "the-atlas-academy-3fae0";
const ISSUER = `https://securetoken.google.com/${PROJECT_ID}`;
const FIREBASE_KEYS_URL = "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com";
const TOKEN_URL = "https://oauth2.googleapis.com/token";
const FIRESTORE = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;
const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Authorization, Content-Type",
  "Access-Control-Max-Age": "86400",
};

let firebaseKeysCache;
let serviceTokenCache;

function response(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}

function fail(message, status = 400) {
  return response({ success: false, message }, status);
}

function decodeBase64Url(value) {
  const normalized = value.replace(/-/g, "+").replace(/_/g, "/");
  const padded = normalized + "=".repeat((4 - normalized.length % 4) % 4);
  return Uint8Array.from(atob(padded), (c) => c.charCodeAt(0));
}

function encodeBase64Url(value) {
  const bytes = typeof value === "string" ? new TextEncoder().encode(value) : value;
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
}

function parseJwtPart(part) {
  return JSON.parse(new TextDecoder().decode(decodeBase64Url(part)));
}

async function verifyFirebaseToken(token) {
  const parts = token.split(".");
  if (parts.length !== 3) throw new Error("Invalid sign-in token.");
  const header = parseJwtPart(parts[0]);
  const claims = parseJwtPart(parts[1]);
  if (header.alg !== "RS256" || !header.kid) throw new Error("Invalid sign-in token.");
  if (!firebaseKeysCache || firebaseKeysCache.expiresAt < Date.now()) {
    const result = await fetch(FIREBASE_KEYS_URL);
    if (!result.ok) throw new Error("Unable to verify sign-in.");
    const keySet = await result.json();
    const keys = Array.isArray(keySet) ? keySet : keySet.keys;
    if (!Array.isArray(keys) || keys.length === 0) {
      throw new Error("Firebase returned an invalid signing-key set. Please retry shortly.");
    }
    firebaseKeysCache = { keys, expiresAt: Date.now() + 3600000 };
  }
  const jwk = firebaseKeysCache.keys.find((item) => item.kid === header.kid);
  if (!jwk) throw new Error("Sign-in token key is no longer valid. Please sign in again.");
  const key = await crypto.subtle.importKey(
    "jwk", jwk, { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["verify"],
  );
  const valid = await crypto.subtle.verify(
    "RSASSA-PKCS1-v1_5",
    key,
    decodeBase64Url(parts[2]),
    new TextEncoder().encode(parts[0] + "." + parts[1]),
  );
  const now = Math.floor(Date.now() / 1000);
  if (!valid || claims.iss !== ISSUER || claims.aud !== PROJECT_ID ||
      !claims.sub || claims.sub.length > 128 || claims.exp <= now ||
      claims.iat > now + 60 || claims.auth_time > now + 60) {
    throw new Error("Your sign-in has expired. Please sign in again.");
  }
  return claims;
}

function pemToBytes(pem) {
  const body = pem.replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "").replace(/\s/g, "");
  return Uint8Array.from(atob(body), (c) => c.charCodeAt(0));
}

async function getServiceAccessToken(env) {
  if (serviceTokenCache && serviceTokenCache.expiresAt > Date.now() + 60000) {
    return serviceTokenCache.token;
  }
  let account;
  try { account = JSON.parse(env.FIREBASE_SERVICE_ACCOUNT); }
  catch { throw new Error("The Firebase service credential is not configured correctly."); }
  if (!account.client_email || !account.private_key) {
    throw new Error("The Firebase service credential is incomplete.");
  }
  const now = Math.floor(Date.now() / 1000);
  const header = encodeBase64Url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claim = encodeBase64Url(JSON.stringify({
    iss: account.client_email,
    scope: "https://www.googleapis.com/auth/datastore",
    aud: TOKEN_URL,
    iat: now,
    exp: now + 3600,
  }));
  const unsigned = header + "." + claim;
  const key = await crypto.subtle.importKey(
    "pkcs8", pemToBytes(account.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(unsigned),
  );
  const assertion = unsigned + "." + encodeBase64Url(new Uint8Array(signature));
  const form = new URLSearchParams({
    grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
    assertion,
  });
  const result = await fetch(TOKEN_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: form,
  });
  const data = await result.json();
  if (!result.ok || !data.access_token) {
    throw new Error("The server could not access the academy database. Check service-account permissions.");
  }
  serviceTokenCache = {
    token: data.access_token,
    expiresAt: Date.now() + (Number(data.expires_in) || 3600) * 1000,
  };
  return data.access_token;
}

function decodeValue(value) {
  if (!value) return null;
  if ("stringValue" in value) return value.stringValue;
  if ("integerValue" in value) return Number(value.integerValue);
  if ("doubleValue" in value) return Number(value.doubleValue);
  if ("booleanValue" in value) return value.booleanValue;
  if ("timestampValue" in value) return value.timestampValue;
  if ("nullValue" in value) return null;
  if ("arrayValue" in value) return (value.arrayValue.values || []).map(decodeValue);
  if ("mapValue" in value) return decodeFields(value.mapValue.fields || {});
  return null;
}

function decodeFields(fields) {
  const result = {};
  for (const [key, value] of Object.entries(fields || {})) result[key] = decodeValue(value);
  return result;
}

function encodeValue(value) {
  if (value === null || value === undefined) return { nullValue: null };
  if (typeof value === "string") return { stringValue: value };
  if (typeof value === "boolean") return { booleanValue: value };
  if (typeof value === "number") {
    return Number.isInteger(value) ? { integerValue: String(value) } : { doubleValue: value };
  }
  if (Array.isArray(value)) return { arrayValue: { values: value.map(encodeValue) } };
  if (typeof value === "object") return { mapValue: { fields: encodeFields(value) } };
  return { nullValue: null };
}

function encodeFields(fields) {
  const result = {};
  const timestampFields = new Set([
    "startedAt", "expiresAt", "createdAt", "completedAt",
    "submittedAt", "updatedAt", "reviewedAt",
  ]);
  for (const [key, value] of Object.entries(fields)) {
    result[key] = timestampFields.has(key) && typeof value === "string"
      ? { timestampValue: value }
      : encodeValue(value);
  }
  return result;
}

async function firestoreRequest(env, path, options = {}) {
  const token = await getServiceAccessToken(env);
  const result = await fetch(FIRESTORE + path, {
    ...options,
    headers: {
      Authorization: "Bearer " + token,
      "Content-Type": "application/json",
      ...(options.headers || {}),
    },
  });
  const text = await result.text();
  let data = {};
  try {
    data = text ? JSON.parse(text) : {};
  } catch {
    // Firestore batchGet may stream one JSON response per line.
    try {
      data = text.trim().split(/\\r?\\n/).filter(Boolean).map((line) => JSON.parse(line));
    } catch {
      data = {};
    }
  }
  if (!result.ok) {
    const message = data.error?.message || "Database request failed.";
    const error = new Error(message);
    error.status = result.status;
    throw error;
  }
  return data;
}

async function getDocument(env, collection, id) {
  try {
    const data = await firestoreRequest(env, "/" + collection + "/" + encodeURIComponent(id));
    return { data: decodeFields(data.fields), updateTime: data.updateTime, name: data.name };
  } catch (error) {
    if (error.status === 404) return null;
    throw error;
  }
}

async function getDocuments(env, collection, ids) {
  if (!ids.length) return new Map();
  const names = ids.map((id) =>
    `projects/${PROJECT_ID}/databases/(default)/documents/${collection}/${id}`
  );
  const result = await firestoreRequest(env, ":batchGet", {
    method: "POST",
    body: JSON.stringify({ documents: names }),
  });
  const found = new Map();
  for (const item of (Array.isArray(result) ? result : [])) {
    if (item.found?.name) {
      const id = item.found.name.split("/").pop();
      found.set(id, {
        data: decodeFields(item.found.fields),
        updateTime: item.found.updateTime,
        name: item.found.name,
      });
    }
  }
  return found;
}

async function queryQuestions(env, examSetId) {
  const filters = [
    { fieldFilter: { field: { fieldPath: "isPublished" }, op: "EQUAL", value: { booleanValue: true } } },
  ];
  if (examSetId) {
    filters.push({ fieldFilter: { field: { fieldPath: "examSetId" }, op: "EQUAL", value: { stringValue: examSetId } } });
  } else {
    filters.push({ fieldFilter: { field: { fieldPath: "trackType" }, op: "EQUAL", value: { stringValue: "structured" } } });
  }
  const result = await firestoreRequest(env, ":runQuery", {
    method: "POST",
    body: JSON.stringify({
      structuredQuery: {
        from: [{ collectionId: "mcqs" }],
        where: { compositeFilter: { op: "AND", filters } },
        limit: 100,
      },
    }),
  });
  return result.filter((item) => item.document).map((item) => ({
    id: item.document.name.split("/").pop(),
    data: decodeFields(item.document.fields),
  }));
}

function hasPermission(user, features) {
  const permissions = user.subscriptionAccessPermissions || {};
  return features.some((feature) => permissions[feature] === true);
}

function activeSubscription(user) {
  const expiry = Date.parse(user.subscriptionExpiryAt || "");
  return user.accessEnabled === true &&
    user.subscriptionStatus === "active" &&
    Number.isFinite(expiry) && expiry > Date.now();
}

async function requireEntitlement(env, uid, trackType, noSet = false) {
  const profile = await getDocument(env, "users", uid);
  if (!profile) throw new Error("Your student profile could not be found.");
  const user = profile.data;
  if (!activeSubscription(user)) throw new Error("An active subscription is required.");
  const features = noSet ? ["mcqPractice"] :
    trackType === "past_paper" ? ["pastPapers", "examinations"] : ["examinations", "mcqPractice"];
  if (!hasPermission(user, features)) throw new Error("Your subscription does not include this feature.");
  return user;
}

async function startSession(env, uid, body) {
  const examSetId = typeof body.examSetId === "string" ? body.examSetId.trim() : "";
  let trackType = "structured";
  let durationMinutes = 60;
  if (examSetId) {
    const set = await getDocument(env, "mcq_exam_sets", examSetId);
    if (!set || set.data.isPublished !== true) throw new Error("This published exam set is unavailable.");
    trackType = set.data.trackType || "structured";
    await requireEntitlement(env, uid, trackType);
    const configured = Number(set.data.durationMinutes);
    if (Number.isInteger(configured) && configured > 0) durationMinutes = Math.min(configured, 240);
  } else {
    await requireEntitlement(env, uid, trackType, true);
  }
  const questions = await queryQuestions(env, examSetId);
  if (!questions.length) throw new Error("No published questions are available in this set.");
  const ids = questions.map((question) => question.id);
  for (let i = ids.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [ids[i], ids[j]] = [ids[j], ids[i]];
  }
  const sessionId = crypto.randomUUID();
  const startedAt = new Date();
  const expiresAt = new Date(startedAt.getTime() + durationMinutes * 60000);
  await firestoreRequest(env, ":commit", {
    method: "POST",
    body: JSON.stringify({
      writes: [{
        update: {
          name: `projects/${PROJECT_ID}/databases/(default)/documents/mcq_practice_sessions/${sessionId}`,
          fields: encodeFields({
            userId: uid, examSetId: examSetId || null, trackType,
            questionIds: ids, durationMinutes, startedAt: startedAt.toISOString(),
            expiresAt: expiresAt.toISOString(), status: "active",
            createdAt: startedAt.toISOString(),
          }),
        },
        currentDocument: { exists: false },
      }],
    }),
  });
  return {
    success: true, sessionId, questionIds: ids, durationMinutes,
    startedAt: startedAt.toISOString(), expiresAt: expiresAt.toISOString(),
  };
}

async function submitSession(env, uid, body) {
  const sessionId = typeof body.sessionId === "string" ? body.sessionId.trim() : "";
  const selectedAnswers = body.selectedAnswers;
  if (!sessionId || sessionId.length > 150) throw new Error("A valid practice session is required.");
  if (!selectedAnswers || typeof selectedAnswers !== "object" || Array.isArray(selectedAnswers)) {
    throw new Error("The selected answers are invalid.");
  }
  const sessionSnapshot = await getDocument(env, "mcq_practice_sessions", sessionId);
  if (!sessionSnapshot) throw new Error("This practice session could not be found.");
  const session = sessionSnapshot.data;
  if (session.userId !== uid || session.status !== "active") {
    throw new Error("This practice session is not available to your account.");
  }
  const questionIds = session.questionIds;
  if (!Array.isArray(questionIds) || questionIds.length < 1 || questionIds.length > 100) {
    throw new Error("The saved practice session is invalid.");
  }
  const expiresAt = Date.parse(session.expiresAt || "");
  if (!Number.isFinite(expiresAt) || Date.now() > expiresAt + 120000) {
    throw new Error("The submission window for this practice has closed.");
  }
  const allowed = new Set(questionIds);
  for (const [id, value] of Object.entries(selectedAnswers)) {
    if (!allowed.has(id)) throw new Error("An answer was submitted for a question outside this session.");
    if (value !== null && (!Number.isInteger(value) || value < 0 || value > 4)) {
      throw new Error("A selected option index is invalid.");
    }
  }

  const examSetId = typeof session.examSetId === "string" ? session.examSetId : "";
  let user;
  if (examSetId) {
    const set = await getDocument(env, "mcq_exam_sets", examSetId);
    if (!set || set.data.isPublished !== true) throw new Error("This exam set is no longer published.");
    user = await requireEntitlement(env, uid, set.data.trackType || "structured");
  } else {
    user = await requireEntitlement(env, uid, "structured", true);
  }

  // Batch reads keep a 100-question submission well below Cloudflare's
  // per-request subrequest ceiling while answer keys remain server-only.
  const [questionDocuments, answerDocuments] = await Promise.all([
    getDocuments(env, "mcqs", questionIds),
    getDocuments(env, "mcq_answer_keys", questionIds),
  ]);
  const snapshots = questionIds.map((id) => {
    const question = questionDocuments.get(id);
    const answerKey = answerDocuments.get(id);
    if (!question || !answerKey) throw new Error("A question or its private answer key is unavailable.");
    const q = question.data;
    if (q.isPublished !== true || (examSetId && q.examSetId !== examSetId)) {
      throw new Error("A question is unpublished or does not belong to this exam set.");
    }
    if (!Array.isArray(q.options) || q.options.length < 4 || q.options.length > 5 ||
        q.options.some((option) => typeof option !== "string" || !option.trim())) {
      throw new Error("A question has invalid options.");
    }
    const correctAnswer = typeof answerKey.data.correctAnswer === "string"
      ? answerKey.data.correctAnswer.trim().toUpperCase() : "";
    const correctIndex = "ABCDE".indexOf(correctAnswer);
    if (correctIndex < 0 || correctIndex >= q.options.length) {
      throw new Error("A question has an invalid private answer key.");
    }
    return { id, question: q, options: q.options, correctAnswer, correctIndex,
      explanation: typeof answerKey.data.explanation === "string" ? answerKey.data.explanation : "" };
  });

  let correctAnswers = 0;
  let incorrectAnswers = 0;
  let unansweredQuestions = 0;
  const answers = [];
  const subjects = new Set();
  const topics = new Set();
  for (const item of snapshots) {
    const selected = Object.prototype.hasOwnProperty.call(selectedAnswers, item.id)
      ? selectedAnswers[item.id] : null;
    if (selected !== null && selected >= item.options.length) {
      throw new Error("A selected answer exceeds the available options.");
    }
    const isAnswered = selected !== null;
    const isCorrect = isAnswered && selected === item.correctIndex;
    if (!isAnswered) unansweredQuestions++;
    else if (isCorrect) correctAnswers++;
    else incorrectAnswers++;
    const subject = typeof item.question.subject === "string" ? item.question.subject.trim() : "";
    const topic = typeof item.question.topic === "string" ? item.question.topic.trim() : "";
    if (subject) subjects.add(subject);
    if (topic) topics.add(topic);
    answers.push({
      questionId: item.id, question: item.question.question || "", options: item.options,
      selectedAnswer: selected === null ? null : String.fromCharCode(65 + selected),
      correctAnswer: item.correctAnswer, isAnswered, isCorrect,
      explanation: item.explanation, subject, topic,
      difficulty: item.question.difficulty || "Medium", reference: item.question.reference || "",
    });
  }
  const now = new Date().toISOString();
  const attemptId = crypto.randomUUID();
  const totalQuestions = snapshots.length;
  const percentage = (correctAnswers / totalQuestions) * 100;
  const attempt = {
    userId: uid, type: "practice", examSetId: examSetId || null, sessionId,
    durationMinutes: session.durationMinutes || 60, totalQuestions,
    correctAnswers, incorrectAnswers, unansweredQuestions, percentage,
    questionIds, answers, subject: Array.from(subjects).join(", "),
    topic: Array.from(topics).join(", "), subjects: Array.from(subjects),
    topics: Array.from(topics), startedAt: session.startedAt,
    completedAt: now, createdAt: now, scoringMethod: "server",
  };
  await firestoreRequest(env, ":commit", {
    method: "POST",
    body: JSON.stringify({
      writes: [
        {
          update: {
            name: `projects/${PROJECT_ID}/databases/(default)/documents/mcq_attempts/${attemptId}`,
            fields: encodeFields(attempt),
          },
          currentDocument: { exists: false },
        },
        {
          update: {
            name: sessionSnapshot.name,
            fields: encodeFields({ ...session, status: "submitted", submittedAt: now, attemptId }),
          },
          updateMask: { fieldPaths: Object.keys({ ...session, status: "submitted", submittedAt: now, attemptId }) },
          currentDocument: { updateTime: sessionSnapshot.updateTime },
        },
      ],
    }),
  });
  return { success: true, message: "Practice submitted successfully.", attemptId,
    totalQuestions, correctAnswers, incorrectAnswers, unansweredQuestions, percentage };
}


function utcDayKey(date = new Date()) {
  return date.toISOString().slice(0, 10);
}

function dayNumber(dayKey) {
  return Math.floor(Date.parse(dayKey + "T00:00:00Z") / 86400000);
}

async function dailyChallengeStart(env, uid) {
  await requireEntitlement(env, uid, "structured", true);
  const today = utcDayKey();
  const sessionId = uid + "_" + today;
  const existing = await getDocument(env, "daily_challenge_sessions", sessionId);
  if (existing) {
    const session = existing.data;
    return {
      success: true, date: today, sessionId,
      questionId: session.questionId,
      question: session.question, options: session.options,
      subject: session.subject || "", topic: session.topic || "",
      difficulty: session.difficulty || "Medium",
      alreadyCompleted: session.status === "completed",
      selectedAnswer: session.selectedAnswer ?? null,
      isCorrect: session.isCorrect ?? null,
      correctAnswer: session.status === "completed" ? session.correctAnswer : null,
      explanation: session.status === "completed" ? session.explanation : null,
      completedAt: session.completedAt || null,
    };
  }
  const pool = await queryQuestions(env, "");
  const eligible = pool.filter((item) =>
    item.data.isPublished === true &&
    typeof item.data.question === "string" && item.data.question.trim() &&
    Array.isArray(item.data.options) && item.data.options.length >= 4 &&
    item.data.options.length <= 5
  ).sort((a, b) => a.id.localeCompare(b.id));
  if (!eligible.length) throw new Error("No published daily challenge questions are available yet.");
  const index = ((dayNumber(today) % eligible.length) + eligible.length) % eligible.length;
  const chosen = eligible[index];
  const session = {
    userId: uid, date: today, questionId: chosen.id,
    question: chosen.data.question, options: chosen.data.options,
    subject: chosen.data.subject || "", topic: chosen.data.topic || "",
    difficulty: chosen.data.difficulty || "Medium",
    status: "active", createdAt: new Date().toISOString(),
  };
  await firestoreRequest(env, ":commit", {
    method: "POST",
    body: JSON.stringify({ writes: [{
      update: {
        name: `projects/${PROJECT_ID}/databases/(default)/documents/daily_challenge_sessions/${sessionId}`,
        fields: encodeFields(session),
      },
      currentDocument: { exists: false },
    }] }),
  });
  return {
    success: true, date: today, sessionId, questionId: chosen.id,
    question: session.question, options: session.options,
    subject: session.subject, topic: session.topic,
    difficulty: session.difficulty, alreadyCompleted: false,
  };
}

async function dailyChallengeStatus(env, uid) {
  await requireEntitlement(env, uid, "structured", true);
  const statsDoc = await getDocument(env, "daily_challenge_stats", uid);
  const stats = statsDoc?.data || {};
  const today = utcDayKey();
  const session = await getDocument(env, "daily_challenge_sessions", uid + "_" + today);
  const result = await firestoreRequest(env, ":runQuery", {
    method: "POST",
    body: JSON.stringify({
      structuredQuery: {
        from: [{ collectionId: "daily_challenge_attempts" }],
        where: { fieldFilter: {
          field: { fieldPath: "userId" }, op: "EQUAL",
          value: { stringValue: uid },
        } },
        orderBy: [{ field: { fieldPath: "completedAt" }, direction: "DESCENDING" }],
        limit: 30,
      },
    }),
  });
  const history = result.filter((item) => item.document).map((item) => {
    const data = decodeFields(item.document.fields);
    return {
      date: data.date || "", isCorrect: data.isCorrect === true,
      subject: data.subject || "", topic: data.topic || "",
      completedAt: data.completedAt || "",
    };
  });
  return {
    success: true,
    currentStreak: Number(stats.currentStreak) || 0,
    longestStreak: Number(stats.longestStreak) || 0,
    totalCompleted: Number(stats.totalCompleted) || 0,
    totalCorrect: Number(stats.totalCorrect) || 0,
    lastChallengeDate: stats.lastChallengeDate || "",
    completedToday: session?.data.status === "completed",
    history,
  };
}

async function dailyChallengeSubmit(env, uid, body) {
  await requireEntitlement(env, uid, "structured", true);
  const today = utcDayKey();
  const sessionId = uid + "_" + today;
  const sessionDoc = await getDocument(env, "daily_challenge_sessions", sessionId);
  if (!sessionDoc || sessionDoc.data.userId !== uid) {
    throw new Error("Today's challenge has not been started. Refresh and try again.");
  }
  const session = sessionDoc.data;
  if (session.status === "completed") {
    return {
      success: true, alreadySubmitted: true,
      isCorrect: session.isCorrect === true,
      selectedAnswer: session.selectedAnswer,
      correctAnswer: session.correctAnswer,
      explanation: session.explanation || "",
      completedAt: session.completedAt,
    };
  }
  const selected = body.selectedAnswer;
  if (!Number.isInteger(selected) || selected < 0 || selected >= session.options.length) {
    throw new Error("Select one answer before submitting.");
  }
  const [questionDoc, answerDoc] = await Promise.all([
    getDocument(env, "mcqs", session.questionId),
    getDocument(env, "mcq_answer_keys", session.questionId),
  ]);
  if (!questionDoc || questionDoc.data.isPublished !== true || !answerDoc) {
    throw new Error("The daily question or its private answer key is unavailable.");
  }
  const correctAnswer = String(answerDoc.data.correctAnswer || "").toUpperCase();
  const correctIndex = "ABCDE".indexOf(correctAnswer);
  if (correctIndex < 0 || correctIndex >= session.options.length) {
    throw new Error("The daily question has an invalid answer key.");
  }
  const isCorrect = selected === correctIndex;
  const completedAt = new Date().toISOString();
  const attemptId = crypto.randomUUID();
  const attempt = {
    userId: uid, date: today, questionId: session.questionId,
    question: session.question, options: session.options,
    selectedAnswer: String.fromCharCode(65 + selected),
    correctAnswer, isCorrect, explanation: answerDoc.data.explanation || "",
    subject: session.subject || "", topic: session.topic || "",
    difficulty: session.difficulty || "Medium",
    completedAt, createdAt: completedAt,
  };
  const statsDoc = await getDocument(env, "daily_challenge_stats", uid);
  const old = statsDoc?.data || {};
  const yesterday = utcDayKey(new Date(Date.now() - 86400000));
  const lastDate = old.lastChallengeDate || "";
  const currentStreak = lastDate === today
    ? Number(old.currentStreak) || 1
    : lastDate === yesterday ? (Number(old.currentStreak) || 0) + 1 : 1;
  const stats = {
    userId: uid, currentStreak,
    longestStreak: Math.max(Number(old.longestStreak) || 0, currentStreak),
    totalCompleted: (Number(old.totalCompleted) || 0) + 1,
    totalCorrect: (Number(old.totalCorrect) || 0) + (isCorrect ? 1 : 0),
    lastChallengeDate: today, updatedAt: completedAt,
  };
  const updatedSession = {
    ...session, status: "completed",
    selectedAnswer: attempt.selectedAnswer, correctAnswer,
    isCorrect, explanation: attempt.explanation,
    completedAt, attemptId,
  };
  const writes = [
    {
      update: {
        name: `projects/${PROJECT_ID}/databases/(default)/documents/daily_challenge_attempts/${attemptId}`,
        fields: encodeFields(attempt),
      },
      currentDocument: { exists: false },
    },
    {
      update: {
        name: sessionDoc.name,
        fields: encodeFields(updatedSession),
      },
      updateMask: { fieldPaths: Object.keys(updatedSession) },
      currentDocument: { updateTime: sessionDoc.updateTime },
    },
  ];
  if (statsDoc) {
    writes.push({
      update: {
        name: statsDoc.name,
        fields: encodeFields(stats),
      },
      updateMask: { fieldPaths: Object.keys(stats) },
      currentDocument: { updateTime: statsDoc.updateTime },
    });
  } else {
    writes.push({
      update: {
        name: `projects/${PROJECT_ID}/databases/(default)/documents/daily_challenge_stats/${uid}`,
        fields: encodeFields(stats),
      },
      currentDocument: { exists: false },
    });
  }
  await firestoreRequest(env, ":commit", {
    method: "POST", body: JSON.stringify({ writes }),
  });
  return {
    success: true, isCorrect, selectedAnswer: attempt.selectedAnswer,
    correctAnswer, explanation: attempt.explanation, completedAt,
    currentStreak, longestStreak: stats.longestStreak,
    totalCompleted: stats.totalCompleted, totalCorrect: stats.totalCorrect,
  };
}

async function checkBackendReady(env) {
  await getServiceAccessToken(env);
  // A no-result/one-result query confirms the service account can reach Firestore.
  await firestoreRequest(env, ":runQuery", {
    method: "POST",
    body: JSON.stringify({
      structuredQuery: { from: [{ collectionId: "users" }], limit: 1 },
    }),
  });
}

export default {
  async fetch(request, env) {
    if (request.method === "OPTIONS") return new Response(null, { status: 204, headers: CORS });
    const healthUrl = new URL(request.url);
    if (request.method === "GET" && healthUrl.pathname === "/health") {
      try {
        await checkBackendReady(env);
        return response({ success: true, status: "ready" });
      } catch (error) {
        return response({ success: false, status: "not_ready", message: error?.message || "Backend unavailable." }, 503);
      }
    }
    const url = new URL(request.url);
    if (request.method !== "POST" || !["/start", "/submit", "/daily/start", "/daily/status", "/daily/submit"].includes(url.pathname)) {
      return fail("Endpoint not found.", 404);
    }
    try {
      const authorization = request.headers.get("Authorization") || "";
      const match = authorization.match(/^Bearer\s+(.+)$/i);
      if (!match) return fail("Please sign in first.", 401);
      const claims = await verifyFirebaseToken(match[1]);
      const body = await request.json();
      if (!body || typeof body !== "object" || Array.isArray(body)) return fail("Invalid request.", 400);
      const result = url.pathname === "/start"
        ? await startSession(env, claims.sub, body)
        : url.pathname === "/submit"
          ? await submitSession(env, claims.sub, body)
          : url.pathname === "/daily/start"
            ? await dailyChallengeStart(env, claims.sub)
            : url.pathname === "/daily/status"
              ? await dailyChallengeStatus(env, claims.sub)
              : await dailyChallengeSubmit(env, claims.sub, body);
      return response(result);
    } catch (error) {
      const message = error?.message || "The MCQ request could not be completed.";
      const status = /sign-in token|sign in first|expired/i.test(message) ? 401 :
        /not found|unavailable/i.test(message) ? 404 :
        /subscription|permission|not available to your account/i.test(message) ? 403 :
        /submission window/i.test(message) ? 410 : 400;
      return fail(message, status);
    }
  },
};
