package org.godotengine.godot.plugin.unityads;

import android.app.Activity;
import android.util.Log;
import android.view.Gravity;
import android.view.ViewGroup;
import android.widget.FrameLayout;

import com.unity3d.ads.IUnityAdsInitializationListener;
import com.unity3d.ads.IUnityAdsLoadListener;
import com.unity3d.ads.IUnityAdsShowListener;
import com.unity3d.ads.UnityAds;
import com.unity3d.ads.UnityAdsShowOptions;
import com.unity3d.services.banners.BannerErrorInfo;
import com.unity3d.services.banners.BannerView;
import com.unity3d.services.banners.UnityBannerSize;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;

import java.util.HashSet;
import java.util.Set;

/**
 * Godot 4.2 Android plugin (v2) wanda ke haɗa Unity Ads SDK da GDScript.
 * Duk method da GDScript ke kira dole ya kasance da @UsedByGodot.
 */
public class UnityAdsPlugin extends GodotPlugin {
    private static final String TAG = "GodotUnityAds";

    private BannerView bannerView;
    private FrameLayout bannerContainer;

    public UnityAdsPlugin(Godot godot) {
        super(godot);
    }

    @Override
    public String getPluginName() {
        return "GodotUnityAds";
    }

    @Override
    public Set<SignalInfo> getPluginSignals() {
        Set<SignalInfo> signals = new HashSet<>();
        signals.add(new SignalInfo("initialization_completed"));
        signals.add(new SignalInfo("initialization_failed", String.class, String.class));

        signals.add(new SignalInfo("rewarded_ad_loaded", String.class));
        signals.add(new SignalInfo("rewarded_ad_failed_to_load", String.class, String.class, String.class));
        signals.add(new SignalInfo("rewarded_ad_completed", String.class));
        signals.add(new SignalInfo("rewarded_ad_skipped", String.class));
        signals.add(new SignalInfo("rewarded_ad_failed_to_show", String.class, String.class, String.class));

        signals.add(new SignalInfo("interstitial_ad_loaded", String.class));
        signals.add(new SignalInfo("interstitial_ad_failed_to_load", String.class, String.class, String.class));
        signals.add(new SignalInfo("interstitial_ad_closed", String.class));
        signals.add(new SignalInfo("interstitial_ad_failed_to_show", String.class, String.class, String.class));

        signals.add(new SignalInfo("banner_ad_loaded", String.class));
        signals.add(new SignalInfo("banner_ad_failed_to_load", String.class, String.class, String.class));
        return signals;
    }

    @UsedByGodot
    public void initialize_ads(String gameId, boolean testMode) {
        final Activity activity = getActivity();
        if (activity == null) {
            emitSignal("initialization_failed", "NO_ACTIVITY", "Activity is null");
            return;
        }
        activity.runOnUiThread(() -> UnityAds.initialize(
            activity.getApplicationContext(), gameId, testMode,
            new IUnityAdsInitializationListener() {
                @Override
                public void onInitializationComplete() {
                    emitSignal("initialization_completed");
                }

                @Override
                public void onInitializationFailed(UnityAds.UnityAdsInitializationError error, String message) {
                    Log.e(TAG, "Initialization failed: " + message);
                    emitSignal("initialization_failed", String.valueOf(error), String.valueOf(message));
                }
            }
        ));
    }

    @UsedByGodot
    public void load_rewarded(String placementId) {
        load(placementId, true);
    }

    @UsedByGodot
    public void show_rewarded(String placementId) {
        show(placementId, true);
    }

    @UsedByGodot
    public void load_interstitial(String placementId) {
        load(placementId, false);
    }

    @UsedByGodot
    public void show_interstitial(String placementId) {
        show(placementId, false);
    }

    private void load(String placementId, final boolean rewarded) {
        final Activity activity = getActivity();
        if (activity == null) {
            return;
        }
        activity.runOnUiThread(() -> UnityAds.load(placementId, new IUnityAdsLoadListener() {
            @Override
            public void onUnityAdsAdLoaded(String loadedPlacement) {
                emitSignal(rewarded ? "rewarded_ad_loaded" : "interstitial_ad_loaded", loadedPlacement);
            }

            @Override
            public void onUnityAdsFailedToLoad(String failedPlacement,
                    UnityAds.UnityAdsLoadError error, String message) {
                Log.e(TAG, "Load failed: " + failedPlacement + " - " + message);
                emitSignal(rewarded ? "rewarded_ad_failed_to_load" : "interstitial_ad_failed_to_load",
                    failedPlacement, String.valueOf(error), String.valueOf(message));
            }
        }));
    }

