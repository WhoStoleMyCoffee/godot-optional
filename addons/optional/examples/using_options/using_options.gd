extends Control

"""
* USING OPTIONS *
This example shows you how to effectively use Options

Note:
	If you're in a context where performance matters more than anything,
	you may want to opt for conventional error handling

Note:
	I highly recommend reading through the F1 help for Option
"""


"""
This example demonstrates how you might implement a weapon system
 with durability
"""
func weapon_durability():
	# See what happens at different durability levels!
	var durability: int = 2
	# var durability: int = 1
	var weapon: Option = Option.Some({ 'id' : 'sword', 'durability' : durability })
	# var weapon: Option = Option.None()
	
	print_console('Player attacked!')
	# If the player is holding a weapon
	if weapon.is_some():
		# Get the weapon data
		var w: Dictionary = weapon.unwrap_unchecked()
		w.durability -= 1
		# Weapon broke!
		if w.durability <= 0:
			# Remove the broken weapon and print it
			var old_weapon: Dictionary = weapon.take() .unwrap_unchecked()
			print_console( str(old_weapon.id) + ' broke!' )
	print_console('weapon = ' + str(weapon))
	
	# Short version
	print_console('Player attacked!')
	# Use durability if holding a weapon
	weapon.map_mut(func(w: Dictionary):	w.durability -= 1)\
		# If the weapon broke...
		.filter(func(w: Dictionary) -> bool:	return w.durability <= 0)\
		# Remove it
		.take()\
		# And print it out
		.map_mut(func(old_weapon: Dictionary):
			print_console( str(old_weapon.id) + ' broke!' )
			)
	print_console('weapon = ' + str(weapon))
	# If you want to do further handling with the broken weapon:
	# var old_weapon: Option = weapon. (...) .take()


"""
This example demonstrates the usage of:
- Option::arr_get()
- Option::map()
- Option::unwrap_or()
Option comes with a safe way to index arrays, dictionaries, and getting nodes
See Option::dict_get() and Option::get_node()
"""
func array_get():
	var array: Array = [ 'Apple', 'Banana', 'GLTFDocumentExtensionConvertImporterMesh' ]
	
	var arrget: Callable = func(i: int) -> String:
		# Option version of array[i]
		return Option.arr_get(array, i)\
			.map(func(v: String):	return 'Found ' + v)\
			.unwrap_or("Couldn't get index %s!" % i)
	
	print_console( arrget.call(0) ) # Some
	print_console( arrget.call(1) ) # Some
	print_console( arrget.call(2) ) # Some
	print_console( arrget.call(3) ) # None!


func print_console(string: String):
	$VSplitContainer/RichTextLabel.text += '\n' + string

func _on_button_pressed(method: String):
	print_console('\nRunning demo "%s"' % method)
	call(method)
