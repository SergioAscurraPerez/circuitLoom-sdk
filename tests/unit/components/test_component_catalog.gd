extends GdUnitTestSuite

## Proves HU SDK-06 acceptance criterion 1: all 10 components load into the
## scene with no broken resource references.


func test_all_ten_component_types_are_registered() -> void:
	assert_array(ComponentCatalog.component_types()).has_size(10)


func test_each_component_loads_into_the_scene_without_errors() -> void:
	for component_type in ComponentCatalog.component_types():
		var component := ComponentCatalog.build_component(component_type)
		assert_object(component).is_not_null()
		add_child(auto_free(component))
		assert_int(component.get_child_count()).is_greater(0)


func test_catalog_builds_all_ten_as_children_with_no_nulls() -> void:
	var catalog := ComponentCatalog.build()
	add_child(auto_free(catalog))

	assert_int(catalog.get_child_count()).is_equal(10)
	for child in catalog.get_children():
		assert_object(child).is_not_null()
		assert_int(child.get_child_count()).is_greater(0)


func test_unknown_component_type_returns_null() -> void:
	assert_object(ComponentCatalog.build_component("not_a_real_type")).is_null()


func test_visual_catalog_matches_the_datasheet_catalog_types() -> void:
	var text := FileAccess.get_file_as_string("res://addons/circuitloom_sdk/data/components.json")
	var data: Dictionary = JSON.parse_string(text)
	var data_types: Array = []
	for entry in data["components"]:
		data_types.append(entry["type"])

	assert_array(ComponentCatalog.component_types()).contains_exactly_in_any_order(data_types)
