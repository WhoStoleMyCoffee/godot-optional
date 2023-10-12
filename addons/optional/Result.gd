class_name Result extends RefCounted
## A generic [code]Result<T, E>[/code]
## 
## Results are types that explicitly annotate that an operation (most often a function call) can fail, and forces the user to handle the exception[br]
## In case of a success, the [code]Ok[/code] variant is returned containing the value returned by said operation.[br]
## In case of a failure, the [code]Err[/code] variant is returned containing information about the error.
## Basic usage:[br]
## [codeblock]
## # By returning a Result, it's clear that this function can fail
## func my_function() -> Result:
##     return Result.from_gderr(ERR_PRINTER_ON_FIRE)
##     return Result.Err("my error message")
##     return Result.Ok(data) # Success!
## # ...
## var res: Result = my_function()
## if res.is_err():
##     # stringify_error() is specific to this Godot addon
##     print(res) .stringify_error()
##     return
## var data = res.expect("Already checked if Err or Ok above") # Safest
## var data = res.unwrap() # Crashes if res is Err. Least safe, but quick for prototyping
## var data = res.unwrap_or( 42 )
## var data = res.unwrap_or_else( some_complex_function )
## var data = res.unwrap_unchecked() # It's okay to use it here because we've already checked above
## [/codeblock][br]
## [Result] also comes with a safe way to open files
## [codeblock]
##  var res: Result = Result.open_file("res://file.txt", FileAccess.READ)
##  var json_res: Result = Result.parse_json_file("res://data.json")
## [/codeblock]

var _value: Variant
var _is_ok: bool

## Contains the success value
static func Ok(v) -> Result:
	return Result.new(v, true)

## Contains the error value
static func Err(err) -> Result:
	return Result.new(err, false)

## Constructs a [Result] from the global [enum @GlobalScope.Error] enum[br]
## [constant @GlobalScope.OK] will result in the Ok() variant, everything else will result in Err()
static func from_gderr(err: int) -> Result:
	return Result.new(err, err == OK)

## Constructs an [code]Err([/code] [Error] [code])[/code] with the error code [param err][br]
## Both [enum @GlobalScope.Error] and custom [Error] codes are allowed[br]
## [constant @GlobalScope.OK] will result in the Ok() variant, everything else will result in Err()
static func newError(err: int) -> Result:
	if err == OK:	return Result.new(OK, true)
	return Result.new(Error.new(err), false)

func _to_string() -> String:
	if _is_ok:
		return 'Ok(%s)' % _value
	return 'Err(%s)' % _value

func duplicate() -> Result:
	return Result.new(_value.duplicate(), _is_ok)

func _init(v, is_ok: bool):
	_value = v
	_is_ok = is_ok

## Returns true if the result if Ok
func is_ok() -> bool:
	return _is_ok

## Returns true if the result if Err
func is_err() -> bool:
	return !_is_ok

## Converts from [Result][code]<T, E>[/code] to [Option][code]<T>[/code]
func ok() -> Option:
	return Option.new(_value if _is_ok else null)

## Converts from [Result][code]<T, E>[/code] to [Option][code]<E>[/code]
## Basically [method ok] but with Err
func err() -> Option:
	return Option.new(_value if !_is_ok else null)

## [code]op: func(T) -> U[/code][br]
## Maps a [code]Result<T, E>[/code] to [code]Result<U, E>[/code] by applying a function to a contained Ok value, leaving an Err value untouched[br]
## Example: [br]
## [codeblock]
## var res: Result = Result.Ok(5) .map(func(x):    return x * 2)
## print(res) # Prints "Ok(10)"
## 
## var res: Result = Result.Err("Nope") .map(func(x):    return x * 2)
## print(res) # Prints "Err(Nope)"
## [/codeblock]
func map(op: Callable) -> Result:
	if _is_ok:
		return Result.new( op.call(_value), true )
	return self

## [code]f: func(T) -> void[/code][br]
## Maps a [code]Result<T, E>[/code] to [code]Result<U, E>[/code] by applying a function to the contained value mutably (if [code]Ok[/code])
## Also good if you simply want to execute a block of code if [code]Ok[/code]
func map_mut(f: Callable) -> Result:
	if !_is_ok:	return self
	f.call(_value)
	return self

## [code]default: U[/code][br]
## [code]f: func(T) -> U[/code][br]
## Returns the provided default if Err, or applies a function to the contained value if Ok.
func map_or(default: Variant, f: Callable) -> Variant:
	if !_is_ok:
		return default
	return f.call(_value)

