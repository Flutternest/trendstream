package com.egeniq.androidtvprogramguide.miniplayer;

import android.content.Context;
import android.net.Uri;
import android.os.Handler;
import android.util.AttributeSet;
import android.view.KeyEvent;
import android.view.LayoutInflater;
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
    private SeekBar seekBar;
    private LinearLayout controlsContainer;

    private final Handler handler = new Handler();
    private final int HIDE_DELAY_MS = 3000;

    private final Runnable hideControlsRunnable = () -> controlsContainer.setVisibility(View.GONE);
    private final Runnable updateSeekRunnable = new Runnable() {
        @Override
        public void run() {
            if (exoPlayer != null && exoPlayer.isPlaying()) {
                seekBar.setProgress((int) exoPlayer.getCurrentPosition());
                handler.postDelayed(this, 500);
            }
        }
    };

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
        seekBar = findViewById(R.id.seekBar);
        controlsContainer = findViewById(R.id.controlsContainer);

        exoPlayer = new ExoPlayer.Builder(context).build();
        exoPlayerView.setPlayer(exoPlayer);
        exoPlayerView.setUseController(false); // we use custom controls

        playPauseButton.setOnClickListener(v -> togglePlayPause());

        seekBar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            boolean wasPlaying = false;
            @Override public void onStartTrackingTouch(SeekBar seekBar) {
                wasPlaying = exoPlayer.isPlaying();
                exoPlayer.pause();
                handler.removeCallbacks(updateSeekRunnable);
            }
            @Override public void onStopTrackingTouch(SeekBar seekBar) {
                exoPlayer.seekTo(seekBar.getProgress());
                if (wasPlaying) exoPlayer.play();
                handler.post(updateSeekRunnable);
            }
            @Override public void onProgressChanged(SeekBar seekBar, int i, boolean b) {}
        });

        // Auto-hide logic
        setOnKeyListener((v, keyCode, event) -> {
            if (event.getAction() == KeyEvent.ACTION_DOWN) showControlsTemporarily();
            return false;
        });
        setFocusableInTouchMode(true);
        requestFocus();
    }

    public void setVideoUrl(String url) {
        MediaItem mediaItem = MediaItem.fromUri(Uri.parse(url));
        exoPlayer.setMediaItem(mediaItem);
        exoPlayer.prepare();
        exoPlayer.play();

        exoPlayer.addListener(new Player.Listener() {
            @Override
            public void onPlaybackStateChanged(int state) {
                if (state == Player.STATE_READY) {
                    seekBar.setMax((int) exoPlayer.getDuration());
                    handler.post(updateSeekRunnable);
                    showControlsTemporarily();
                }
            }
        });
    }

    private void togglePlayPause() {
        if (exoPlayer.isPlaying()) {
            exoPlayer.pause();
            playPauseButton.setImageResource(android.R.drawable.ic_media_play);
        } else {
            exoPlayer.play();
            playPauseButton.setImageResource(android.R.drawable.ic_media_pause);
        }
        showControlsTemporarily();
    }

    private void showControlsTemporarily() {
        controlsContainer.setVisibility(View.VISIBLE);
        handler.removeCallbacks(hideControlsRunnable);
        handler.postDelayed(hideControlsRunnable, HIDE_DELAY_MS);
    }

    public void release() {
        handler.removeCallbacks(updateSeekRunnable);
        handler.removeCallbacks(hideControlsRunnable);
        exoPlayer.release();
    }
}
