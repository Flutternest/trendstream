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
    private FrameLayout playerRoot;
    private ImageButton playPauseButton;
    private ImageButton muteButton;
    private ProgressBar loadingSpinner;
    private boolean isMuted = true;

    private MiniPlayerCallback callback;
    public void setCallback(MiniPlayerCallback callback) {
        this.callback = callback;
    }

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
        playPauseButton = findViewById(R.id.playPauseButton);
        muteButton = findViewById(R.id.muteButton);
        playerRoot = findViewById(R.id.playerRoot);

        // Button setup
        playPauseButton.setOnClickListener(v -> togglePlayPause());
        playPauseButton.setFocusable(true);
        playPauseButton.setFocusableInTouchMode(true);

        muteButton.setOnClickListener(v -> toggleMute());
        muteButton.setFocusable(true);
        muteButton.setFocusableInTouchMode(true);


        playerRoot.setNextFocusRightId(R.id.playPauseButton);
        playerRoot.setNextFocusDownId(R.id.playPauseButton);

        playPauseButton.setNextFocusRightId(R.id.muteButton);
        playPauseButton.setNextFocusLeftId(R.id.playerRoot);
        playPauseButton.setNextFocusDownId(R.id.muteButton);

        muteButton.setNextFocusLeftId(R.id.playPauseButton);
        muteButton.setNextFocusUpId(R.id.playPauseButton);

        playerRoot.setOnFocusChangeListener((v, hasFocus) -> {
            if (hasFocus) {
                playerRoot.setBackgroundResource(R.drawable.focus_border); // Add a border drawable
            } else {
                playerRoot.setBackgroundColor(Color.BLACK); // Remove border
            }
        });

        playerRoot.setClickable(true);
        playerRoot.setOnClickListener(v -> {
            Log.d("MiniPlayerView", "Root clicked — opening full screen");
        });

        // Init player
        exoPlayer = new ExoPlayer.Builder(context).build();
        exoPlayer.setVolume(0f); // 🔇 muted by default
        exoPlayerView.setPlayer(exoPlayer);
        exoPlayerView.setUseController(false);



        updateButtonIcon();
        updateMuteIcon();
    }

    @Override
    public void onFocusChanged(boolean gainFocus, int direction, Rect previouslyFocusedRect) {
        super.onFocusChanged(gainFocus, direction, previouslyFocusedRect);
        if (gainFocus) {
            playerRoot.requestFocus(); // optional
        }
    }

    public void requestFocusToPlayerRoot() {
        playerRoot.setFocusable(true);
        playerRoot.setFocusableInTouchMode(true);
        playerRoot.post(() -> {
            playerRoot.requestFocus();
        });
    }

    public void togglePlayPause() {
        if (exoPlayer.isPlaying()) {
            exoPlayer.pause();
        } else {
            exoPlayer.play();
        }
        updateButtonIcon();
    }

    private void updateButtonIcon() {
        if (playPauseButton != null) {
            playPauseButton.setImageResource(
                    exoPlayer.isPlaying()
                            ? android.R.drawable.ic_media_pause
                            : android.R.drawable.ic_media_play
            );
        }
    }

    private void toggleMute() {
        isMuted = !isMuted;
        exoPlayer.setVolume(isMuted ? 0f : 1f);
        updateMuteIcon();
    }

    private void updateMuteIcon() {
        if (muteButton != null) {
            muteButton.setImageResource(
                    isMuted
                            ? android.R.drawable.ic_lock_silent_mode
                            : android.R.drawable.ic_lock_silent_mode_off
            );
        }
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
                        showLoading(false);
                        updateButtonIcon();
                        break;
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

    @Override
    public boolean dispatchKeyEvent(KeyEvent event) {
        if (event.getAction() == KeyEvent.ACTION_DOWN) {
            Log.d("Focus", "Focused view ID: " + getResources().getResourceEntryName(findFocus().getId()));
        }
        if (event.getAction() == KeyEvent.ACTION_DOWN &&
                (event.getKeyCode() == KeyEvent.KEYCODE_DPAD_CENTER || event.getKeyCode() == KeyEvent.KEYCODE_ENTER)) {

            View focused = findFocus();

            if (focused == playerRoot) {
                if (callback != null) {
                    callback.onRootTapped();
                }
                return true;
            } else if (focused == playPauseButton) {
                playPauseButton.performClick();
                return true;
            } else if (focused == muteButton) {
                muteButton.performClick();
                return true;
            }
        }
        return super.dispatchKeyEvent(event);
    }

    @Override
    public View focusSearch(View focused, int direction) {
        if (focused == playerRoot && (direction == View.FOCUS_RIGHT || direction == View.FOCUS_DOWN)) {
            return playPauseButton;
        }

        if (focused == playPauseButton && (direction == View.FOCUS_RIGHT || direction == View.FOCUS_DOWN)) {
            return muteButton;
        }

        if (focused == muteButton && (direction == View.FOCUS_LEFT || direction == View.FOCUS_UP)) {
            return playPauseButton;
        }

        if (focused == playPauseButton && (direction == View.FOCUS_LEFT || direction == View.FOCUS_UP)) {
            return playerRoot;
        }

        return super.focusSearch(focused, direction);
    }


    public void release() {
        exoPlayer.release();
    }



}
