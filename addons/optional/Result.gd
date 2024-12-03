class_name Result extends RefCounted
## A generic [code]Result<T, E>[/code]
## 
## Results are types that explicitly annotate that an operation (most often a function call) can fail, and forces the user to handle the exception[br]
## In case of a success, the [code]Ok[/code] variant is returned containing the value returned by said operation.[br]
## In case of a failure, the [code]Err[/code] variant is returned containing information about the error.
## Basic usage:
## [codeblock]
## # By returning a Result, it's clear that this function can fail
## func my_function() -> Result:
##     return Result.from_gderr(ERR_PRINTER_ON_FIRE)
##     return Result.Err("my error message")
##     return Result.Ok(data) # Success!
## 
## var res: Result = my_function()
## if res.is_err():
##     # my_function() failed! Print the error
##     print(res.gderror_to_string())
##     return
## var data = res.expect("Already checked if Err or Ok above") # Safest
## var data = res.unwrap() # Crashes if res is Err. Least safe, but quick for prototyping
## var data = res.unwrap_or( 42 ) # Return the data if Ok. If not, return 42
## var data = res.unwrap_or_else( some_complex_function ) # ... or calculate from a function
## var data = res.unwrap_unchecked() # It's okay to use it here because we've already checked above
## [/codeblock][br]
## [Result] also comes with a safe way to open files
## [codeblock]
##  var res: Result = Result.open_file("res://file.txt", FileAccess.READ)
##  var json_res: Result = Result.parse_json_file("res://data.json")
## [/codeblock]
## See examples scene for more

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

## Formats this [Result] into a [String] for printing
func _to_string() -> String:
	if _is_ok:
		return 'Ok(%s)' % _value
	return 'Err(%s)' % _value

func duplicate() -> Result:
	return Result.new(_value.duplicate(), _is_ok)

func _init(v, is_ok: bool):
	_value = v
	_is_ok = is_ok

## Returns true if the [Result] is Ok
func is_ok() -> bool:
	return _is_ok

## Returns true if this [Result] is Ok, and the contained value matches the predicate
## [codeblock]
## var x = Result.Ok(2)
## assert( x.is_ok_and(func(x):  return x > 1) == true)
## 
## var x = Result.Ok(0)
## assert( x.is_ok_and(func(x):  return x > 1) == false)
## 
## var x = Result.Err("something happened!")
## assert( x.is_ok_and(func(x):  return x > 1) == false)
## [/codeblock]
## To check whether the contained value matches another, see [method matches]
func is_ok_and(f: Callable) -> bool:
	return _is_ok and f.call(_value)

## Returns true if the result if Err
func is_err() -> bool:
	return !_is_ok

## Returns true if this [Result] is Err, and the contained value matches the predicate
## [codeblock]
## var x = Result.Err(ERR_BUSY)
## assert( x.is_err_and(func(x):  return x == ERR_BUSY) == true)
## 
## var x = Result.Err(ERR_LOCKED)
## assert( x.is_err_and(func(x):  return x == ERR_BUSY) == false)
## 
## var x = Result.Ok(123)
## assert( x.is_err_and(func(x):  return x == ERR_BUSY) == false)
## [/codeblock]
## To check whether the contained value matches another, see [method matches]
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
## Calls the function [param f] if [code]Ok[/code], does nothing if [code]Err[/code]
## [br]Returns self
## [codeblock]
## var res = Result.Ok("hello")\
##     .if_ok(func(str):	print(str))
## 
## # Same as doing this
## if res.is_ok():
##     print( res.unwrap_unchecked() )
## [/codeblock]
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
## Calls the function [param f] if [code]Err[/code], does nothing if [code]Ok[/code]
## [br]Returns self
## [codeblock]
## var res = Result.Err(ERR_SKIP)\
##     .if_err(func(err):	print(err))
## 
## # Same as doing this
## if res.is_err():
##     print( res.unwrap_unchecked() )
## [/codeblock]
func if_err(f: Callable) -> Result:
	if _is_ok:	return self
	f.call(_value)
	return self

# TODO option to stfu
## Attempts to covert this [code]Result.Err([/code][enum @GlobalScope.Error][code])[/code] to a [code]Result.Err(String)[/code] by using [method @GlobalScope.error_string]
## [br]Does nothing if this [Result] is an [code]Ok[/code], and pushes a warning if the operation failed
## [br]Returns self
## [codeblock]
## Result.Err(ERR_BUSY)       # Err(44)
##     .gderror_to_string()   # Err("Busy")
## [/codeblock]
func gderror_to_string() -> Result:
	if _is_ok:
		return self
	if _value is Report:
		_value.gderror_to_string()
		return self
	if !(_value is int) or _value < OK or _value > ERR_PRINTER_ON_FIRE:
		push_warning("Attempt to call Result::gderror_to_string() on a non-GlobalScope.Error value: ", err)
		return self
	_value = error_string(_value)
	return self

