class_name TimedVar extends RefCounted
## A variable that keeps track of time
##
## [TimedVar]s keep track of when they were created, and can expire after a certain amount of time if configured to (see [method set_lifespan]).
## [br]When expired, the contained value will be deleted (set to null)
## [br]A [TimedVar] with no lifespan will not expire unless made to (See [method force_expiration], [method take])
## [br][br]Usage:
## [codeblock]
## var t: TimedVar = TimedVar.with_lifespan(42, 800) # Expires after 0.8s
## print("Init: ", t)
## print(" value = ", t.get_value())
## # Init: TimedVar(42: expires in 0.80s)
## #  value = Some(42)
## 
## await get_tree().create_timer(0.5).timeout
## print("After 0.5s: ", t)
## print(" value = ", t.get_value())
## # After 0.5s: TimedVar(42: expires in 0.30s)
## #  value = Some(42)
## 
## await get_tree().create_timer(1.0).timeout
## print("After 1.5s: ", t)
## print(" value = ", t.get_value())
## # After 1.5s: TimedVar::Expired
## #  value = None
## [/codeblock]

## The tick (in milliseconds) this [TimedVar] was created[br]
## You can use it to compare with [method Time.get_ticks_msec]
var created_tick_ms: int = 0
## How long this var will live for[br]
## If 0, this var will never expire
var lifespan: int = 0

var _value: Variant
var _is_expired: bool = false :
	set(v):
		if v:
			_value = null
			created_tick_ms = 0
		_is_expired = v

## Constructor function
## [br]By default, [TimedVar]s only keep track of when they were created.
## [br]See also [method with_lifespan]
## [codeblock]
## var timed = TimedVar.new("foo")
## 
## # Wait 0.6s ...
## 
## print( timed.get_value() ) # Some("foo")
## print( timed.time_ms() ) # Should print "600"
## [/codeblock]
func _init(value: Variant):
	_value = value
	created_tick_ms = Time.get_ticks_msec()
	lifespan = 0
	_is_expired = false
	call_deferred(&"update")

## Create an empty [TimedVar] that only keeps track of when it was created
static func empty() -> TimedVar:
	var tv: TimedVar = TimedVar.new(null)
	return tv

## Create a new [TimedVar] that will live for [param lifespan_ms]
## [br]This is the equivalent to doing
## [br][code]var timed = TimedVar.new(value) .set_lifespan(lifespan_ms)[/code]
## [codeblock]
## <~~~~~~~~~lifespan~~~~~~~~~>
## (now) ---------------------> (expiration)
## [/codeblock]
static func with_lifespan(value: Variant, lifespan_ms: int) -> TimedVar:
	return TimedVar.new(value) .set_lifespan(lifespan_ms)

func _to_string() -> String:
	update()
	if _is_expired:
		return "TimedVar::Expired"
	if lifespan == 0:
		return "TimedVar(%s: alive for %.2fs)" % [_value, time_secs()]
	return "TimedVar(%s: expires in %.2fs)" % [_value, time_ms_until_expiration().unwrap_unchecked() * 0.001]


## Returns self.
## [br]Set a new lifespan for this [TimedVar], counting from now, after which it will expire
## [codeblock]
## Before calling set_lifespan():
##     (created) --> (now)
##     Or if a lifespan is already set:
##     <~~~~~~~~~lifespan~~~~~~~~~>
##     (created) --> (now) -------> (expiration)
## After calling set_lifespan():
##                   <~~~~~~~~~lifespan~~~~~~~~>
##     ------------> (created) ----------------> (expiration)
##                   (now)
## [/codeblock]
## It is more common to use this method upon initialization:
## [br][code]var timed_var = TimedVar.new( 42 ) .set_lifespan(1000)[/code]
## [br]which would be the same as writing:
## [br][code]var timed_var = TimedVar.with_lifespan( 42, 1000 )[/code]
## [br][br]If you don't want to change [member created_tick_ms], please set [member lifespan] manually
## [codeblock]
## Before:
##     (created) --> (now)
##     Or if a lifespan is already set:
##     <~~~~~~~~~lifespan~~~~~~~~~>
##     (created) --> (now) -----> (expiration)
## After:
##     <~~~~~~~~~~~~lifespan~~~~~~~~~~~~~~~~~>
##     (created) --> (now) ------------------> (expiration)
## [/codeblock]
func set_lifespan(lifespan_ms: int) -> TimedVar:
	assert(lifespan_ms > 0)
	created_tick_ms = Time.get_ticks_msec()
	lifespan = lifespan_ms
	return self



