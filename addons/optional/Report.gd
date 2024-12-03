class_name Report extends Node
## An error report that can carry additional info about the exception
##
## @experimental
## These are often used alongside [Result]s, and can also crash the application with [method Report.crash][br]
## Example:
## [codeblock]
## var res = Result.Err(ERR_TIMEOUT).as_report(r: Report):
##     r.gderror_to_string()
##         .msg("Failed to do operation")
##         .info("some_key", "some_value")
##         .cause(ERR_BUSY)
##         .report()
##     )
## [/codeblock]
## You can convert any [code]Err(value)[/code] into an [code]Err(Report(value))[/code] with [method Result.as_report], and back with [method as_result][br]
## Reports are also formattable to strings:
## [codeblock]
## var r = Report.new(&"test error")
## print(r)
## push_warning(r)
## push_error(r)
## Report.crash( str(r) )
## [/codeblock]

## What level to log a report at[br]
## See [method report]
enum LogLevel {
	## Simply print to the console
	INFO,
	## Push a warning
	WARNING,
	## Push an error
	ERROR,
	## Push and error, and crash the application
	CRASH,
}

## The contained error
var err: Variant
## Additional details about the exception[br]
## See [method info]
var details: Dictionary = {}
## Message to print with[br]
## See [method msg]
var message: String = ""
## The cause of this error, if any[br]
## See [method cause]
var caused_by: Variant = null


## Crashes the program
static func crash(message: String, title_override: String = ""):
	OS.alert(
		message,
		"%s | Crash report" % ProjectSettings.get("application/config/name") if title_override.is_empty() else title_override
	)
	OS.kill(OS.get_process_id())


## The constructor for this [Report][br]
## Filling [param _details] is the same as calling [method info]
## [codeblock]
## Report.new(&"test error", {
##     "name": "John",
##     "age": 41,
## })
##
## # Same as doing this
## Report.new(&"test error")
##     .info("name", "John")
##     .info("age", 41)
## [/codeblock]
func _init(_err, _details: Dictionary = {}):
	err = _err
	details = _details

# TODO make it so it adds instead of setting?
# func add_msg() and func set_msg()?
## Sets the message of this [Report]
## [codeblock]
## Report.new(&"test error")
##     .msg("Failed to do operation")
##     .info("operation", "greet")
##     .cause(error_string(ERR_ALREADY_IN_USE))
##     .report(Report.LogLevel.INFO)
## [/codeblock]
## Prints:
## [codeblock]
## [INFO] Failed to do operation: test error { "operation": "greet" }
##     Caused by: Already in use
## [/codeblock]
func msg(_message: String) -> Report:
	message = _message
	return self

## Sets the cause for this [Report]
## [codeblock]
## Report.new(&"test error")
##     .msg("Failed to do operation")
##     .info("operation", "greet")
##     .cause(error_string(ERR_ALREADY_IN_USE))
##     .report(Report.LogLevel.INFO)
## [/codeblock]
## Prints:
## [codeblock]
## [INFO] Failed to do operation: test error { "operation": "greet" }
##     Caused by: Already in use
## [/codeblock]
func cause(cause: Variant) -> Report:
	caused_by = cause
	return self

## Adds a detail for easier debugging
## [codeblock]
## Report.new(&"test error")
##     .msg("Failed to do operation")
##     .info("operation", "greet")
##     .cause(error_string(ERR_ALREADY_IN_USE))
##     .report(Report.LogLevel.INFO)
## [/codeblock]
## Prints:
## [codeblock]
## [INFO] Failed to do operation: test error { "operation": "greet" }
##     Caused by: Already in use
## [/codeblock]
func info(key: Variant, value: Variant) -> Report:
	details[key] = value
	return self

## Reports this [Report][br]
## [codeblock]
## Report.new("error!") .report(LogLevel.INFO)
## Report.new("error!") .report(LogLevel.WARNING)
## Report.new("error!") .report(LogLevel.ERROR)
## Report.new("error!") .report(LogLevel.CRASH)
## [/codeblock]
## The default log level is [enum LogLevel.ERROR][br]
## See also [enum LogLevel]
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
## Attempts to covert this [code]Report([/code][enum @GlobalScope.Error][code])[/code] to a [code]Report(String)[/code] by using [method @GlobalScope.error_string]
## [br]Pushes a warning if the operation failed
## [br]Returns self
## [codeblock]
## Report.new(ERR_BUSY)       # Report(44)
##     .gderror_to_string()   # Report("Busy")
## [/codeblock]
func gderror_to_string() -> Report:
	if !(err is int) or err < OK or err > ERR_PRINTER_ON_FIRE:
		push_warning("Attempt to call Report::gderror_to_string() on a non-GlobalScope.Error value: ", err)
		return self
	err = error_string(err)
	return self

# Aa my eyes
## Formats this [Report] to a [String] for printing
func _to_string() -> String:
	var detailsstr: String = "" if details.is_empty() else " " + str(details)
	var msgstr: String = "Report: " if message.is_empty() else message + ": "
	var causestr: String = "" if caused_by == null else "\n    Caused by: " + str(caused_by)
	return msgstr + str(err) + detailsstr + causestr


## Converts this [code]Report(value)[/code] to a [code]Result.Err(Report(value))[/code]
func as_result() -> Result:
	return Result.new(self, false)

#func as_err() -> Result:
	#return Result.new(self, false)

