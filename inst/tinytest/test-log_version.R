local({
  expect_equal(
    log_version(),
    as.character(utils::packageVersion("autometric"))
  )
})
