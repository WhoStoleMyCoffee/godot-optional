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
## 
## var res: Option = get_player_stats("player_3")
## if res.is_none():
##     print("Player doesn't exist!")
##     return
## 
## # Getting the contained value (in order of safety):
## var data = res.unwrap_or( 42 ) # Get from default value
## var data = res.unwrap_or_else( some_complex_function ) # Get default value from function
## var data = res.expect("Res was None!")
## var data = res.unwrap() # Crashes if None, but quick for prototyping
## var data = res.unwrap_unchecked() # Least safe. It's okay to use it here because we've already checked above
## [/codeblock][br]
## [Option] also comes with a safe way to index arrays and dictionaries[br]
## [codeblock]
## var my_arr = [2, 4, 6]
## print( Option.arr_get(1))  # Prints "Some(4)"
## print( Option.arr_get(4))  # Prints "None" because index 4 is out of bounds
## [/codeblock]

var _value: Variant = null

## Creates a [code]Some([/code][param v][code])[/code]
## [br][param v] must not be [code]null[/code]
static func Some(v) -> Option:
	assert(v != null, "Cannot assign null to an Some")
	return Option.new(v)

## Creates a [code]None[/code]
static func None() -> Option:
	return Option.new(null)

func _to_string() -> String:
	if _value == null:
		return 'None'
	return 'Some(%s)' % str(_value)

## Creates a duplicate with the inner value duplicated as well
func duplicate() -> Option:
	if _value == null:
		return Option.new(null)
	return Option.new( _value.duplicate() )

## Constructor function
## [br]Creates a [code]None[/code] if [param val] is [code]null[/code], otherwise [code]Some([/code][param val][code])[/code]
func _init(val: Variant):
	_value = val

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
	if _value != null:
		return _value
	push_warning("Unresolved unwrap(). It is good practice to properly handle options in release builds")
	Report.crash("Called Option::unwrap() on a None")
	return

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
## [/codeblock][br]
## This is different from [method unwrap_or] in that the value is lazily evaluated, so it's good for methods that may take a long time to compute
func unwrap_or_else(f: Callable) -> Variant:
	if _value == null:
		return f.call()
	return _value

## Similar to [method unwrap] where the contained value is returned[br]
## The difference is that there are NO checks to see if the value is null because you are assumed to have already checked if it's a None with [method is_none] or [method is_some][br]
## If used incorrectly, it can lead to unpredictable behavior
func unwrap_unchecked() -> Variant:
	return _value

## [code]f: func(T) -> U[/code][br]
## Maps an [code]Option<T>[/code] to [code]Option<U>[/code] by applying a function to the contained value (if [code]Some[/code]) or returns [code]None[/code] (if [code]None[/code])
func map(f: Callable) -> Option:
	if _value == null:
		return self
	return Option.new( f.call(_value) )

## [code]f: func(T) -> void[/code][br]
## Maps an [code]Option<T>[/code] to [code]Option<U>[/code] by applying a function to the contained value mutably (if [code]Some[/code])
## [br]Also good if you simply want to execute a block of code if [code]Some[/code]
## [br]Returns self
func call_some(f: Callable) -> Option:
	if _value != null:
		f.call(_value)
	return self

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
	assert(default != null, "The default value must not be `null`")
	if _value == null:
		return default
	var u: Variant = f.call(_value)
	assert(u != null, "The function `f` must not return `null`")
	return u

## [code]default: func() -> U[/code][br]
## [code]f: func(T) -> U[/code][br]
## Computes a default function result (if none), or applies a different function to the contained value (if any)[br]
## Same as [method map_or] but computes the default from a function
func map_or_else(default: Callable, f: Callable) -> Variant:
	if _value == null:
		var u: Variant = default.call()
		assert(u != null, "The default function must not return null")
		return u
	var u: Variant = f.call(_value)
	assert(u != null, "The function `f` must not return null")
	return u

