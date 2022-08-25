# Utility class that adds Javascript utilities for HTML5 builds
class_name JavascriptUtils
extends Reference

static func get_browser_url_domain() -> String:
	if not OS.has_feature("HTML5"):
		printerr("Not running on browser")
		return ""
	
	var browser_url : String = JavaScript.eval("window.location.href")
	browser_url = browser_url.replace("http://", "")
	browser_url = browser_url.replace("https://", "")
	var last_character_index := browser_url.find("/")
	browser_url = browser_url.left(last_character_index)
	return browser_url
