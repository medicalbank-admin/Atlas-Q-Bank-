const { onCall, HttpsError } = require(“firebase-functions/v2/https”);
const { onSchedule } = require(“firebase-functions/v2/scheduler”);
const admin = require(“firebase-admin”);

admin.initializeApp();

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;
const Timestamp = admin.firestore.Timestamp;

// ———————————————
// SECURITY HELPERS
// ———————————————

function verifyAdmin(request) {
if (!request.auth) {
throw new HttpsError(
“unauthenticated”,
“You must be signed in to perform this action.”
);
}

if (request.auth.token.admin !== true) {
throw new HttpsError(
“permission-denied”,
“Only authorized administrators can perform this action.”
);
}
}

function validateRequestId(data) {
const requestId = data?.requestId;

if (
typeof requestId !== “string” ||
requestId.trim().length < 1 ||
requestId.length > 150
) {
throw new HttpsError(
“invalid-argument”,
“A valid subscription request ID is required.”
);
}

return requestId.trim();
}

function cleanAdminNote(note) {
if (note === undefined || note === null) return “”;

if (typeof note !== “string”) {
throw new HttpsError(
“invalid-argument”,
“The admin note must be text.”
);
}

return note.trim().slice(0, 1000);
}

function validatePaymentDetails(requestData, plan) {
const requestedAmount = Number(requestData.amount);
const planPrice = Number(plan.price);

if (
!Number.isFinite(requestedAmount) ||
!Number.isFinite(planPrice) ||
requestedAmount <= 0 ||
planPrice <= 0 ||
Math.abs(requestedAmount - planPrice) > 0.001
) {
throw new HttpsError(
“failed-precondition”,
“The requested payment amount does not match the subscription plan.”
);
}

const requestedCurrency =
typeof requestData.currency === “string”
? requestData.currency.trim().toUpperCase()
: “”;

const planCurrency =
typeof plan.currency === “string”
? plan.currency.trim().toUpperCase()
: “”;

if (!requestedCurrency || requestedCurrency !== planCurrency) {
throw new HttpsError(
“failed-precondition”,
“The payment currency does not match the subscription plan.”
);
}

if (
typeof requestData.transactionReference !== “string” ||
requestData.transactionReference.trim().length < 3
) {
throw new HttpsError(
“failed-precondition”,
“The payment transaction reference is missing or invalid.”
);
}

const requestedDuration = Number(requestData.durationDays);
const planDuration = Number(plan.durationDays);

if (
!Number.isInteger(requestedDuration) ||
!Number.isInteger(planDuration) ||
requestedDuration !== planDuration
) {
throw new HttpsError(
“failed-precondition”,
“The requested subscription duration does not match the plan.”
);
}
}

// ———————————————
// APPROVE SUBSCRIPTION REQUEST
// ———————————————

