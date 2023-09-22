class_name IterRange
## Experimental. A range to be iterated on
## 
## The idea is that [method @GDScript.range] generates an array of numbers instaed of simply iterating[br]
## Usage:
## [codeblock]
## IterRange.new(start, end, step (optional))
## for i in IterRange.new(-1, 8, 2):
##     print(i) # Prints -1, 1, 3, 5, 7
## 
## # Possibly favorable over range() for large ranges
## for i in IterRange.new(0, 1000000):
##     print(i)
## [/codeblock]

var begin: int
var end: int
var current: int
var increment: int

func _init(start: int, stop: int, step: int = 1):
	begin = start
	end = stop
	current = begin
	increment = step
	
	# In invalid
	if increment == 0 or end == begin or (increment > 0) != (end > begin):
		increment = 0

func _should_continue() -> bool:
	# Check validity
	return increment != 0\
		# Check iter
		and (increment > 0 and current < end) or (increment < 0 and current > end)

func _iter_init(_arg) -> bool:
	current = begin
	return _should_continue()

func _iter_next(_arg) -> bool:
	current += increment
	return _should_continue()

func _iter_get(_arg) -> int:
	return current

# Returns a new [IterRange] that is this one reversed
func reverse() -> IterRange:
	return IterRange.new(end, begin, -increment)