## This is the rust equivalent of [code]Option.and()[/code][br]
## [param optb]: [code]Option<U>[/code][br]
## Returns None if the option is None, otherwise returns [param optb]
## Example:
## [codeblock]
## print( Option.Some(2) .and_opt(Option.None()) )      # Prints: None
## print( Option.None() .and_opt(Option.Some("foo")) )  # Prints: None
## print( Option.Some(2) .and_opt(Option.Some("foo")) ) # Prints: Some("foo")
## print( Option.None() .and_opt(Option.None()) )       # Prints: None()
## [/codeblock]
func and_opt(optb: Option) -> Option:
	return optb if _value != null and optb._value != null else Option.None()

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
	var u: Option = f.call(_value)
	assert(u is Option, "The function `f` must return an Option but returned %s" % u)
	return u

## This is the rust equivalent of [code]Option.or()[/code][br]
## [param optb]: [code]Option<T>[/code][br]
## Returns the option if it contains a value, ortherwise returns [param optb][br]
## Example:
## [codeblock]
## print( Option.Some(2) .or_opt(Option.None()) )    # Prints: Some(2)
## print( Option.None() .or_opt(Option.Some(100)) )  # Prints: Some(100)
## print( Option.Some(2) .or_opt(Option.Some(100)) ) # Prints: Some(2)
## print( Option.None() .or_opt(Option.None()) )     # Prints: None
## [/codeblock]
func or_opt(optb: Option) -> Option:
	return self if _value != null else optb

## [code]f: func() -> Option<T>[/code][br]
## Returns the option if it contains a value, otherwise calls [code]f[/code] and returns the result[br]
## Example:
## [codeblock]
## func nobody() -> Option:
##     return Option.None()
## 
## func vikings() -> Option:
##     return Option.Some("vikings")
## 
## print( Option.Some("barbarians") .or_else(vikings) ) # Prints: Some("barbarians")
## print( Option.None .or_else(vikings) ) # Prints: Some("vikings")
## print( Option.None .or_else(nobody) ) # Prints: None
## [/codeblock]
func or_else(f: Callable) -> Option:
	if _value != null:
		return self
	var u: Option = f.call()
	assert(u is Option, "The function `f` must return an Option but returned %s" % u)
	return u

## This is the rust equivalent of [code]Option.xor()[/code][br]
## [param optb]: [code]Option<T>[/code][br]
## Returns Some if exactly one of [param self], [param optb] is Some, otherwise returns None[br]
## Example:
## [codeblock]
## print( Option.Some(2) .xor_opt(Option.None()) )    # Prints: Some(2)
## print( Option.None() .xor_opt(Option.Some(100)) )  # Prints: Some(100)
## print( Option.Some(2) .xor_opt(Option.Some(100)) ) # Prints: None
## print( Option.None() .xor_opt(Option.None()) )     # Prints: None
## [/codeblock]
func xor_opt(optb: Option) -> Option:
	if (_value == null) == (optb._value == null):
		return Option.None()
	return self if _value != null else optb

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

## Replaces the contained value in the option with the given [param value]
## Example:
## [codeblock]
## var x = Option.Some(2)
## var old = x.replace(5)
## print("x =", x, ", old =", old) # Prints "x = Some(5), old = Some(2)"
## [/codeblock]
func replace(value) -> Option:
	assert(value != null)
	var old: Option = Option.new(_value)
	_value = value
	return old

## Converts [code]Option<Option<T>>[/code] to [code]Option<T>[/code]
## Example:
## [codeblock]
## var x = Option.Some(Option.Some(42))
## print( x.flatten() ) # Some(42)
## 
## var x = Option.Some(Option.None())
## print( x.flatten() ) # None
## 
## var x = Option.None()
## print( x.flatten() ) # None
## [/codeblock]
func flatten() -> Option:
	if _value == null or !(_value is Option):
		return self
	return _value

