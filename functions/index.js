
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;
const Timestamp = admin.firestore.Timestamp;

// ---------------------------------------------
// SECURITY HELPERS
// ---------------------------------------------

function verifyAdmin(request) {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "You must be signed in to perform this action."
    );
  }

  if (request.auth.token.admin !== true) {
    throw new HttpsError(
      "permission-denied",
      "Only authorized administrators can perform this action."
    );
  }
}

function validateRequestId(data) {
  const requestId = data?.requestId;

  if (
    typeof requestId !== "string" ||
    requestId.trim().length < 1 ||
    requestId.length > 150
  ) {
    throw new HttpsError(
      "invalid-argument",
      "A valid subscription request ID is required."
    );
  }

  return requestId.trim();
}

function cleanAdminNote(note) {
  if (note === undefined || note === null) return "";

  if (typeof note !== "string") {
    throw new HttpsError(
      "invalid-argument",
      "The admin note must be text."
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
      "failed-precondition",
      "The requested payment amount does not match the subscription plan."
    );
  }

  const requestedCurrency =
    typeof requestData.currency === "string"
      ? requestData.currency.trim().toUpperCase()
      : "";

  const planCurrency =
    typeof plan.currency === "string"
      ? plan.currency.trim().toUpperCase()
      : "";

  if (!requestedCurrency || requestedCurrency !== planCurrency) {
    throw new HttpsError(
      "failed-precondition",
      "The payment currency does not match the subscription plan."
    );
  }

  if (
    typeof requestData.transactionReference !== "string" ||
    requestData.transactionReference.trim().length < 3
  ) {
    throw new HttpsError(
      "failed-precondition",
      "The payment transaction reference is missing or invalid."
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
      "failed-precondition",
      "The requested subscription duration does not match the plan."
    );
  }
}

// ---------------------------------------------
// APPROVE SUBSCRIPTION REQUEST
// ---------------------------------------------

exports.approveSubscriptionRequest = onCall(async (request) => {
  verifyAdmin(request);

  const requestId = validateRequestId(request.data);
  const adminNote = cleanAdminNote(request.data?.adminNote);

  const requestRef = db
    .collection("subscription_requests")
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

      // Read every required document before writing.
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

      // If the student already has an active subscription,
      // extend it instead of discarding the remaining days.
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

// ---------------------------------------------
// REJECT SUBSCRIPTION REQUEST
// ---------------------------------------------

exports.rejectSubscriptionRequest = onCall(async (request) => {
  verifyAdmin(request);

  const requestId = validateRequestId(request.data);
  const adminNote = cleanAdminNote(request.data?.adminNote);

  if (!adminNote) {
    throw new HttpsError(
      "invalid-argument",
      "Please provide a reason for rejecting this request."
    );
  }

  const requestRef = db
    .collection("subscription_requests")
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

// ---------------------------------------------
// AUTOMATIC SUBSCRIPTION EXPIRY
// Runs every day at 12:15 AM Pakistan time.
// ---------------------------------------------

exports.expireSubscriptions = onSchedule(
  {
    schedule: "every day 00:15",
    timeZone: "Asia/Karachi",
    region: "asia-south1",
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
        
