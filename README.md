⚠️ Files arent updated to the modified versions yet

This is a modification to TheNexusAvenger's LocalAudioSubtitles to use Norteous's Subtitle Engine subtitles instead of the native ones.

The main use case of this is to take advantage of the subtitle configuration in LocalAudio while using the nicer-looking Subtitle Engine for the subtitles displayed to the user.

# Setup

Setup is an easy drop-and-replace. Simply replace your existing LocalAudioSubtitles module with the one in this repo, and ensure Subtitle Engine is set up (default settings can remain, if you change anything, make sure the "Self" profile exists, and has no speaker name). If you do that correctly, it should work!

If this is your first time using LocalAudioSubtitles, please refer to the original repo's readme for how to set up subtitles.

# Limitations

This system has been designed to still have similar features to the native subtitles, but there's still some things that don't work perfectly:

* Rolloff half-works. If you're too far away from an audio, just like natively, it won't show a subtitle. However, it cannot remove a subtitle automatically when you get too far away.
* Stacking isn't natively supported by Subtitle Engine. (havent tested how stacking works, but these are probably the outcomes) While duplicate subtitles will still group together, there's no indicator for many are stacked. OR. This means that duplicate subtitles will appear twice and not combine into one.

Feel free to make a pull request to fix any of these things!
