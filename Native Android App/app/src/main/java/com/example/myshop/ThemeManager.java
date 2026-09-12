package com.example.myshop;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.res.Configuration;
import android.os.Build;
import android.util.Log;
import android.view.View;

public final class ThemeManager {
    private static final String PREFS_NAME = "myshop_theme";
    private static final String KEY_DARK_MODE = "dark_mode";
    private static final String TAG = "ThemeManager";

    private ThemeManager() {
    }

    public static boolean isDarkMode(Context context) {
        return preferences(context).getBoolean(KEY_DARK_MODE, false);
    }

    public static void setDarkMode(Activity activity, boolean enabled) {
        preferences(activity).edit().putBoolean(KEY_DARK_MODE, enabled).apply();
        applyTheme(activity);
        Intent intent = new Intent(activity, activity.getClass());
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
        activity.startActivity(intent);
        activity.finish();
    }

    public static void applyTheme(Activity activity) {
        boolean darkMode = isDarkMode(activity);
        try {
            Configuration configuration = new Configuration(activity.getResources().getConfiguration());
            int nightMode = darkMode ? Configuration.UI_MODE_NIGHT_YES : Configuration.UI_MODE_NIGHT_NO;
            configuration.uiMode = (configuration.uiMode & ~Configuration.UI_MODE_NIGHT_MASK) | nightMode;
            activity.getResources().updateConfiguration(configuration, activity.getResources().getDisplayMetrics());

            int backgroundColor = activity.getResources().getColor(R.color.background, activity.getTheme());
            activity.getWindow().setStatusBarColor(backgroundColor);
            activity.getWindow().setNavigationBarColor(backgroundColor);
        } catch (RuntimeException ex) {
            Log.e(TAG, "Failed to apply saved theme preference.", ex);
        }

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                int flags = activity.getWindow().getDecorView().getSystemUiVisibility();
                if (darkMode) {
                    flags &= ~View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR;
                } else {
                    flags |= View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR;
                }
                activity.getWindow().getDecorView().setSystemUiVisibility(flags);
            }
        } catch (RuntimeException ex) {
            Log.e(TAG, "Failed to update theme system UI flags.", ex);
        }
    }

    private static SharedPreferences preferences(Context context) {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
    }
}
