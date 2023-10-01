class_name Error extends RefCounted
## A class for user-defined error types
## 
## The aim is to allow for errors to carry with them info about the exception, leading to better error handling[br]
## It also acts as a place to have a centralized list of errors specific to your application, as [enum @GlobalScope.Error] doesn't cover most cases[br]
## 
## Usage:
## [codeblock]
## # Used with a Result:
## var my_result: Result = Result.Err( Error.new(Error.Type.MyCustomError) )
## 
## # Can be made from a Godot error, and with optional additional info
## var myerr = Error.from_gderr(ERR_PRINTER_ON_FIRE, { 'cause' : 'Not enough ink!' })
##     # Or with an additional message too
##     .msg('The printer is on fire!!!')
## 
## # Prints: "Printer on fire { "cause": "Not enough ink!", "msg": "The printer is on fire!!!" }"
## print(myerr)
## 
## # You can even nest them
## Error.from_gderr(ERR_TIMEOUT) .cause( Error.new(Error.Type.Other).msg("Oh no!") )
## [/codeblock]
## [br]
## You can also define custom error types in the [Error] script
## [codeblock]
## # res://addons/optional/Error.gd
## enum Type {
##     # Define custom errors here ...
##     MyCustomError,
## }
## [/codeblock]
## [br]
## Ideally, I'd get rid of the [code]Error.Type[/code] step in accessing custom error types (so, just [code]Error.CustomError[/code] instead of [code]Error.Type.CustomError[/code]) because it's kind of inconvenient but I don't know how I would do that while keeping [code]_to_string()[/code] intact[br]

## Custom error types
## You can define yours here
enum Type {
	Ok=0,
	Other,
	# Define custom errors here ...
}

## The [Error]'s type. This can be from [enum Type] or [enum @GlobalScope.Error]
var type: int = Type.Other
var _is_gderr: bool = false
## Optional additional info about this error
var info: Dictionary = {}

## Create a new [Error] of type [param t], with (optional) additional [param _info][br]
## [param is_gderror] is used to check if this error is a [enum @GlobalScope.Error], but isn't really necessary if you're not going to convert this [Error] into a string
func _init(t: int, _info: Dictionary = {}, is_gderror: bool = false):
	type = t
	_is_gderr = is_gderror
	info = _info

## Shorthand for[br]
## [code]Error.new([param err], [param _info], true)[/code]
static func from_gderr(err: int, _info: Dictionary = {}) -> Error:
	return Error.new(err, _info, true)

## Shorthand for[br]
## [code]Error.new(some_type, { 'msg' : [/code][param msg][code] })[/code][br]
## Returns self
func msg(message: String) -> Error:
	info.msg = message
	return self

## Shorthand for[br]
## [code]Error.new(some_type, { 'cause' : [/code][param cause][code] })[/code][br]
## Returns self
func cause(cause: Variant) -> Error:
	info.cause = cause
	return self

func _to_string() -> String:
	var str: String = error_string(type) if _is_gderr else Type.keys()[type]
	if info.is_empty():
		return str
	return str + ' ' + str(info)

