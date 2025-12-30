# GridTimer - Quick Start Guide

## 🚀 5-Minute Setup

### Prerequisites
- Flutter SDK (≥ 3.0.0) installed
- Android Studio or Android SDK installed
- Git

### Step 1: Clone & Setup (2 min)

```bash
# Clone the repository
git clone <your-repo-url>
cd GridTimer

# Make scripts executable (Mac/Linux)
chmod +x tool/*.sh

# Initialize project
./tool/flutter-init.sh
```

**Windows users:** Run commands manually:
```cmd
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
```

### Step 2: Add Audio Files (1 min)

You need 6 MP3 ringtone files. Quick options:

**Option A - Use placeholder silence (for testing):**
Create 1-second silent MP3 files and copy to both locations:
- `assets/sounds/`
- `android/app/src/main/res/raw/`

**Option B - Download free sounds:**
Get royalty-free sounds from:
- https://freesound.org/
- https://mixkit.co/free-sound-effects/

Required filenames:
```
bell_01.mp3
bell_02.mp3
beep_soft.mp3
chime.mp3
ding.mp3
gentle.mp3
```

### Step 3: Configure Android SDK Path (30 sec)

Create `android/local.properties`:
```properties
flutter.sdk=C:\\path\\to\\flutter
```
(Usually auto-created by Android Studio)

### Step 4: Run! (1 min)

```bash
# Connect Android device or start emulator
flutter devices

# Run the app
flutter run
```

## ✅ Verification Checklist

After running, verify:
- [ ] App launches without errors
- [ ] 3x3 grid is visible
- [ ] Tapping a cell shows dialog
- [ ] Can start a timer
- [ ] Timer counts down
- [ ] (Test on device) Notification appears at completion

## 🐛 Common Issues

### "No devices found"
```bash
# Enable USB debugging on Android device
# Or start emulator:
flutter emulators --launch <emulator-name>
```

### "Build failed: compileSdk 35 not found"
- Open Android Studio → SDK Manager
- Install Android API 35 (Android 15)

### "Generated files not found"
```bash
# Re-run code generation
./tool/gen.sh
```

### "Audio files missing" error
- Add at least placeholder MP3 files (see Step 2)

## 📱 Testing Tips

1. **Test on real device** - Emulators may not support all notification features
2. **Use Android 14+** - For testing exact alarm permissions
3. **Kill app and reopen** - Verify timer state recovery works

## 🎯 What's Next?

After basic setup works:
1. Read **SETUP.md** for detailed configuration
2. Review **PROJECT_STATUS.md** for implementation details
3. Check **CONTRIBUTING.md** if you want to modify code
4. See **README.md** for full PRD documentation

## 🆘 Still Having Issues?

1. Check **PROJECT_STATUS.md** - Known limitations section
2. Review build output for specific errors
3. Ensure Flutter SDK is up to date: `flutter upgrade`
4. Clean and rebuild: `flutter clean && flutter pub get`

---

**Estimated total time:** 5-10 minutes  
**Prerequisites:** Flutter SDK, Android SDK  
**Result:** Working GridTimer app on Android device

