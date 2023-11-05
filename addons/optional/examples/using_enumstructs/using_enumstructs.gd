extends Control

"""
* USING ENUMSTRUCTS *
This example shows you how to effectively use EnumStructs, EnumVariants, and EnumDicts
I recommend using EnumStruct instead of EnumDict if in doubt on which to use

Note:
	Normally, you'd want EnumStruct and EnumDict declarations to be static vars
	Here, they're not because we can't define statics inside functions

I highly recommend reading through the F1 help for EnumStruct
"""

"""
This example demonstrates the usage of EnumStructs and EnumVariants
"""
func example_process():
	var ProcessStates: EnumStruct = EnumStruct.new()\
		.add(&"Processing", { 'percentage': 0.0 })\
		.add(&"Done") # The percentage is already implied to be 100% when done
	
	var state: EnumVariant = ProcessStates.Processing
	
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

"""
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
	print_console("pet_state = %s" % EnumDict.stringify(pet_state)) # Prettier
	
	pet_state = PetState.variant(&"Following", { "player": "player2" })
	print_console("pet_state = %s" % EnumDict.stringify(pet_state))


func print_console(string: String):
	$VSplitContainer/RichTextLabel.text += '\n' + string

func _on_button_pressed(method: String):
	print_console('\nRunning demo "%s"' % method)
	call(method)
