class_name IterRangef
## Experimental. [br]Same as [IterRange] but iterates over floats instead of ints[br]
## See also [IterRange]

var begin: float
var end: float
var current: float
var increment: float

func _init(start: float, stop: float, step: float = 1.0):
	begin = start
	end = stop
	current = begin
	increment = step
	
	# In invalid
	if increment == 0.0 or end == begin or (increment > 0.0) != (end > begin):
		increment = 0.0

func should_continue() -> bool:
	# Check validity
	return increment != 0.0\
		# Check iter
		and (increment > 0.0 and current < end) or (increment < 0.0 and current > end)

func _iter_init(_arg) -> bool:
	current = begin
	return should_continue()

func _iter_next(_arg) -> bool:
	current += increment
	return should_continue()

func _iter_get(_arg) -> float:
	return current

# Returns a new [IterRangef] that is this one reversed
func reverse() -> IterRangef:
	return IterRangef.new(end, begin, -increment)


