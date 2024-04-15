@tool
## Base class for XMP metadata. Has a property for the XMP JSON-LD, a method to
## construct a new instance, and helper methods for parsing JSON-LD, XMP, & RDF data.
## https://github.com/KhronosGroup/glTF/tree/main/extensions/2.0/Khronos/KHR_xmp_json_ld
class_name XMPMetadataBase
extends Resource


# Return these as-is. JSON-LD distinguishes lists and sets, but Godot does not.
const _VALUE_KEYS: PackedStringArray = ["@json", "@list", "@set", "@value"]

## Keeps a copy of the imported JSON-LD to allow reading or displaying it later.
var xmp_json_ld: Dictionary


## Constructs a new XMPMetadataBase class. With only the base class, no
## processing is performed, and the dictionary is copied to `xmp_json_ld`.
static func from_dictionary(xmp_dict: Dictionary) -> XMPMetadataBase:
	var ret = XMPMetadataBase.new()
	ret.xmp_json_ld = xmp_dict
	return ret


## Extracts a single data value from a JSON-LD structure (not an array or dict).
static func extract_single_value_from_json_ld(from_data: Variant) -> Variant:
	var value = extract_value_from_json_ld(from_data)
	if value is Array:
		return value[0]
	if value is Dictionary:
		return value.values()[0]
	return value


## Extracts an array value from a JSON-LD structure (not a single value or dict).
static func extract_array_from_json_ld(from_data: Variant) -> Array:
	var value = extract_value_from_json_ld(from_data)
	if value is Array:
		return value
	if value is Dictionary:
		return value.values()
	return [value]


## Extracts a data value from a JSON-LD structure.
static func extract_value_from_json_ld(from_data: Variant) -> Variant:
	if from_data is Dictionary:
		if "@type" in from_data:
			var value = from_data["@type"]
			if value == "rdf:Alt":
				return extract_value_from_rdf_xmp(from_data)
			else:
				push_warning("GLTF KHR XMP: Unrecognized value '" + value + "' for JSON-LD @type.")
		elif "@id" in from_data and from_data.size() == 1:
			return find_by_json_ld_id(from_data, from_data["@id"])
		else:
			for value_key in _VALUE_KEYS:
				if value_key in from_data:
					return from_data[value_key]
			push_warning("GLTF KHR XMP: Tried to parse JSON-LD but did not find a recognized key.")
	return from_data


## Extracts one value with the most similar language
## from a larger RDF structure inside of an XMP structure.
static func extract_value_from_rdf_xmp(from_data: Variant, desired_lang: String = "") -> Variant:
	var rdf_dict: Dictionary = extract_rdf_dict_from_rdf_xmp(from_data, desired_lang)
	return rdf_dict.get("@value", null)


## Extracts one RDF dictionary with the most similar language
## from a larger RDF structure inside of an XMP structure.
static func extract_rdf_dict_from_rdf_xmp(from_data: Variant, desired_lang: String = "") -> Dictionary:
	desired_lang = language_tag_to_culture_code(desired_lang)
	# Look through the RDF languages and find the closest matching language.
	# If only one language, or multiple match equally well, pick the first one.
	var best_dict: Dictionary
	var best_similarity: float = -1.0
	for key in from_data:
		if not key.begins_with("rdf:"):
			continue
		var rdf_dict: Dictionary = from_data[key]
		var rdf_lang: String = String(rdf_dict.get("@language", ""))
		# RDF language tags are fully lowercase, but for comparing them using
		# String similarity, it's helpful to have the country suffix uppercase.
		rdf_lang = language_tag_to_culture_code(rdf_lang)
		var similarity: float = rdf_lang.similarity(desired_lang)
		if similarity > best_similarity:
			best_dict = rdf_dict
			best_similarity = similarity
	return best_dict


## Recursively finds the JSON-LD element with the given ID.
static func find_by_json_ld_id(json_ld_container: Variant, json_ld_id: String): # -> Dictionary?:
	if json_ld_container is Dictionary:
		# If an element doesn't have "@id", it's not what we are looking for.
		# If an element ONLY has "@id" it's a reference, also not what we're
		# looking for. We want a matching "@id" with other elements too.
		if json_ld_container.size() > 1 and \
				json_ld_container.keys()[0] == "@id" and \
				json_ld_container["@id"] == json_ld_id:
			return json_ld_container
		for key in json_ld_container:
			var value: Variant = json_ld_container[key]
			var found = find_by_json_ld_id(value, json_ld_id)
			if found:
				return found
	elif json_ld_container is Array:
		for item in json_ld_container:
			var found = find_by_json_ld_id(item, json_ld_id)
			if found:
				return found
	return null


## Converts a language tag (ex: RDF "en-us") to a country code (ex: "en_US").
## This funcion helps us avoid mixing up languages and countries when using String
## similarity to compare county codes. For example, "ar" Arabic and "AR" Argentina.
static func language_tag_to_culture_code(language_tag: String) -> String:
	language_tag = language_tag.replace("-", "_")
	if not language_tag.contains("_"):
		return language_tag.to_lower()
	var split: PackedStringArray = language_tag.split("_")
	return split[0].to_lower() + "_" + split[1].to_upper()
