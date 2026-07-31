package com.lastmagazine.game;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.graphics.Color;
import android.net.Uri;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.webkit.ConsoleMessage;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceError;
import android.webkit.WebResourceRequest;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;

public final class MainActivity extends Activity {
    private static final String START_URL = "file:///android_asset/index.html";

    private WebView webView;

    @SuppressLint({"SetJavaScriptEnabled", "ObsoleteSdkInt"})
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        try {
            requestWindowFeature(Window.FEATURE_NO_TITLE);
            getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
            getWindow().setStatusBarColor(Color.BLACK);
            getWindow().setNavigationBarColor(Color.BLACK);
            enterImmersiveMode();
            createAndLoadWebView();
        } catch (Throwable error) {
            android.util.Log.e("LAST_MAGAZINE", "Startup failure", error);
            showStartupError(error);
        }
    }

    @SuppressLint({"SetJavaScriptEnabled", "ObsoleteSdkInt"})
    private void createAndLoadWebView() {
        webView = new WebView(this);
        webView.setBackgroundColor(Color.BLACK);
        webView.setOverScrollMode(View.OVER_SCROLL_NEVER);
        webView.setHapticFeedbackEnabled(false);
        webView.setLongClickable(false);
        webView.setOnLongClickListener(new View.OnLongClickListener() {
            @Override
            public boolean onLongClick(View view) {
                return true;
            }
        });
        webView.setFocusable(true);
        webView.setFocusableInTouchMode(true);

        WebSettings settings = webView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setDatabaseEnabled(true);
        settings.setAllowFileAccess(true);
        settings.setAllowContentAccess(true);
        settings.setAllowFileAccessFromFileURLs(true);
        settings.setAllowUniversalAccessFromFileURLs(false);
        settings.setSupportZoom(false);
        settings.setBuiltInZoomControls(false);
        settings.setDisplayZoomControls(false);
        settings.setUseWideViewPort(true);
        settings.setLoadWithOverviewMode(false);
        settings.setMediaPlaybackRequiresUserGesture(false);
        settings.setDefaultTextEncodingName("UTF-8");
        settings.setCacheMode(WebSettings.LOAD_NO_CACHE);

        webView.setWebChromeClient(new WebChromeClient() {
            @Override
            public boolean onConsoleMessage(ConsoleMessage consoleMessage) {
                android.util.Log.d(
                    "LAST_MAGAZINE_WEB",
                    consoleMessage.message() + " @" + consoleMessage.lineNumber()
                );
                return true;
            }
        });

        webView.setWebViewClient(new WebViewClient() {
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
                Uri uri = request.getUrl();
                return !"file".equalsIgnoreCase(uri.getScheme());
            }

            @Override
            public void onPageFinished(WebView view, String url) {
                view.evaluateJavascript(
                    "document.documentElement.classList.add('android-app');" +
                    "window.LAST_MAGAZINE_ANDROID=true;",
                    null
                );
            }

            @Override
            public void onReceivedError(
                WebView view,
                WebResourceRequest request,
                WebResourceError error
            ) {
                if (request.isForMainFrame()) {
                    String message = "WebView load error " + error.getErrorCode() + ": " + error.getDescription();
                    android.util.Log.e("LAST_MAGAZINE", message);
                    showStartupError(new IllegalStateException(message));
                }
            }
        });

        setContentView(webView);
        webView.loadUrl(START_URL);
        webView.requestFocus(View.FOCUS_DOWN);
    }

    private void showStartupError(Throwable error) {
        if (webView != null) {
            try {
                webView.destroy();
            } catch (Throwable ignored) {
                // Fall through to a native error screen.
            }
            webView = null;
        }

        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        layout.setGravity(Gravity.CENTER);
        layout.setPadding(48, 48, 48, 48);
        layout.setBackgroundColor(Color.rgb(7, 11, 16));

        TextView title = new TextView(this);
        title.setText("LAST MAGAZINE\nSTARTUP ERROR");
        title.setTextColor(Color.WHITE);
        title.setTextSize(24.0f);
        title.setGravity(Gravity.CENTER);
        layout.addView(title);

        TextView detail = new TextView(this);
        detail.setText(error.getClass().getSimpleName() + "\n" + String.valueOf(error.getMessage()));
        detail.setTextColor(Color.rgb(255, 189, 85));
        detail.setTextSize(14.0f);
        detail.setGravity(Gravity.CENTER);
        detail.setPadding(0, 24, 0, 24);
        layout.addView(detail);

        Button retry = new Button(this);
        retry.setText("RETRY");
        retry.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                try {
                    createAndLoadWebView();
                } catch (Throwable retryError) {
                    android.util.Log.e("LAST_MAGAZINE", "Retry failure", retryError);
                    showStartupError(retryError);
                }
            }
        });
        layout.addView(retry);

        setContentView(layout);
    }

    @Override
    protected void onResume() {
        super.onResume();
        enterImmersiveMode();
        if (webView != null) {
            webView.onResume();
            webView.resumeTimers();
        }
    }

    @Override
    protected void onPause() {
        if (webView != null) {
            webView.onPause();
            webView.pauseTimers();
        }
        super.onPause();
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        if (hasFocus) {
            enterImmersiveMode();
        }
    }

    @Override
    public void onBackPressed() {
        if (webView == null) {
            moveTaskToBack(true);
            return;
        }

        String script =
            "(function(){" +
            "var active=document.querySelector('.screen.active');" +
            "if(!active||active.id==='titleScreen')return 'exit';" +
            "if(active.id==='rewardScreen'||active.id==='routeScreen')return 'blocked';" +
            "var close=active.querySelector('[data-back],[data-close],#closeBag,.close');" +
            "if(close){close.click();return 'handled';}" +
            "document.dispatchEvent(new KeyboardEvent('keydown',{key:'Escape',code:'Escape'}));" +
            "return 'handled';" +
            "})()";

        webView.evaluateJavascript(script, new android.webkit.ValueCallback<String>() {
            @Override
            public void onReceiveValue(String result) {
                if ("\"exit\"".equals(result)) {
                    moveTaskToBack(true);
                }
            }
        });
    }

    @Override
    protected void onDestroy() {
        if (webView != null) {
            webView.loadUrl("about:blank");
            webView.stopLoading();
            webView.setWebChromeClient(null);
            webView.setWebViewClient(null);
            webView.destroy();
            webView = null;
        }
        super.onDestroy();
    }

    private void enterImmersiveMode() {
        getWindow().getDecorView().setSystemUiVisibility(
            View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                | View.SYSTEM_UI_FLAG_FULLSCREEN
                | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                | View.SYSTEM_UI_FLAG_LAYOUT_STABLE
        );
    }
}
