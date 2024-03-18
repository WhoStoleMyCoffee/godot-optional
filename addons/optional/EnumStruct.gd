class_name Enum extends RefCounted
## A class for declaring struct-like enums
##
## The aim is to have enums hold extra data with them.[br]
## In most programming languages, enums are, under the hood, represented as [int]s.[br]
## This makes them effective for simple state flags, but useless for carrying variant-specific data (similar motives to [Error])[br]
## See also [EnumDict], [EnumVar][br]
## [br]
## There are a couple ways to declare [Enum]Structs:
## [codeblock]
## # Let's declare an Enum where VariantA will behave like a normal enum,
## # and VariantB will have a 'value' field (defaulting to 0)
## 
## # Using a Dictionary of StringNames
## static var MyEnum: Enum = Enum.new({
##     &"VariantA" : {},
##     &"VariantB" : { "value" : 0 }
## })
## 
## # Using chained methods
## static var MyEnum: Enum = Enum.new()\
##     .add(&"VariantA")\
##     .add(&"VariantB", { 'value' : 0 })
## [/codeblock]
## Note: Once an [Enum] is initialized, you cannot change the variants of it.[br]
## [br][br]
## Usage:
## [codeblock]
## # Declare enum
## static var AnimalState: Enum = Enum.new()\
##     .add(&"Alive", { "is_hungry" : false })\
##     .add(&"Dead") # A dead animal can't be hungry
## 
## # There are a couple ways to get an Enum variant:
## var cat_state: EnumVar = AnimalState.Alive
## cat_state.is_hungry = true
## # or
## var cat_state: EnumVar = AnimalState.variant(&"Alive", { "is_hungry" : true })
## 
## print(cat_state) # Prints: Alive { "is_hungry" : true }
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
## @experimental


# Dictionary<StringName, Dictionary>
# {
# 	&'VariantA' : {},
# 	&'VariantB' : { ... },
# 	...
# }
var _variants: Dictionary = {}


func _init(variants: Dictionary = {}):
	_variants = variants
	# This call is deferred to allow for .add() calls
	call_deferred(&"lock")

func lock() -> Enum:
	_variants.make_read_only()
	return self

## Adds a variant to this [Enum][br]
## Usage:
## [codeblock]
## static var MyEnum: Enum = Enum.new()\
##     .add(&"VariantA")\
##     .add(&"VariantB", { 'value' : 0 })
## [/codeblock]
## Note: You can only add variants during initialization[br]
func add(type: StringName, value: Dictionary = {}) -> Enum:
	assert(!_variants.is_read_only(), "Please add variants only during initialization")
	_variants[type] = value
	return self

## Gets a variant from this [Enum], with (optional) initial values
func variant(type: StringName, init_values: Dictionary = {}) -> EnumVar:
	assert(_variants.has(type))
	
	var values: Dictionary = _variants[type].duplicate(true)
	values.merge(init_values, true)
	return EnumVar.new(self, type, values)

## Gets all the variants in this [Enum]
func get_variant_list() -> Array[StringName]:
	return Array(_variants.keys(), TYPE_STRING_NAME, &"", null) # ???

## Checks whether [param enum_dict] is within this [Enum][br]
## Returns a [Result]<[Enum], [Error]>:[br]
## - [code]Err(Error(ERR_INVALID_PARAMETER))[/code] if the [param enum_variant] is not from this [Enum][br]
## - [code]Err(Error([/code] [constant Error.NotContained] [code]))[/code] if this [Enum] doesn't contain the [param enum_variant][br]
## - [code]Err(Error([/code] [constant Error.MissingParameters] [code]))[/code] if the [param enum_variant] exists but there are missing parameters[br]
## - [code]Ok(enum_variant)[/code] otherwise[br]
## See [Result], [Error]
func contains(enum_variant: EnumVar) -> Result:
	if enum_variant.base_enum != self:
		return Result.error(ERR_INVALID_PARAMETER)\
			.err_info('variant', enum_variant.variant)\
			.err_msg("The variant is from a different enum")
	
	elif !_variants.has(enum_variant.variant):
		return Result.error(Error.NotContained)\
			.err_info('variant', enum_variant.variant)\
			.err_msg("This enum does not have the specified variant")
	
	elif !enum_variant.values.has_all( _variants[enum_variant.variant].keys() ):
		return Result.error(Error.MissingParameters)\
			.err_info('expected', _variants[enum_variant.variant].keys())\
			.err_info('found', enum_variant.values.keys())\
			.err_msg("The enum dict is missing some paramters")
	
	return Result.Ok(enum_variant)


## Checks whether this [Enum] has the specified [param variant]
func has(variant: StringName) -> bool:
	return _variants.has(variant)


func _get(property: StringName) -> Variant:
	if _variants.has(property):
		var values: Dictionary = _variants[property].duplicate(true)
		return EnumVar.new(self, property, values)
	return null

func _get_property_list():
	return _variants.keys()\
		.map(func(key: StringName):	return { 'name': key, 'type': TYPE_DICTIONARY })

