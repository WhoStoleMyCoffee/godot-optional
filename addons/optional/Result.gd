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

## TODO documentation
func is_ok_and(f: Callable) -> bool:
	return _is_ok and f.call(_value)

## Returns true if the result if Err
func is_err() -> bool:
	return !_is_ok

## TODO documentation
func is_err_and(f: Callable) -> bool:
	return !_is_ok and f.call(_value)

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
## [br]Also good if you simply want to execute a block of code if [code]Ok[/code]
func if_ok(f: Callable) -> Result:
	if !_is_ok:	return self
	f.call(_value)
	return self

## [code]default: U[/code][br]
## [code]f: func(T) -> U[/code][br]
## Returns the provided default if Err, or applies a function to the contained value if Ok.
func map_or(default: Variant, f: Callable) -> Variant:
	return f.call(_value) if is_ok else default

## [code]default: func(E) -> U[/code][br]
## [code]f: func(T) -> U[/code][br]
## Same as [method map_or] but computes the default (if Err) from a function
func map_or_else(default: Callable, f: Callable) -> Variant:
	return f.call(_value) if _is_ok else default.call(_value)

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
## [br]Also good if you simply want to execute a block of code if [code]Err[/code]
func if_err(f: Callable) -> Result:
	if _is_ok:	return self
	f.call(_value)
	return self

# TODO option to stfu
func gderror_to_string() -> Result:
	if _is_ok or !(_value is int):
		return self
	_value = error_string(_value)
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
## Internally, this method uses [code]assert()[/code], so it will be optimized away in release builds
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
	if _is_ok:
		return _value
	
	push_warning("Unresolved unwrap(). It is good practice to properly handle results in release builds")
	if _value is Report:
		_value.report(Report.LogLevel.CRASH)
	else:
		Report.crash("Called Result::unwrap() on an Err.\n value: %s" % str(_value))
	return

## Same as [method unwrap] but panics in case of an Ok
func unwrap_err() -> Variant:
	if !_is_ok:
		return _value
	
	push_warning("Unresolved unwrap_err(). It is good practice to properly handle results in release builds")
	Report.crash("Called Result::unwrap_err() on an Ok.\n value: %s" % _value)
	return

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

func report(log_level: Report.LogLevel = Report.LogLevel.ERROR) -> Result:
	if _is_ok:	return self
	if _value is Report:
		_value.report(log_level)
	else:
		_value = Report.new(_value) .report(log_level)
	return self

# TODO refactor ig
func as_report(f: Callable = Callable()) -> Result:
	if _is_ok:	return self
	if _value is Report:
		if !f.is_null():
			_value = f.call(_value)
		return self
	
	if f.is_null():
		_value = Report.new(_value)
	else:
		_value = f.call(Report.new(_value))
	return self


## [code]op: func(T) -> Result<U, E>[/code][br]
## Does nothing if the result is Err. If Ok, calls [code]op[/code] with the contained value and returns the result[br]
func and_then(op: Callable) -> Result:
	if !_is_ok:
		return self
	var r: Result = op.call(_value)
	assert(r is Result, "The function `op` must return a Result but got %s" % r)
	return r

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
	var r: Result = op.call(_value)
	assert(r is Result, "The function `op` must return a Result but got %s" % r)
	return r

## Checks whether the contained value matches [param rhs]
## [br]i.e. checks that [code]self == Ok(rhs)[/code]
## [br]If this [Result] is an [code]Err[/code], this method will return [code]false[/code]
func matches(rhs: Variant) -> bool:
	return _value == rhs and _is_ok

## Checks whether the contained error matches [param rhs]
## [br]i.e. checks that [code]self == Err(rhs)[/code]
## [br]If this [Result] is an [code]Ok[/code], this method will return [code]false[/code]
func matches_err(rhs: Variant) -> bool:
	return !_is_ok and (_value == _value.err if _value is Report else _value == rhs)


#region Util

## Open a file safely and return the result[br]
## Returns [code]Result<FileAccess, Error>[/code][br]
## See also [FileAccess], [Error]
static func open_file(path: String, flags: FileAccess.ModeFlags) -> Result:
	var f = FileAccess.open(path, flags)
	if f == null:
		return Result.Err( Report.new(FileAccess.get_open_error())
			.info('path', path)
			)
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
			return Result.from_gderr( json.parse(f.get_as_text()) )\
				.as_report(func(r: Report):
					return r.msg( json.get_error_message() )\
						.info("line", json.get_error_line())
					)
			)\
		.map(func(__):	return json.data)

#endregion
