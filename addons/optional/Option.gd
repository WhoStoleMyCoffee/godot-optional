class_name Option extends RefCounted
## A generic [code]Option<T>[/code]
## 
## Options are types that explicitly annotate that a value can be [code]null[/code], and forces the user to handle the exception[br]
## Basic usage: [br]
## [codeblock]
## # By returning an Option, it's clear that this function can return null, which must be handled
## func get_player_stats(id: String) -> Option:
##     return Option.None() # Represents a null
##     return Option.Some( data ) # Sucess!
## # ...
## var res: Option = get_player_stats("player_3")
## if res.is_none():
##     print("Player doesn't exist!")
##     return
## var data = res.expect("Already checked if None or Some above") # Safest
## var data = res.unwrap_or( some_default_value )
## var data = res.get_value() # Generally, it's okay to use get_value() because we've already checked above
## var data = res.unwrap() # Crashes if res is None. Least safe, but quick for prototyping
## [/codeblock][br]
## [Option] also comes with a safe way to index arrays[br]
## [codeblock]
## var my_arr = [2, 4, 6]
## print( Option.arr_get(1))  # Prints "4"
## print( Option.arr_get(4))  # Prints "None" because index 4 is out of bounds
## [/codeblock]

var _value: Variant = null

static func Some(v) -> Option:
	assert(v != null, "Cannot assign null to an Some")
	return Option.new(v)

static func None() -> Option:
	return Option.new(null)

func _to_string() -> String:
	if _value == null:
		return 'None'
	return 'Some(%s)' % _value

## Creates a duplicate with the inner value duplicated as well
func duplicate() -> Option:
	if _value == null:
		return Option.new(null)
	return Option.new( _value.duplicate() )

func _init(v):
	_value = v

## Returns [code]true[/code] if the option is a [code]Some[/code] value
func is_some() -> bool:
	return _value != null

## Returns [code]true[/code] if the option is a [code]None[/code] value
func is_none() -> bool:
	return _value == null

## Returns the contained [code]Some[/code] value[br]
## Stops the program if the value is a [code]None[/code] with a custom panic message provided by [code]msg[/code][br]
## Example:
## [codeblock]
## var will_not_fail: String = Option.Some("value")\
##     .expect("Shouldn't fail because (...) ")
## print(will_not_fail) # Prints "value"
## 
## var will_fail = Option.None()\
##     .expect("This fails!")
## [/codeblock]
func expect(msg: String) -> Variant:
	assert(_value != null, msg)
	return _value

## Returns the contained [code]Some[/code] value[br]
## Stops the program if the value is a [code]None[/code][br]
## The use of this method is generally discouraged because it may panic. 
## Instead, prefer to handle the [code]None[/code] case explicitly, or call [method unwrap_or], [method unwrap_or_else]
## Example: [codeblock]
## var will_not_fail: String = Option.Some("air") .unwrap()
## print(will_not_fail) # Prints "air"
## 
## var will_fail = Option.None() .unwrap() # Fails
## [/codeblock]
func unwrap() -> Variant:
	if _value == null:
		push_warning("Unresolved unwrap(). Please handle options in release builds")
		OS.alert("Called Option::unwrap() on a None value", 'Option unwrap error')
		OS.crash('')
		return
	return _value

## Returns the contained [code]Some[/code] value or a provided default[br]
## Example: [codeblock]
## print( Option.Some("car") .unwrap_or("bike") ) # Prints "car"
## print( Option.None() .unwrap_or("bike") ) # Prints "bike"
## [/codeblock]
func unwrap_or(default) -> Variant:
	if _value == null:
		assert(default != null)
		return default
	return _value

## [code]f: func() -> T[/code][br]
## Returns the contained [code]Some[/code] value or computes it from a closure
## Example: [codeblock]
## var k: int = 10
## print( Option.Some(4) .unwrap_or_else(func():    return 2 * k) ) # Prints 4
## print( Option.None() .unwrap_or_else(func():    return 2 * k) ) # Prints 20
## [/codeblock]
func unwrap_or_else(f: Callable) -> Variant:
	if _value == null:
		return f.call()
	return _value

