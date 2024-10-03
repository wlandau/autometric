test_that("Versions agree between DESCRIPTION and src/version.h", {
  expect_equal(
    log_version(),
    as.character(utils::packageVersion("autometric"))
  )
})
