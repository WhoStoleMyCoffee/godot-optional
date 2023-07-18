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
# ...
var res: Option = get_player_stats("player_3")
if res.is_none():
    print("Player doesn't exist!")
    return
var data = res.expect("Already checked if None or Some above") # Safest
var data = res.unwrap_or( some_default_value )
var data = res.get_value() # Generally, it's okay to use get_value() because we've already checked above
var data = res.unwrap() # Crashes if res is None. Least safe, but quick for prototyping
```

Option also comes with a safe way to index arrays
```gdscript
var my_arr = [2, 4, 6]
print( Option.arr_get(1))  # Prints "4"
print( Option.arr_get(4))  # Prints "None"
```

## Result
A generic `Result<T, E>`
Results are types that explicitly annotate that an operation (most often a function call) can fail, and forces the user to handle the exception
In case of a success, the `Ok` variant is returned containing the value returned by said operation
In case of a failure, the `Err` variant is returned containing information about the error.
Basic usage:
```gdscript
# By returning a Result, it's clear that this function can fail
func load_data_from_file(path: String) -> Result:
    return Result.Err(ERR_FILE_NOT_FOUND)
    return Result.Err("my error message")
    return Result.Ok(data) # Success!
# ...
var res: Result = load_data_from_file( ... )
if res.is_err():
    print(res)
    return
var data = res.expect("Already checked if Err or Ok above") # Safest
var data = res.unwrap_or( some_default_value )
var data = res.get_value() # Generally, it's okay to use get_value() because we've already checked above
var data = res.unwrap() # Crashes if res is Err. Least safe, but quick for prototyping
```
