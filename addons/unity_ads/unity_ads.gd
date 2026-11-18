extends Node

## Unity Ads (Android kawai). Autoload mai suna "UnityAds".
##
## Yadda ake amfani:
##   UnityAds.rewarded_earned.connect(_on_rewarded_earned)   # sau ɗaya kawai, a _ready()
##   UnityAds.show_rewarded()
##   UnityAds.show_interstitial()
##   UnityAds.show_banner() / UnityAds.hide_banner()

signal rewarded_earned
signal rewarded_not_ready
signal rewarded_skipped
signal ad_error(message: String)

const GAME_ID := "800439932"
const REWARDED_ID := "BP_Rewarded_Android"
const INTERSTITIAL_ID := "Interstitial_Android"  # Canza idan Dashboard ɗinka yana da wani suna
const BANNER_ID := "Banner_Android"               # Canza idan Dashboard ɗinka yana da wani suna
const TEST_MODE := true                           # Kashe (false) kawai lokacin release
const RETRY_SECONDS := 30.0

var _bridge: Object = null
var _initialized := false
var _rewarded_ready := false
var _interstitial_ready := false
var _showing_rewarded := false


func _ready() -> void:
	# Talla tana aiki ko da wasa yana pause (misali a Shop)
	process_mode = Node.PROCESS_MODE_ALWAYS

	if OS.get_name() != "Android":
		print("UnityAds: ba Android ba ne, an tsallake talla.")
		return

	if not Engine.has_singleton("GodotUnityAds"):
		var message := "GodotUnityAds plugin bai samu ba. Duba cewa an kunna plugin, an kunna Gradle Build, kuma AAR yana addons/unity_ads/bin."
		push_error(message)
		ad_error.emit(message)
		return

	_bridge = Engine.get_singleton("GodotUnityAds")

	# A haɗa signals KAFIN init
	_connect_bridge_signal("initialization_completed", _on_initialization_completed)
	_connect_bridge_signal("initialization_failed", _on_initialization_failed)

	_connect_bridge_signal("rewarded_ad_loaded", _on_rewarded_loaded)
	_connect_bridge_signal("rewarded_ad_failed_to_load", _on_ad_failed_to_load)
	_connect_bridge_signal("rewarded_ad_completed", _on_rewarded_completed)
	_connect_bridge_signal("rewarded_ad_skipped", _on_rewarded_skipped)
	_connect_bridge_signal("rewarded_ad_failed_to_show", _on_ad_failed_to_show)

	_connect_bridge_signal("interstitial_ad_loaded", _on_interstitial_loaded)
	_connect_bridge_signal("interstitial_ad_failed_to_load", _on_ad_failed_to_load)
	_connect_bridge_signal("interstitial_ad_closed", _on_interstitial_closed)
	_connect_bridge_signal("interstitial_ad_failed_to_show", _on_ad_failed_to_show)

	_connect_bridge_signal("banner_ad_loaded", _on_banner_loaded)
	_connect_bridge_signal("banner_ad_failed_to_load", _on_ad_failed_to_load)

	_bridge.initialize_ads(GAME_ID, TEST_MODE)


func _connect_bridge_signal(signal_name: String, callback: Callable) -> void:
	if _bridge != null and _bridge.has_signal(signal_name):
		if not _bridge.is_connected(signal_name, callback):
			_bridge.connect(signal_name, callback)


# ---------------- Initialization ----------------

func _on_initialization_completed() -> void:
	_initialized = true
	_bridge.load_rewarded(REWARDED_ID)
	_bridge.load_interstitial(INTERSTITIAL_ID)


func _on_initialization_failed(error_name: String, message: String) -> void:
	var error_text := "Unity Ads initialization failed: %s - %s" % [error_name, message]
	push_error(error_text)
	ad_error.emit(error_text)


# ---------------- Load / show errors ----------------

func _on_ad_failed_to_load(placement_id: String, error_name: String, message: String) -> void:
	var error_text := "Ad load failed (%s): %s - %s" % [placement_id, error_name, message]
	push_warning(error_text)
	ad_error.emit(error_text)

	if placement_id == REWARDED_ID:
		_rewarded_ready = false
		_retry_load(REWARDED_ID)
	elif placement_id == INTERSTITIAL_ID:
		_interstitial_ready = false
		_retry_load(INTERSTITIAL_ID)


func _on_ad_failed_to_show(placement_id: String, error_name: String, message: String) -> void:
	var error_text := "Ad show failed (%s): %s - %s" % [placement_id, error_name, message]
	push_warning(error_text)
	ad_error.emit(error_text)

	if placement_id == REWARDED_ID:
		_showing_rewarded = false
		_rewarded_ready = false
		_bridge.load_rewarded(REWARDED_ID)
	elif placement_id == INTERSTITIAL_ID:
		_interstitial_ready = false
		_bridge.load_interstitial(INTERSTITIAL_ID)


func _retry_load(placement_id: String) -> void:
	await get_tree().create_timer(RETRY_SECONDS).timeout
	if _bridge == null or not _initialized:
		return
	if placement_id == REWARDED_ID and not _rewarded_ready:
		_bridge.load_rewarded(REWARDED_ID)
	elif placement_id == INTERSTITIAL_ID and not _interstitial_ready:
		_bridge.load_interstitial(INTERSTITIAL_ID)


# ---------------- Rewarded ----------------

func is_rewarded_ready() -> bool:
	return _initialized and _rewarded_ready and not _showing_rewarded


func show_rewarded() -> bool:
	if not is_rewarded_ready():
		rewarded_not_ready.emit()
		return false
	_rewarded_ready = false
	_showing_rewarded = true  # Yana hana danna sau biyu
	_bridge.show_rewarded(REWARDED_ID)
	return true


func _on_rewarded_loaded(placement_id: String) -> void:
	if placement_id == REWARDED_ID:
		_rewarded_ready = true


func _on_rewarded_completed(placement_id: String) -> void:
	if placement_id != REWARDED_ID:
		return
	_showing_rewarded = false
	# Wannan ne kaɗai wurin da ake bayar da lada
	rewarded_earned.emit()
	_bridge.load_rewarded(REWARDED_ID)


func _on_rewarded_skipped(placement_id: String) -> void:
	if placement_id != REWARDED_ID:
		return
	_showing_rewarded = false
	rewarded_skipped.emit()  # Babu lada; a sake load
	_bridge.load_rewarded(REWARDED_ID)


# ---------------- Interstitial ----------------

func show_interstitial() -> bool:
	if not _initialized or not _interstitial_ready:
		return false
	_interstitial_ready = false
	_bridge.show_interstitial(INTERSTITIAL_ID)
	return true


func _on_interstitial_loaded(placement_id: String) -> void:
	if placement_id == INTERSTITIAL_ID:
		_interstitial_ready = true


func _on_interstitial_closed(placement_id: String) -> void:
	if placement_id == INTERSTITIAL_ID:
		_bridge.load_interstitial(INTERSTITIAL_ID)


# ---------------- Banner ----------------

func show_banner() -> void:
	if _initialized:
		_bridge.show_banner(BANNER_ID, true)  # true = ƙasan allo


func hide_banner() -> void:
	if _bridge != null:
		_bridge.hide_banner()


func _on_banner_loaded(_placement_id: String) -> void:
	pass
