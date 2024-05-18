class_name Report extends Node

enum LogLevel {
	INFO,
	WARNING,
	ERROR,
	CRASH,
}

var err: Variant
var details: Dictionary = {}
var message: String = ""
var caused_by: Variant = null
# var desc: String = ""


static func crash(message: String, title_override: String = ""):
	OS.alert(
		message,
		"%s | Crash report" % ProjectSettings.get("application/config/name") if title_override.is_empty() else title_override
	)
	OS.kill(OS.get_process_id())


func _init(_err, _details: Dictionary = {}):
	err = _err
	details = _details

func msg(_message: String) -> Report:
	message = _message
	return self

# func add_msg():

func cause(cause: Variant) -> Report:
	caused_by = cause
	return self

func info(key: Variant, value: Variant) -> Report:
	details[key] = value
	return self

func report(log_level: LogLevel = LogLevel.ERROR) -> Report:
	match log_level:
		LogLevel.INFO:
			print("[INFO] ", str(self))
		
		LogLevel.WARNING:
			push_warning(str(self))
		
		LogLevel.ERROR:
			push_error(str(self))
		
		LogLevel.CRASH:
			push_error(str(self))
			Report.crash("ERROR:\n " + str(self))
		
		_:
			push_warning("Invalid log level: ", log_level, ". Expected value between LogLevel.INFO and LogLevel.CRASH")
			push_error(str(self))
	return self


# TODO option to stfu
func gderror_to_string() -> Report:
	if !(err is int) or err <= OK or err > ERR_PRINTER_ON_FIRE:
		push_warning("Attempt to call Report::gderror_to_string() on a non-GlobalScope.Error value: ", err)
		return self
	err = error_string(err)
	return self

# Aa my eyes
func _to_string() -> String:
	var detailsstr: String = "" if details.is_empty() else " " + str(details)
	var msgstr: String = "Report: " if message.is_empty() else message + ": "
	var causestr: String = "" if caused_by == null else "\n    Caused by: " + str(caused_by)
	return msgstr + str(err) + detailsstr + causestr


func as_result() -> Result:
	return Result.new(self, false)

#func as_err() -> Result:
	#return Result.new(self, false)

