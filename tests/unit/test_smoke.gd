extends GdUnitTestSuite


# Placeholder so CI has a real pass/fail signal before SDK-03/SDK-04 land the
# circuit graph and rules engine tests.
func test_ci_smoke() -> void:
	assert_bool(true).is_true()
