class_name EnumVariant extends RefCounted
## A [EnumStruct] variant
## 
## [EnumVariant]s represent the variants of an [EnumStruct].[br]
## They differ from normal enums in that they can hold extra data with them
## See also [EnumStruct][br]
## Usage:
## [codeblock]
## # Declare enum
## static var AnimalState: EnumStruct = EnumStruct.new()\
##     .add(&"Alive", { "is_hungry" : false })\
##     .add(&"Dead") # A dead animal can't be hungry
## 
## # There are a couple ways to get an EnumStruct variant:
## var cat_state: EnumVariant = AnimalState.Alive
## cat_state.is_hungry = true
## # or
## var cat_state: EnumVariant = AnimalState.variant(&"Alive", { "is_hungry" : true })
## 
## print(cat_state) # Prints: Alive { "is_hungry" : true }
## [/codeblock]
## Note: Although the properties of an [EnumVariant] are stored as a Dictionary, you are meant to set and get them like normal
## [codeblock]
## # You could do this:
## my_enum_variant.values[property] = something
## 
## # But this is the intended way:
## my_enum_variant.property = something
## # Or alternatively:
## my_enum_variant.set_value(property, something)
## [/codeblock]

## The [EnumStruct] this variant is from
var base_enum: EnumStruct # TODO remove?
var variant: StringName
var values: Dictionary = {}

func _init(base: EnumStruct, variant_: StringName, values_: Dictionary):
	base_enum = base
	variant = variant_
	values = values_


## Set a property of this [EnumVariant] and returns Self[br]
## To initialize values in bulk, you can use the [method EnumStruct.variant] method
func set_value(property: StringName, value: Variant) -> EnumVariant:
	assert(values.has(property))
	values[property] = value
	return self


func _set(property: StringName, value: Variant):
	if values.has(property):
		values[property] = value
		return true
	return false

func _get(property: StringName) -> Variant:
	# var varname: String = String(property)
	return values.get(property)

func _get_property_list():
	return values.keys()\
		.map(func(key):	return { 'name': key, 'type': typeof(values[key]) })


func _to_string() -> String:
	if values.is_empty():
		return String(variant)
	return '%s %s' % [ variant, values ]
