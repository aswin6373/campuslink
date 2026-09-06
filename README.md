# CampusLink

CampusLink is a Flutter app that connects campus communities. It supports
**Admin**, **Teacher**, **Student** and **Guest** roles with the following
features:

- **Role-based dashboards** — stat cards, upcoming events, quick actions
- **Student & teacher management** — CRUD via the PHP backend, fingerprint
  (NodeMCU) biometric enrollment for attendance
- **Attendance reports** — class summaries for teachers/admins and personal
  history for students
- **Events** — create, edit, delete and browse campus events (with schedule &
  coordinators)
- **Community posts** — text + image posts with media uploads
- **Chatroom** — campus-wide chat with emoji support
- **Campus chatbot** — AI assistant (Google Gemini) grounded on per-institution
  FAQ answers managed by admins
- **Push notifications** — Firebase Cloud Messaging with local notifications

## Project layout

```
lib/
├── main.dart                  # App entry point, routes, providers
├── app_theme.dart             # Light & dark Material 3 themes
├── data/
│   ├── config.dart            # Environment-based configuration (.env)
│   ├── data_provider.dart     # Students/teachers state (ChangeNotifier)
│   └── save_user_data.dart    # Persist session data locally
├── models/
│   └── teacher_and_student_model.dart
├── services/                  # HTTP services & providers
│   ├── firebase_api.dart      # FCM + local notifications
│   ├── media_provider.dart    # Community posts state
│   ├── fetch_posts.dart / add_post.dart / upload_media.dart
│   ├── profile_services.dart  # Profile fetch / update
│   └── my_http_overrides.dart
├── screens/
│   ├── authentication/        # Login & signup
│   ├── chatbot/               # Gemini-powered assistant + admin FAQ editor
│   ├── chatroom/              # Campus chat
│   ├── community_post/        # Community feed
│   └── dashboard/             # Dashboards, events, attendance, management
└── widgets/                   # Splash, home, main shell, profile
```

## Getting started

### Prerequisites

- Flutter SDK (stable channel, 3.x)
- A running CampusLink PHP backend (the app talks to `<API_BASE_URL>/clink/api/...`)
- A Firebase project with an Android app registered
  (`android/app/google-services.json`)

### Setup

```bash
flutter pub get

# Configure environment (backend URL, device URL, Gemini API key)
cp .env.example .env
# then edit .env
```

`.env` keys:

| Key             | Description                                              |
|-----------------|----------------------------------------------------------|
| `API_BASE_URL`  | PHP backend base URL. Android emulator: `http://10.0.2.2`|
| `NODE_URL`      | Fingerprint device (NodeMCU) base URL                    |
| `GEMINI_API_KEY`| Google Gemini API key for the chatbot                    |

> `.env` is gitignored on purpose — never commit real keys. The example file
> `.env.example` is committed instead.

### Run

```bash
flutter run                      # debug on a connected device/emulator
flutter run -d chrome            # web (push notifications need web config)
```

### Test & analyze

```bash
flutter analyze
flutter test
```

### Release build

```bash
flutter build appbundle --release
```

Before shipping a release:

1. Add a real signing config in `android/app/build.gradle` (currently uses the
   debug keystore).
2. Change `applicationId` from `com.example.campuslink` to your own id.
3. Register the app in Firebase and add the release SHA-1 for FCM.
4. Set `API_BASE_URL` (and `NODE_URL`) in `.env` to the production server.
5. Rotate the Gemini API key if it was ever committed, and restrict it by
   app/package in Google Cloud Console.
