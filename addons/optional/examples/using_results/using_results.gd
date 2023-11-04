extends Control

"""
* USING RESULTS *
This example shows you how to effectively use Results and Errors

Note:
	If you're in a context where performance matters more than anything,
	you may want to opt for conventional error handling

Note:
	I highly recommend reading through the generated documentation (F1 help)
	for Result and Error
"""

"""
This example demonstrates ways to handle errors using signals as a dummy
 for a method that can fail
These are way cleaner than spamming uninsightful errors in the console
"""
func handling():
	var dummy_fn: Callable = func():
		print('Dummy func called!')
	
	var res1: Result = Result.from_gderr( hidden.connect(dummy_fn) )
	print_console("First connect: " + str(res1))
	
	# The following should all fail
	print_console("Look at the debugger console for errors!")
	# Simply using godot errors
	var res2: Result = Result.from_gderr( hidden.connect(dummy_fn) ) .stringify_err()\
		.report()
	# Using custom error handling
	var res3: Result = Result.newError( hidden.connect(dummy_fn) )\
		.err_msg("Error while connecting signal: ")\
		.report()


"""
This example shows the ways to use Result to safely open and parse files
"""
func file_open():
	# Should fail because the file doesn't exist
	var res1: Result = Result.open_file("res://nonexistent_file.json", FileAccess.READ)\
		.err_msg("Failed to load file: ")
	print_console('Result 1 (should fail) = ' + str(res1))
	
	# Should succeed with Ok() containing the file content
	var res2: Result = Result.parse_json_file("res://addons/optional/examples/userdata.json")\
		.err_msg("Failed to load JSON: ")
	print_console('Result 2 (should succeed) = ' + str(res2))


"""
This example shows the usage of custom Errors and reporting
Right now, all reports are pused as errors, but I might add methods to 
 push them as warnings in the future.
"""
func custom_errors():
	# Custom error types specific to your application!
	Result.Err(Error.new( Error.ExampleError ))
	# Also supports Godot errors!
	Result.Err(Error.new( ERR_ALREADY_EXISTS ))
	
	print_console("Look at the debugger console for errors!")
	# You can also add a message, cause, and additional info to help with debugging
	Result.Err(Error.new( Error.ExampleError ))\
		.err_info('path', 'path_to_file...')\
		# Useful if you have chains of Results dependant on each other
		.err_cause( error_string(ERR_FILE_CANT_WRITE) )\
		.err_msg("Testing error reporting: ")\
		.report()
	# Result::err_info(), err_cause(), err_as_cause(), err_msg(), and report() are actually
	# wrappers of Error methods


func print_console(string: String):
	$VSplitContainer/RichTextLabel.text += '\n' + string

func _on_button_pressed(method: String):
	print_console('\nRunning demo "%s"' % method)
	call(method)
