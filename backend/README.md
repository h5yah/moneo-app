# Backend Cloud Functions

This backend includes secure XP and Finance operations using Firebase Cloud Functions.

## Functions

- `getXp` - returns authenticated user XP total.
- `earnXp` - increments XP atomically.
- `spendXp` - decrements XP atomically, blocks overspending.

### Finance functions

- `getFinanceSummary` - returns authenticated user balances (`available`, `income`, `spent`, `saved`, `weeklyBudget`).
- `addFunds` - atomically adds funds and logs a transaction.
- `logExpense` - atomically deducts from available balance and logs an expense.
- `scanToPay` - atomically performs merchant QR payment and logs transaction metadata.
- `payBill` - atomically pays a bill and logs it as `bill_payment`.

All functions require Firebase Authentication (`request.auth.uid`).

## Data model

- Main user XP: `users/{uid}.xp`
- Audit log: `users/{uid}/xpTransactions/{transactionId}`

Finance collections:

- Balances: `balances/{uid}`
- Transactions: `transactions/{transactionId}`

## Setup

1. Install Firebase CLI (if needed):
   - `npm i -g firebase-tools`
2. Login:
   - `firebase login`
3. Update project id in `.firebaserc`.
4. Install function dependencies:
   - `cd backend/functions && npm install`

## Run locally

- From `backend/functions`:
  - `npm run serve`

## Deploy

- From `backend/functions`:
  - `npm run deploy`

## Suggested frontend calls

Use Flutter `cloud_functions` package and call:

- `FirebaseFunctions.instance.httpsCallable('getXp')`
- `FirebaseFunctions.instance.httpsCallable('earnXp').call({'amount': 10, 'source': 'quiz_correct'})`
- `FirebaseFunctions.instance.httpsCallable('spendXp').call({'amount': 500, 'source': 'deal_claim'})`

Finance call examples:

- `FirebaseFunctions.instance.httpsCallable('getFinanceSummary').call()`
- `FirebaseFunctions.instance.httpsCallable('addFunds').call({'amount': 1000, 'destination': 'general', 'source': 'card'})`
- `FirebaseFunctions.instance.httpsCallable('logExpense').call({'amount': 300, 'expenseName': 'Groceries', 'category': 'food', 'source': 'manual'})`
- `FirebaseFunctions.instance.httpsCallable('scanToPay').call({'amount': 250, 'merchantName': 'Cafe', 'merchantId': 'M123', 'merchantAccount': 'cafe@bank', 'rawPayload': '...raw qr...'})`
- `FirebaseFunctions.instance.httpsCallable('payBill').call({'amount': 850, 'billName': 'Electricity Bill', 'billerId': 'LECO-55'})`
