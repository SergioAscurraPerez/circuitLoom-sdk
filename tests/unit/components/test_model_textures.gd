extends GdUnitTestSuite

## Web builds download every model texture before the first scene, so each one is
## imported at 1024 px or less (`process/size_limit` in its .import keeps the source).

const MODELS_DIR := "res://addons/circuitloom_sdk/models/"
const MAX_SIZE := 1024


func test_model_textures_import_at_most_1024_px() -> void:
	var textures := 0
	for file_name in ResourceLoader.list_directory(MODELS_DIR):
		if file_name.get_extension() != "png":
			continue
		textures += 1
		var texture := load(MODELS_DIR + file_name) as Texture2D
		assert_object(texture).is_not_null()
		(
			assert_int(maxi(texture.get_width(), texture.get_height()))
			. override_failure_message(
				"%s is %dx%d" % [file_name, texture.get_width(), texture.get_height()]
			)
			. is_less_equal(MAX_SIZE)
		)
	assert_int(textures).is_greater(0)
