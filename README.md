# Spendi

Spendi is a modern Flutter expense tracker with Firebase Authentication,
real-time Firestore storage, multi-currency totals, AI-assisted receipt
scanning, and Cloudinary receipt uploads.

## Features

- Email/password registration, login, restored sessions, and logout
- Manual expense entry and AI-assisted receipt review
- Real-time expense history with date filters
- Current-rate currency conversion
- Category insights and spending summaries
- Light and dark themes with responsive Material 3 UI
- Saved receipt image preview

## Project layout

```text
lib/
  controllers/   Lightweight presentation controllers
  models/        Domain models
  services/      Firebase, scanning, upload, and conversion integrations
  theme/         Shared color and component themes
  utils/         Formatting and category presentation helpers
  views/         App screens and dashboard presentation
  widgets/       Reusable UI components and transitions
```

`DashboardView` owns navigation, service coordination, and async state.
`DashboardHomeView` renders the dashboard content. Shared visual primitives live
in `app_components.dart`, while the global light/dark themes live in
`app_theme.dart`.

## Setup

The checked-in Firebase options target the `expenset-2e3bc` project. In the
Firebase Console, enable **Authentication > Sign-in method > Email/Password**.

Copy `.env.example` to `.env` and add the NVIDIA and Cloudinary values. Use an
unsigned Cloudinary upload preset restricted to JPG and PNG. Never add a
Cloudinary API secret or `CLOUDINARY_URL` to Flutter build arguments because
client build-time values are extractable.

```sh
flutter pub get
flutter run --dart-define-from-file=.env
```

Expenses are stored under `users/{uid}/expenses/{expenseId}`. Deploy the
included Firestore rules before using a non-emulator build:

```sh
firebase deploy --only firestore:rules
```

## Quality checks

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

The tests use fake authentication, expense, receipt, and currency services, so
they do not create accounts or records in the live Firebase project.
