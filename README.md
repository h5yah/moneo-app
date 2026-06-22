#  Monéo

> A gamified mobile app designed to teach financial literacy to young people in Mauritius using interactive learning and an AI financial assistant.

---

##  About

Monéo is a final year project (BSc Software Engineering, University of Mauritius) that aims to improve financial literacy among young people through a simple, engaging mobile experience.

It combines:

* Gamified learning
* A simulated wallet for practice
* AI-powered financial guidance

The goal is to help users learn how to manage money in a safe, interactive way.

> ⚠️ Educational prototype only, no real money is used.

---

##  Features

*  Financial literacy lessons (budgeting, saving, debt, etc.)
*  Gamification (XP, levels, rewards)
*  Simulated wallet for practice
*  AI financial assistant (OpenAI)
*  Firebase authentication
*  Progress tracking

---

##  Tech Stack

* Flutter (Dart)
* Firebase (Auth, Firestore, Cloud Functions)
* Node.js (backend functions)
* OpenAI API (AI assistant)
* Figma (UI/UX design)

---

## 🚀= Running the App

### Prerequisites

* Flutter SDK installed
* Firebase CLI set up
* Firebase project configured (Auth, Firestore, Functions)
* OpenAI API key (for AI features)

### Setup & Run

```bash id="h6k2a2"
git clone https://github.com/h5yah/moneo.git
cd moneo
flutter pub get
```

Then configure Firebase:

```bash
firebase login
flutterfire configure
```

Run the app:

```bash
flutter run
```

---

##  Security

* API keys stored in Firebase Secret Manager
* No direct OpenAI calls from the app
* Firestore rules protect user data
* Fully simulated wallet (no real money)