## Similar to [method unwrap] where the contained value is returned[br]
## The difference is that there are NO checks to see if the value is null because you are assumed to have already checked if it's a None with [method is_none] or [method is_some][br]
## This does mean that this fnction can return a null
func get_value() -> Variant:
	return _value

## [code]f: func(T) -> U[/code][br]
## Maps an [code]Option<T>[/code] to [code]Option<U>[/code] by applying a function to the contained value (if [code]Some[/code]) or returns [code]None[/code] (if [code]None[/code])
func map(f: Callable) -> Option:
	if _value == null:
		return self
	return Option.new( f.call(_value) )

## [code]default: U[/code][br]
## [code]f: func(T) -> U[/code][br]
## Returns the provided default result (if none), or applies a function to the contained value (if any)
## Example: [codeblock]
## var x = Option.Some("foo")
## print( x.map_or(42, func(v):    return v.length()) ) # Prints 3
## 
## var x = Option.None()
## print( x.map_or(42, func(v):    return v.length()) ) # Prints 42
## [/codeblock]
func map_or(default, f: Callable) -> Variant:
	if _value == null:
		assert(default != null)
		return default
	return f.call(_value)

## [code]default: func() -> U[/code][br]
## [code]f: func(T) -> U[/code][br]
## Computes a default function result (if none), or applies a different function to the contained value (if any)[br]
## Same as [method map_or] but computes the default from a function
func map_or_else(default: Callable, f: Callable) -> Variant:
	if _value == null:
		return default.call()
	return f.call(_value)

## [code]f: func(T) -> Option<U>[/code][br]
## Returns None if the option is None, otherwise calls [code]f[/code] with the contained value and returns the result[br]
## Example:
## [codeblock]
## func square_if_small_enough(x: int) -> Option:
##     if x > 42:
##         return Option.None()
##     return Option.Some(x * x)
## 
## print( Option.Some(4) .and_then(square_if_small_enough) ) # Prints Some(16)
## print( Option.Some(1000) .and_then(square_if_small_enough) ) # Prints None
## print( Option.None() .and_then(square_if_small_enough) ) # Prints None
## [/codeblock]
func and_then(f: Callable) -> Option:
	if _value == null:
		return self
	return f.call(_value)

## Takes the value out of this option, leaving a None in its place
## Example:
## [codeblock]
## var x = Option.Some(2)
## var y = x.take()
## print("x=", x, " y=", y) # Prints "x=None y=Some(2)"
## [/codeblock]
func take() -> Option:
	var o: Option = Option.new(_value)
	_value = null
	return o

## Replaces teh actual value in the option by the given [param value]
## Example:
## [codeblock]
## var x = Option.Some(2)
## var old = x.replace(5)
## print("x=", x, " y=", y) # Prints "x=Some(5) y=Some(2)"
## [/codeblock]
func replace(value) -> Option:
	assert(value != null)
	var old: Option = Option.new(_value)
	_value = value
	return old

## Converts [code]Option<Option<T>>[/code] to [code]Option<T>[/code][br]
func flatten() -> Option:
	if _value == null or !(_value is Option):
		return self
	return _value

## Transforms the [Option] into a [class Result]
func ok_or(err: Variant) -> Result:
	if _value == null:
		return Result.Err(err)
	return Result.Ok(_value)

## Same as [method ok_or] but computes the error value from the lambda [param err]
func ok_or_else(err: Callable) -> Result:
	if _value == null:
		return Result.Err(err.call())
	return Result.Ok(_value)


# ----------------------------------------------------------------
# ** Util **
# ----------------------------------------------------------------

## Safe version of [code]arr[idx][/code]
static func arr_get(arr: Array, idx: int) -> Option:
	if idx >= arr.size():
		return Option.new(null)
	return Option.new(arr[idx])

## Safe version of [code]dict[key][/code]
static func dict_get(dict: Dictionary, key: Variant) -> Option:
	if !dict.has(key):
		return Option.new(null)
	return Option.new(dict[key])

