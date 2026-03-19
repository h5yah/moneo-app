const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

setGlobalOptions({
  region: "us-central1",
  maxInstances: 10,
});

function requireAuth(request) {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }
  return uid;
}

function validatePositiveInteger(value, fieldName) {
  if (!Number.isInteger(value) || value <= 0) {
    throw new HttpsError("invalid-argument", `${fieldName} must be a positive integer.`);
  }
}

function validatePositiveNumber(value, fieldName) {
  if (typeof value !== "number" || !Number.isFinite(value) || value <= 0) {
    throw new HttpsError("invalid-argument", `${fieldName} must be a positive number.`);
  }
}

function sanitizeString(value, fallback = "") {
  if (typeof value !== "string") return fallback;
  return value.trim();
}

function toNumber(value, fallback = 0) {
  const normalized = Number(value);
  if (!Number.isFinite(normalized)) return fallback;
  return normalized;
}

function buildTransactionPayload({
  uid,
  type,
  amount,
  expenseName,
  category,
  merchantName,
  merchantId,
  merchantAccount,
  rawPayload,
  note,
  metadata,
}) {
  return {
    userId: uid,
    type,
    amount,
    myShare: amount,
    expenseName,
    category,
    merchantName,
    merchantId,
    merchantAccount,
    rawPayload,
    note,
    date: new Date().toISOString(),
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    metadata: metadata ?? {},
  };
}

