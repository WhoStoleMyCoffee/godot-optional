extends VBoxContainer

"""
* EXAMPLES *

Note:
	If you're in a context where performance matters more than anything,
	you may want to opt for conventional error handling instead
	
	I highly recommend reading through the F1 documentation for
	Option, Result, Report, and TimedVar
"""



"""
PLAYGROUND FOR TESTING
"""
func demo_playground():
	print("Write your own tests here!")

#region Using TimedVars

"""
This example demonstrates the use of TimedVars for use in combo systems
`param_delay` controls the time between simulated attacks; see what happens when
it changes!
See:
- TimedVar::set_value()
- TimedVar::take() and take_timed()
- Option::matches()
"""
func example_combo():
	var param_delay: float = 0.2
	#var param_delay: float = 0.6 # A little slow. No 'biggest slash' at the end
	#var param_delay: float = 1.5 # Too slow! No combo for you!
	
	var combo: TimedVar = TimedVar.empty() # Combo not yet started
	print("  combo = ", combo)
	
	await get_tree().create_timer( param_delay ).timeout
	# Start the combo with a slash
	print("SLASH!")
	combo.set_value(&"slash") .set_lifespan(1000) # 1s window for following combos
	print("  combo = ", combo)

	await get_tree().create_timer( param_delay ).timeout
	# Follow it up with a big slash
	if combo.get_value() .matches(&"slash"):
		print("BIG SLASH!")
		# Set the value and reset timer
		combo.set_value(&"slash_big")
	else:
		print("No big slash")
	print("  combo = ", combo)
	
	await get_tree().create_timer( param_delay ).timeout
	# End it with a biggest slash, but with a tighter timing window of 0.5s
	# Using take() (or in this case, take_timed()) takes care of finishing the
	#  combo with no loose ends
	if combo.take_timed(500) .matches(&"slash_big"):
		print("BIGGEST SLASH!!!")
	else:
		print("No biggest slash :(")
	print("  combo = ", combo)


#endregion Using TimedVars


#region Using Options

"""
This example demonstrates how you might implement a weapon system
with durability using Options
"""
func demo_weapon_durability():
	# See what happens at different durability levels!
	var durability: int = 2
	var weapon: Option = Option.Some({ 'id' : 'sword', 'durability' : durability })
	# var weapon: Option = Option.None()
	
	print("weapon = ", weapon)
	print('Player attacked!')
	# If the player is holding a weapon
	if weapon.is_some():
		# Get the weapon data
		var w: Dictionary = weapon.unwrap_unchecked()
		w.durability -= 1
		# Weapon broke!
		if w.durability <= 0:
			# Remove the broken weapon and print it
			# Option.unwrap_unchecked() is like the evil twin on Option.unwrap()
			# Only use it if you're sure it can't be a None
			var broken_weapon: Dictionary = weapon.take() .unwrap_unchecked()
			print(broken_weapon.id, ' broke!')
	print('weapon = ', weapon)
	
	# Short version
	print('Player attacked!')
	# Use durability if holding a weapon
	var broken_weapon: Option = weapon.if_some(func(w: Dictionary):	w.durability -= 1)\
		# If the weapon broke...
		.filter(func(w: Dictionary) -> bool:	return w.durability <= 0)\
		# Remove it
		.take()\
		# And print it out
		.if_some(func(old_weapon: Dictionary):
			print(old_weapon.id, ' broke!')
			)
	print('weapon = ', weapon)
	print("broken_weapon = ", broken_weapon)



"""
This example demonstrates ways to handle Options
See:
- Option::matches()
- Option::is_some(), is_none(), is_some_and(), if_some()
"""
func demo_option_handling():
	var list: Option = Option.Some([
		"apples",
		"bananas",
		"milk",
	])
	print(" list = ", list)
	
	print("Going shopping...")
	# Let's take `list`, leaving a None in its place
	var taken_list: Option = list.take()\
		# ... and add "bread"
		.if_some(func(arr: Array):
			print("(Whoops, forgot to add bread!)")
			arr.append("bread")
			)
	print(" list = ", list)
	print(" taken_list = ", taken_list)
	
	if taken_list.is_some_and(func(arr: Array):	return arr.size() > 3):
		print("Shopping list is too long!")
		# It's okay to use unwrap_unchecked() here because we already
		# checked if it's Some (through is_some_and())
		print(" taken_list size = ", taken_list.unwrap_unchecked().size() )
	
	# Doing things this way isn't necessary
	# It's just for showcasing purposes...
	# Basically, we leave out only "milk"
	taken_list = taken_list.map(func(arr: Array):
		return arr.filter(func(str: String):	return str == "milk")
		)
	
	if taken_list.matches([ "milk" ]):
		print("Couldn't find only milk...")


