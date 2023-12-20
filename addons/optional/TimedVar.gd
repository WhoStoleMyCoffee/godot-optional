class_name TimedVar extends RefCounted

## The tick (in milliseconds) this [TimedVar] was created[br]
## You can use it to compare with [method Time.get_ticks_msec]
var created_tick_ms: int = 0

var _value: Variant
var lifespan: int = 0
var _is_expired: bool = false :
	set(v):
		if v:
			_value = null
			created_tick_ms = 0
		_is_expired = v

## Constructor function
func _init(value: Variant):
	_value = value
	created_tick_ms = Time.get_ticks_msec()
	lifespan = 0
	_is_expired = false
	call_deferred(&"update")

static func empty() -> TimedVar:
	var tv: TimedVar = TimedVar.new(null)
	tv.created_tick_ms = 0
	return tv

func _to_string() -> String:
	update()
	if _is_expired:
		return "TimedVar::Expired"
	if lifespan == 0:
		return "TimedVar(%s: alive for %.2fs)" % [_value, time_secs()]
	return "TimedVar(%s: expires in %.2fs)" % [_value, time_ms_until_expiration().unwrap_unchecked() * 0.001]


## Set the lifespan on this [TimedVar], after which it will expire[br]
## See also [method no_lifespan]
## Returns self
func with_lifespan(lifespan_ms: int) -> TimedVar:
	assert(lifespan_ms > 0)
	lifespan = lifespan_ms
	return self

func no_lifespan() -> TimedVar:
	lifespan = 0
	return self

## Schedule the expiration of this var at a specific tick[br]
## Returns self
func until(tick_ms: int) -> TimedVar:
	lifespan = tick_ms - Time.get_ticks_msec()
	return self

## Returns the time since creation in milliseconds
func time_ms() -> int:
	return Time.get_ticks_msec() - created_tick_ms

## Returns the time since creation in seconds
func time_secs() -> float:
	return (Time.get_ticks_msec() - created_tick_ms) * 0.001

## Returns Option<float>
func time_ms_until_expiration() -> Option:
	update()
	if _is_expired or lifespan <= 0:
		return Option.None()
	return Option.Some( created_tick_ms + lifespan - Time.get_ticks_msec() )

## Returns self
func force_expiration() -> TimedVar:
	_is_expired = true
	return self


## For a non-resetting option, see [method mut_value]
func set_value(value: Variant) -> TimedVar:
	_value = value
	created_tick_ms = Time.get_ticks_msec()
	_is_expired = false
	return self

## Returns self
func mut_value(value: Variant) -> TimedVar:
	if !update()._is_expired:
		_value = value
	return self


func get_value() -> Option:
	if update()._is_expired:
		return Option.None()
	if lifespan <= 0:
		return Option.Some(_value)
	# We have a lifespan, check it
	if Time.get_ticks_msec() > created_tick_ms + lifespan:
		_is_expired = true
	return Option.new(_value)


# override lifespan
func get_value_timed(lifespan_ms: int) -> Option:
	if update()._is_expired:
		return Option.None()
	# Check expiration if not already expired
	if Time.get_ticks_msec() > created_tick_ms + lifespan_ms:
		_is_expired = true
	return Option.new(_value)

func get_value_unchecked() -> Variant:
	return _value

func take() -> Option:
	if update()._is_expired:
		return Option.None()
	# Check scheduled expiration
	if lifespan > 0 and Time.get_ticks_msec() > created_tick_ms + lifespan:
		_value = null
		created_tick_ms = 0
		_is_expired = true
		return Option.None()
	
	# Not expired; take
	var ret_value: Variant = _value
	_is_expired = true
	return Option.new(ret_value)

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


## Returns self
func update() -> TimedVar:
	if _is_expired:
		return self
	# Check scheduled expiration
	if lifespan > 0 and Time.get_ticks_msec() > created_tick_ms + lifespan:
		_is_expired = true
	return self

func has_lifespan() -> bool:
	return lifespan > 0

## Returns: Option<int>
func get_lifespan_ms() -> Option:
	update()
	return Option.Some(lifespan) if lifespan > 0 and !_is_expired else Option.None()

func is_expiration_scheduled() -> bool:
	update()
	return lifespan > 0 and !_is_expired

func is_expired() -> bool:
	return update()._is_expired

func is_expired_unchecked() -> bool:
	return _is_expired

