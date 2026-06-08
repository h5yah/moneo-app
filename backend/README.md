# Backend Cloud Functions

Secure XP operations, finance summary read, and the Miro AI assistant for the Monéo app.

**Deploy from the `backend/` directory** (not the repo root).

## Deployed functions

### XP (server-side)

- `getXp` — returns authenticated user XP total.
- `earnXp` — increments XP atomically.
- `earnXpOnce` — increments XP only once per `awardKey` (stored under `users/{uid}/xpAwards`).
- `spendXp` — decrements XP atomically; blocks overspending.

### Finance (read-only on server)

- `getFinanceSummary` — returns authenticated user balances (`available`, `income`, `spent`, `saved`).

Wallet mutations (add funds, send money, pay bill, scan to pay) are performed **client-side** via Firestore transactions in the Flutter app. Server finance write callables are not deployed.

### Push notifications (FCM)

- `onUserNotificationCreated` — Firestore trigger on `users/{uid}/notifications/{id}`; sends FCM when `notifications.push` is enabled and `fcmToken` is set.
- `sendTestPush` — callable test: `{ "title": "...", "body": "..." }`.

The Flutter app saves `users/{uid}.fcmToken` on sign-in. Streak/lesson alerts created via `AppNotificationService` also deliver as device push when FCM is configured.

**iOS:** Enable Push Notifications capability in Xcode and upload your APNs key in Firebase Console → Project Settings → Cloud Messaging.

### AI assistant

- `miroChat` — authenticated chat with **OpenAI** (Monéo “Ask Miro” screen).
  - **Secret:** `firebase functions:secrets:set OPENAI_API_KEY` (run from `backend/`).
  - **Local emulator:** copy `backend/functions/.env.example` to `.env.local` with your key (not deployed; do not use `.env`).
  - Flutter calls `httpsCallable('miroChat')` with `{ "message": "...", "knowledgeContext": "..." }` and reads `{ "reply": "..." }`.

All functions require Firebase Authentication (`request.auth.uid`).

## Data model

- User XP: `users/{uid}.xp`
- XP audit: `users/{uid}/xpTransactions/{id}`
- One-time awards: `users/{uid}/xpAwards/{awardKey}`

Finance collections (client writes + rules in `firestore.rules`):

- Balances: `balances/{uid}`
- Transactions: `transactions/{transactionId}`
- Expenses: `expenses/{expenseId}`

Cloud Storage paths (`storage.rules`):

- `users/{uid}/profile.jpg` — profile photo (client upload)
- `certificates/{uid}/{topicId}.json` — topic completion certificate metadata
- `lesson_assets/**` — read-only lesson media (upload via Firebase Console or Admin SDK)

## Setup

1. Install Firebase CLI: `npm i -g firebase-tools`
2. Login: `firebase login`
3. Project id: `backend/.firebaserc` (`fyp-fintech-app`)
4. Install dependencies: `cd backend/functions && npm install`
5. Set OpenAI secret (production): `cd backend && firebase functions:secrets:set OPENAI_API_KEY`

## Run locally

```bash
cd backend/functions
npm run serve
```

## Deploy

```bash
cd backend/functions
npm install
npm run deploy
```

This deploys Cloud Functions, Firestore rules, and Storage rules.

**Do not** put `OPENAI_API_KEY` in `backend/functions/.env` — Firebase uploads that as a plain env var and conflicts with the secret. Use Secret Manager only (or `.env.local` for the emulator).

If `miroChat` fails with *Secret environment variable overlaps non secret environment variable*, delete and redeploy:

```bash
cd backend
firebase functions:delete miroChat --region us-central1 --force
cd functions && npm run deploy
```

## Suggested frontend calls

```dart
FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable('getXp');
FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable('earnXpOnce').call({
  'amount': 20,
  'source': 'lesson_completion',
  'awardKey': 'lesson:budgeting:1',
});
FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable('spendXp').call({
  'amount': 500,
  'source': 'deal_claim',
});
FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable('getFinanceSummary').call();
FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable('miroChat').call({
  'message': 'How do I pay a bill?',
  'knowledgeContext': '...',
});
```
