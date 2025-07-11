package com.egeniq.androidtvprogramguide.miniplayer;

import android.content.Context;
import android.graphics.Rect;
import android.net.Uri;
import android.os.Handler;
import android.util.AttributeSet;
import android.view.KeyEvent;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.ImageButton;
import android.widget.LinearLayout;
import android.widget.SeekBar;

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
    private ImageButton playPauseButton;

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

        exoPlayerView = findViewById(R.id.exoPlayerView);
        playPauseButton = findViewById(R.id.playPauseButton);

        setFocusable(true);
        setFocusableInTouchMode(true);

        exoPlayer = new ExoPlayer.Builder(context).build();
        exoPlayerView.setPlayer(exoPlayer);
        exoPlayerView.setUseController(false);

        playPauseButton.setOnClickListener(v -> togglePlayPause());
        playPauseButton.setFocusable(true);
        playPauseButton.setFocusableInTouchMode(true);
        updateButtonIcon();
    }

    private void togglePlayPause() {
        if (exoPlayer.isPlaying()) {
            exoPlayer.pause();
        } else {
            exoPlayer.play();
        }
        updateButtonIcon();
    }

    private void updateButtonIcon() {
        playPauseButton.setImageResource(
                exoPlayer.isPlaying()
                        ? android.R.drawable.ic_media_pause
                        : android.R.drawable.ic_media_play
        );
    }

    public void setVideoUrl(String url) {
        MediaItem mediaItem = MediaItem.fromUri(Uri.parse(url));
        exoPlayer.setMediaItem(mediaItem);
        exoPlayer.prepare();
        exoPlayer.play();

        // Wait until player is ready before updating icon
        exoPlayer.addListener(new Player.Listener() {
            @Override
            public void onPlaybackStateChanged(int state) {
                if (state == Player.STATE_READY) {
                    updateButtonIcon();
                }
            }
        });
    }

    @Override
    public boolean dispatchKeyEvent(KeyEvent event) {
        if (event.getAction() == KeyEvent.ACTION_DOWN) {
            if (event.getKeyCode() == KeyEvent.KEYCODE_DPAD_CENTER ||
                    event.getKeyCode() == KeyEvent.KEYCODE_ENTER) {
                togglePlayPause();
                return true; // Consume the event
            }
        }
        return super.dispatchKeyEvent(event);
    }

    public void release() {
        exoPlayer.release();
    }
}
