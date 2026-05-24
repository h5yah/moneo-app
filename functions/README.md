# Deprecated

Cloud Functions for this project live in **`backend/functions/`**.

Deploy from `backend/`:

```bash
cd backend/functions && npm run deploy
```

Or from the repo root (uses root `firebase.json`):

```bash
firebase deploy --only functions,firestore:rules
```
