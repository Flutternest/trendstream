# Full-Screen Mini Player Screen

## Overview
This feature allows users to click on the mini player in the sports view to navigate to a dedicated full-screen screen with custom controls while keeping the native Android mini player running in the background.

## How It Works

### 1. **Mini Player Widget**
- The `MiniPlayerWidget` now accepts an optional `onTap` callback
- When clicked (either by keyboard Enter/Select or touch), it triggers the callback
- If no callback is provided, it falls back to the default behavior (opening native player)

### 2. **Full-Screen Screen**
- `FullScreenMiniPlayerScreen` provides a dedicated full-screen Flutter screen
- Contains custom controls: back button, play/pause button, seek bar, and time display
- Communicates with the native mini player through method channels
- Users can navigate to and from this screen using standard navigation

### 3. **Method Channel Communication**
- Uses the `mini_player_view_channel` to control the native player
- Supports: play, pause, seek, get player state, get current position

## Usage

### In Sports View
```dart
MiniPlayerWidget(
  videoUrl: 'https://example.com/video.m3u8',
  onTap: () {
    setState(() {
      _showFullScreenOverlay = true;
    });
  },
)
```

### Full-Screen Screen Navigation
```dart
onTap: () {
  AppRouter.navigateToPage(
    Routes.fullScreenMiniPlayer,
    arguments: 'https://example.com/video.m3u8',
  );
},
```

## Features

### Controls
- **Back Button**: Returns to the previous view
- **Play/Pause Button**: Large center button to control playback
- **Seek Bar**: Interactive slider to navigate through the video
- **Time Display**: Shows current position and total duration

### User Experience
- **Auto-hide Controls**: Controls automatically hide after 3 seconds of inactivity
- **Tap to Toggle**: Tap anywhere on screen to show/hide controls
- **Smooth Transitions**: Gradient overlays for better visibility
- **Loading States**: Shows loading indicator during operations

## Technical Implementation

### Flutter Side
- `FullScreenMiniPlayerScreen`: Main full-screen widget
- Uses `useState` and `useEffect` hooks for state management
- Periodic updates every 500ms for position tracking
- Method channel communication with native side
- Standard navigation integration

### Native Android Side
- `MiniPlayerPlatformView`: Handles method channel calls
- `MiniPlayerView`: Extended with control methods
- Supports: play, pause, seek, state queries

### Method Channel Methods
```dart
// Play video
await methodChannel.invokeMethod('play');

// Pause video
await methodChannel.invokeMethod('pause');

// Seek to position
await methodChannel.invokeMethod('seekTo', {
  'position': position.inMilliseconds,
});

// Get player state
final state = await methodChannel.invokeMethod('getPlayerState');

// Get current position
final position = await methodChannel.invokeMethod('getCurrentPosition');
```

## Benefits

1. **Better UX**: Full-screen experience without losing mini player state
2. **Custom Controls**: Flutter-based controls that match app design
3. **Seamless Integration**: Works with existing mini player infrastructure
4. **Performance**: Native player continues running, screen is just UI
5. **Flexibility**: Easy to customize controls and add new features
6. **Standard Navigation**: Users can navigate to and from using familiar navigation patterns
7. **Clean Architecture**: Separate screen instead of overlay, better state management

## Future Enhancements

1. **Volume Control**: Add volume slider
2. **Quality Selection**: Allow switching between different video qualities
3. **Subtitles**: Support for subtitle tracks
4. **Picture-in-Picture**: Support for PiP mode
5. **Gesture Controls**: Swipe gestures for seeking and volume
6. **Keyboard Shortcuts**: Additional keyboard controls

## Troubleshooting

### Common Issues
1. **Method Channel Not Working**: Ensure native side implements all required methods
2. **Navigation Not Working**: Check if route is properly added to router
3. **Seek Not Working**: Verify seek method is implemented in native MiniPlayerView
4. **Performance Issues**: Consider reducing update frequency for position updates

### Debug Tips
- Use `debugPrint` in method channel calls to verify communication
- Check native logs for method channel errors
- Verify MiniPlayerView methods are properly implemented
- Test with simple video URLs first

## Example Implementation

See `lib/features/sports/widgtes/current_sports_details.dart` for a complete working example of how to navigate to the full-screen player.
