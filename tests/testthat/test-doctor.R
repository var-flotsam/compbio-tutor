test_that("R version check", {
  expect_true(r_version_check(package_version("4.4.1"))$ok)
  old <- r_version_check(package_version("4.1.0"))
  expect_false(old$ok)
  expect_match(old$fix, "cran.r-project.org")
})

test_that("folder check rejects the home folder, a drive root and .claude", {
  home <- withr::local_tempdir("home")
  course <- file.path(home, "Documents", "compbio")
  dir.create(course, recursive = TRUE)
  expect_true(folder_check(course, home)$ok)
  expect_false(folder_check(home, home)$ok)
  expect_match(folder_check(home, home)$fix, "mkdir -p")
  expect_false(folder_check("/", home)$ok)
  dot_claude <- file.path(home, ".claude", "x")
  dir.create(dot_claude, recursive = TRUE)
  expect_false(folder_check(dot_claude, home)$ok)
})

test_that("render shows each check and only the first fix", {
  checks <- list(
    check("R", TRUE, "4.4"),
    check("Course folder", FALSE, "home", "make a folder"),
    check("R packages", FALSE, "missing", "install them")
  )
  out <- render_doctor(checks)
  expect_match(out, "[ok] R: 4.4", fixed = TRUE)
  expect_match(out, "[!!] Course folder", fixed = TRUE)
  expect_match(out, "Next step (Course folder): make a folder", fixed = TRUE)
  expect_false(grepl("install them", out, fixed = TRUE))
  expect_match(render_doctor(checks[1]), "Everything is ready")
})

test_that("doctor runs end to end in a course folder", {
  local_course()
  res <- run_cli("doctor")
  expect_equal(res$status, 0L)
  expect_match(res$out, "compbio-tutor setup check")
  expect_match(res$out, "[ok] R:", fixed = TRUE)
})
