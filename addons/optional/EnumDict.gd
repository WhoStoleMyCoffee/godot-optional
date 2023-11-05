class_name EnumDict extends RefCounted
## A class for declaring struct-like enums
##
## The aim is to have enums hold extra data with them.[br]
## In most programming languages, enums are, under the hood, represented as [int]s.[br]
## This makes them effective for simple state flags, but useless for carrying variant-specific data (similar motives to [Error])[br]
## [br]
## [EnumDict]s work in the [b]exact same[/b] way as [EnumStruct]s, so see those further documentation[br]
## The only difference is that [EnumDict]s return Dictionaries as variants (with an extra [code]EnumDict[/code] property) instead of [EnumVariant]s, which could be useful in some cases[br]
## Whether you use [EnumStruct] or [EnumDict] is up to your preference

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

func lock() -> EnumDict:
	_variants.make_read_only()
	return self

## Adds a variant to this [EnumDict][br]
## Usage:
## [codeblock]
## static var MyEnum: EnumDict = EnumDict.new()\
##     .add(&"VariantA")\
##     .add(&"VariantB", { 'value' : 0 })
## [/codeblock]
## Note: You can only add variants during initialization[br]
func add(type: StringName, value: Dictionary = {}) -> EnumDict:
	assert(!_variants.is_read_only(), "Please add variants only during initialization")
	_variants[type] = value
	return self

## Gets a variant from this [EnumDict], with (optional) initial values
func variant(type: StringName, init_values: Dictionary = {}) -> Dictionary:
	assert(_variants.has(type))
	
	var values: Dictionary = _variants[type].duplicate(true)
	values.EnumDict = type
	values.merge(init_values, true)
	return values

## Gets all the variants in this [EnumDict]
func get_variant_list() -> Array[StringName]:
	return Array(_variants.keys(), TYPE_STRING_NAME, &"", null) # ???
	# return _variants.keys() .map(func(key):	return StringName(key))

## Checks whether [param enum_dict] is within this [EnumDict][br]
## Returns a [Result]<[EnumDict], [Error]>:[br]
## - [code]Err(Error(ERR_DOES_NOT_EXIST))[/code] if this [EnumDict] doesn't contain the variant[br]
## - [code]Err(Error(ERR_INVALID_DATA))[/code] if the variant exists but there are missing variables[br]
## - [code]Ok(enum_dict)[/code] otherwise[br]
## See [Result], [Error]
func contains(enum_dict: Dictionary) -> Result:
	assert(enum_dict.has("EnumDict"), "Parameter enum_dict must be an EnumDict variant")
	
	if !_variants.has(enum_dict.EnumDict):
		return Result.newError(ERR_DOES_NOT_EXIST)\
			.err_info('variant', enum_dict.EnumDict)\
			.err_msg("This enum does not have the specified variant")
	elif !enum_dict.has_all( _variants[enum_dict.EnumDict].keys() ):
		return Result.newError(ERR_INVALID_DATA)\
			.err_info('expected', _variants[enum_dict.EnumDict].keys())\
			.err_info('found', enum_dict.keys())\
			.err_msg("The enum dict is missing some paramters")
	
	return Result.Ok(enum_dict)


## Checks whether this [EnumDict] has the specified [param variant]
func has(variant: StringName) -> bool:
	return _variants.has(variant)


func _get(property: StringName) -> Variant:
	if _variants.has(property):
		var values: Dictionary = _variants[property].duplicate(true)
		values.EnumDict = property
		return values
	return null

func _get_property_list():
	return _variants.keys()\
		.map(func(key: StringName):	return { 'name': key, 'type': TYPE_DICTIONARY })


## Turns [param enum_dict] into a prettier [String]
static func stringify(enum_dict: Dictionary) -> String:
	if !enum_dict.has("EnumDict"):
		push_error("Parameter enum_dict must be an EnumDict variant")
		return str(enum_dict)
	
	if enum_dict.size() == 1: # If there's only EnumDict (no other values)
		return String(enum_dict.EnumDict)
	
	var values: Dictionary = enum_dict.duplicate()
	values.erase("EnumDict")
	return '%s %s' % [ enum_dict.EnumDict, values ]

