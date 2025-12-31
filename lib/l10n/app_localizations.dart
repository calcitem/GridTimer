import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'GridTimer'**
  String get appTitle;

  /// Timer status: idle
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get timerIdle;

  /// Timer status: running
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get timerRunning;

  /// Timer status: paused
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get timerPaused;

  /// Timer status: ringing
  ///
  /// In en, this message translates to:
  /// **'RINGING'**
  String get timerRinging;

  /// Dialog title when starting a new timer
  ///
  /// In en, this message translates to:
  /// **'Confirm Start?'**
  String get confirmStartTitle;

  /// Dialog body when starting a new timer
  ///
  /// In en, this message translates to:
  /// **'Other timers are running. Continue to start {name}?'**
  String confirmStartBody(String name);

  /// Action: start timer
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get actionStart;

  /// Action: pause timer
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get actionPause;

  /// Action: resume timer
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get actionResume;

  /// Action: reset timer
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get actionReset;

  /// Action: stop alarm
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get actionStop;

  /// Action: cancel
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// Timer actions dialog title
  ///
  /// In en, this message translates to:
  /// **'Timer Actions'**
  String get timerActions;

  /// Button to stop ringing alarm
  ///
  /// In en, this message translates to:
  /// **'Stop Alarm'**
  String get stopAlarm;

  /// TTS announcement when timer completes
  ///
  /// In en, this message translates to:
  /// **'{name} time is up'**
  String timeUpTts(String name);

  /// Permission guide: notification title
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get permissionNotificationTitle;

  /// Permission guide: notification body
  ///
  /// In en, this message translates to:
  /// **'To receive timer alerts, please enable notifications.'**
  String get permissionNotificationBody;

  /// Permission guide: exact alarm title
  ///
  /// In en, this message translates to:
  /// **'Enable Exact Alarms'**
  String get permissionExactAlarmTitle;

  /// Permission guide: exact alarm body
  ///
  /// In en, this message translates to:
  /// **'For precise timer alerts, please enable \'Alarms & reminders\' permission.'**
  String get permissionExactAlarmBody;

  /// Button to open system settings
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// Button to postpone action
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// Label for minutes
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// Label for remaining seconds
  ///
  /// In en, this message translates to:
  /// **'seconds left'**
  String get remainingSeconds;

  /// Label when timer is paused
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get pausing;

  /// Label when timer rings
  ///
  /// In en, this message translates to:
  /// **'Time\'s Up'**
  String get timeUp;

  /// Instruction to stop alarm
  ///
  /// In en, this message translates to:
  /// **'Click to stop'**
  String get clickToStop;

  /// Settings page title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Section: App Information
  ///
  /// In en, this message translates to:
  /// **'App Information'**
  String get appInformation;

  /// Label for app version
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// Section: Timer Settings
  ///
  /// In en, this message translates to:
  /// **'Timer Settings'**
  String get timerSettings;

  /// Sound settings option
  ///
  /// In en, this message translates to:
  /// **'Sound Settings'**
  String get soundSettings;

  /// Description for sound settings
  ///
  /// In en, this message translates to:
  /// **'Configure alarm sound'**
  String get soundSettingsDesc;

  /// TTS settings option
  ///
  /// In en, this message translates to:
  /// **'TTS Settings'**
  String get ttsSettings;

  /// Description for TTS settings
  ///
  /// In en, this message translates to:
  /// **'Configure voice announcements'**
  String get ttsSettingsDesc;

  /// Language settings option
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSettings;

  /// Description for language settings
  ///
  /// In en, this message translates to:
  /// **'Choose app language'**
  String get languageSettingsDesc;

  /// Section: Permissions
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissions;

  /// Notification permission option
  ///
  /// In en, this message translates to:
  /// **'Notification Permission'**
  String get notificationPermission;

  /// Description for notification permission
  ///
  /// In en, this message translates to:
  /// **'Allow timer notifications'**
  String get notificationPermissionDesc;

  /// Section: About
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// License option
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get license;

  /// Description for license
  ///
  /// In en, this message translates to:
  /// **'View open source licenses'**
  String get licenseDesc;

  /// Message for unimplemented features
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// Dialog title for language selection
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// English language name
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Simplified Chinese language name
  ///
  /// In en, this message translates to:
  /// **'简体中文'**
  String get languageChineseSimplified;

  /// Error message template
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorText(String error);

  /// Confirmation message when starting timer with others running
  ///
  /// In en, this message translates to:
  /// **'Other timers are running. Continue to start this timer?'**
  String get confirmStart;

  /// Flash animation setting
  ///
  /// In en, this message translates to:
  /// **'Flash Animation'**
  String get flashAnimation;

  /// Description for flash animation
  ///
  /// In en, this message translates to:
  /// **'Red flash when timer rings'**
  String get flashAnimationDesc;

  /// Vibration setting
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get vibration;

  /// Description for vibration
  ///
  /// In en, this message translates to:
  /// **'Vibrate when timer rings'**
  String get vibrationDesc;

  /// Keep screen on setting
  ///
  /// In en, this message translates to:
  /// **'Keep Screen On'**
  String get keepScreenOn;

  /// Description for keep screen on
  ///
  /// In en, this message translates to:
  /// **'Prevent screen from sleeping while timer runs'**
  String get keepScreenOnDesc;

  /// TTS enabled setting
  ///
  /// In en, this message translates to:
  /// **'Voice Announcements'**
  String get ttsEnabled;

  /// Description for TTS enabled
  ///
  /// In en, this message translates to:
  /// **'Announce timer completion with voice'**
  String get ttsEnabledDesc;

  /// Alarm sound setting
  ///
  /// In en, this message translates to:
  /// **'Alarm Sound'**
  String get alarmSound;

  /// Description for alarm sound
  ///
  /// In en, this message translates to:
  /// **'Choose sound for timer alerts'**
  String get alarmSoundDesc;

  /// Volume setting
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volume;

  /// Description for volume
  ///
  /// In en, this message translates to:
  /// **'Adjust alarm volume'**
  String get volumeDesc;

  /// TTS language setting
  ///
  /// In en, this message translates to:
  /// **'TTS Language'**
  String get ttsLanguage;

  /// Description for TTS language
  ///
  /// In en, this message translates to:
  /// **'Choose voice announcement language'**
  String get ttsLanguageDesc;

  /// Test sound button
  ///
  /// In en, this message translates to:
  /// **'Test Sound'**
  String get testSound;

  /// Test TTS button
  ///
  /// In en, this message translates to:
  /// **'Test Voice'**
  String get testTts;

  /// Grid durations settings option
  ///
  /// In en, this message translates to:
  /// **'Grid Durations Settings'**
  String get gridDurationsSettings;

  /// Description for grid durations settings
  ///
  /// In en, this message translates to:
  /// **'Customize duration for each grid cell'**
  String get gridDurationsSettingsDesc;

  /// Grid slot label
  ///
  /// In en, this message translates to:
  /// **'Grid {index}'**
  String gridSlot(int index);

  /// Seconds unit
  ///
  /// In en, this message translates to:
  /// **'seconds'**
  String get seconds;

  /// Hours unit
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get hours;

  /// Save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Reset button
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// Reset to default button
  ///
  /// In en, this message translates to:
  /// **'Reset to Default'**
  String get resetToDefault;

  /// Reset to default confirmation
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reset grid durations to default values?'**
  String get gridDurationsResetConfirm;

  /// Audio playback settings title
  ///
  /// In en, this message translates to:
  /// **'Audio Playback Settings'**
  String get audioPlaybackSettings;

  /// Audio playback settings description
  ///
  /// In en, this message translates to:
  /// **'Configure alarm audio playback mode'**
  String get audioPlaybackSettingsDesc;

  /// Audio playback mode label
  ///
  /// In en, this message translates to:
  /// **'Playback Mode'**
  String get audioPlaybackMode;

  /// Loop indefinitely mode description
  ///
  /// In en, this message translates to:
  /// **'Loop indefinitely until manually stopped'**
  String get audioPlaybackModeLoopIndefinitely;

  /// Loop for duration mode description
  ///
  /// In en, this message translates to:
  /// **'Loop for N minutes then auto-stop'**
  String get audioPlaybackModeLoopForDuration;

  /// Loop with interval mode description
  ///
  /// In en, this message translates to:
  /// **'Loop N min, pause M min, loop N min (once)'**
  String get audioPlaybackModeLoopWithInterval;

  /// Loop with interval repeating mode description
  ///
  /// In en, this message translates to:
  /// **'Loop N min, pause M min, repeat until stopped'**
  String get audioPlaybackModeLoopWithIntervalRepeating;

  /// Play once mode description
  ///
  /// In en, this message translates to:
  /// **'Play once only'**
  String get audioPlaybackModePlayOnce;

  /// Loop duration label
  ///
  /// In en, this message translates to:
  /// **'Loop Duration'**
  String get loopDuration;

  /// Interval pause duration label
  ///
  /// In en, this message translates to:
  /// **'Interval Pause Duration'**
  String get intervalPause;

  /// Minutes unit label
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutesUnit;

  /// Custom audio section title
  ///
  /// In en, this message translates to:
  /// **'Custom Alarm Sound'**
  String get customAudio;

  /// Custom audio description
  ///
  /// In en, this message translates to:
  /// **'Upload your own audio file as alarm sound (supports MP3, WAV, etc.)'**
  String get customAudioDesc;

  /// Upload custom audio button
  ///
  /// In en, this message translates to:
  /// **'Upload Audio File'**
  String get uploadCustomAudio;

  /// Change custom audio button
  ///
  /// In en, this message translates to:
  /// **'Change Audio File'**
  String get changeCustomAudio;

  /// Clear custom audio button
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearCustomAudio;

  /// Custom audio active message
  ///
  /// In en, this message translates to:
  /// **'Currently using custom audio'**
  String get customAudioActive;

  /// Custom audio selected confirmation
  ///
  /// In en, this message translates to:
  /// **'Custom audio has been set'**
  String get customAudioSelected;

  /// Custom audio cleared confirmation
  ///
  /// In en, this message translates to:
  /// **'Restored to default sound'**
  String get customAudioCleared;

  /// Gesture settings title
  ///
  /// In en, this message translates to:
  /// **'Gesture Control Settings'**
  String get gestureSettings;

  /// Gesture settings description
  ///
  /// In en, this message translates to:
  /// **'Configure gesture actions when alarm rings'**
  String get gestureSettingsDesc;

  /// Gesture actions section title
  ///
  /// In en, this message translates to:
  /// **'Gesture Actions'**
  String get gestureActions;

  /// Screen tap gesture
  ///
  /// In en, this message translates to:
  /// **'Tap Screen'**
  String get gestureTypeScreenTap;

  /// Volume up button gesture
  ///
  /// In en, this message translates to:
  /// **'Volume+ Button'**
  String get gestureTypeVolumeUp;

  /// Volume down button gesture
  ///
  /// In en, this message translates to:
  /// **'Volume- Button'**
  String get gestureTypeVolumeDown;

  /// Shake phone gesture
  ///
  /// In en, this message translates to:
  /// **'Shake Phone'**
  String get gestureTypeShake;

  /// Flip phone gesture
  ///
  /// In en, this message translates to:
  /// **'Flip Phone (Face Down)'**
  String get gestureTypeFlip;

  /// Stop and reset action
  ///
  /// In en, this message translates to:
  /// **'Stop & Reset'**
  String get gestureActionStopAndReset;

  /// Pause action
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get gestureActionPause;

  /// No action
  ///
  /// In en, this message translates to:
  /// **'No Action'**
  String get gestureActionNone;

  /// Shake sensitivity label
  ///
  /// In en, this message translates to:
  /// **'Shake Sensitivity'**
  String get shakeSensitivity;

  /// Low sensitivity description
  ///
  /// In en, this message translates to:
  /// **'Low (Shake hard)'**
  String get shakeSensitivityLow;

  /// High sensitivity description
  ///
  /// In en, this message translates to:
  /// **'High (Shake gently)'**
  String get shakeSensitivityHigh;

  /// Shake sensitivity description
  ///
  /// In en, this message translates to:
  /// **'Adjust shake detection sensitivity'**
  String get shakeSensitivityDesc;

  /// Gesture hint for seniors
  ///
  /// In en, this message translates to:
  /// **'Senior-friendly: Enable screen tap, volume buttons, and flip phone'**
  String get gestureHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
