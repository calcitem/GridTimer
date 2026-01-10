# Localization Guide

This guide explains how to add complete multi-language support to Grid Timer.

## Overview

Grid Timer uses a multi-layered localization architecture that supports all platforms (Android, iOS, macOS).

**Note**: Chinese characters (or other non-English text) should ONLY appear in:
- ARB translation files (`lib/l10n/arb/app_*.arb`)
- Platform resources (`android/app/src/main/res/values-*/`, `macos/Runner/*.lproj/`)
- App Store metadata (`fastlane/metadata/android/*/`)
- Code comment examples (showing expected output)

All source code comments must be in English.

## Architecture Layers

Grid Timer's localization spans four layers:

### 1. Flutter Layer (UI Strings)
- **Location**: `lib/l10n/arb/*.arb`
- **Purpose**: All UI text, dialogs, settings, etc.
- **Access**: Via `AppLocalizations.of(context)`
- **Generated Code**: `lib/l10n/app_localizations_*.dart`

### 2. Platform Layer (Native Resources)
- **Android**: `android/app/src/main/res/values-*/strings.xml`
  - App name in launcher
  - Home screen widget text
- **macOS**: `macos/Runner/*.lproj/MainMenu.strings`
  - Window title
  - Menu items
- **iOS** (future): `ios/Runner/*.lproj/InfoPlist.strings`

### 3. Service Layer (Background Services)
- **Implementation**: Uses generated `AppLocalizations` directly
- **Purpose**: Notifications, TTS, widgets
- **Note**: No longer requires separate translation maps (refactored to use ARB-generated code)

### 4. Metadata Layer (App Stores)
- **Location**: `fastlane/metadata/android/*/`
- **Purpose**: App Store listings, descriptions, changelogs

## Adding a New Language - Quick Checklist

For a new language (e.g., Japanese `ja`):

1. ✅ Add to `lib/core/config/supported_locales.dart`
2. ✅ Create `lib/l10n/arb/app_ja.arb` (translate all strings)
3. ✅ Create `android/app/src/main/res/values-ja/strings.xml`
4. ✅ Create `macos/Runner/ja.lproj/MainMenu.strings`
5. ✅ Create `fastlane/metadata/android/ja/*.txt` (App Store metadata)
6. ✅ Run `./tool/gen.sh` to regenerate code
7. ✅ Test thoroughly

## Step-by-Step Guide

### Step 1: Configure Supported Language

Edit `lib/core/config/supported_locales.dart` and add your language:

```dart
static const List<SupportedLanguage> languages = [
  // ... existing languages
  SupportedLanguage(
    code: 'ja',                    // ISO 639-1 language code
    nativeName: '日本語',           // Language name in native script
    englishName: 'Japanese',       // Language name in English
    ttsLocale: 'ja-JP',            // TTS locale code
  ),
];
```

### Step 2: Create ARB File

```bash
# Copy English template
cp lib/l10n/arb/app_en.arb lib/l10n/arb/app_ja.arb

# Edit app_ja.arb and translate all ~300 strings
# Keep the same keys, translate the values
```

Example:
```json
{
  "@@locale": "ja",
  "appTitle": "グリッドタイマー",
  "timerRunning": "実行中",
  ...
}
```

### Step 3: Create Android Resources

```bash
mkdir -p android/app/src/main/res/values-ja
```

Create `android/app/src/main/res/values-ja/strings.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">グリッドタイマー</string>
    <string name="widget_description">グリッドタイマーの状態を表示</string>
    <string name="widget_timers_ringing">%d 個のタイマーが鳴っています</string>
    <string name="widget_timers_active">%d 個のタイマーが実行中</string>
    <string name="widget_tap_to_open">タップしてアプリを開く</string>
</resources>
```

### Step 4: Create macOS Resources

```bash
mkdir -p macos/Runner/ja.lproj
```

Create `macos/Runner/ja.lproj/MainMenu.strings`:

```
/* Localized versions of MainMenu.xib keys */

/* Window Title */
"QvC-M9-y7g.title" = "グリッドタイマー";

/* Application Menu */
"1Xt-HY-uBw.title" = "グリッドタイマー";
"uQy-DD-JDr.title" = "グリッドタイマー";
"5kV-Vb-QxS.title" = "グリッドタイマーについて";
...
```

**Tip**: Copy from `zh-Hans.lproj/MainMenu.strings` and translate the values (keep Object IDs unchanged).

### Step 5: Create App Store Metadata (Optional)

```bash
mkdir -p fastlane/metadata/android/ja/{changelogs,images}
echo "グリッドタイマー" > fastlane/metadata/android/ja/title.txt
echo "シニア向けの9グリッド並列タイマー" > fastlane/metadata/android/ja/short_description.txt
# Create full_description.txt with complete app description
```

### Step 6: Generate Code

```bash
./tool/gen.sh
```

This generates `lib/l10n/app_localizations_ja.dart`.

### Step 7: Test

```bash
flutter run
# Navigate to Settings → Language → 日本語
# Verify all text is translated correctly
```

