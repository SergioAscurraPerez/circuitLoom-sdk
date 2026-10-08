extends GdUnitTestSuite

## Proves HU SDK-22: a component pack registered from outside the addon adds its
## components to ComponentCatalog, with their pins, model contract and electrical model.

const PACK_DIR := "res://examples/component_pack"


func _valid_pack() -> Dictionary:
	var text := FileAccess.get_file_as_string(PACK_DIR + "/pack.json")
	return JSON.parse_string(text)


func after_test() -> void:
	ComponentPacks.unregister_all()


func test_register_adds_namespaced_types_to_the_catalog() -> void:
	assert_array(ComponentPacks.register(PACK_DIR)).is_empty()

	assert_array(ComponentCatalog.component_types()).contains(
		["example.battery_holder_4aa", "example.rectifier_diode", "led"]
	)
	assert_str(ComponentPacks.entry("example.rectifier_diode")["display_name"]).is_equal(
		"1A Rectifier Diode"
	)


func test_register_accepts_a_trailing_slash_and_reloads() -> void:
	assert_array(ComponentPacks.register(PACK_DIR + "/")).is_empty()
	assert_array(ComponentPacks.register(PACK_DIR)).is_empty()

	assert_array(ComponentPacks.types()).has_size(2)


func test_unregister_all_leaves_only_the_built_in_types() -> void:
	ComponentPacks.register(PACK_DIR)
	ComponentPacks.unregister_all()

	assert_array(ComponentCatalog.component_types()).has_size(10)
	assert_object(ComponentCatalog.build_component("example.rectifier_diode")).is_null()


func test_missing_folder_is_reported() -> void:
	var problems := ComponentPacks.register("res://no/such/pack")

	assert_array(problems).has_size(1)
	assert_str(problems[0]).contains("no pack.json")


func test_pack_component_builds_a_placeholder_with_its_pins() -> void:
	ComponentPacks.register(PACK_DIR)

	var built := auto_free(ComponentCatalog.build_component("example.rectifier_diode")) as Node3D

	assert_str(str(built.name)).is_equal("rectifier_diode")
	assert_object(built.find_child("PIN_anode", true, false)).is_not_null()
	assert_object(built.find_child("PIN_cathode", true, false)).is_not_null()
	assert_array(ModelLoader.validate(built, "example.rectifier_diode")).is_empty()


func test_model_path_and_contract_come_from_the_pack() -> void:
	ComponentPacks.register(PACK_DIR)

	assert_str(ModelLoader.model_path("example.rectifier_diode")).is_equal(
		PACK_DIR + "/models/rectifier_diode.glb"
	)
	var contract := ComponentPacks.contract_entry("example.battery_holder_4aa")
	assert_array(contract["pins"]).contains_exactly(["pos", "neg"])
	assert_array(contract["extent_m"]).has_size(2)


func test_node_is_a_ready_circuit_graph_node() -> void:
	ComponentPacks.register(PACK_DIR)

	var node := ComponentPacks.node("example.battery_holder_4aa", "bat_1")

	assert_str(node["id"]).is_equal("bat_1")
	assert_str(node["type"]).is_equal("example.battery_holder_4aa")
	assert_str(node["electrical"]["model"]).is_equal("source")
	assert_array(node["pins"]).has_size(2)


func test_validate_accepts_the_example_pack() -> void:
	assert_array(ComponentPacks.validate(_valid_pack())).is_empty()


func test_validate_rejects_a_bad_id_and_a_missing_dimensions_source() -> void:
	var pack := _valid_pack()
	pack["id"] = "Bad.Id"
	pack["components"][0].erase("dimensions_source")

	var problems := ComponentPacks.validate(pack)

	assert_array(problems).contains(
		["id must match ^[a-z][a-z0-9_]*$", "battery_holder_4aa: dimensions_source is required"]
	)


func test_validate_rejects_terminals_that_are_not_pins() -> void:
	var pack := _valid_pack()
	pack["components"][1]["electrical"]["terminals"] = ["anode", "gate"]

	assert_array(ComponentPacks.validate(pack)).contains(
		["rectifier_diode: electrical terminal 'gate' is not a pin"]
	)


func test_validate_rejects_a_source_without_a_ground_pin() -> void:
	var pack := _valid_pack()
	pack["components"][0]["pins"][1]["role"] = "passive"

	assert_array(ComponentPacks.validate(pack)).contains(
		["battery_holder_4aa: a 'source' needs a power and a ground pin"]
	)


func test_validate_rejects_missing_electrical_values() -> void:
	var pack := _valid_pack()
	pack["components"][1]["electrical"].erase("forward_voltage_v")

	assert_array(ComponentPacks.validate(pack)).contains(
		["rectifier_diode: electrical.forward_voltage_v is required for 'diode'"]
	)


func test_invalid_pack_registers_nothing() -> void:
	var dir := "user://bad_pack"
	DirAccess.make_dir_recursive_absolute(dir)
	var pack := _valid_pack()
	pack["components"][1]["electrical"]["model"] = "transistor"
	var file := FileAccess.open(dir + "/pack.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(pack))
	file.close()

	var problems := ComponentPacks.register(dir)
	DirAccess.remove_absolute(dir + "/pack.json")

	assert_array(problems).is_not_empty()
	assert_array(ComponentPacks.types()).is_empty()


func test_same_id_from_another_folder_is_rejected() -> void:
	var dir := "user://copy_pack"
	DirAccess.make_dir_recursive_absolute(dir)
	var file := FileAccess.open(dir + "/pack.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(_valid_pack()))
	file.close()
	ComponentPacks.register(PACK_DIR)

	var problems := ComponentPacks.register(dir)
	DirAccess.remove_absolute(dir + "/pack.json")

	assert_array(problems).has_size(1)
	assert_str(problems[0]).contains("already registered")