    private void show(String placementId, final boolean rewarded) {
        final Activity activity = getActivity();
        if (activity == null) {
            emitSignal(rewarded ? "rewarded_ad_failed_to_show" : "interstitial_ad_failed_to_show",
                placementId, "NO_ACTIVITY", "Activity is null");
            return;
        }
        activity.runOnUiThread(() -> UnityAds.show(activity, placementId,
            new UnityAdsShowOptions(), new IUnityAdsShowListener() {
                @Override
                public void onUnityAdsShowComplete(String shownPlacement,
                        UnityAds.UnityAdsShowCompletionState state) {
                    if (rewarded) {
                        // Lada kawai idan an kalli talla har ƙarshe (COMPLETED)
                        if (state == UnityAds.UnityAdsShowCompletionState.COMPLETED) {
                            emitSignal("rewarded_ad_completed", shownPlacement);
                        } else {
                            emitSignal("rewarded_ad_skipped", shownPlacement);
                        }
                    } else {
                        emitSignal("interstitial_ad_closed", shownPlacement);
                    }
                }

                @Override
                public void onUnityAdsShowFailure(String failedPlacement,
                        UnityAds.UnityAdsShowError error, String message) {
                    Log.e(TAG, "Show failed: " + failedPlacement + " - " + message);
                    emitSignal(rewarded ? "rewarded_ad_failed_to_show" : "interstitial_ad_failed_to_show",
                        failedPlacement, String.valueOf(error), String.valueOf(message));
                }

                @Override
                public void onUnityAdsShowStart(String shownPlacement) { }

                @Override
                public void onUnityAdsShowClick(String shownPlacement) { }
            }
        ));
    }

    @UsedByGodot
    public void show_banner(String placementId, boolean bottom) {
        final Activity activity = getActivity();
        if (activity == null) {
            return;
        }
        activity.runOnUiThread(() -> {
            hideBannerInternal();

            bannerView = new BannerView(activity, placementId, new UnityBannerSize(320, 50));
            bannerView.setListener(new BannerView.IListener() {
                @Override
                public void onBannerLoaded(BannerView view) {
                    emitSignal("banner_ad_loaded", view.getPlacementId());
                }

                @Override
                public void onBannerFailedToLoad(BannerView view, BannerErrorInfo errorInfo) {
                    Log.e(TAG, "Banner load failed: " + errorInfo.errorMessage);
                    emitSignal("banner_ad_failed_to_load", view.getPlacementId(),
                        String.valueOf(errorInfo.errorCode), String.valueOf(errorInfo.errorMessage));
                }

                @Override
                public void onBannerShown(BannerView view) { }

                @Override
                public void onBannerClick(BannerView view) { }

                @Override
                public void onBannerLeftApplication(BannerView view) { }
            });

            bannerContainer = new FrameLayout(activity);
            FrameLayout.LayoutParams containerParams = new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
                (bottom ? Gravity.BOTTOM : Gravity.TOP) | Gravity.CENTER_HORIZONTAL
            );
            ViewGroup content = activity.findViewById(android.R.id.content);
            content.addView(bannerContainer, containerParams);
            bannerContainer.addView(bannerView, new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
                Gravity.CENTER
            ));
            bannerView.load();
        });
    }

    @UsedByGodot
    public void hide_banner() {
        final Activity activity = getActivity();
        if (activity == null) {
            return;
        }
        activity.runOnUiThread(this::hideBannerInternal);
    }

    private void hideBannerInternal() {
        if (bannerView != null) {
            bannerView.destroy();
        }
        if (bannerContainer != null) {
            ViewGroup parent = (ViewGroup) bannerContainer.getParent();
            if (parent != null) {
                parent.removeView(bannerContainer);
            }
        }
        bannerView = null;
        bannerContainer = null;
    }
}