## [code]default: func(E) -> U[/code][br]
## [code]f: func(T) -> U[/code][br]
## Same as [method map_or] but computes the default (if Err) from a function
func map_or_else(default: Callable, f: Callable) -> Variant:
	if _is_ok:
		return f.call(_value)
	return default.call(_value)

## [code]op: func(E) -> F[/code][br]
## Maps a [code]Result<T, E>[/code] to [code]Result<T, F>[/code] by applying a function to a contained Err value, leaving an Ok value untouched[br]
## Example: [br]
## [codeblock]
## var res: Result = Result.Ok(5) .map_err(func(x):    return "error code: " + str(x))
## print(res) # Prints "Ok(5)"
## 
## var res: Result = Result.Err(48) .map_err(func(x):    return "error code: " + str(x))
## print(res) # Prints "Err(error code: 48)"
## [/codeblock]
func map_err(op: Callable) -> Result:
	if _is_ok:
		return self
	return Result.new( op.call(_value), false )

## [code]f: func(E) -> void[/code][br]
## Maps a [code]Result<T, E>[/code] to [code]Result<T, F>[/code] by applying a function to the contained error mutably (if [code]Err[/code])
## Also good if you simply want to execute a block of code if [code]Err[/code]
func map_err_mut(f: Callable) -> Result:
	if _is_ok:	return self
	f.call(_value)
	return self

## Turns a [code]Result<_, @GlobalScope.Error>[/code] into a [code]Result<_, String>[/code][br]
## This is similar to doing the following but safer
## [codeblock]
## result.map_err(func(err: int):	return error_string(err))
## [/codeblock]
## See also [enum @GlobalScope.Error], [method @GlobalScope.error_string]
func stringify_err() -> Result:
	if _is_ok or typeof(_value) != TYPE_INT:	return self
	_value = error_string(_value)
	return self

## Converts this [code]Err([/code][enum @GlobalScope.Error][code])[/code] into [code]Err([/code][Error][code])[/code][br]
## This is similar to doing the following but safer
## [codeblock]
## result.map_err(Error.new)
## [/codeblock]
func toError() -> Result:
	if _is_ok or typeof(_value) != TYPE_INT:	return self
	_value = Error.new(_value)
	return self

## Set the message to show when converting to string or printing if this is an [code]Err[/code]
## This is similar to doing
## [codeblock]
## result.map_err(func(err: Error): return err.msg(message))
## [/codeblock]
## See also [method toError], [method err_cause], [method err_info], [method Error.msg]
func err_msg(message: String) -> Result:
	if _is_ok or !(_value is Error):	return self
	_value.message = message # Error.msg(message) expanded
	return self

## Calls [method Error.cause] if this is an [code]Err([/code][Error][code])[/code][br]
## This is similar to doing
## [codeblock]
## result.map_err(func(err: Error): return err.cause(cause))
## [/codeblock]
## See also [method toError], [method err_msg], [method err_info], [method Error.cause]
func err_cause(cause: Variant) -> Result:
	if _is_ok or !(_value is Error):	return self
	_value.details.cause = cause # Error.cause(cause) expanded
	return self

## Calls [method Error.info] if this is an [code]Err([/code][Error][code])[/code][br]
## This is similar to doing
## [codeblock]
## result.map_err(func(err: Error): return err.info(key, value))
## [/codeblock]
## See also [method toError], [method err_msg], [method err_cause], [method Error.info]
func err_info(key: String, value: Variant) -> Result:
	if _is_ok or !(_value is Error):	return self
	_value.details[key] = value # Error.info(key, value) expanded
	return self

## Returns the contained [code]Ok[/code] value[br]
## Stops the program if the value is an Err with a custom panic message provided by [code]msg[/code][br]
## Example:
## [codeblock]
## var will_not_fail: String = Result.Ok("value")\
##     .expect("Shouldn't fail because (...) ")
## print(will_not_fail) # Prints "value"
## 
## var will_fail = Result.Err("Oh no!")\
##     .expect("This fails!")
## [/codeblock]
func expect(msg: String) -> Variant:
	assert(_is_ok, msg + ': ' + str(_value))
	return _value

## Same as [method expect] except stops the program if the value is an Ok
func expect_err(msg: String) -> Variant:
	assert(!_is_ok, msg + ': ' + str(_value))
	return _value

