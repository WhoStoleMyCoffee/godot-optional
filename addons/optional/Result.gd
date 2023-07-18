class_name Result extends RefCounted
## A generic [code]Result<T, E>[/code]
## 
## Results are types that explicitly annotate that an operation (most often a function call) can fail, and forces the user to handle the exception[br]
## In case of a success, the [code]Ok[/code] variant is returned containing the value returned by said operation.[br]
## In case of a failure, the [code]Err[/code] variant is returned containing information about the error.
## Basic usage:[br]
## [codeblock]
## # By returning a Result, it's clear that this function can fail
## func load_data_from_file(path: String) -> Result:
##     return Result.Err(ERR_FILE_NOT_FOUND)
##     return Result.Err("my error message")
##     return Result.Ok(data) # Success!
## # ...
## var res: Result = load_data_from_file( ... )
## if res.is_err():
##     print(res)
##     return
## var data = res.expect("Already checked if Err or Ok above") # Safest
## var data = res.unwrap_or( some_default_value )
## var data = res.get_value() # Generally, it's okay to use get_value() because we've already checked above
## var data = res.unwrap() # Crashes if res is Err. Least safe, but quick for prototyping
## [/codeblock]

var _value: Variant
var _is_ok: bool

## Contains the success value
static func Ok(v) -> Result:
	return Result.new(v, true)

## Contains the error value
static func Err(err) -> Result:
	return Result.new(err, false)

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
		OS.alert("Called Result::unwrap() on an Err. value: %s" % _value, 'Result unwrap error')
		OS.crash('')
		return
	return _value

## Same as [method unwrap] but panics in case of an Ok
func unwrap_err() -> Variant:
	if _is_ok:
		push_warning("Unresolved unwrap_err(). Please handle results in release builds")
		OS.alert("Called Result::unwrap_err() on an Ok. value: %s" % _value, 'Result unwrap error')
		OS.crash('')
		return
	return _value

## Returns the contained Ok value or a provided default
func unwrap_or(default: Variant) -> Variant:
	return _value if _is_ok else default

## [code]op: func(E) -> T[/code][br]
## Same as [method unwrap_or] but computes the default (if Err) from a function with the contained error as an argument
func unwrap_or_else(op: Callable) -> Variant:
	if _is_ok:
		return _value
	return op.call(_value)

## Similar to [method unwrap] where the contained value is returned[br]
## The difference is that there are NO checks to see if the value is an Err because you are assumed to have already checked[br]
## If used incorrectly, it will lead to unpredictable behavior
func get_value() -> Variant:
	return _value

## [code]op: func(T) -> Result<U, E>[/code][br]
## Returns the Err if the result is Err. If Ok, calls [code]op[/code] with the contained value and returns the result[br]
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


