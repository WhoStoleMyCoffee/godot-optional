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
	# Instead, if you want to do further handling with the broken weapon:
	# var old_weapon: Option = weapon.map_mut ... .take()


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


"""
This example demonstrates the usage of:
- Option::to_dict()
- Option::from_dict()
"""
func serialization():
	var pet_name: Option = Option.Some("Buster")
	var pet_name_dict: Dictionary = pet_name.to_dict()
	print_console("pet_name = %s" % pet_name)
	print_console("pet_name_dict = %s" % pet_name_dict)
	
	var loaded_pet_name: Result = Option.from_dict(pet_name_dict)
	print_console("loaded_pet_name = %s" % loaded_pet_name)
	
	var invalid: Result = Option.from_dict({
		"invalid_data": 12,
		"None": 0,
		"Some": "Rick"
	}) .stringify_err()
	print_console("invalid = %s" % invalid)


"""
This example demonstrates ways to handle Options
"""
func matching():
	var list: Option = Option.Some([
		"apples",
		"bananas",
		"milk",
	])
	print_console(" list = %s" % list)
	
	print_console("\nGoing shopping...")
	# Let's take `list`, leaving a None in its place
	var taken_list: Option = list.take()\
		# And add "bread"
		.map_mut(func(arr: Array):
			print_console("(Whoops, forgot to add bread!)")
			arr.append("bread")
			)
	print_console(" list = %s" % list)
	print_console(" taken_list = %s" % taken_list)
	
	if taken_list.is_some_and(func(arr: Array):	return arr.size() > 3):
		print_console("Shopping list is too long!")
		# It's okay to use unwrap_unchecked() here because we already
		# checked if it's Some
		print_console(" taken_list size = %s" % taken_list.unwrap_unchecked().size() )
	
	# Doing things this way isn't necessary
	# It's just for showcasing purposes...
	# Basically, we leave out only "milk"
	taken_list = taken_list.map(func(arr: Array):
		return arr.filter(func(str: String):	return str == "milk")
		)
	
	if taken_list.matches([ "milk" ]):
		print_console("Couldn't find only milk...")


func print_console(string: String):
	$VSplitContainer/RichTextLabel.text += '\n' + string

func _on_button_pressed(method: String):
	print_console('\nRunning demo "%s"' % method)
	call(method)