exports.approveSubscriptionRequest = onCall(async (request) => {
verifyAdmin(request);

const requestId = validateRequestId(request.data);
const adminNote = cleanAdminNote(request.data?.adminNote);

const requestRef = db
.collection(“subscription_requests”)
.doc(requestId);

try {
const result = await db.runTransaction(async (transaction) => {
const requestSnapshot = await transaction.get(requestRef);

  if (!requestSnapshot.exists) {
    throw new HttpsError(
      "not-found",
      "The subscription request could not be found."
    );
  }
  const requestData = requestSnapshot.data();
  if (requestData.status !== "pending") {
    throw new HttpsError(
      "failed-precondition",
      "This request has already been reviewed."
    );
  }
  const studentUid = requestData.studentUid;
  const planId = requestData.planId;
  if (
    typeof studentUid !== "string" ||
    !studentUid.trim() ||
    typeof planId !== "string" ||
    !planId.trim()
  ) {
    throw new HttpsError(
      "failed-precondition",
      "The request is missing student or plan information."
    );
  }
  const studentRef = db.collection("users").doc(studentUid);
  const planRef = db.collection("subscription_plans").doc(planId);
  const studentSnapshot = await transaction.get(studentRef);
  const planSnapshot = await transaction.get(planRef);
  if (!studentSnapshot.exists) {
    throw new HttpsError(
      "not-found",
      "The student account could not be found."
    );
  }
  if (!planSnapshot.exists) {
    throw new HttpsError(
      "not-found",
      "The subscription plan could not be found."
    );
  }
  const plan = planSnapshot.data();
  const student = studentSnapshot.data();
  if (plan.isActive !== true) {
    throw new HttpsError(
      "failed-precondition",
      "This subscription plan is no longer active."
    );
  }
  validatePaymentDetails(requestData, plan);
  const durationDays = Number(plan.durationDays);
  const permissions = plan.accessPermissions;
  if (
    !Number.isInteger(durationDays) ||
    durationDays < 1 ||
    durationDays > 3650
  ) {
    throw new HttpsError(
      "failed-precondition",
      "The subscription plan has an invalid duration."
    );
  }
  if (
    permissions === null ||
    typeof permissions !== "object" ||
    Array.isArray(permissions)
  ) {
    throw new HttpsError(
      "failed-precondition",
      "The subscription plan has invalid access permissions."
    );
  }
  const nowDate = new Date();
  let subscriptionStartDate = nowDate;
  let expiryBaseDate = nowDate;
  const existingExpiry = student.subscriptionExpiryAt;
  if (
    student.subscriptionStatus === "active" &&
    existingExpiry &&
    typeof existingExpiry.toDate === "function"
  ) {
    const existingExpiryDate = existingExpiry.toDate();
    if (existingExpiryDate > nowDate) {
      expiryBaseDate = existingExpiryDate;
      if (
        student.subscriptionStartedAt &&
        typeof student.subscriptionStartedAt.toDate === "function"
      ) {
        subscriptionStartDate =
          student.subscriptionStartedAt.toDate();
      }
    }
  }
  const expiryDate = new Date(
    expiryBaseDate.getTime() +
    durationDays * 24 * 60 * 60 * 1000
  );
  const now = FieldValue.serverTimestamp();
  transaction.update(requestRef, {
    status: "approved",
    adminNote,
    reviewedBy: request.auth.uid,
    reviewedAt: now,
    updatedAt: now,
  });
  transaction.update(studentRef, {
    accountStatus: "approved",
    subscriptionStatus: "active",
    accessEnabled: true,
    subscriptionPlanId: planId,
    subscriptionPlanName: plan.name || "Subscription",
    subscriptionDurationDays: durationDays,
    subscriptionAccessPermissions: permissions,
    subscriptionStartedAt:
      Timestamp.fromDate(subscriptionStartDate),
    subscriptionExpiryAt: Timestamp.fromDate(expiryDate),
    updatedAt: now,
  });
  return {
    studentUid,
    planName: plan.name || "Subscription",
    expiryDate: expiryDate.toISOString(),
  };
});
return {
  success: true,
  message: "Subscription approved successfully.",
  ...result,
};

} catch (error) {
if (error instanceof HttpsError) throw error;

console.error("Subscription approval failed:", error);
throw new HttpsError(
  "internal",
  "The subscription could not be approved. Please try again."
);

}
});

// ———————————————
// REJECT SUBSCRIPTION REQUEST
// ———————————————

exports.rejectSubscriptionRequest = onCall(async (request) => {
verifyAdmin(request);

const requestId = validateRequestId(request.data);
const adminNote = cleanAdminNote(request.data?.adminNote);

if (!adminNote) {
throw new HttpsError(
“invalid-argument”,
“Please provide a reason for rejecting this request.”
);
}

const requestRef = db
.collection(“subscription_requests”)
.doc(requestId);

try {
await db.runTransaction(async (transaction) => {
const requestSnapshot = await transaction.get(requestRef);

  if (!requestSnapshot.exists) {
    throw new HttpsError(
      "not-found",
      "The subscription request could not be found."
    );
  }
  if (requestSnapshot.data().status !== "pending") {
    throw new HttpsError(
      "failed-precondition",
      "This request has already been reviewed."
    );
  }
  const now = FieldValue.serverTimestamp();
  transaction.update(requestRef, {
    status: "rejected",
    adminNote,
    reviewedBy: request.auth.uid,
    reviewedAt: now,
    updatedAt: now,
  });
});
return {
  success: true,
  message: "Subscription request rejected successfully.",
};

} catch (error) {
if (error instanceof HttpsError) throw error;

console.error("Subscription rejection failed:", error);
throw new HttpsError(
  "internal",
  "The request could not be rejected. Please try again."
);

}
});

// ———————————————
// SECURE MCQ PRACTICE SUBMISSION
//
// Students submit question IDs and selected option
// indexes only. Correct answers and explanations
// are read from the private mcq_answer_keys collection.
// Scores are calculated and saved by the server.
// ———————————————