## Removes the lifespan on this [TimedVar] if there is one, making it so it only keeps track of when it was created
## [br]This is the default state of [TimedVar]s upon construction
## [br]Return self
## [codeblock]
## var timedvar = TimedVar.new("foo") .set_lifespan(5000) # Will expire after 5s
## ...
## timedvar.no_lifespan()
## # timedvar will no longer expire
## # You can still call methods like time_ms() to check how long it's been alive for
## [/codeblock]
func no_lifespan() -> TimedVar:
	lifespan = 0
	return self

## Schedule the expiration of this var at a specific tick
## [br]The difference between this and [method set_lifespan] is that [method set_lifespan] defines [i]how long until[/i] this var expires, while [method until] defines [i]when[/i] this var will expire.
## [br]Returns self
func until(tick_ms: int) -> TimedVar:
	lifespan = tick_ms - Time.get_ticks_msec()
	return self

## Returns the time since creation in milliseconds
func time_ms() -> int:
	return Time.get_ticks_msec() - created_tick_ms

## Returns the time since creation in seconds
func time_secs() -> float:
	return (Time.get_ticks_msec() - created_tick_ms) * 0.001

## Returns [code]Option<float>[/code] containing the time in milliseconds until this var expires
## [br]If this [TimedVar] has no lifespan or is already expired, it will return [code]None[/code]
func time_ms_until_expiration() -> Option:
	update()
	if _is_expired or lifespan <= 0:
		return Option.None()
	return Option.Some( created_tick_ms + lifespan - Time.get_ticks_msec() )

## Forces this [TimedVar] to expire
## [br]Returns self
func force_expiration() -> TimedVar:
	_is_expired = true
	return self


## Sets the contained value and extends when this [TimedVar] will expire (if a lifespan is configured)
## [br]For a non-resetting option, see [method mut_value]
## [br]Returns self
## [codeblock]
## var timed = TimedVar.new("foo") .set_lifespan(5000)
## print( timed ) # TimedVar(foo: expires in 5.00s)
## ...
## timed.set_value("bar")
## print( timed ) # TimedVar(bar: expires in 5.00s)
## [/codeblock]
func set_value(value: Variant) -> TimedVar:
	_value = value
	created_tick_ms = Time.get_ticks_msec()
	_is_expired = false
	return self

## Sets the contained value [b]without[/b] extending the lifespan (if a lifespan is configured)
## [br]Returns self
## [codeblock]
## var timed = TimedVar.new("foo") .set_lifespan(5000)
## print( timed ) # TimedVar(foo: expires in 5.00s)
## 
## # Wait for 2 seconds ...
## 
## timed.mut_value("bar")
## print( timed ) # TimedVar(bar: expires in 3.00s)
## [/codeblock]
## This method does nothing if this [TimedVar] is already expired
func mut_value(value: Variant) -> TimedVar:
	if !update()._is_expired:
		_value = value
	return self


## Returns [code]Option<Variant>[/code] with the contained value
## [br]This method will return [code]None[/code] if this [TimedVar] is expired
## [br][b]Note[/b]:
## [br]  Due to how [Option]s are implemented, this method will return [code]None[/code] if the contained value is [code]null[/code]
func get_value() -> Option:
	if update()._is_expired:
		return Option.None()
	if lifespan <= 0:
		return Option.Some(_value)
	# We have a lifespan, check it
	if Time.get_ticks_msec() > created_tick_ms + lifespan:
		_is_expired = true
	return Option.new(_value)


