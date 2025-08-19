package com.example.latest_movies.mini_player;

import android.content.Context;
import android.view.View;

import com.egeniq.androidtvprogramguide.miniplayer.MiniPlayerView;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;

public class MiniPlayerPlatformView implements PlatformView {

    private final MiniPlayerView miniPlayerView;
    private final MethodChannel methodChannel;

    MiniPlayerPlatformView(Context context, BinaryMessenger messenger, int id, Map<String, Object> args) {
        miniPlayerView = new MiniPlayerView(context);

        methodChannel = new MethodChannel(messenger, "mini_player_view_channel");


        methodChannel.setMethodCallHandler((call, result) -> {
            switch (call.method) {
                case "play":
                    miniPlayerView.play();
                    result.success(true);
                    break;
                case "pause":
                    miniPlayerView.pause();
                    result.success(true);
                    break;
                case "seekTo":
                    if (call.arguments instanceof Map) {
                        Map<String, Object> seekArgs = (Map<String, Object>) call.arguments;
                        Integer position = (Integer) seekArgs.get("position");
                        if (position != null) {
                            miniPlayerView.seekTo(position);
                            result.success(true);
                        } else {
                            result.error("INVALID_ARGUMENT", "Position is required", null);
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "Arguments must be a Map", null);
                    }
                    break;
                case "getPlayerState":
                    Map<String, Object> state = new HashMap<>();
                    state.put("isPlaying", miniPlayerView.isPlaying());
                    state.put("duration", miniPlayerView.getDuration());
                    result.success(state);
                    break;
                case "getCurrentPosition":
                    result.success(miniPlayerView.getCurrentPosition());
                    break;
                default:
                    result.notImplemented();
                    break;
            }
        });

        // Set initial video URL if passed
        if (args.containsKey("videoUrl")) {
            String url = (String) args.get("videoUrl");
            miniPlayerView.setVideoUrl(url);
        }
    }

    @Override
    public View getView() {
        return miniPlayerView;
    }

    @Override
    public void dispose() {
        miniPlayerView.release();
    }
}