exports.submitMcqPractice = onCall(
{
region: “asia-south1”,
enforceAppCheck: false,
},
async (request) => {
if (!request.auth) {
throw new HttpsError(
“unauthenticated”,
“Please sign in before submitting your practice.”
);
}

const userId = request.auth.uid;
const data = request.data || {};
const questionIds = data.questionIds;
const selectedAnswers = data.selectedAnswers;
const startedAtValue = data.startedAt;
if (
  !Array.isArray(questionIds) ||
  questionIds.length < 1 ||
  questionIds.length > 100
) {
  throw new HttpsError(
    "invalid-argument",
    "A practice session must contain between 1 and 100 questions."
  );
}
if (
  !selectedAnswers ||
  typeof selectedAnswers !== "object" ||
  Array.isArray(selectedAnswers)
) {
  throw new HttpsError(
    "invalid-argument",
    "The selected answers are invalid."
  );
}
const uniqueIds = new Set();
for (const questionId of questionIds) {
  if (
    typeof questionId !== "string" ||
    questionId.trim().length < 1 ||
    questionId.length > 150
  ) {
    throw new HttpsError(
      "invalid-argument",
      "A question ID is invalid."
    );
  }
  if (uniqueIds.has(questionId)) {
    throw new HttpsError(
      "invalid-argument",
      "Duplicate questions are not allowed."
    );
  }
  uniqueIds.add(questionId);
}
const allowedAnswerIds = new Set(questionIds);
for (const key of Object.keys(selectedAnswers)) {
  if (!allowedAnswerIds.has(key)) {
    throw new HttpsError(
      "invalid-argument",
      "An answer was submitted for a question outside this session."
    );
  }
  const value = selectedAnswers[key];
  if (
    value !== null &&
    (!Number.isInteger(value) || value < 0 || value > 4)
  ) {
    throw new HttpsError(
      "invalid-argument",
      "A selected option index is invalid."
    );
  }
}
let startedAt = new Date();
if (typeof startedAtValue === "string") {
  const parsedDate = new Date(startedAtValue);
  if (Number.isNaN(parsedDate.getTime())) {
    throw new HttpsError(
      "invalid-argument",
      "The practice start time is invalid."
    );
  }
  startedAt = parsedDate;
}
const nowDate = new Date();
if (
  startedAt.getTime() > nowDate.getTime() + 60000 ||
  startedAt.getTime() < nowDate.getTime() - 24 * 60 * 60 * 1000
) {
  throw new HttpsError(
    "invalid-argument",
    "The practice start time is outside the allowed range."
  );
}
const userRef = db.collection("users").doc(userId);
const questionRefs = questionIds.map((id) =>
  db.collection("mcqs").doc(id)
);
const answerKeyRefs = questionIds.map((id) =>
  db.collection("mcq_answer_keys").doc(id)
);
try {
  const result = await db.runTransaction(async (transaction) => {
    const userSnapshot = await transaction.get(userRef);
    if (!userSnapshot.exists) {
      throw new HttpsError(
        "permission-denied",
        "Your student profile could not be found."
      );
    }
    const user = userSnapshot.data();
    const expiry = user.subscriptionExpiryAt;
    const subscriptionStillValid =
      expiry &&
      typeof expiry.toDate === "function" &&
      expiry.toDate().getTime() > Date.now();
    if (
      user.accessEnabled !== true ||
      user.subscriptionStatus !== "active" ||
      !subscriptionStillValid
    ) {
      throw new HttpsError(
        "permission-denied",
        "An active subscription is required to submit MCQ practice."
      );
    }
    const questionSnapshots = [];
    for (let i = 0; i < questionRefs.length; i += 1) {
      const questionSnapshot = await transaction.get(
        questionRefs[i]
      );
      const answerKeySnapshot = await transaction.get(
        answerKeyRefs[i]
      );
      if (
        !questionSnapshot.exists ||
        !answerKeySnapshot.exists
      ) {
        throw new HttpsError(
          "failed-precondition",
          "A question or its answer key is unavailable."
        );
      }
      const question = questionSnapshot.data();
      const answerKey = answerKeySnapshot.data();
      if (question.isPublished !== true) {
        throw new HttpsError(
          "failed-precondition",
          "This practice contains an unpublished question."
        );
      }
      const options = question.options;
      if (
        !Array.isArray(options) ||
        options.length < 4 ||
        options.length > 5 ||
        options.some(
          (option) =>
            typeof option !== "string" ||
            option.trim().length === 0
        )
      ) {
        throw new HttpsError(
          "failed-precondition",
          "A question has invalid options."
        );
      }
      const correctAnswer =
        typeof answerKey.correctAnswer === "string"
          ? answerKey.correctAnswer.trim().toUpperCase()
          : "";
      const correctIndex = "ABCDE".indexOf(correctAnswer);
      if (
        correctIndex < 0 ||
        correctIndex >= options.length
      ) {
        throw new HttpsError(
          "failed-precondition",
          "A question has an invalid private answer key."
        );
      }
      questionSnapshots.push({
        id: questionIds[i],
        question,
        options,
        correctAnswer,
        correctIndex,
        explanation:
          typeof answerKey.explanation === "string"
            ? answerKey.explanation
            : "",
      });
    }
    let correctAnswers = 0;
    let incorrectAnswers = 0;
    let unansweredQuestions = 0;
    const answerSnapshots = [];
    const subjects = new Set();
    const topics = new Set();
    for (const item of questionSnapshots) {
      const question = item.question;
      const selectedIndex =
        selectedAnswers[item.id] === undefined
          ? null
          : selectedAnswers[item.id];
      if (
        selectedIndex !== null &&
        selectedIndex >= item.options.length
      ) {
        throw new HttpsError(
          "invalid-argument",
          "A selected answer exceeds the available options."
        );
      }
      const isAnswered = selectedIndex !== null;
      const isCorrect =
        isAnswered && selectedIndex === item.correctIndex;
      if (!isAnswered) {
        unansweredQuestions += 1;
      } else if (isCorrect) {
        correctAnswers += 1;
      } else {
        incorrectAnswers += 1;
      }
      const subject =
        typeof question.subject === "string"
          ? question.subject.trim()
          : "";
      const topic =
        typeof question.topic === "string"
          ? question.topic.trim()
          : "";
      if (subject) subjects.add(subject);
      if (topic) topics.add(topic);
      answerSnapshots.push({
        questionId: item.id,
        question: question.question || "",
        options: item.options,
        selectedAnswer:
          selectedIndex === null
            ? null
            : String.fromCharCode(65 + selectedIndex),
        correctAnswer: item.correctAnswer,
        isAnswered,
        isCorrect,
        explanation: item.explanation,
        subject,
        topic,
        difficulty: question.difficulty || "Medium",
        reference: question.reference || "",
      });
    }
    const totalQuestions = questionSnapshots.length;
    const percentage =
      (correctAnswers / totalQuestions) * 100;
    const attemptRef = db.collection("mcq_attempts").doc();
    const attemptData = {
      userId,
      type: "practice",
      totalQuestions,
      correctAnswers,
      incorrectAnswers,
      unansweredQuestions,
      percentage,
      questionIds,
      answers: answerSnapshots,
      subject: Array.from(subjects).join(", "),
      topic: Array.from(topics).join(", "),
      subjects: Array.from(subjects),
      topics: Array.from(topics),
      startedAt: Timestamp.fromDate(startedAt),
      completedAt: FieldValue.serverTimestamp(),
      createdAt: FieldValue.serverTimestamp(),
      scoringMethod: "server",
    };
    transaction.create(attemptRef, attemptData);
    return {
      attemptId: attemptRef.id,
      totalQuestions,
      correctAnswers,
      incorrectAnswers,
      unansweredQuestions,
      percentage,
    };
  });
  return {
    success: true,
    message: "Practice submitted successfully.",
    ...result,
  };
} catch (error) {
  if (error instanceof HttpsError) throw error;
  console.error("MCQ practice submission failed:", error);
  throw new HttpsError(
    "internal",
    "Your practice could not be submitted. Please try again."
  );
}

}
);

// ———————————————
// AUTOMATIC SUBSCRIPTION EXPIRY
// Runs every day at 12:15 AM Pakistan time.
// ———————————————

exports.expireSubscriptions = onSchedule(
{
schedule: “every day 00:15”,
timeZone: “Asia/Karachi”,
region: “asia-south1”,
},
async () => {
const now = Timestamp.now();
let totalExpired = 0;

while (true) {
  const expiredStudents = await db
    .collection("users")
    .where("subscriptionStatus", "==", "active")
    .where("subscriptionExpiryAt", "<=", now)
    .limit(400)
    .get();
  if (expiredStudents.empty) {
    break;
  }
  const batch = db.batch();
  for (const student of expiredStudents.docs) {
    batch.update(student.ref, {
      subscriptionStatus: "expired",
      accessEnabled: false,
      updatedAt: FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
  totalExpired += expiredStudents.size;
  if (expiredStudents.size < 400) {
    break;
  }
}
console.log(
  `Subscription expiry check completed. Expired: ${totalExpired}`
);
return {
  success: true,
  expiredCount: totalExpired,
};

}
);
