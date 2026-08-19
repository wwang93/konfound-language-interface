test_that("structured-output schema is strict", {
  schema <- konfound_extraction_schema()
  expect_identical(schema$type, "object")
  expect_false(schema$additionalProperties)
  expect_setequal(names(schema$properties), schema$required)
  expect_false(schema$properties$evidence$items$additionalProperties)
})

test_that("response text can be found in Responses API output", {
  body <- list(output = list(list(content = list(list(
    type = "output_text",
    text = '{"outcome_type":"unknown"}'
  )))))
  expect_identical(openai_response_text(body), '{"outcome_type":"unknown"}')
})
