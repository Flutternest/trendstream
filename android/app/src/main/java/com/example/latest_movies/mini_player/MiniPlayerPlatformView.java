package com.example.latest_movies.mini_player;

import android.content.Context;
import android.view.View;

import com.egeniq.androidtvprogramguide.miniplayer.MiniPlayerView;

import io.flutter.plugin.platform.PlatformView;

public class MiniPlayerPlatformView implements PlatformView {

    private final MiniPlayerView miniPlayerView;

    MiniPlayerPlatformView(Context context, String videoUrl) {
        miniPlayerView = new MiniPlayerView(context);
        miniPlayerView.setVideoUrl(videoUrl);
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