## Returns [code]Option<Variant>[/code] with the contained value
## [br]This method is the same as [method get_value], except that it overrides the lifespan with [param lifespan_ms]
func get_value_timed(lifespan_ms: int) -> Option:
	if update()._is_expired:
		return Option.None()
	# Check expiration if not already expired
	if Time.get_ticks_msec() > created_tick_ms + lifespan_ms:
		_is_expired = true
	return Option.new(_value)

## Returns the contained value without any additional checks
## [br]Because of that, it may lead to undefined behavior
## [br]It is suggested that you only use this if you're absolutely sure this [TimedVar] isn't expired
## [codeblock]
## var timed = TimedVar.new("foo")
## # It's okay here because we know that timed cannot be expired, as we just created it
## timed.get_value_unchecked()
## 
## if !timed.is_expired():
##     # It's also okay here because we checked whether timed is expired
##     timed.get_value_unchecked()
## [/codeblock]
func get_value_unchecked() -> Variant:
	return _value

## Returns [code]Option<Variant>[/code] with the contained value
## [br]This method is the same as [method get_value], except that the contained value is taken, expiring this [TimedVar]
## [codeblock]
## var t: TimedVar = TimedVar.new("foo")
## print(t.get_value())
## print(t)
## print(t.take())
## print(t)
## 
## Prints:
##  Some(foo)
##  TimedVar(foo: alive for 0.00s)
##  Some(foo)
##  TimedVar::Expired
## [/codeblock]
func take() -> Option:
	if update()._is_expired:
		return Option.None()
	
	# Not expired; take
	var ret_value: Variant = _value
	_is_expired = true
	return Option.new(ret_value)

## Returns [code]Option<Variant>[/code] with the contained value
## [br]This method is the same as [method take], except that it overrides the lifespan with [param lifespan_ms]
func take_timed(lifespan_ms: int) -> Option:
	if update()._is_expired:
		return Option.None()
	# Check scheduled expiration
	if lifespan >= 0 and Time.get_ticks_msec() > created_tick_ms + lifespan_ms:
		_is_expired = true
		return Option.None()
	
	# Not expired; take
	var ret_value: Variant = _value
	_is_expired = true
	return Option.new(ret_value)


## Checks this [TimedVar]'s expiration and updates the inner state
## [br]Returns self
## [br]You should almost never have to call this method since state checks are performed extensively
func update() -> TimedVar:
	if _is_expired:
		return self
	# Check scheduled expiration
	if lifespan > 0 and Time.get_ticks_msec() > created_tick_ms + lifespan:
		_is_expired = true
	return self

## Returns whether this [TimedVar] as a lifespan configured
func has_lifespan() -> bool:
	return lifespan > 0

## Returns: [code]Option<int>[/code] containing this [TimedVar]'s lifespan
## [br]Returns [code]Nonde[/code] if this [TimedVar] has no lifespan configured
func get_lifespan_ms() -> Option:
	update()
	return Option.Some(lifespan) if lifespan > 0 and !_is_expired else Option.None()

## Returns the lifespan of this [TimedVar] without any additional checks
## [br]This is the same as just accessing the [member lifespan] property
func get_lifespan_ms_unchecked() -> int:
	return lifespan

## Checks and returns whether this [TimedVar] will expire in the future
## [br]i.e. whether it has a lifespan and is not already expired
func is_expiration_scheduled() -> bool:
	update()
	return lifespan > 0 and !_is_expired

## Checks and returns whether this [TimedVar] is expired
func is_expired() -> bool:
	return update()._is_expired

## Returns whether this [TimedVar] is expired without any additional checks
## [br]If not used properly, it may cause undefined behavior
## [br]I discourage you from using this method
## [br]See [method is_expired] instead
func is_expired_unchecked() -> bool:
	return _is_expired

