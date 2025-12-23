
# LeetBlock

LeetBlock is a productivity app that helps you build consistent coding habits by blocking access to selected apps until you've completed your daily LeetCode problem quota.

## Features

- **Daily Quota System** - Set a daily goal
- **App Blocking** - Select which apps to block until quota is met
- **LeetCode Stats** - Track your total solved problems (Easy/Medium/Hard)

## How It Works

1. **Setup** - Enter your LeetCode username
2. **Set Quota** - Choose how many problems you need to solve daily
3. **Select Apps** - Pick which apps to block (social media, games, etc.)
4. **Grant Permissions** - Allow usage stats and overlay permissions
5. **Stay Focused** - Blocked apps show a blocking screen until quota is met


## Requirements

- Android 7.0 (API 24) or higher
- Flutter 3.0+

## Permissions Required

- **Usage Stats Access** - To detect when blocked apps are opened
- **Display Over Other Apps** - To show the blocking overlay
- **Internet** - To fetch your LeetCode stats

## Installation

```bash
# Clone the repository

# Navigate to project
cd LeetBlock

# Get dependencies
flutter pub get

# Run the app
flutter run
```

## Building for Release

```bash
flutter build apk --release
```

The APK will be at `build/app/outputs/flutter-apk/app-release.apk`