extends Control

"""
* MISCELLANEOUS EXAMPLES *

Note:
	Normally, you'd want Enum (or EnumDict) declarations to be static vars
	Here, they're not because we can't define statics inside functions
"""


"""
PLAYGROUND FOR TESTING
"""
func playground():
	print_console("See the function `func playground()`")
	print_console("Use `print_console` to print to this console!")


"""
This example demonstrates the use of TimedVars for use in combo systems
param_delay controls the time between simulated attacks; see what happens when
 it changes!
"""
func example_combo():
	var param_delay: float = 0.2
	#var param_delay: float = 0.6 # A little slow. No 'biggest slash' at the end
	#var param_delay: float = 1.5 # Too slow! No combo for you!
	
	var combo: TimedVar = TimedVar.empty() # Combo not yet started
	print_console("  combo = %s" % combo)
	
	await get_tree().create_timer( param_delay ).timeout
	# Start the combo with a slash
	print_console("SLASH!")
	combo.set_value("slash") .set_lifespan(1000) # 1s window for following combos
	print_console("  combo = %s" % combo)

	await get_tree().create_timer( param_delay ).timeout
	# Follow it up with a big slash
	if combo.get_value() .matches("slash"):
		print_console("BIG SLASH!")
		combo.set_value("slash_big")
	else:
		print_console("No big slash")
	print_console("  combo = %s" % combo)
	
	await get_tree().create_timer( param_delay ).timeout
	# End it with a biggest slash, but with a tighter timing window of 0.5s
	# Using take() (or in this case, take_timed()) takes care of finishing the
	#  combo with no loose ends
	if combo.take_timed(500) .matches("slash_big"):
		print_console("BIGGEST SLASH!!!")
	else:
		print_console("No biggest slash :(")
	print_console("  combo = %s" % combo)



#region EXPERIMENTAL

"""
This example demonstrates the usage of Enums and EnumVars
"""
func example_process():
	var ProcessStates: Enum = Enum.new()\
		.add(&"Processing", { 'percentage': 0.0 })\
		.add(&"Done") # We don't need to store percentage when done!
	
	var state: EnumVar = ProcessStates.Processing
	
	while true:
		print_console("state = %s" % state)
		
		match state.variant:
			&"Processing":
				state.percentage += 0.1
				if state.percentage >= 1.0:
					state = ProcessStates.Done
			&"Done":
				print_console("Done!")
				break

""" EXPERIMENTAL
This example demonstrates the usage of EnumDicts
Notice how pet_state is a Dictionary
"""
func example_pet_state():
	var PetState: EnumDict = EnumDict.new()\
		.add(&"Sleeping")\
		.add(&"Following", { "player": "owner" })\
		.add(&"Idle")
	
	var pet_state: Dictionary = PetState.Idle
	print_console("pet_state = %s" % pet_state) # Kind of ugly
	print_console("pet_state = %s" % EnumDict.stringify(pet_state)) # Prettier, but more verbose in code
	
	pet_state = PetState.variant(&"Following", { "player": "player2" })
	print_console("pet_state = %s" % EnumDict.stringify(pet_state))

#endregion


#region META

func print_console(string: String):
	$VSplitContainer/RichTextLabel.text += '\n' + string

func _on_button_pressed(method: String):
	print_console('\nRunning demo "%s"' % method)
	call(method)

#endregion