## Returns the contained [code]Ok[/code] value[br]
## Stops the program if the value is an Err with a custom panic message provided by [code]msg[/code][br]
## Example:
## [codeblock]
## var will_not_fail: String = Result.Ok("value")\
##     .expect("Shouldn't fail")
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
## var will_fail = Result.Err("Oh no!") .unwrap() # Crashes
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

## Returns the contained Ok value or a provided default[br]
## See also [method Option.unwrap_or_else]
func unwrap_or(default: Variant) -> Variant:
	return _value if _is_ok else default

## [code]op: func(E) -> T[/code][br]
## Same as [method unwrap_or] but computes the default (if Err) from a function with the contained error as an argument
## This is different from [method unwrap_or] in that the value is lazily evaluated, so it's good for methods that may take a long time to compute[br]
## See also [method Option.unwrap_or]
func unwrap_or_else(op: Callable) -> Variant:
	if _is_ok:
		return _value
	return op.call(_value)

## Similar to [method unwrap] where the contained value is returned[br]
## The difference is that there are NO checks to see if the value is an Err because you are assumed to have already done so yourself[br]
## If used incorrectly, it will lead to unpredictable behavior
func unwrap_unchecked() -> Variant:
	return _value

## Report this [Result] if [code]Err[/code][br]
## Converts the inner value to a [Report] if necessary
## Does nothing if [code]Ok[/code][br]
## The default log level is [enum Report.LogLevel.ERROR][br]
## See also [method Report.report], [enum Report.LogLevel]
## [codeblock]
## var r = Result.Err("test error").report(Report.LogLevel.INFO)
##
## Prints:
## [INFO] Report: test error
## [/codeblock]
func report(log_level: Report.LogLevel = Report.LogLevel.ERROR) -> Result:
	if _is_ok:	return self
	if _value is Report:
		_value.report(log_level)
	else:
		_value = Report.new(_value) .report(log_level)
	return self

## [param f]: [code]func(Report) -> Report[/code][br]
## Converts this [code]Err(value)[/code] to an [code]Err(Report)[/code], and optionally calls [param f] as a constructor[br]
## If this [Result] is already an [code]Err(Report)[/code], [param f] simply gets called[br]
## You can do whatever you want with the constructed [Report] inside [param f]. 
## In fact, returning a [Report] isn't even necessary if you won't use it further[br]
## Does nothing if [code]Ok[/code][br]
## [codeblock]
## var res = Result.Ok(123) .as_report()
## print(res) # Prints: Ok(123)
##
## var res = Result.Err("test error") .as_report()
## print(res) # Prints: Err(Report: test error)
##
## var res = Result.Err("test error") .as_report(func(r: Report):
##     return r.msg("Something happened!")
##     )
## print(res) # Prints: Err(Something happened!: test error)
##
## var res = Result.Err(Report.new("test error")) .as_report(func(r: Report):
##     return r.msg("Something happened!")
##     )
## print(res) # Prints: Err(Something happened!: test error)
##
## # Here, it's okay if `f` returns `void` because we won't use this Result further
## Result.Err("test error") .as_report(func(r: Report):
##     r.msg("Something happened!") .report()
##     )
## [/codeblock]
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

# TODO if_matches() ?
## Checks whether the contained value matches [param rhs]
## [br]i.e. checks that [code]self == Ok(rhs)[/code]
## [br]If this [Result] is an [code]Err[/code], this method will return [code]false[/code]
func matches(rhs: Variant) -> bool:
	return _is_ok and _value == rhs

## Checks whether the contained error matches [param rhs]
## [br]i.e. checks that [code]self == Err(rhs)[/code]
## [br]If this [Result] is an [code]Ok[/code], this method will return [code]false[/code]
## [br]If this is an [code]Err(Report)[/code], it checks whether the container [Report]'s value matches
func matches_err(rhs: Variant) -> bool:
	if _is_ok:
		return false
	if _value is Report:
		return typeof(_value.err) == typeof(rhs) and _value.err == rhs
	return typeof(_value) == typeof(rhs) and _value == rhs


#region Util

## Open a file safely and return the result[br]
## Returns [code]Result<FileAccess, Report<GlobalScope.Error>>[/code][br]
## See also [FileAccess], [Report]
static func open_file(path: String, flags: FileAccess.ModeFlags) -> Result:
	var f = FileAccess.open(path, flags)
	if f == null:
		return Result.Err( Report.new(FileAccess.get_open_error())
			.info('path', path)
			)
	return Result.Ok(f)

## Open and parse the given file as JSON[br]
## Returns [code]Result<Variant, Report<GlobalScope.Error>>[/code][br]
## [codeblock]
## var data = Result.parse_json_file("path_to_file.json") # Ok(data)
## # Err(File not found { "path" : "nonexistent_file.json" })
## var error = Result.parse_json_file("nonexistent_file.json")
## [/codeblock]
## See also [method open_file], [Report]
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