"""
This example demonstrates the usage of:
- Option::arr_get()
- Option::map()
- Option::unwrap_or()
Option comes with a safe way to index arrays, dictionaries, and getting nodes
See Option::dict_get()
"""
func example_safe_get():
	var array: Array = [ 'Apple', 'Banana', 'GLTFDocumentExtensionConvertImporterMesh' ]
	
	var arrget: Callable = func(i: int) -> String:
		# Option version of array[i]
		return Option.arr_get(array, i)\
			.map(func(v: String):	return 'Found ' + v)\
			.unwrap_or("Couldn't get index %s!" % i)
	
	print( arrget.call(0) ) # Some
	print( arrget.call(1) ) # Some
	print( arrget.call(2) ) # Some
	print( arrget.call(3) ) # None!


"""
This example demonstrates the usage of:
- Option::to_dict()
- Option::from_dict()
See also:
- Result.gderror_to_string()
"""
func example_option_serialization():
	var pet_name: Option = Option.Some("Buster")
	var pet_name_dict: Dictionary = pet_name.to_dict()
	print("pet_name = ", pet_name)
	print("pet_name_dict = ", pet_name_dict)
	
	# Should succeed
	var loaded_pet_name: Result = Option.from_dict(pet_name_dict)
	print("loaded_pet_name = ", loaded_pet_name)
	
	# Should fail:
	var invalid: Result = Option.from_dict({
		"invalid_data": 12,
		"None": 0,
		"Some": "Rick"
	}) .gderror_to_string()
	print("invalid = ", invalid)

#endregion Using Options



#region Using Results


"""
This example demonstrates ways to handle errors using signals as a dummy
 method that can fail
These are way cleaner than spamming uninsightful errors in the console
See:
- Result::Ok(), Err(), and from_gderr()
- Result::as_report() and report()
- Result::matches(), matches_err()
- Report::msg(), cause(), info(), and report()
- Report::LogLevel
"""
signal dummy_signal
func example_result_handling():
	var dummy_fn: Callable = func():
		pass
	
	# Should succeed
	var res1: Result = Result.from_gderr( dummy_signal.connect(dummy_fn) )\
		.map(func(__):	return "Success!")
	print("First connect: ", res1)
	
	print("Look at the debugger console for errors!")
	# The following should all fail:
	# Simply using godot errors
	var res2: Result = Result.from_gderr( dummy_signal.connect(dummy_fn) )\
		# Convert Err(31) (whatever "31" means...) to Err("Invalid parameter")
		.gderror_to_string()\
		.report()
	
	# Using custom error handling
	var res3: Result = Result.from_gderr( dummy_signal.connect(dummy_fn) )\
		# as_report() converts our Err(ERR_INVALID_PARAMETER) into an Err(Report(ERR_INVALID_PARAMETER))
		.as_report(func(r: Report):
			return r.msg("Error while connecting signal")\
				# Convert to string like seen above
				.gderror_to_string()\
				.report(Report.LogLevel.WARNING)
			)
	
	# Instead of using .report(), you could also handle Results yourself
	print("No thanks, I'll handle them myself!")
	# Just like Options, Results have a  .matches()  method
	if res1.matches("Success!"):
		print('res1 was Ok("Success!")')
	if res2.matches_err(ERR_INVALID_PARAMETER):
		print("res2 failed to connect!")
	# Even though res3 is an  Err(Report) , we can still match the inner value
	# Same as  if res3.is_err_and(func(r: Report):	return r.err == ERR_INVALID_PARAMETER):
	if res3.matches_err(ERR_INVALID_PARAMETER):
		print("res3 failed to connect!")


