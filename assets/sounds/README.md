# Audio Assets

## Current Sound

GridTimer uses **Kenney's Interface Sounds** - a free, CC0 licensed sound pack.

**Active sound file:**
- `kenney_interface-sounds/Audio/confirmation_001.ogg` - Used for all timer completions

**License:** CC0 (Public Domain)  
**Source:** https://kenney.nl/assets/interface-sounds

## Android Notification Sound

The sound file is also copied to:
- `android/app/src/main/res/raw/confirmation_001.ogg`

This is required for Android notification system to play the sound when timers complete.

## About Kenney Interface Sounds

This sound pack contains 100+ high-quality UI sounds, all released under CC0 license (public domain). This means:
- ✅ Free to use commercially
- ✅ No attribution required (but appreciated)
- ✅ Can be modified
- ✅ Perfect for open-source projects

The full collection is in `kenney_interface-sounds/Audio/` with sounds for:
- Confirmations, errors, clicks
- UI interactions
- Toggles, switches
- And more

## Changing the Sound

To use a different sound from the pack:

1. Choose a sound from `kenney_interface-sounds/Audio/`
2. Copy it to `android/app/src/main/res/raw/` (without .ogg extension in reference)
3. Update `lib/infrastructure/audio_service.dart` asset path
4. Update `lib/infrastructure/notification_service.dart` resource name

