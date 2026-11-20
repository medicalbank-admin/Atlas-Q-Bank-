const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;
const Timestamp = admin.firestore.Timestamp;

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
      "Only authorized administrators can review subscription requests."
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

/**
 * Approves a student's subscription request.
 *
 * All important subscription values are read from the
 * administrator-controlled subscription plan document.
 * The student cannot choose their own access permissions.
 */
exports.approveSubscriptionRequest = onCall(async (request) => {
  verifyAdmin(request);

  const requestId = validateRequestId(request.data);
  const adminNote = cleanAdminNote(request.data?.adminNote);

  const requestRef = db.collection("subscription_requests").doc(requestId);

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
        studentUid.length === 0 ||
        typeof planId !== "string" ||
        planId.length === 0
      ) {
        throw new HttpsError(
          "failed-precondition",
          "The request is missing its student or plan information."
        );
      }

      const studentRef = db.collection("users").doc(studentUid);
      const planRef = db.collection("subscription_plans").doc(planId);

      // Complete all transaction reads before writing.
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

      if (plan.isActive !== true) {
        throw new HttpsError(
          "failed-precondition",
          "This subscription plan is no longer active."
        );
      }

      const durationDays = Number(plan.durationDays);

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

      const permissions = plan.accessPermissions;

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

      const startDate = new Date();
      const expiryDate = new Date(
        startDate.getTime() + durationDays * 24 * 60 * 60 * 1000
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

        subscriptionStartedAt: Timestamp.fromDate(startDate),
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

/**
 * Rejects a student's subscription request.
 * Rejection does not grant or change subscription access.
 */
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

  const requestRef = db.collection("subscription_requests").doc(requestId);

  try {
    await db.runTransaction(async (transaction) => {
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
      
