package com.example.latest_movies.mini_player;

import android.content.Context;
import android.view.View;

import com.egeniq.androidtvprogramguide.miniplayer.MiniPlayerView;

import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;

public class MiniPlayerPlatformView implements PlatformView {

    private final MiniPlayerView miniPlayerView;
    private final MethodChannel methodChannel;

    MiniPlayerPlatformView(Context context, BinaryMessenger messenger, int id, Map<String, Object> args) {
        miniPlayerView = new MiniPlayerView(context);
        miniPlayerView.setFocusable(true);
        miniPlayerView.setFocusableInTouchMode(true);

        methodChannel = new MethodChannel(messenger, "mini_player_view_channel");

        miniPlayerView.setCallback(() -> {
            methodChannel.invokeMethod("onRootTapped", null);
        });

        methodChannel.setMethodCallHandler((call, result) -> {
            switch (call.method) {
                case "togglePlayPause":
                    miniPlayerView.togglePlayPause();
                    result.success(null);
                    break;

                case "requestNativeFocus":
                    miniPlayerView.requestFocusToPlayerRoot();
                    result.success(true);
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
