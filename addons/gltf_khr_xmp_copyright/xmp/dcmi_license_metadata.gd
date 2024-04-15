@tool
## Stores DCMI XMP license info and metadata as defined by Khronos and DCMI.
## List of elements: http://purl.org/dc/elements/1.1/
## https://github.com/KhronosGroup/glTF/tree/main/extensions/2.0/Khronos/KHR_xmp_json_ld
class_name DCMILicenseMetadata
extends XMPMetadataBase

# TODO: On export: format

const CONTEXT_URL: String = "http://purl.org/dc/elements/1.1/"

@export_group("License")
## License name. Examples: "MIT License", "CC BY-SA 4.0", "All Rights Reserved"
@export_placeholder("Ex: MIT, BSD, CC0, etc") var rights: String = ""
## Primary authors. Example: John Smith <jsmith@email.com>
@export var creator: PackedStringArray = []
## Secondary authors. Example: John Smith <jsmith@email.com>
@export var contributor: PackedStringArray = []
## Company names. Example: Smith Co.
@export var publisher: PackedStringArray = []

@export_group("Content")
## Example: Rainbow Godette Model
@export_placeholder("Name of this GLTF file") var title: String = ""
## Example: Detailed Godette model with added sunshine, lollipops, and rainbows.
@export_placeholder("Description of this GLTF file") var description: String = ""
## Examples: Architecture, Automotive, Botany
@export var subject: PackedStringArray = []
## Examples: Character, Building, Vehicle, Plant, Prop
@export var type: PackedStringArray = []

@export_group("Locale")
## Location. Example: Bay Area, CA, USA
@export_placeholder("Location/area/city/country") var coverage: String = ""
## Examples: 2014-02-09, 2014-02-09T22:10:30
@export_placeholder("YYYY-MM-DD and/or hh:mm:ss") var date: String = ""
## ISO 639-2 code (ex: en), ISO 639-3 code (ex: eng), or culture ID (ex: en_US).
@export_placeholder("en, eng, en_US, etc") var language: String = ""

@export_group("Reference")
## Example: ISBN-13:978-0802144423
@export_placeholder("DOI, ISBN, URN, etc") var identifier: String = ""
## Example: https://your.website/file.glb
@export_placeholder("URL to this GLTF on the web") var source: String = ""
## Websites. Example: https://godotengine.org/
@export var relation: PackedStringArray = []


func to_dictionary() -> Dictionary:
	var dcmi_dict: Dictionary = _dcmi_properties_to_dictionary()
	if dcmi_dict.is_empty():
		# If there was no data, don't add @context, just return an empty dict.
		return dcmi_dict
	var ret: Dictionary = {
		"@context": {
			"dc": "http://purl.org/dc/elements/1.1/",
		},
		"@id": "",
	}
	ret.merge(dcmi_dict)
	return ret


func _dcmi_properties_to_dictionary() -> Dictionary:
	var dcmi_dict: Dictionary = {}
	if not contributor.is_empty():
		dcmi_dict["dc:contributor"] = { "@set": contributor }
	if not coverage.is_empty():
		dcmi_dict["dc:coverage"] = coverage
	if not creator.is_empty():
		dcmi_dict["dc:creator"] = { "@list": creator }
	if not date.is_empty():
		dcmi_dict["dc:date"] = date
	if not description.is_empty():
		dcmi_dict["dc:description"] = description
	if not identifier.is_empty():
		dcmi_dict["dc:identifier"] = identifier
	if not language.is_empty():
		dcmi_dict["dc:language"] = language
	if not publisher.is_empty():
		dcmi_dict["dc:publisher"] = { "@set": publisher }
	if not relation.is_empty():
		dcmi_dict["dc:relation"] = { "@set": relation }
	if not rights.is_empty():
		dcmi_dict["dc:rights"] = rights
	if not source.is_empty():
		dcmi_dict["dc:source"] = source
	if not subject.is_empty():
		dcmi_dict["dc:subject"] = { "@set": subject }
	if not title.is_empty():
		dcmi_dict["dc:title"] = title
	if not type.is_empty():
		dcmi_dict["dc:type"] = { "@set": type }
	return dcmi_dict


static func from_dictionary(xmp_packet: Dictionary) -> XMPMetadataBase:
	var context_url: String = xmp_packet["@context"]["dc"]
	if context_url != DCMILicenseMetadata.CONTEXT_URL:
		push_warning("GLTF KHR XMP: DCMI metadata had a URL of '" + context_url + "' but expected '" + DCMILicenseMetadata.CONTEXT_URL + "'. Attempting to parse anyway.")
	var ret := DCMILicenseMetadata.new()
	ret.xmp_json_ld = xmp_packet
	_dcmi_properties_from_dictionary(ret, xmp_packet)
	return ret


const _SINGLE_VALUES: PackedStringArray = ["coverage", "date", "description", "identifier", "language", "rights", "source", "title"]
const _ARRAY_VALUES: PackedStringArray = ["contributor", "creator", "publisher", "relation", "subject", "type"]

static func _dcmi_properties_from_dictionary(dcmi_data: DCMILicenseMetadata, xmp_packet: Dictionary) -> void:
	for single_value_name in _SINGLE_VALUES:
		var dcmi_prefixed: String = "dc:" + single_value_name
		if xmp_packet.has(dcmi_prefixed):
			var extracted = extract_single_value_from_json_ld(xmp_packet[dcmi_prefixed])
			dcmi_data.set(single_value_name, String(extracted))
	for array_value_name in _ARRAY_VALUES:
		var dcmi_prefixed: String = "dc:" + array_value_name
		if xmp_packet.has(dcmi_prefixed):
			var extracted = extract_array_from_json_ld(xmp_packet[dcmi_prefixed])
			dcmi_data.set(array_value_name, PackedStringArray(extracted))
