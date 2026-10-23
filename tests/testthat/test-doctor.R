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

# doctor switches R to the course library; put the test session's back afterwards.
local_doctor <- function(env = parent.frame()) {
  withr::local_libpaths(.libPaths(), .local_envir = env)
  withr::local_envvar(
    R_USER_CACHE_DIR = NA, R_USER_DATA_DIR = NA, R_USER_CONFIG_DIR = NA,
    CLAUDE_CODE_REMOTE = NA, .local_envir = env
  )
}

test_that("doctor runs end to end in a course folder", {
  local_course()
  local_doctor()
  res <- run_cli("doctor")
  expect_equal(res$status, 0L)
  expect_match(res$out, "compbio-tutor setup check")
  expect_match(res$out, "[ok] R:", fixed = TRUE)
})

test_that("doctor sets up a package library inside the course folder", {
  dir <- local_course()
  local_doctor()
  run_cli("doctor")
  expect_true(dir.exists(file.path(dir, ".compbio-tutor", "library")))
  expect_equal(readLines(file.path(dir, ".Rprofile")), rprofile_lines)
  expect_equal(.libPaths()[1], normalizePath(file.path(dir, ".compbio-tutor", "library"), "/"))
  expect_true(startsWith(Sys.getenv("R_USER_CACHE_DIR"), normalizePath(dir, "/")))
  # A student's own .Rprofile is left alone; doctor says what to add.
  writeLines("options(digits = 4)", file.path(dir, ".Rprofile"))
  res <- run_cli("doctor")
  expect_match(res$out, "[!!] Course R library", fixed = TRUE)
  expect_equal(readLines(file.path(dir, ".Rprofile")), "options(digits = 4)")
})

test_that("doctor writes nothing when the folder is wrong", {
  dir <- local_course()
  local_doctor()
  checks <- run_doctor(cwd = "/")
  expect_false(checks[[3]]$ok)
  expect_length(checks, 3)
  expect_false(file.exists(file.path(dir, ".Rprofile")))
})

test_that("the course .Rprofile makes R use the course library", {
  dir <- local_course()
  local_doctor()
  run_cli("doctor")
  rscript <- file.path(R.home("bin"), "Rscript")
  out <- system2(rscript, c("-e", shQuote("cat(.libPaths()[1])")), stdout = TRUE)
  expect_equal(out, normalizePath(file.path(dir, ".compbio-tutor", "library"), "/"))
})

test_that("doctor warns in a cloud session", {
  expect_true(where_check("")$ok)
  cloud <- where_check("true")
  expect_false(cloud$ok)
  expect_match(cloud$fix, "your own computer")
})
