# godot-optional
## Better error handling for Godot!
Introduces to Godot Option, Result, and custom Error types inspired by Rust

#### Features

- [Optionals](#option) to explicitly annotate that a variable can be `null`
- [Results](#result) to explicitly annotate that an operation can fail
- [Custom error types](#custom-error-types) specific to your application
- [TimedVars](#timedvar) that keep track of how long they've existed for, and can delete themselves after some time
- [EnumStructs](#enum-structs-experimental) (Experimental)

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

# Getting the contained value (in order of safety):
var data = res.unwrap_or( 42 ) # Get from default value
var data = res.unwrap_or_else( some_complex_function ) # Get default value from function
var data = res.expect("Res was None!")
var data = res.unwrap() # Crashes if None, but quick for prototyping
var data = res.unwrap_unchecked() # Least safe. It's okay to use it here because we've already checked above
```

Option also comes with a safe way to index arrays and dictionaries
```gdscript
var my_arr = [2, 4, 6]
print( Option.arr_get(1) )  # Prints "Some(4)"
print( Option.arr_get(4) )  # Prints "None" because index 4 is out of bounds
```
![](screenshots/example_attack.png)


## Result
A generic `Result<T, E>`

Results are types that explicitly annotate that an operation (most often a function call) can fail, and forces the user to handle the exception

In case of a success, the `Ok` variant is returned containing the value returned by said operation
In case of a failure, the `Err` variant is returned containing information about the error.

Basic usage:
```gdscript

# By returning a Result, it's clear that this function can fail
func my_function() -> Result:
    return Result.from_gderr(ERR_PRINTER_ON_FIRE)
    # Also supports custom error types!
    return Result.Err( Error.new(Error.MyCustomError).info("expected", "some_value") )
    return Result.Err("my error message")
    return Result.Ok(data) # Success!

var res: Result = my_function()
# Ways to handle results:
if res.is_err():
    res.stringify_error() # @GlobalScope.Error to String
    # Custom errors can bear extra details. See the "Custom error types" section below
    res.err_cause(...) .err_info(...) .err_msg(...)\
        .report()
    return

# Getting the contained value (in order of safety):
var data = res.unwrap_or( 42 ) # Get from default value
var data = res.unwrap_or_else( some_complex_function ) # Get default value from function
var data = res.expect("my_function failed!")
var data = res.unwrap() # Crashes if res is Err. Least safe, but quick for prototyping
var data = res.unwrap_unchecked() # It's okay to use it here because we've already checked above

print(res) # "Ok( whatever data is contained )"
```

Result also comes with a safe way to open files and parse JSON

```gdscript
# "Error" refers to custom error types. Not to be confused with @GlobalScope.Error
 var res: Result = Result.open_file("res://file.txt", FileAccess.READ) # Result<FileAccess, Error>
 var json_res: Result = Result.parse_json_file("res://data.json") # Result<data, Error>
```
![](screenshots/example_file.png)

## Custom error types
Godot-optional introduces a custom `Error` class for custom error types. 

The aim is to allow for errors to carry with them details about the exception, leading to better error handling. 
It also acts as a place to have a centralized list of errors specific to your application, as Godot's global Error enum doesn't cover most cases. 

Usage:
```gdscript
# Can be made from a Godot error, and with optional additional details
var myerr: Error = Error.new(ERR_PRINTER_ON_FIRE) .cause('Not enough ink!')
    # Or with an additional message too!
    .msg("The printer gods demand input..")

# Prints: "Printer on fire { "cause": "Not enough ink!", "msg": "The printer gods demand input.." }"
print(myerr)
# Push the error to the debugger
myerr.report()

# You can even nest them!
# (These two lines do the same thing)
Error.from_gderr(ERR_TIMEOUT)\
    .cause( Error.new(Error.Other).msg("Oh no!") )
Error.new(Error.Other).msg("Oh no!")\
    .as_cause( Error.from_gderr(ERR_TIMEOUT) )

# Used alongside a Result:
Result.error(Error.MyCustomError)
Result.open_file( ... ) .err_msg("Failed to open the specified file")
```

You can also define custom error types specific to your application in the Error script
```gdscript
# res://addons/optional/Error.gd
enum {
    Other,
    # Define custom errors here ...
    MyCustomError,
}
```
![](screenshots/example_custom_errors.png)

## TimedVar
`TimedVar`s are variables that keep track of when they were created and can expire after a certain amount of time if configured to.

When expired, the contained value will be deleted (set to `null / None`)

Example: Creating a combo system using `TimedVar`s

```gdscript
var combo: TimedVar = TimedVar.empty() # Combo not yet started
print("  combo = ", combo) # "TimedVar(<null>: alive for 0.00s)"

# Player input ...

# Start the combo with a slash
print("SLASH!")
combo = TimedVar.with_lifespan("slash", 1000)
# Same as writing one of the following:
combo = TimedVar.new("slash") .set_lifespan(1000)
combo.set_value("slash") .set_lifespan(1000) # 1s window for following combos

# Now, combo = TimedVar(slash: expires in 1.00s)
# Player input ...

# Follow it up with a big slash
if combo.get_value() .matches("slash"):
	print("BIG SLASH!")
	combo.set_value("slash_big") # Also resets lifespan back to that 1s window we defined earlier
else:
    # Too late! `combo` already expired, so no more follow-ups!
	print("No big slash")

# Now, combo = TimedVar(slash_big: expires in 1.00s)
# Player input ...

# End it with a 'biggest slash', but with a tighter timing window of 0.5s
# Using take() (or in this case, take_timed()) takes care of finishing the
#  combo with no loose ends
if combo.take_timed(500) .matches("slash_big"):
	print("BIGGEST SLASH ULTIMATE!!!")
else:
    # Too late! `combo` already expired!
	print("No biggest slash :(")

# Now, combo = TimedVar::Expired
```

---

### Enum Structs (experimental)

Usage:

```gdscript
# Declare enum
static var AnimalState: EnumStruct = EnumStruct.new()\
    .add(&"Alive", { "is_hungry" : false })\
    .add(&"Dead") # A dead animal can't be hungry

# There are a couple ways to get an EnumStruct variant:
var cat_state: EnumVariant = AnimalState.Alive
cat_state.is_hungry = true
# or
var cat_state: EnumVariant = AnimalState.variant(&"Alive", { "is_hungry" : true })

print(cat_state) # Prints: Alive { "is_hungry" : true }
```
Notice how `EnumStruct`s and `EnumVariant`s can both be treated like normal objects, but with the user declared properties.

`Note`: There are also `EnumDict`s which use Dictionaries as variants instead of `EnumVariant`

The above code is the same as doing the following in Rust:
```rust
enum AnimalState {
    Alive{ is_hungry: bool },
    Dead,
}

let cat_state: AnimalState = AnimalState::Alive{ is_hungry: true };
```