## File Locations by Language Layer

### Core Configuration
| File | Purpose |
|------|---------|
| `lib/core/config/supported_locales.dart` | Define all supported languages |

### Flutter Layer (ARB Files)
| File Pattern | Purpose |
|--------------|---------|
| `lib/l10n/arb/app_en.arb` | English UI strings (template) |
| `lib/l10n/arb/app_zh.arb` | Chinese UI strings |
| `lib/l10n/arb/app_*.arb` | Other language UI strings |
| `lib/l10n/app_localizations_*.dart` | Generated localization code |

### Platform Layer
| Platform | File Pattern | Purpose |
|----------|--------------|---------|
| Android | `android/app/src/main/res/values/strings.xml` | English (default) |
| Android | `android/app/src/main/res/values-zh/strings.xml` | Chinese resources |
| Android | `android/app/src/main/res/values-*/strings.xml` | Other languages |
| macOS | `macos/Runner/en.lproj/MainMenu.strings` | English menu |
| macOS | `macos/Runner/zh-Hans.lproj/MainMenu.strings` | Chinese menu |
| macOS | `macos/Runner/*.lproj/MainMenu.strings` | Other language menus |
| iOS (future) | `ios/Runner/en.lproj/InfoPlist.strings` | English app info |
| iOS (future) | `ios/Runner/*/InfoPlist.strings` | Other languages |

### Metadata Layer (App Stores)
| File Pattern | Purpose |
|--------------|---------|
| `fastlane/metadata/android/en-US/*.txt` | English Play Store listing |
| `fastlane/metadata/android/zh-CN/*.txt` | Chinese Play Store listing |
| `fastlane/metadata/android/*/title.txt` | App title per language |
| `fastlane/metadata/android/*/short_description.txt` | Short description |
| `fastlane/metadata/android/*/full_description.txt` | Full description |
| `fastlane/metadata/android/*/changelogs/*.txt` | Release notes |

## Best Practices

1. **Consistency**: Ensure all translation files use consistent keys
2. **Completeness**: New languages should translate all entries to avoid fallback to English
3. **Testing**:
   - Test UI text rendering
   - Test notification text
   - Test TTS voice announcements
   - Test text display on different screen sizes
4. **Code Generation**: Always run `./tool/gen.sh` after modifying ARB files

## Common Issues

### Q: Why don't ARB file changes take effect?
A: You need to run `./tool/gen.sh` to regenerate localization code.

### Q: What's the difference between service layer text and ARB file text?
A: 
- **ARB Files**: For UI interface text, accessed via `AppLocalizations.of(context)`
- **Service Layer Text**: For background services (notifications, TTS), not dependent on `BuildContext`

### Q: How to test if TTS is using the correct language?
A: 
1. Go to Settings → TTS Settings
2. Click the "Test Voice" button
3. Confirm the announcement is in the correct language

## Current Status

**Fully Supported Languages:**
- 🇬🇧 English (`en`)
- 🇨🇳 Simplified Chinese (`zh`)

**Platforms:**
- ✅ Android (14+)
- ✅ macOS (10.14+)
- 🚧 iOS (planned)
- 🚧 Windows (planned)
- 🚧 Linux (planned)

## Future Enhancements

- [ ] iOS platform support
- [ ] Windows platform support
- [ ] Linux platform support
- [ ] Support regional variants (e.g., en-US vs en-GB, zh-CN vs zh-TW)
- [ ] Translation completeness checking tool
- [ ] Integration with translation management platforms (Crowdin, Lokalise)
- [ ] Automated translation validation in CI/CD

## References

- [Flutter Internationalization](https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization)
- [ARB File Format](https://github.com/google/app-resource-bundle)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)

## Language Code Reference

| Language | Code | TTS Locale | Android Folder | macOS Folder |
|----------|------|------------|----------------|--------------|
| English | `en` | `en-US` | `values` | `en.lproj` |
| Chinese (Simplified) | `zh` | `zh-CN` | `values-zh` | `zh-Hans.lproj` |
| Japanese | `ja` | `ja-JP` | `values-ja` | `ja.lproj` |
| Korean | `ko` | `ko-KR` | `values-ko` | `ko.lproj` |
| French | `fr` | `fr-FR` | `values-fr` | `fr.lproj` |
| German | `de` | `de-DE` | `values-de` | `de.lproj` |
| Spanish | `es` | `es-ES` | `values-es` | `es.lproj` |

## Want to Contribute a Translation?

We welcome community contributions!

**Most Wanted Languages:**
- 🇯🇵 Japanese
- 🇰🇷 Korean
- 🇫🇷 French
- 🇩🇪 German
- 🇪🇸 Spanish
- 🇷🇺 Russian
- 🇸🇦 Arabic

**Pull Request Checklist:**
1. ✅ All files listed in the checklist above
2. ✅ Tested on at least one device
3. ✅ Include screenshots showing the language working
4. ✅ Note any translation decisions in PR description
