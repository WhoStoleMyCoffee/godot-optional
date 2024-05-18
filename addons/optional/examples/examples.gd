extends VBoxContainer


func example_foo():
	print('foo')

func example_bar():
	print('bar')



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
	print('\nRunning example "%s"' % method_name)
	call(method_name)

#endregion
