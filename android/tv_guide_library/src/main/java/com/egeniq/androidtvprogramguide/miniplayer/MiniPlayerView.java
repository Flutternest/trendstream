package com.egeniq.androidtvprogramguide.miniplayer;

import android.content.Context;
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

        exoPlayer = new ExoPlayer.Builder(context).build();
        exoPlayerView.setPlayer(exoPlayer);
        exoPlayerView.setUseController(false);

        // Ensure click on play/pause works
        playPauseButton.setOnClickListener(v -> togglePlayPause());

        // Show button only when this view is focused
        setOnFocusChangeListener((v, hasFocus) -> {
            updateButtonVisibility(hasFocus, isHovered());
        });

        // Show button only when hovered
        setOnHoverListener((v, event) -> {
            switch (event.getAction()) {
                case MotionEvent.ACTION_HOVER_ENTER:
                    updateButtonVisibility(isFocused(), true);
                    break;
                case MotionEvent.ACTION_HOVER_EXIT:
                    updateButtonVisibility(isFocused(), false);
                    break;
            }
            return true;
        });

        // Ensure root is focusable
        setFocusable(true);
        setFocusableInTouchMode(true);
        requestFocus();
    }

    public void setVideoUrl(String url) {
        MediaItem mediaItem = MediaItem.fromUri(Uri.parse(url));
        exoPlayer.setMediaItem(mediaItem);
        exoPlayer.prepare();
        exoPlayer.play();
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

    private void updateButtonVisibility(boolean isFocused, boolean isHovered) {
        if (isFocused || isHovered) {
            playPauseButton.setVisibility(View.VISIBLE);
        } else {
            playPauseButton.setVisibility(View.GONE);
        }
    }

    public void release() {
        exoPlayer.release();
    }
}

