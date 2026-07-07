# Smart Finance

Smart Finance is a modern, production-quality personal finance management application written in **Flutter** & **Dart** using clean architecture. It helps users track income, expenses, budgets, savings goals, loan EMIs, and bills using AI analytics, local OCR text recognition, and automated transactional SMS parsing.

---


## Technical Stack & Plugins

- **State Management**: [Riverpod](https://pub.dev/packages/flutter_riverpod)
- **Database**: [Hive](https://pub.dev/packages/hive_flutter) (Offline persistence) & [Cloud Firestore](https://pub.dev/packages/cloud_firestore) (Remote sync)
- **Authentication**: [Firebase Auth](https://pub.dev/packages/firebase_auth)
- **Charts**: [fl_chart](https://pub.dev/packages/fl_chart)
- **Hardware Integration**:
  - `telephony` (SMS reading/permission management)
  - `google_mlkit_text_recognition` (OCR scanning of receipt documents)
  - `local_auth` (Fingerprint/Face biometrics verification)
  - `image_picker` (Camera & gallery selector)
- **Navigation**: `go_router`
- **Notifications**: `flutter_local_notifications`
- **Exports**: `pdf`, `csv`, `excel`, and `share_plus`

---

## Directory Architecture

```text
lib/
├── core/
│   ├── constants/        # Global strings, categories list
│   ├── navigation/       # GoRouter path redirects & guards
│   ├── theme/            # Material 3 light/dark presets & gradients
│   └── services/         # Providers, Hive, SMS, OCR, AI, reports, biometrics
├── models/               # Transaction, User, Budget, Savings, Loan, Bill models
├── repositories/         # Hive database query controllers and Firebase linkers
├── features/             # Feature UI components & view controllers
│   ├── authentication/   # login, register, PIN lock, recoveries
│   ├── dashboard/        # balance widgets, quick buttons, performance cards
│   ├── transactions/     # search, filters, sheets, OCR cam analyzer
│   ├── budget/           # monthly thresholds, visual gauges, categories
│   ├── analytics/        # Pie & Bar fl_charts, statement exports
│   ├── savings/          # goal tracker, deadline notices, animations
│   ├── loans/            # interest rates, EMIs log, due warnings
│   ├── bills/            # util calendars, recurring rollovers
│   ├── ai/               # assistant chatbot room, analytical alerts
│   └── profile_settings/ # theme switches, locks, backups, accounts
└── widgets/              # reusable glass cards, gradient buttons, loader screens
```

---

## Platform Configurations

### 1. Android Manifest (`android/app/src/main/AndroidManifest.xml`)

Add the following permissions inside your `<manifest>` root node:

```xml
<!-- Reading transactional bank alert SMS -->
<uses-permission android:name="android.permission.RECEIVE_SMS" />
<uses-permission android:name="android.permission.READ_SMS" />

<!-- Camera access for Receipt OCR scanning -->
<uses-permission android:name="android.permission.CAMERA" />

<!-- Biometric authorization triggers -->
<uses-permission android:name="android.permission.USE_BIOMETRIC" />
<uses-permission android:name="android.permission.USE_FINGERPRINT" />
```

### 2. iOS Info Configuration (`ios/Runner/Info.plist`)

Add the following description tags for permissions inside your `<dict>` node:

```xml
<key>NSCameraUsageDescription</key>
<string>Smart Finance requires camera access to scan receipt documents for text extraction.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Smart Finance requires gallery access to upload invoice receipts from your album.</string>
<key>NSFaceIDUsageDescription</key>
<string>Smart Finance requires Face ID authorization to secure access to your financial dashboard.</string>
```

---

## Installation & Onboarding

### Step 1: Clone and Restore Packages

Navigate to the project root and run:
```bash
flutter pub get
```

### Step 2: Configure Firebase Credentials

1. Go to the [Firebase Console](https://console.firebase.google.com/).
2. Create a project named `Smart Finance`.
3. Enable **Email/Password** under Authentication Providers.
4. Add an Android app and download `google-services.json` to `android/app/`.
5. Add an iOS app and download `GoogleService-Info.plist` to `ios/Runner/`.

### Step 3: Run the Project

Ensure you have an emulator open or a physical device connected:
```bash
flutter run
```
