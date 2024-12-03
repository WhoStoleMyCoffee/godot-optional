# godot-optional

#todo
## Better error handling for Godot!

Introduces to Godot Options, Results

The issue:

### You may not need godot-optional



## Features

- [Optionals](#option) to explicitly annotate that a variable can be `null`
- [Results](#result) to explicitly annotate that an operation can fail
- [Error Reports](#reports), which carry details about the exception for better logging
- [TimedVars](#timedvar) that keep track of how long they've existed for, and can delete themselves after some time

## Option
A generic `Option<T>`

Options are types that explicitly annotate that a value can be `null`, and forces the user to handle the exception

```gdscript
func player_attack_regular():
    # The player may or may not be holding anything
    # Just by looking at this line, it's unclear whether `weapon` can be null
    var weapon = { "id": "sword", "durability": 2 }
    print("Player attacks!")
    # Use durability if holding a weapon
    # If we omit these "!= null" checks, it will lead to undefined behavior!
    if weapon != null:
        weapon.durability -= 1
        if weapon.durability <= 0:
            print(weapon, " broke")
            weapon = null

func player_attack_with_option():
    # Here, it's clear that `weapon` can be null
    var weapon: Option = Option.Some({ "id": "sword", "durability": 2 })
    print("Player attacks!")
    # Use durability if holding a weapon
    weapon.if_some(func(w: Dictionary):  w.durability -= 1)\
        .filter(func(w: Dictionary):  return w.durability <= 0)\
        .take()\
        .if_some(func(old_w: Dictionary):  print(old_weapon, " broke"))
```

Basic usage:
```gdscript
# By returning an Option, it's clear that this function can return null, which must be handled
func get_player_health(id: String) -> Option:
    return Option.None() # Represents a null
    return Option.Some( data ) # Sucess!

var opt: Option = get_player_health("player_3")
if opt.is_none():
    print("Player doesn't exist!")
    return

# Getting the contained value
var data = opt.unwrap_or( 42 ) # Get or provided default
var data = opt.unwrap_or_else( some_complex_function ) # Get or default value from function
var data = opt.expect("`opt` surely can't be None here") # Assert this isn't a `null`, and get the inner value
var data = opt.unwrap() # Crashes if None
var data = opt.unwrap_unchecked() # Least safe. It's okay to use it here because we've already checked above
print(opt) # "Some( whatever data is contained )"

# Doing checks on Options
if opt.matches(100):
    print("Player is at 100 health!")
elif opt.is_some_and(func(health: int):    return health <= 10):
    print("Player has critically low health!")
```

Option also comes with a safe way to index arrays and dictionaries
```gdscript
var my_arr = [2, 4, 6]
print( Option.arr_get(1) )  # Prints "Some(4)"
print( Option.arr_get(4) )  # Prints "None" because index 4 is out of bounds
```


## Result
A generic `Result<T, E>`

Results are types that explicitly annotate that an operation (most often a function call) can fail, and forces the user to handle the exception

In case of a success, the `Ok` variant is returned containing the value returned by said operation
In case of a failure, the `Err` variant is returned containing information about the error.

```gdscript
func file_open():
    # Should fail because the file doesn't exist
    var res1: Result = Result.open_file("res://nonexistent_file.txt", FileAccess.READ)\
        .gderror_to_string()\
        .map(func(fileaccess: FileAccess):  return fileaccess.get_as_text())
    print(res1) # Should print: "Err(Report: File not found { "path": "res://nonexistent_file.txt" })"

    var res2: Result = Result.parse_json_file("res://data.json")
    print(res2) # Should print: "Ok( [contents of data.json] )"
```

Basic usage:
```gdscript

# By returning a Result, it's clear that this function can fail
func my_function() -> Result:
    return Result.Ok("foo") # Success!
    return Result.from_gderr(ERR_PRINTER_ON_FIRE)
    return Result.Err(&"my error")
    # With an error report
    return Result.Err(Report.new()
        .info("expected", "some_value")
        .info("found", "some_other_value")
        .cause(ERR_BUSY)
        )

var res: Result = my_function()
# Ways to handle results:
if res.is_err():
    res\
        # @GlobalScope.Error to String
        .gderror_to_string()\
        # Report this error. See the "Reports" section below
        .report()
    return

# Getting the contained value
var data = res.unwrap_or( 42 ) # Get if Ok(value) or provided default
var data = res.unwrap_or_else( some_complex_function ) # Get or default value from function
var data = res.expect("my_function() somehow failed!") # Assert this isn't an `Err`, and get the inner value
var data = res.unwrap() # Crashes if Err
var data = res.unwrap_unchecked() # Least safe. It's okay to use it here because we've already checked above
print(res) # "Ok( whatever data is contained )"

# Doing checks on Results
if res.matches("foo"):
    print("my_function() was a success and returned 'foo'!")
```

Result also comes with a safe way to open files and parse JSON

```gdscript
 var res: Result = Result.open_file("res://file.txt", FileAccess.READ) # Result<FileAccess, Report>
 var json_res: Result = Result.parse_json_file("res://data.json") # Result<data, Report>
```


## Reports
Godot-optional introduces a custom `Report` class for custom error reporting. 

It can also somewhat act as a crash handler.

The aim is to allow for errors to carry with them details about the exception, leading to better error handling. 

These are often used alongside `Result`s

```gdscript
var res = Result.Err(ERR_TIMEOUT).as_report(r: Report):
    r\
        # Convert "24" (whatever that means...) to "Timeout"
        .gderror_to_string()\
        .msg("Failed to do operation")\
        .info("some_key", "some_value")\
        .cause(ERR_BUSY)\
        .report()
    )
```

Additionally, `Report`s can be logged at different 'levels'

```gdscript
Report.new("foo")\
    .report(Report.LogLevel.INFO)\
    .report(Report.LogLevel.WARNING)\
    .report(Report.LogLevel.ERROR)\
    .report(Report.LogLevel.CRASH)
```



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
combo = TimedVar.new(&"slash") .set_lifespan(1000)
combo.set_value("slash") .set_lifespan(1000) # 1s window for following combos

# Now, combo = TimedVar(slash: expires in 1.00s)
# Player input ...

# Follow it up with a big slash
if combo.get_value() .matches("slash"):
	print("BIG SLASH!")
	combo.set_value(&"slash_big") # Also resets lifespan back to that 1s window we defined earlier
else:
    # Too late! `combo` already expired, so no more follow-ups!
	print("No big slash")

# Now, combo = TimedVar(slash_big: expires in 1.00s)
# Player input ...

# End it with a 'biggest slash', but with a tighter timing window of 0.5s
# Using take() (or in this case, take_timed()) takes care of finishing the
#  combo with no loose ends
if combo.take_timed(500) .matches(&"slash_big"):
	print("BIGGEST SLASH ULTIMATE!!!")
else:
    # Too late! `combo` already expired!
	print("No biggest slash :(")

# Now, combo = TimedVar::Expired
```


