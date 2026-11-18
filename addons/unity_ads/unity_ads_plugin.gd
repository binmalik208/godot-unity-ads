@tool
extends EditorPlugin

const AUTOLOAD_NAME := "UnityAds"
const AUTOLOAD_PATH := "res://addons/unity_ads/unity_ads.gd"

# Dole ya yi daidai da unityAdsVersion a android/gradle.properties
const UNITY_ADS_VERSION := "4.22.0"

var _export_plugin: AndroidExportPlugin


func _enter_tree() -> void:
	_export_plugin = AndroidExportPlugin.new()
	_export_plugin.unity_ads_version = UNITY_ADS_VERSION
	add_export_plugin(_export_plugin)

	if not ProjectSettings.has_setting("autoload/" + AUTOLOAD_NAME):
		add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)


func _exit_tree() -> void:
	remove_export_plugin(_export_plugin)
	_export_plugin = null

	if ProjectSettings.has_setting("autoload/" + AUTOLOAD_NAME):
		remove_autoload_singleton(AUTOLOAD_NAME)


class AndroidExportPlugin extends EditorExportPlugin:
	var unity_ads_version := ""

	func _supports_platform(platform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _get_android_libraries(platform, debug) -> PackedStringArray:
		if debug:
			return PackedStringArray(["res://addons/unity_ads/bin/godot-unity-ads-debug.aar"])
		return PackedStringArray(["res://addons/unity_ads/bin/godot-unity-ads-release.aar"])

	func _get_android_dependencies(platform, debug) -> PackedStringArray:
		return PackedStringArray(["com.unity3d.ads:unity-ads:" + unity_ads_version])

	func _get_name() -> String:
		return "GodotUnityAds"
