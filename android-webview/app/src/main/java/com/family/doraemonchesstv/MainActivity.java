package com.family.doraemonchesstv;

import android.annotation.SuppressLint;
import android.content.pm.ActivityInfo;
import android.os.Build;
import android.os.Bundle;
import android.view.KeyEvent;
import android.view.View;
import android.view.WindowManager;
import android.webkit.JavascriptInterface;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

/**
 * Android TV / phone wrapper: loads local web game from assets/www.
 * Tối ưu Xiaomi Google TV (4K, remote D-pad, không cảm ứng).
 */
public class MainActivity extends AppCompatActivity {
    private WebView web;
    private long lastBackMs = 0L;
    // Cập nhật từ JS: true khi đang ở màn hình menu chính (có thể thoát app)
    private volatile boolean atMainMenu = true;

    @SuppressLint("SetJavaScriptEnabled")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // Ép landscape — TV không xoay, tránh sensorLandscape lỗi trên một số panel
        setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE);

        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        // Fullscreen immersive cho overscan TV
        hideSystemUi();

        web = new WebView(this);
        setContentView(web);

        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setDatabaseEnabled(true);
        s.setMediaPlaybackRequiresUserGesture(false);
        s.setAllowFileAccess(true);
        s.setAllowContentAccess(true);
        // Needed for file:// relative assets inside WebView on older APIs
        s.setAllowFileAccessFromFileURLs(true);
        s.setAllowUniversalAccessFromFileURLs(true);
        s.setCacheMode(WebSettings.LOAD_DEFAULT);
        s.setUseWideViewPort(true);
        s.setLoadWithOverviewMode(true);
        s.setBuiltInZoomControls(false);
        s.setDisplayZoomControls(false);
        s.setSupportZoom(false);
        // TV 4K: render theo CSS viewport, không scale text hệ thống làm vỡ layout
        s.setTextZoom(100);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            s.setOffscreenPreRaster(true);
        }
        // Hardware layer giúp 4K/144Hz mượt hơn với canvas/CSS animation
        web.setLayerType(View.LAYER_TYPE_HARDWARE, null);

        web.setWebViewClient(new WebViewClient());
        web.setFocusable(true);
        web.setFocusableInTouchMode(true);
        web.requestFocus(View.FOCUS_DOWN);
        // Cầu nối JS -> native để biết đang ở menu chính hay không
        web.addJavascriptInterface(new NavBridge(), "AndroidNav");

        // Local game bundle
        web.loadUrl("file:///android_asset/www/index.html");
    }

    private void hideSystemUi() {
        View decor = getWindow().getDecorView();
        decor.setSystemUiVisibility(
                View.SYSTEM_UI_FLAG_FULLSCREEN
                        | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                        | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                        | View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                        | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                        | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
        );
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            WindowManager.LayoutParams lp = getWindow().getAttributes();
            lp.layoutInDisplayCutoutMode =
                    WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES;
            getWindow().setAttributes(lp);
        }
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        if (hasFocus) {
            hideSystemUi();
            if (web != null) {
                web.requestFocus(View.FOCUS_DOWN);
            }
        }
    }

    /** JS gọi AndroidNav.setMainMenu(true/false) khi đổi màn hình. */
    private class NavBridge {
        @JavascriptInterface
        public void setMainMenu(boolean v) {
            atMainMenu = v;
        }
    }

    @Override
    public boolean dispatchKeyEvent(KeyEvent event) {
        // Cho WebView nhận D-pad / Enter / Back — remote TV
        if (web != null) {
            return web.dispatchKeyEvent(event) || super.dispatchKeyEvent(event);
        }
        return super.dispatchKeyEvent(event);
    }

    @Override
    public void onBackPressed() {
        if (web == null) {
            super.onBackPressed();
            return;
        }
        if (atMainMenu) {
            // Ở menu chính: nhấn Back 2 lần trong 2s để thoát app
            long now = System.currentTimeMillis();
            if (now - lastBackMs < 2000L) {
                finish();
            } else {
                lastBackMs = now;
                Toast.makeText(this, "Nhấn Back lần nữa để thoát", Toast.LENGTH_SHORT).show();
            }
            return;
        }
        // Trong game / màn hình phụ: chuyển Back thành Escape cho JS xử lý
        web.evaluateJavascript(
                "(function(){var e=new KeyboardEvent('keydown',{key:'Escape',bubbles:true});window.dispatchEvent(e);})();",
                null
        );
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (web != null) {
            web.onResume();
        }
        hideSystemUi();
    }

    @Override
    protected void onPause() {
        if (web != null) {
            web.onPause();
        }
        super.onPause();
    }

    @Override
    protected void onDestroy() {
        if (web != null) {
            web.loadUrl("about:blank");
            web.stopLoading();
            web.destroy();
            web = null;
        }
        super.onDestroy();
    }
}
