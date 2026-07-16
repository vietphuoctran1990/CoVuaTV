package com.family.doraemonchesstv;

import android.annotation.SuppressLint;
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
 */
public class MainActivity extends AppCompatActivity {
    private WebView web;
    private long lastBackMs = 0L;
    // Cap nhat tu JS: true khi dang o man hinh menu chinh (co the thoat app)
    private volatile boolean atMainMenu = true;

    @SuppressLint("SetJavaScriptEnabled")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        getWindow().getDecorView().setSystemUiVisibility(
                View.SYSTEM_UI_FLAG_FULLSCREEN
                        | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                        | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                        | View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                        | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
        );

        web = new WebView(this);
        setContentView(web);

        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
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

        web.setWebViewClient(new WebViewClient());
        web.setFocusable(true);
        web.setFocusableInTouchMode(true);
        web.requestFocus(View.FOCUS_DOWN);
        // Cau noi JS -> native de biet dang o menu chinh hay khong
        web.addJavascriptInterface(new NavBridge(), "AndroidNav");

        // Local game bundle
        web.loadUrl("file:///android_asset/www/index.html");
    }

    /** JS goi AndroidNav.setMainMenu(true/false) khi doi man hinh. */
    private class NavBridge {
        @JavascriptInterface
        public void setMainMenu(boolean v) {
            atMainMenu = v;
        }
    }

    @Override
    public boolean dispatchKeyEvent(KeyEvent event) {
        // Let WebView receive D-pad / Enter / Back for the game
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
            // O menu chinh: nhan Back 2 lan trong 2s de thoat app
            long now = System.currentTimeMillis();
            if (now - lastBackMs < 2000L) {
                finish();
            } else {
                lastBackMs = now;
                Toast.makeText(this, "Nhấn Back lần nữa để thoát", Toast.LENGTH_SHORT).show();
            }
            return;
        }
        // Trong game / man hinh phu: chuyen Back thanh Escape cho JS xu ly
        web.evaluateJavascript(
                "(function(){var e=new KeyboardEvent('keydown',{key:'Escape',bubbles:true});window.dispatchEvent(e);})();",
                null
        );
    }

    @Override
    protected void onDestroy() {
        if (web != null) {
            web.destroy();
            web = null;
        }
        super.onDestroy();
    }
}
