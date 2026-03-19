# MortWise

A Canadian mortgage calculator and prequalification tool built with Flutter, supporting mobile, web, and desktop platforms.

## Features

- **Mortgage Calculator** — Calculate payments across multiple frequencies (monthly, bi-weekly, weekly, accelerated bi-weekly/weekly)
- **Canadian Mortgage Math** — Semi-annual compounding, amortization schedules, and stress test rate calculations (5.25% floor)
- **CMHC Insurance** — Automatic premium calculations based on down payment percentage
- **Prequalification** — Estimate maximum purchase price based on income, debts, and down payment
- **Scenario Management** — Save, pin, and compare multiple mortgage and prequalification scenarios
- **Responsive UI** — Adapts between mobile (bottom nav) and desktop/web (side rail nav) layouts

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart ^3.11.0)
- Android Studio or Xcode for mobile builds
- Firebase project (for cloud features)

### Setup

```bash
# Install dependencies
flutter pub get

# Run on your target platform
flutter run                  # default device
flutter run -d chrome        # web
flutter run -d windows       # Windows desktop
```

### Firebase Setup

This app uses Firebase. To configure:

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add your platform apps (Android, iOS, Web)
3. Download and place `google-services.json` in `android/app/`
4. Run `flutterfire configure` to regenerate `lib/firebase_options.dart`
5. Add Firebase packages to `pubspec.yaml` as needed

## Project Structure

```
lib/
├── main.dart                        # App entry point, responsive scaffold
├── core/
│   ├── mortgage_math.dart           # Mortgage calculation engine
│   ├── prequal_models.dart          # Prequalification models
│   └── theme.dart                   # Colors and typography
├── models/                          # Immutable data models
├── screens/                         # App screens
├── services/
│   └── scenario_service.dart        # State management (ValueNotifier)
└── widgets/
    └── bottom_nav.dart              # Bottom navigation bar
```

## Platform Support

| Platform | Status |
|----------|--------|
| Android  | Supported |
| iOS      | Supported |
| Web      | Supported |
| macOS    | Supported |
| Windows  | Supported |
| Linux    | Partial (Firebase not configured) |

## Tech Stack

- **Framework:** Flutter
- **State Management:** ValueNotifier (built-in)
- **Fonts:** DM Sans, Playfair Display (via `google_fonts`)
- **Backend:** Firebase (in progress)
- **Hosting:** Firebase Hosting (`build/web`)
