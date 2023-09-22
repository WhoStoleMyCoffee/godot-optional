# godot-optional
Introduces to Godot Option and Result types inspired from Rust

## Option
A generic `Option<T>`

Options are types that explicitly annotate that a value can be `null`, and forces the user to handle the exception

Basic usage:
```gdscript
# By returning an Option, it's clear that this function can return null, which must be handled
func get_player_stats(id: String) -> Option:
    return Option.None() # Represents a null
    return Option.Some( data ) # Sucess!

var res: Option = get_player_stats("player_3")
if res.is_none():
    print("Player doesn't exist!")
    return

var data = res.expect("Already checked if None or Some above") # Safest
var data = res.unwrap() # Crashes if res is None. Least safe, but quick for prototyping
var data = res.unwrap_or( 42 ) # Get from default value
var data = res.unwrap_or_else( some_complex_function ) # Get default value from function
var data = res.unwrap_unchecked() # It's okay to use it here because we've already checked above
```

Option also comes with a safe way to index arrays and dictionaries
```gdscript
var my_arr = [2, 4, 6]
print( Option.arr_get(1))  # Prints "4"
print( Option.arr_get(4))  # Prints "None" because index 4 is out of bounds
```


## Result
A generic `Result<T, E>`

Results are types that explicitly annotate that an operation (most often a function call) can fail, and forces the user to handle the exception

In case of a success, the `Ok` variant is returned containing the value returned by said operation
In case of a failure, the `Err` variant is returned containing information about the error.

Basic usage:
```gdscript
# By returning a Result, it's clear that this function can fail
func my_function() -> Result:
    return Result.from_err(ERR_PRINTER_ON_FIRE)
    return Result.Err("my error message")
    return Result.Ok(data) # Success!

var res: Result = my_function()
if res.is_err():
    # stringify_error() is specific to this Godot addon
    print(res) .stringify_error()
    return

var data = res.expect("Already checked if Err or Ok above") # Safest
var data = res.unwrap() # Crashes if res is Err. Least safe, but quick for prototyping
var data = res.unwrap_or( 42 )
var data = res.unwrap_or_else( some_complex_function )
var data = res.unwrap_unchecked() # It's okay to use it here because we've already checked above
```

Result also comes with a safe way to open files

```gdscript
 var res: Result = Result.open_file("res://file.txt", FileAccess.READ)
 var json_res: Result = Result.parse_json_file("res://data.json")
```

## IterRange and IterRangef (experimental)
`IterRange` and `IterRangef` both represent a range to be iterated on.

`IterRangef` is the same as `IterRange` but iterates over floats rather than ints

The idea is that GDScript's `range()` generates an array of numbers instaed of simply iterating

Usage:

```gdscript
# IterRange.new(start, end, step (optional))
for i in IterRange.new(-1, 8, 2):
    print(i) # Prints -1, 1, 3, 5, 7

# Possibly favorable over range() for large ranges
for i in IterRangef.new(0.0, 1000000.0, 0.2):
    print(i)
```
