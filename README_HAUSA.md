# Unity Ads don Godot 4.2 (Android) - hanya mafi sauƙi

Ba sai ka shigar da Android Studio ba. GitHub zai gina maka AAR kyauta.

## Sashe na 1: A gina AAR a GitHub (sau ɗaya kawai)

1. Ka buɗe asusu a github.com (kyauta), sannan ka ƙirƙiri **New repository** (misali `godot-unity-ads`), Public ko Private.
2. Ka ɗora fayilolin wannan folder zuwa repository ɗin:
   - Ka danna **Add file → Upload files**, ka ja folder `android` da `addons` ka sauke, ka danna **Commit changes**.
   - **Fayil ɗin workflow:** ka danna **Add file → Create new file**, a filin suna ka rubuta daidai:
     `.github/workflows/build.yml`
     sannan ka liƙa abin da ke cikin `.github/workflows/build.yml` na zip ɗin, ka danna **Commit**.
3. Ka je shafin **Actions**. Idan ya tambaya, ka danna **I understand my workflows, go ahead and enable them**.
4. Ka zaɓi **Build Unity Ads plugin**, ka danna **Run workflow**. Jira kusan minti 3 zuwa 6.
5. Idan ya yi kore (nasara), ka buɗe run ɗin, a ƙasa (**Artifacts**) ka sauke **unity_ads_addon**.
   - Idan ya yi ja (kuskure), ka buɗe step ɗin da ya fashe, ka kwafi rubutun kuskuren ka aiko mini.

## Sashe na 2: A saka a project ɗin Godot

1. Ka yi backup na project ɗinka.
2. **Ka share tsohon** `res://addons/unity_ads` gaba ɗaya (tsohon `.gdap`, `.aar` da `src`).
3. Ka cire zip ɗin `unity_ads_addon`. A ciki akwai folder `unity_ads`. Ka sanya shi a `res://addons/`.
   A ƙarshe ya kamata ka sami:
   - `addons/unity_ads/plugin.cfg`
   - `addons/unity_ads/unity_ads.gd`
   - `addons/unity_ads/unity_ads_plugin.gd`
   - `addons/unity_ads/bin/godot-unity-ads-debug.aar`
   - `addons/unity_ads/bin/godot-unity-ads-release.aar`
4. **Project → Project Settings → Plugins**: ka kunna **GodotUnityAds**. Ka tabbata a **Globals → Autoload** akwai `UnityAds` sau ɗaya kawai.
5. **Project → Install Android Build Template…** (sau ɗaya).
6. **Project → Export → Android**:
   - Ka kunna **Use Gradle Build**.
   - A **Architectures**, ka bar **arm64-v8a** kaɗai.
   - Ka tabbata **Internet** da **Access Network State** suna cikin Permissions.
7. Ka haɗa waya da kebul (USB debugging a kunne) ka yi **Remote Deploy** (alamar waya kusa da Play) don gwaji.

## Sashe na 3: Yadda ake amfani da shi a wasa

A script ɗin da ke sarrafa kuɗi (misali `main.gd`), a `_ready()`, **sau ɗaya kawai**:

```gdscript
func _ready() -> void:
	UnityAds.rewarded_earned.connect(_on_rewarded_earned)
	UnityAds.rewarded_not_ready.connect(_on_rewarded_not_ready)

func _on_rewarded_earned() -> void:
	money += 2000
	_update_ui()
	save_game()
	show_toast("Reward: +N2,000", "success")

func _on_rewarded_not_ready() -> void:
	show_toast("Ad not ready yet. Try again in a moment.", "error")
```

Maɓallin kallon talla: `UnityAds.show_rewarded()`.
Interstitial: `UnityAds.show_interstitial()` (misali bayan End of Day Report).
Banner: `UnityAds.show_banner()` da `UnityAds.hide_banner()`.

## Abubuwan da dole ka duba

- **Placement IDs:** a `unity_ads.gd`, `INTERSTITIAL_ID` da `BANNER_ID` misalai ne. Ka duba su a Unity Dashboard ka daidaita.
- **TEST_MODE = true** yana nuna tallan gwaji. Ka mayar da shi `false` kawai lokacin release.
- **Version:** idan ka canza `unityAdsVersion` a `android/gradle.properties`, dole ka canza `UNITY_ADS_VERSION` a `unity_ads_plugin.gd` zuwa ƙima ɗaya (workflow zai tsaya idan ba daidai ba).
- Idan talla ba ta fito ba, ka duba logcat (`adb logcat -s GodotUnityAds godot`).
