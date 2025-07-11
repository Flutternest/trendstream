package com.example.latest_movies.mini_player;

import android.content.Context;

import java.util.Map;

import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

public class MiniPlayerViewFactory extends PlatformViewFactory {

    public MiniPlayerViewFactory() {
        super(StandardMessageCodec.INSTANCE);
    }

    @Override
    public PlatformView create(Context context, int id, Object args) {
        String url = ((Map<String, Object>) args).get("videoUrl").toString();
        return new MiniPlayerPlatformView(context, url);
    }
}

