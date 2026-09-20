extends GdUnitTestSuite

## Proves HU SDK-11: the model contract covers the whole catalog, ModelLoader checks
## a model against it, and a component always builds, falling back to its primitive
## placeholder when the realistic model is missing or invalid.


func _model_with(node_names: Array) -> Node3D:
	var root := Node3D.new()
	for node_name: String in node_names:
		var child := Node3D.new()
		child.name = node_name
		root.add_child(child)
	return auto_free(root)


func test_contract_covers_exactly_the_catalog_types() -> void:
	assert_array(ModelLoader.contract().keys()).contains_exactly_in_any_order(
		ComponentCatalog.component_types()
	)


func test_every_contract_entry_lists_pins_and_an_extent_range() -> void:
	for component_type: String in ModelLoader.contract():
		var entry: Dictionary = ModelLoader.contract()[component_type]
		assert_array(entry["pins"]).is_not_empty()
		assert_array(entry["extent_m"]).has_size(2)


func test_model_with_every_pin_and_part_is_valid() -> void:
	var model := _model_with(["PIN_anode", "PIN_cathode", "STATE_Lens"])

	assert_array(ModelLoader.validate(model, "led")).is_empty()


func test_validate_finds_pins_and_parts_nested_below_the_root() -> void:
	var model := _model_with(["PIN_anode", "PIN_cathode"])
	var body := Node3D.new()
	body.name = "Body"
	model.add_child(body)
	var lens := Node3D.new()
	lens.name = "STATE_Lens"
	body.add_child(lens)

	assert_array(ModelLoader.validate(model, "led")).is_empty()


func test_validate_reports_a_missing_pin() -> void:
	var model := _model_with(["PIN_anode", "STATE_Lens"])

	assert_array(ModelLoader.validate(model, "led")).contains_exactly(["missing PIN_cathode"])


func test_validate_reports_a_missing_part() -> void:
	var model := _model_with(["PIN_anode", "PIN_cathode"])

	assert_array(ModelLoader.validate(model, "led")).contains_exactly(["missing STATE_Lens"])


func test_validate_reports_an_unknown_pin() -> void:
	var model := _model_with(["PIN_anode", "PIN_cathode", "PIN_gate", "STATE_Lens"])

	assert_array(ModelLoader.validate(model, "led")).contains_exactly(["unknown PIN_gate"])


func test_validate_reports_a_type_without_contract() -> void:
	var model := _model_with([])

	assert_array(ModelLoader.validate(model, "not_a_real_type")).has_size(1)


func test_load_model_returns_null_when_there_is_no_model_file() -> void:
	assert_object(ModelLoader.load_model("not_a_real_type")).is_null()


func test_every_component_builds_with_or_without_a_model_file() -> void:
	for component_type: String in ComponentCatalog.component_types():
		var component := ComponentCatalog.build_component(component_type)

		assert_object(component).is_not_null()
		assert_str(str(component.name)).is_equal(component_type)
		auto_free(component)


func test_a_loaded_model_satisfies_the_contract() -> void:
	for component_type: String in ComponentCatalog.component_types():
		var model := ModelLoader.load_model(component_type)
		if model == null:
			continue  # No model file for this type yet: the catalog uses the fallback.
		auto_free(model)

		assert_array(ModelLoader.validate(model, component_type)).is_empty()