## Returns the contained Ok value[br]
## Stops the program if the value is an Err[br]
## The use of this method is generally discouraged because it may panic. 
## Instead, prefer to handle the Err case explicitly, or call [method unwrap_or], [method unwrap_or_else]
## Example: [codeblock]
## var will_not_fail: String = Result.Ok("air") .unwrap()
## print(will_not_fail) # Prints "air"
## 
## var will_fail = Result.Err("Oh no!") .unwrap() # Fails
## [/codeblock]
func unwrap() -> Variant:
	if !_is_ok:
		push_warning("Unresolved unwrap(). Please handle results in release builds")
		OS.alert("Called Result::unwrap() on an Err. value:\n %s" % _value, 'Result unwrap error')
		OS.kill(OS.get_process_id())
		return
	return _value

## Same as [method unwrap] but panics in case of an Ok
func unwrap_err() -> Variant:
	if _is_ok:
		push_warning("Unresolved unwrap_err(). Please handle results in release builds")
		OS.alert("Called Result::unwrap_err() on an Ok. value:\n %s" % _value, 'Result unwrap error')
		OS.kill(OS.get_process_id())
		return
	return _value

## Returns the contained Ok value or a provided default
func unwrap_or(default: Variant) -> Variant:
	return _value if _is_ok else default

## [code]op: func(E) -> T[/code][br]
## Same as [method unwrap_or] but computes the default (if Err) from a function with the contained error as an argument
## This is different from [method unwrap_or] in that the value is lazily evaluated, so it's good for methods that may take a long time to compute[br]
## See also [method Option.unwrap_or_else]
func unwrap_or_else(op: Callable) -> Variant:
	if _is_ok:
		return _value
	return op.call(_value)

## Similar to [method unwrap] where the contained value is returned[br]
## The difference is that there are NO checks to see if the value is an Err because you are assumed to have already checked[br]
## If used incorrectly, it will lead to unpredictable behavior
func unwrap_unchecked() -> Variant:
	return _value

## Pushes this error to the built-in debugger and OS terminal (if this result is an Err(_))
func report() -> Result:
	if _is_ok:	return self
	push_error(str(_value))
	return self

## [code]op: func(T) -> Result<U, E>[/code][br]
## Does nothing if the result is Err. If Ok, calls [code]op[/code] with the contained value and returns the result[br]
func and_then(op: Callable) -> Result:
	if !_is_ok:
		return self
	return op.call(_value)

## [code]op: func(E) -> Result<T, F>[/code][br]
## Calls [param op] if the result is Err, otherwise returns the Ok value
## Example: [br]
## [codeblock]
## func sq(x: int) -> Result:    return Result.Ok(x * x)
## func err(x: int) -> Result:    return Result.Err(x)
## 
## print(Ok(2).or_else(sq).or_else(sq), Ok(2))
## print(Ok(2).or_else(err).or_else(sq), Ok(2))
## print(Err(3).or_else(sq).or_else(err), Ok(9))
## print(Err(3).or_else(err).or_else(err), Err(3))
## [/codeblock][br]
## I totally didn't just copy and paste everything from Rust documentation haha
func or_else(op: Callable) -> Result:
	if _is_ok:
		return self
	return op.call(_value)


# ----------------------------------------------------------------
# ** Util **
# ----------------------------------------------------------------

## Open a file safely and return the result[br]
## Returns [code]Result<FileAccess, Error>[/code][br]
## See also [FileAccess], [Error]
static func open_file(path: String, flags: FileAccess.ModeFlags) -> Result:
	var f = FileAccess.open(path, flags)
	if f == null:
		return Result.Err( Error.new(FileAccess.get_open_error()) .info('path', path) )
	return Result.Ok(f)

## Open and parse the given file as JSON[br]
## [codeblock]
## var data = Result.parse_json_file("path_to_file.json") # Ok(data)
## # Err(File not found { "path" : "nonexistent_file.json" })
## var error = Result.parse_json_file("nonexistent_file.json")
## [/codeblock]
## See also [method open_file], [Error]
static func parse_json_file(path: String) -> Result:
	var json: JSON = JSON.new()
	return Result.open_file(path, FileAccess.READ)\
		.and_then(func(f: FileAccess):
			# Yo why json.get_error_message() and get_error_line() always empty?
			# Anyways, it's here just in case
			return Result.from_gderr( json.parse(f.get_as_text()) ) .toError()\
				.err_msg(json.get_error_message())\
				.err_info('line', json.get_error_line())
			)\
		.map(func(__):	return json.data)