"""
This example demonstrates the ways to use Result to safely open and parse files
See:
- Result::map_err(), if_err(), and as_report()
	These 2 are pretty similar, it doesn't matter which you use in this case
	Here, I used both just for example purposes
- Report::gderror_to_string()
"""
func example_file_open():
	# Should fail because the file doesn't exist
	var res1: Result = Result.open_file("res://nonexistent_file.json", FileAccess.READ)\
		.map_err(func(r: Report):
			return r.gderror_to_string()
			)
	print('Result 1 (should fail) = ', res1)
	
	# Should succeed with Ok(...) containing the file content
	var res2: Result = Result.parse_json_file("res://addons/optional/examples/example_userdata.json")\
		.if_err(func(r: Report):
			r = r.gderror_to_string()
			)
	print('Result 2 (should succeed) = ', res2)
	
	# `example_userdata_erroneous.json`
	var res3: Result = Result.parse_json_file("res://addons/optional/examples/example_userdata_erroneous.json")\
		.map_err(func(r: Report):
			return r.gderror_to_string()
			)
	print('Result 3 (should fail) = ', res3)



# Using an enum
# Enums are just a colletion of ints, not great for printing
enum PrintError {
	NOT_ENOUGH_PAPER,
	NOT_ENOUGH_INK,
}
# Using a const Dictionary
# More involved, but has a builtin print message
# Here we use StringNames for faster comparing
const GreetError: Dictionary = {
	NO_NAME = &"No name found",
	SOCIAL_ANXIETY = &"Has social anxiety",
}
"""
This example shows ways to do custom errors and reporting
See:
- Result::is_ok(), is_err()
- Result::matches(), matches_err()
- Result::unwrap_unchecked()
"""
func example_custom_errors():
	# 1. Using match/if statements
	var res1: Result = Result.Err(PrintError.NOT_ENOUGH_INK)
	# var res1: Result = Result.Ok("success")
	if res1.is_ok():
		match res1.unwrap_unchecked():
			"success":
				print("Print successful!")
	else:
		match res1.unwrap_unchecked():
			PrintError.NOT_ENOUGH_PAPER:
				push_warning("Failed to print: Not enough paper!")
			PrintError.NOT_ENOUGH_INK:
				push_warning("Failed to print: The printer gods demand ink...")
	
	# 2. Using  Result.matches_err()
	# You could also use  Result.is_err_and()  for more complex operations
	if res1.matches("success"):
		print("Print successful!")
	elif res1.matches_err(PrintError.NOT_ENOUGH_PAPER):
		push_warning("Failed to print: Not enough paper!")
	elif res1.matches_err(PrintError.NOT_ENOUGH_INK):
		push_warning("Failed to print: The printer gods demand ink...")
	
	# 3. If you use the const Dictionary approach:
	var res2: Result = Result.Err(GreetError.NO_NAME)
	# var res2: Result = Result.Ok("Hello, world!")
	if res2.is_ok():
		print("Greeting message: ", res2.unwrap_unchecked())
	else:
		push_warning("Failed to greet user: ", res2.unwrap_unchecked())
	
	# 4. The tryhard
	var res3: Result = Result.Err(GreetError.NO_NAME)\
		.as_report(func(r: Report):
			return r.msg("Failed to greet user")\
				.cause( error_string(ERR_CANT_CONNECT) )
			)\
		.report(Report.LogLevel.WARNING)
		# See what happens if log level is CRASH instead
		# .report(Report.LogLevel.CRASH)

#endregion Using Results



#region Meta

func _ready():
	for method in get_method_list():
		var method_name: String = method.name
		if method_name.begins_with("example_"):
			add_example(method_name, method_name.trim_prefix("example_"))
		elif method_name.begins_with("test_"):
			add_example(method_name, method_name.trim_prefix("test_"))
		elif method_name.begins_with("demo_"):
			add_example(method_name, method_name.trim_prefix("demo_"))


func add_example(method_name: String, display: String):
	var btn = Button.new()
	btn.text = display
	btn.pressed.connect(run_example.bind(method_name) )
	$GridContainer.add_child(btn)


func run_example(method_name: String):
	print("\n----------------\n")
	print('Running example "%s"' % method_name)
	call(method_name)

#endregion
