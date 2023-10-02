class_name Error extends RefCounted
## A class for user-defined error types
## 
## The aim is to allow for errors to carry with them details about the exception, leading to better error handling[br]
## It also acts as a place to have a centralized list of errors specific to your application, as [enum @GlobalScope.Error] doesn't cover most cases[br]
## 
## Usage:
## [codeblock]
## # Can be made from a Godot error, and with optional additional details
## var myerr = Error.new(ERR_PRINTER_ON_FIRE) .cause('Not enough ink!')
##     # Or with an additional message too
##     .msg("The printer gods demand input..")
## 
## # Prints: "Printer on fire { "cause": "Not enough ink!", "msg": "The printer gods demand input.." }"
## print(myerr)
## 
## # You can even nest them!
## Error.from_gderr(ERR_TIMEOUT) .cause( Error.new(Error.Other).msg("Oh no!") )
## 
## # Used alongside a Result:
## Result.Err( Error.new(Error.MyCustomError) )
## Result.open_file( ... ) .err_msg("Failed to open the specified file.")
## [/codeblock]
## [br]
## You can also define custom error types in the [Error] script
## [codeblock]
## # res://addons/optional/Error.gd
## enum {
##     Other,
##     # Define custom errors here ...
##     MyCustomError,
## }
## [/codeblock]

# Custom error types
# You can define yours here
# This enum is unnamed for convenience
enum {
	Other = ERR_PRINTER_ON_FIRE+1, ## Other error type. Below ERR_PRINTER_ON_FIRE is reserved for [enum @GlobalScope.Error]
	# Define custom errors here ...
}

## The [Error]'s type. This can be a custom error type defined in the [Error] script or a [enum @GlobalScope.Error]
var type: int = Other
## Optional additional details about this error
var details: Dictionary = {}

## Create a new [Error] of type [param t], with (optional) additional [param _details][br]
func _init(t: int, _details: Dictionary = {}):
	type = t
	details = _details

## Shorthand for[br]
## [code]Error.new(some_type, { 'msg' : [/code][param msg][code] })[/code][br]
## Returns self
func msg(message: String) -> Error:
	details.msg = message
	return self

## Shorthand for[br]
## [code]Error.new(some_type, { 'cause' : [/code][param cause][code] })[/code][br]
## Returns self
func cause(cause: Variant) -> Error:
	details.cause = cause
	return self

## Adds additional info to this error. Shorthand for[br]
## [code]Error.new(some_type, { [/code][param key][code] : [/code][param value][code] })[/code][br]
## Returns self
func info(key: String, value: Variant) -> Error:
	details[key] = value
	return self

## Returns whether this error is an [enum @GlobalScope.Error]
func is_gderror() -> bool:
	return type <= ERR_PRINTER_ON_FIRE

# Aa my eyes
func _to_string() -> String:
	# Details dictionary
	var infostr: String = '' if details.is_empty() else ' ' + str(details)
	# Godot error
	if type <= ERR_PRINTER_ON_FIRE:
		return error_string(type) + infostr
	# Custom error
	var s = get_script().get_script_constant_map() .find_key(type)
	return (s if s != null else '(Invalid error type: %s)' % type) + infostr