## [param predicate]: [code]func(T) -> bool[/code]
## [br]Returns [code]None[/code] if the option is [code]None[/code], otherwise calls [param predicate] with the wrapped value and returns:
## [br] - [code]Some(t)[/code] if predicate returns true (where t is the wrapped value)
## [br] - [code]None[/code] if predicate returns false.
## [br]
## Example:
## [codeblock]
## var is_even = func(n: int) -> bool:
##     return n % 2 == 0
## 
## assert( Option.None()  .filter(is_even) .is_none() )
## assert( Option.Some(3) .filter(is_even) .is_none() )
## assert( Option.Some(4) .filter(is_even) .matches(4) )
## [/codeblock]
## See also [method matches]
func filter(predicate: Callable) -> Option:
	if _value == null:
		return self
	var v: bool = predicate.call(_value)
	assert(v is bool, "The predicate function must return a bool but got %s" % v)
	return self if v else Option.None()

## Ensures that the type of the contained value is [param type][br]
## This is similar to doing
## [codeblock]
## option.filter(func(v):	return typeof(v) == type)
## [/codeblock]
func typed(type: Variant.Type) -> Option:
	if typeof(_value) == type:
		return self
	return Option.None()

## Checks whether the contained value matches [param rhs]
## [br]i.e. checks that [code]self == Some(rhs)[/code]
## [br]If this [Option] is a [code]None[/code], this method will return [code]false[/code]
## [br]This is a shorthand for
## [code].is_some_and(func(value): value == rhs)[/code]
## [br](See [method is_some_and])
func matches(rhs: Variant) -> bool:
	return _value == rhs and _value != null

## [code]f: func(T) -> bool[/code][br]
## Returns true if the [Option] is [code]Some[/code] and the value inside matches the predicate
## Example:
## [codeblock]
## var x = Option.Some(2)
## assert( x.is_some_and(func(x):	return x > 1) == true)
## 
## var x = Option.Some(0)
## assert( x.is_some_and(func(x):	return x > 1) == false)
## 
## var x = Option.None()
## assert( x.is_some_and(func(x):	return x > 1) == false)
## [/codeblock]
## To check whether the contained value matches another, see [method matches]
func is_some_and(f: Callable) -> bool:
	return _value != null and f.call(_value)

## Transforms the [Option][code]<T>[/code] into a [Result][code]<T, err>[/code]
func ok_or(err: Variant) -> Result:
	if _value == null:
		return Result.Err(err)
	return Result.Ok(_value)

## Same as [method ok_or] but computes the error value from the lambda [param err]
func ok_or_else(err: Callable) -> Result:
	if _value == null:
		return Result.Err(err.call())
	return Result.Ok(_value)


#region UTIL

## Safe version of [code]arr[idx][/code]
static func arr_get(arr: Array, idx: int) -> Option:
	if idx >= arr.size():
		return Option.new(null)
	return Option.new(arr[idx])

## Safe version of [code]dict[key][/code]
static func dict_get(dict: Dictionary, key: Variant) -> Option:
	return Option.new( dict.get(key, null) )

## @deprecated
## Please use [method Node.get_node_or_null]
static func get_node(parent: Node, path: NodePath) -> Option:
	push_warning("Use of deprecated method Option.get_node(). Please use Node.get_node_or_null()")
	return Option.new(parent.get_node_or_null(path))


## Converts this [Option] into a Dictionary for serialization
## [br]See [method from_dict]
func to_dict() -> Dictionary:
	if _value == null:
		return { "None": false }
	return { "Some": _value }

## Deserializes a Dictionary into an Option
## [br][param dict] must have either of [code]"Some": Variant[/code] or [code]"None"[/code], but not both, in which case it will return [Result][code].Err(ERR_INVALID_DATA)[/code]
## [br]See [method to_dict]
static func from_dict(dict: Dictionary) -> Result:
	if dict.has("Some") == dict.has("None") or dict.size() != 1:
		return Result.Err(ERR_INVALID_DATA)
	# At this point, it's guaranteed dict is either "Some" or "None"
	# just trust me bro
	return Result.Ok(Option.new( dict.get("Some", null) ))

#endregion
