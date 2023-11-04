class_name EnumStruct extends Object
## A class for declaring struct-like enums
##
## The aim is to have enums hold extra data with them.[br]
## In most programming languages, enums are, under the hood, represented as [int]s.[br]
## This makes them effective for simple state flags, but useless for carrying variant-specific data (similar motives to [Error])
## [br][br]
## There are a couple ways to declare [EnumStruct]s:
## [codeblock]
## # Let's declare an EnumStruct where VariantA will behave like a normal enum,
## # and VariantB will have a 'value' field (defaulting to 0)
## 
## # Using a Dictionary of StringNames
## static var MyEnum: EnumStruct = EnumStruct.new({
##     &"VariantA" : {},
##     &"VariantB" : { "value" : 0 }
## })
## 
## # Using chained methods
## static var MyEnum: EnumStruct = EnumStruct.new()\
##     .add(&"VariantA")\
##     .add(&"VariantB", { 'value' : 0 })
## [/codeblock]
## Note: Once an [EnumStruct] is initialized, you cannot change the variants of it.[br]
## Note: The variable doesn't [i]need[/i] to be a [code]static var[/code]. That is something you can decide.[br]
## [br][br]
## Usage:
## [codeblock]
## # Declare enum
## static var AnimalState: EnumStruct = EnumStruct.new()\
##     .add(&"Alive", { "is_hungry" : false })\
##     .add(&"Dead") # A dead animal can't be hungry
## 
## # There are a couple ways to get an EnumStruct variant:
## # Notice how cat_state is a Dictionary
## var cat_state: Dictionary = AnimalState.Alive
## cat_state.is_hungry = true
## # or
## var cat_state: Dictionary = AnimalState.variant(&"Alive", { "is_hungry" : true })
## 
## print(cat_state) # A bit ugly
## print( EnumStruct.stringify(cat_state) ) # Prettier
## [/codeblock]
## [br]
## The above code is the same as doing the following in Rust:
## [codeblock]
## enum AnimalState {
##     Alive{ is_hungry: bool },
##     Dead,
## }
## 
## let cat_state: AnimalState = AnimalState::Alive{ is_hungry: true };
## [/codeblock]


"""
Dictionary<StringName, Dictionary>
{
	&'VariantA' : {},
	&'VariantB' : { ... },
	...
}
"""
var _variants: Dictionary = {}


func _init(variants: Dictionary = {}):
	_variants = variants
	# This call is deferred to allow for .add() calls
	call_deferred(&"make_read_only")

func make_read_only() -> EnumStruct:
	_variants.make_read_only()
	return self

## Adds a variant to this [EnumStruct][br]
## Usage:
## [codeblock]
## static var MyEnum: EnumStruct = EnumStruct.new()\
##     .add(&"VariantA")\
##     .add(&"VariantB", { 'value' : 0 })
## [/codeblock]
## Note: You can only add variants during initialization[br]
func add(type: StringName, value: Dictionary = {}) -> EnumStruct:
	assert(!_variants.is_read_only(), "Please add variants only during initialization")
	_variants[type] = value
	return self

## Gets a variant from this [EnumStruct], with (optional) initial values
func variant(type: StringName, init_values: Dictionary = {}) -> Dictionary:
	assert(_variants.has(type))
	
	var values: Dictionary = _variants[type].duplicate(true)
	values.EnumStruct = type
	values.merge(init_values, true)
	return values

## Gets all the variants in this [EnumStruct]
func get_variant_list() -> Array[StringName]:
	return _variants.keys()
	# return _variants.keys() .map(func(key):	return StringName(key))

## Checks whether [param enum_dict] is within this [EnumStruct][br]
## Returns a [Result]<[EnumStruct], [Error]>:[br]
## - [code]Err(Error(ERR_DOES_NOT_EXIST))[/code] if this [EnumStruct] doesn't contain the variant[br]
## - [code]Err(Error(ERR_INVALID_DATA))[/code] if the variant exists but there are missing variables[br]
## - [code]Ok(enum_dict)[/code] otherwise[br]
## See [Result], [Error]
func contains(enum_dict: Dictionary) -> Result:
	assert(enum_dict.has("EnumStruct"), "Parameter enum_dict must be an EnumStruct variant")
	
	if !_variants.has(enum_dict.EnumStruct):
		return Result.newError(ERR_DOES_NOT_EXIST)\
			.err_info('variant', enum_dict.EnumStruct)\
			.err_msg("This enum does not have the specified variant")
	elif !enum_dict.has_all( _variants[enum_dict.EnumStruct].keys() ):
		return Result.newError(ERR_INVALID_DATA)\
			.err_info('expected', _variants[enum_dict.EnumStruct].keys())\
			.err_info('found', enum_dict.keys())\
			.err_msg("The enum dict is missing some paramters")
	
	return Result.Ok(enum_dict)


## Checks whether this [EnumStruct] has the specified [param variant]
func has(variant: StringName) -> bool:
	return _variants.has(variant)


func _get(property: StringName) -> Variant:
	if _variants.has(property):
		var values: Dictionary = _variants[property].duplicate(true)
		values.EnumStruct = String(property)
		return values
	return null

func _get_property_list():
	return _variants.keys()\
		.map(func(key: StringName):	return { 'name': key, 'type': TYPE_DICTIONARY })


## Turns [param enum_dict] into a prettier [String]
static func stringify(enum_dict: Dictionary) -> String:
	if !enum_dict.has("EnumStruct"):
		push_error("Parameter enum_dict must be an EnumStruct variant")
		return str(enum_dict)
	
	var values: Dictionary = enum_dict.duplicate()
	values.erase("EnumStruct")
	return '%s %s' % [ enum_dict.EnumStruct, values ]
