package com.egeniq.androidtvprogramguide.miniplayer;

import android.content.Context;
import android.graphics.Color;
import android.graphics.Rect;
import android.net.Uri;
import android.os.Handler;
import android.util.AttributeSet;
import android.util.Log;
import android.view.KeyEvent;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.ImageButton;
import android.widget.ProgressBar;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.egeniq.androidtvprogramguide.R;

import androidx.media3.common.MediaItem;
import androidx.media3.common.Player;
import androidx.media3.exoplayer.ExoPlayer;
import androidx.media3.ui.PlayerView;

public class MiniPlayerView extends FrameLayout {

    private PlayerView exoPlayerView;
    private ExoPlayer exoPlayer;
    private ProgressBar loadingSpinner;

    public MiniPlayerView(@NonNull Context context) {
        super(context);
        init(context);
    }

    public MiniPlayerView(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        init(context);
    }

    private void init(Context context) {
        LayoutInflater.from(context).inflate(R.layout.mini_player_view, this, true);

        loadingSpinner = findViewById(R.id.loadingSpinner);
        exoPlayerView = findViewById(R.id.exoPlayerView);

        // Init player
        exoPlayer = new ExoPlayer.Builder(context).build();
        exoPlayer.setVolume(0f); // 🔇 muted by default
        exoPlayerView.setPlayer(exoPlayer);
        exoPlayerView.setUseController(false);


    }


    public void setVideoUrl(String url) {
        MediaItem mediaItem = MediaItem.fromUri(Uri.parse(url));
        exoPlayer.setMediaItem(mediaItem);
        exoPlayer.prepare();
        exoPlayer.play();

        exoPlayer.addListener(new Player.Listener() {
            @Override
            public void onPlaybackStateChanged(int state) {
                switch (state) {
                    case Player.STATE_BUFFERING:
                        showLoading(true);
                        break;
                    case Player.STATE_READY:
                    case Player.STATE_ENDED:
                        showLoading(false);
                        break;
                }
            }
        });
    }

    private void showLoading(boolean show) {
        if (loadingSpinner != null) {
            loadingSpinner.setVisibility(show ? View.VISIBLE : View.GONE);
        }
    }


    public void release() {
        exoPlayer.release();
    }



}
