# Custom Audio Feature Removal

## Date: 2025-12-31

## Decision: Remove Custom Audio Upload Feature

### Rationale

The custom audio upload feature has been **completely removed** from GridTimer for the following critical reasons:

#### 1. Reliability Concerns

**Problem**: Android system cannot guarantee reliable background playback of custom audio files:
- FLAG_INSISTENT (notification sound looping) has unpredictable behavior with custom audio
- AudioService may be restricted by aggressive battery optimization
- No way to ensure 100% reliability for custom audio in background/lockscreen

**Risk**: User uploads a custom audio file (e.g., family member's voice reminder), relies on it for critical timing (medicine), but the alarm fails to loop or play in background → serious consequences

#### 2. Legal Liability

For a timer application designed for senior care and medical reminders:
- **One failure can cause serious harm** (missed medication, cooking fire, etc.)
- **Free/open source does not eliminate liability** in some jurisdictions
- **Custom audio adds unpredictability** we cannot control or test exhaustively
- **Default audio is predictable and testable** across devices

#### 3. Technical Complexity vs. Value

**Cost**:
- Would require Foreground Service implementation (2-3 days work)
- Extensive device-specific testing (100+ device combinations)
- Ongoing maintenance for Android version updates
- Support burden for user-reported issues

**Benefit**:
- Marginal UX improvement (personalization)
- Does not improve core value proposition (reliable timing)

### What Was Removed

Complete removal of custom audio functionality:

1. **Data Model**
   - `customAudioPath` field from `AppSettings` entity
   - Related Hive adapter code

2. **Service Layer**
   - `customAudioPath` parameter from `IAudioService.playLoop()`
   - `customAudioPath` parameter from `IAudioService.playWithMode()`
   - `customAudioPath` parameter from `INotificationService.showTimeUpNow()`
   - All custom audio handling logic in `AudioService`

3. **UI Layer**
   - Custom audio upload section in `SoundSettingsPage`
   - File picker integration
   - All related UI methods (`_pickAudioFile`, `_clearCustomAudio`)

4. **Localization**
   - All custom audio related strings (8 keys in Chinese + English)

5. **Dependencies**
   - `file_picker: ^10.3.8` package

6. **Documentation**
   - `BACKGROUND_AUDIO_PLAYBACK_FIX.md` (obsolete)

### Reverted Commits

The following commits related to custom audio have been reverted:

```
595e0a8 - docs(audio): add user-facing explanation for dual-source playback
5fa95d1 - fix(audio): enable reliable custom audio playback in background with dual-source strategy
86c3586 - fix(audio): enable custom audio playback in background (earlier attempt)
7e390c8 - feat: Add custom audio file upload support for alarm sounds (initial implementation)
```

### Remaining Functionality

GridTimer now focuses on **proven, reliable** alarm functionality:

✅ **What Works Reliably**:
- Default built-in alarm sound (tested across devices)
- Notification system integration for lockscreen
- Multiple playback modes (loop indefinitely, timed, interval)
- TTS announcements
- Vibration
- Gesture controls

❌ **What Is NOT Supported**:
- Custom audio file upload
- User-provided audio files

### Future Considerations

If custom audio is reconsidered in the future, it would require:

1. **Foreground Service Implementation**
   - Persistent notification when timer is active
   - Guaranteed process priority
   - Users must accept persistent notification

2. **Extensive Testing Matrix**
   - 50+ device models
   - Multiple Android versions (10-15)
   - Various OEM ROMs (MIUI, EMUI, OneUI, etc.)

3. **Clear User Communication**
   - Prominent warnings about reliability limitations
   - Explicit disclaimer about non-critical use only
   - Mandatory user acknowledgment

4. **Legal Review**
   - Jurisdiction-specific legal consultation
   - Liability insurance consideration
   - Terms of Service with explicit limitations

### Legal Protection

To address legal concerns, we have added:

1. **LICENSE_DISCLAIMER.md**
   - Comprehensive NO WARRANTY disclaimer
   - Critical medical use prohibition
   - Limitation of liability clause
   - User responsibility acknowledgment
   - Bilingual (English + Chinese)

2. **Recommendation**: Display disclaimer to users at:
   - First app launch
   - In About/Settings page
   - Before app store submission

### Conclusion

**Reliability > Features**

For a timer application targeting senior care:
- **Predictable behavior is more valuable than customization**
- **One reliable sound is better than ten unreliable ones**
- **Legal protection requires realistic limitations**

This decision prioritizes:
1. ✅ User safety
2. ✅ Developer legal protection
3. ✅ Maintainable codebase
4. ✅ Honest communication of capabilities

---

**Status**: Feature removal complete
**Impact**: No users affected (pre-release)
**Testing Required**: Verify default audio works reliably