async function performFinanceTransaction({
  uid,
  amount,
  type,
  expenseName,
  category,
  note,
  metadata,
  merchantName,
  merchantId,
  merchantAccount,
  rawPayload,
  operation,
}) {
  const balanceRef = db.collection("balances").doc(uid);
  const transactionRef = db.collection("transactions").doc();

  return db.runTransaction(async (tx) => {
    const balanceSnap = await tx.get(balanceRef);
    const balanceData = balanceSnap.data() ?? {};

    const currentAvailable = toNumber(balanceData.available, 0);
    const currentIncome = toNumber(balanceData.income, 0);
    const currentSpent = toNumber(balanceData.spent, 0);
    const currentSaved = toNumber(balanceData.saved, 0);

    const next = operation({
      currentAvailable,
      currentIncome,
      currentSpent,
      currentSaved,
      amount,
    });

    tx.set(
      balanceRef,
      {
        available: next.available,
        income: next.income,
        spent: next.spent,
        saved: next.saved,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    tx.set(
      transactionRef,
      buildTransactionPayload({
        uid,
        type,
        amount,
        expenseName,
        category,
        merchantName,
        merchantId,
        merchantAccount,
        rawPayload,
        note,
        metadata,
      }),
      { merge: true }
    );

    return {
      available: next.available,
      income: next.income,
      spent: next.spent,
      saved: next.saved,
    };
  });
}

exports.getXp = onCall(async (request) => {
  const uid = requireAuth(request);
  const userRef = db.collection("users").doc(uid);
  const snap = await userRef.get();

  if (!snap.exists) {
    throw new HttpsError("not-found", "User profile does not exist.");
  }

  const xp = Number(snap.data()?.xp ?? 0);
  return { xp };
});

exports.earnXp = onCall(async (request) => {
  const uid = requireAuth(request);
  const amount = request.data?.amount;

  validatePositiveInteger(amount, "amount");

  const userRef = db.collection("users").doc(uid);

  const updatedXp = await db.runTransaction(async (tx) => {
    const snap = await tx.get(userRef);
    if (!snap.exists) {
      throw new HttpsError("not-found", "User profile does not exist.");
    }

    const currentXp = Number(snap.data()?.xp ?? 0);
    const newXp = currentXp + amount;

    tx.update(userRef, {
      xp: newXp,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    tx.set(
      userRef.collection("xpTransactions").doc(),
      {
        type: "earn",
        amount,
        previousXp: currentXp,
        newXp,
        source: request.data?.source ?? "unknown",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    return newXp;
  });

  return { xp: updatedXp };
});

exports.spendXp = onCall(async (request) => {
  const uid = requireAuth(request);
  const amount = request.data?.amount;

  validatePositiveInteger(amount, "amount");

  const userRef = db.collection("users").doc(uid);

  const updatedXp = await db.runTransaction(async (tx) => {
    const snap = await tx.get(userRef);
    if (!snap.exists) {
      throw new HttpsError("not-found", "User profile does not exist.");
    }

    const currentXp = Number(snap.data()?.xp ?? 0);
    if (currentXp < amount) {
      throw new HttpsError("failed-precondition", "Not enough XP.");
    }

    const newXp = currentXp - amount;

    tx.update(userRef, {
      xp: newXp,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    tx.set(
      userRef.collection("xpTransactions").doc(),
      {
        type: "spend",
        amount,
        previousXp: currentXp,
        newXp,
        source: request.data?.source ?? "unknown",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    return newXp;
  });

  return { xp: updatedXp };
});

exports.getFinanceSummary = onCall(async (request) => {
  const uid = requireAuth(request);
  const balanceRef = db.collection("balances").doc(uid);
  const snap = await balanceRef.get();
  const data = snap.data() ?? {};

  return {
    available: toNumber(data.available, 0),
    income: toNumber(data.income, 0),
    spent: toNumber(data.spent, 0),
    saved: toNumber(data.saved, 0),
    weeklyBudget: toNumber(data.weeklyBudget, 0),
  };
});

exports.addFunds = onCall(async (request) => {
  const uid = requireAuth(request);
  const amount = request.data?.amount;
  const destination = sanitizeString(request.data?.destination, "general").toLowerCase();
  const source = sanitizeString(request.data?.source, "manual");

  validatePositiveNumber(amount, "amount");

  if (!["general", "emergency"].includes(destination)) {
    throw new HttpsError(
      "invalid-argument",
      "destination must be either 'general' or 'emergency'."
    );
  }

  const balances = await performFinanceTransaction({
    uid,
    amount,
    type: "add_funds",
    expenseName: destination === "emergency" ? "Emergency Fund Top-up" : "Funds Added",
    category: destination,
    note: "",
    metadata: {
      source,
      destination,
    },
    operation: ({ currentAvailable, currentIncome, currentSpent, currentSaved, amount }) => {
      return {
        available: destination === "general" ? currentAvailable + amount : currentAvailable,
        income: currentIncome + amount,
        spent: currentSpent,
        saved: destination === "emergency" ? currentSaved + amount : currentSaved,
      };
    },
  });

  return {
    ok: true,
    balances,
  };
});

exports.logExpense = onCall(async (request) => {
  const uid = requireAuth(request);
  const amount = request.data?.amount;
  const expenseName = sanitizeString(request.data?.expenseName, "Expense");
  const category = sanitizeString(request.data?.category, "other");
  const note = sanitizeString(request.data?.note, "");
  const source = sanitizeString(request.data?.source, "manual");

  validatePositiveNumber(amount, "amount");

  const balances = await performFinanceTransaction({
    uid,
    amount,
    type: "expense",
    expenseName,
    category,
    note,
    metadata: {
      source,
    },
    operation: ({ currentAvailable, currentIncome, currentSpent, currentSaved, amount }) => {
      if (currentAvailable < amount) {
        throw new HttpsError("failed-precondition", "Insufficient available balance.");
      }

      return {
        available: currentAvailable - amount,
        income: currentIncome,
        spent: currentSpent + amount,
        saved: currentSaved,
      };
    },
  });

  return {
    ok: true,
    balances,
  };
});

exports.scanToPay = onCall(async (request) => {
  const uid = requireAuth(request);
  const amount = request.data?.amount;
  const merchantName = sanitizeString(request.data?.merchantName, "Unknown Merchant");
  const merchantId = sanitizeString(request.data?.merchantId, "");
  const merchantAccount = sanitizeString(request.data?.merchantAccount, "");
  const rawPayload = sanitizeString(request.data?.rawPayload, "");

  validatePositiveNumber(amount, "amount");

  const balances = await performFinanceTransaction({
    uid,
    amount,
    type: "scan_to_pay",
    expenseName: `Payment to ${merchantName}`,
    category: "payment",
    note: "",
    metadata: {
      method: "qr",
    },
    merchantName,
    merchantId,
    merchantAccount,
    rawPayload,
    operation: ({ currentAvailable, currentIncome, currentSpent, currentSaved, amount }) => {
      if (currentAvailable < amount) {
        throw new HttpsError("failed-precondition", "Insufficient available balance.");
      }

      return {
        available: currentAvailable - amount,
        income: currentIncome,
        spent: currentSpent + amount,
        saved: currentSaved,
      };
    },
  });

  return {
    ok: true,
    balances,
  };
});

exports.payBill = onCall(async (request) => {
  const uid = requireAuth(request);
  const amount = request.data?.amount;
  const billName = sanitizeString(request.data?.billName, "Bill Payment");
  const billerId = sanitizeString(request.data?.billerId, "");
  const note = sanitizeString(request.data?.note, "");

  validatePositiveNumber(amount, "amount");

  const balances = await performFinanceTransaction({
    uid,
    amount,
    type: "bill_payment",
    expenseName: billName,
    category: "bills",
    note,
    metadata: {
      billerId,
    },
    operation: ({ currentAvailable, currentIncome, currentSpent, currentSaved, amount }) => {
      if (currentAvailable < amount) {
        throw new HttpsError("failed-precondition", "Insufficient available balance.");
      }

      return {
        available: currentAvailable - amount,
        income: currentIncome,
        spent: currentSpent + amount,
        saved: currentSaved,
      };
    },
  });

  return {
    ok: true,
    balances,
  };
});
