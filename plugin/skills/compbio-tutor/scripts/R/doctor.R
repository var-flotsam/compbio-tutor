# Check a student's computer for everything the lessons need.
#
# Run by `tutor.R doctor`. Prints a short checklist and one next step, in plain
# language for a student new to the terminal. Base R only. If this runs at all,
# R is installed and on the PATH; the setup guide in the skill's references
# folder covers getting R itself.

min_r <- "4.3.0"
course_folder_name <- "compbio"
# Packages each track needs. Biostrings comes from Bioconductor.
needed_packages <- list("Track 1" = c("Biostrings"))
bioconductor_packages <- c("Biostrings")
cran_repo <- "https://cloud.r-project.org"

# Packages are installed into the course folder, not the student's R library,
# and a course-folder .Rprofile points R at them whenever R starts here.
library_rel <- ".compbio-tutor/library"
rprofile_marker <- "# compbio-tutor:"
rprofile_lines <- c(
  paste(rprofile_marker, "use the R packages installed in this course folder."),
  sprintf('if (dir.exists("%s")) .libPaths(normalizePath("%s"))', library_rel, library_rel)
)

check <- function(name, ok, detail, fix = "") {
  list(name = name, ok = ok, detail = detail, fix = fix)
}

os_name <- function() {
  sysname <- Sys.info()[["sysname"]]
  if (sysname == "Darwin") "macos" else if (.Platform$OS.type == "windows") "windows" else "linux"
}

r_version_check <- function(version = getRversion()) {
  shown <- as.character(version)
  if (version < min_r) {
    return(check(
      "R", FALSE, sprintf("%s is too old (need %s+)", shown, min_r),
      "install the newest R from https://cran.r-project.org/ (see the setup guide)."
    ))
  }
  check("R", TRUE, sprintf("%s (%s)", shown, os_name()))
}

folder_check <- function(cwd = getwd(), home = path.expand("~")) {
  cwd <- normalizePath(cwd, winslash = "/", mustWork = FALSE)
  home <- normalizePath(home, winslash = "/", mustWork = FALSE)
  suggestion <- file.path(home, "Documents", course_folder_name)
  is_root <- dirname(cwd) == cwd
  if (cwd == home || is_root) {
    return(check(
      "Course folder", FALSE,
      sprintf("you're working in %s, which is your home folder or a whole drive", cwd),
      sprintf(paste(
        "make a folder just for this course, such as %s, then start Claude Code from",
        "inside it (`mkdir -p` the folder, `cd` into it, run `claude`)."
      ), suggestion)
    ))
  }
  if (".claude" %in% strsplit(cwd, "/", fixed = TRUE)[[1]]) {
    return(check(
      "Course folder", FALSE, sprintf("you're inside Claude Code's own settings folder (%s)", cwd),
      sprintf("start Claude Code from a course folder such as %s instead.", suggestion)
    ))
  }
  check("Course folder", TRUE, cwd)
}

project_library <- function() course_path(".compbio-tutor", "library")

# Use only the course library (plus R's own), like the course .Rprofile does.
use_project_library <- function() {
  lib <- project_library()
  dir.create(lib, showWarnings = FALSE, recursive = TRUE)
  .libPaths(lib)
  # Keep caches that packages such as BiocManager write inside the course folder too.
  cache <- course_path(".compbio-tutor", "cache")
  Sys.setenv(R_USER_CACHE_DIR = cache, R_USER_DATA_DIR = cache, R_USER_CONFIG_DIR = cache)
  lib
}

library_check <- function() {
  path <- course_path(".Rprofile")
  if (!file.exists(path)) {
    writeLines(rprofile_lines, path)
  } else if (!any(startsWith(readLines(path, warn = FALSE), rprofile_marker))) {
    return(check(
      "Course R library", FALSE, "this folder already has its own .Rprofile",
      sprintf("add these two lines to .Rprofile (or ask your teacher):\n%s",
        paste(rprofile_lines, collapse = "\n"))
    ))
  }
  use_project_library()
  check("Course R library", TRUE, library_rel)
}

missing_packages <- function() {
  pkgs <- unlist(needed_packages, use.names = FALSE)
  pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
}

install_packages <- function(pkgs, lib = project_library()) {
  for (pkg in pkgs) {
    message(sprintf("Installing %s into %s...", pkg, library_rel))
    if (pkg %in% bioconductor_packages) {
      if (!requireNamespace("BiocManager", quietly = TRUE)) {
        utils::install.packages("BiocManager", lib = lib, repos = cran_repo)
      }
      BiocManager::install(pkg, lib = lib, update = FALSE, ask = FALSE)
    } else {
      utils::install.packages(pkg, lib = lib, repos = cran_repo)
    }
  }
}

packages_check <- function(install = FALSE) {
  missing <- missing_packages()
  if (length(missing) > 0 && install) {
    install_packages(missing)
    missing <- missing_packages()
  }
  if (length(missing) == 0) return(check("R packages", TRUE, "all installed"))
  if (install) {
    return(check(
      "R packages", FALSE, sprintf("%s did not install", paste(missing, collapse = ", ")),
      "copy the last lines of the messages above and show them to your teacher."
    ))
  }
  check(
    "R packages", FALSE, sprintf("missing %s", paste(missing, collapse = ", ")),
    "install them: run `doctor --install-packages` (it can take a few minutes)."
  )
}

# Stops at the first failure, so nothing is written until the folder is right.
# Cloud sessions (Claude Code on the web or the mobile app) throw files away when
# they end, so a student's work there is lost unless it is committed to git.
where_check <- function(remote = Sys.getenv("CLAUDE_CODE_REMOTE")) {
  if (identical(tolower(remote), "true")) {
    return(check(
      "Where Claude runs", FALSE, "a cloud session, which deletes your files when it ends",
      "run the lessons in Claude Code on your own computer (terminal, desktop app or VS Code)."
    ))
  }
  check("Where Claude runs", TRUE, "this computer")
}

# The course is built for Positron: the student writes R there with Claude Code in
# a side panel. The Claude desktop app can't sit beside the student's code, so it
# is sent to Positron; a plain terminal still works as a fallback.
editor_check <- function(entrypoint = Sys.getenv("CLAUDE_CODE_ENTRYPOINT"),
                         env_names = names(Sys.getenv())) {
  name <- "Where you write R"
  if (entrypoint %in% c("claude-desktop", "claude-desktop-3p", "local-agent")) {
    return(check(
      name, FALSE, "the Claude desktop app, which can't sit next to your R code",
      paste(
        "install Positron and open this course folder in it, then use Claude Code in",
        "Positron's side panel (guide getting-started, steps 2-3)."
      )
    ))
  }
  if (identical(entrypoint, "claude-vscode")) {
    in_positron <- any(startsWith(env_names, "POSITRON"))
    where <- if (in_positron) "Positron" else "an editor panel (Positron or VS Code)"
    return(check(name, TRUE, where))
  }
  check(name, TRUE, "a terminal; Positron is recommended (guide getting-started, step 2)")
}

run_doctor <- function(install_packages = FALSE, cwd = getwd()) {
  steps <- list(
    where_check, r_version_check, editor_check, function() folder_check(cwd), library_check,
    function() packages_check(install_packages)
  )
  checks <- list()
  for (step in steps) {
    result <- step()
    if (is.null(result)) next
    checks[[length(checks) + 1]] <- result
    if (!result$ok) break
  }
  checks
}

render_doctor <- function(checks) {
  lines <- c("compbio-tutor setup check", "")
  for (ch in checks) {
    lines <- c(lines, sprintf("[%s] %s: %s", if (ch$ok) "ok" else "!!", ch$name, ch$detail))
  }
  failing <- Filter(function(ch) !ch$ok, checks)
  lines <- c(lines, "", if (length(failing) == 0) {
    "Everything is ready. Next step: start the first lesson."
  } else {
    sprintf("Next step (%s): %s", failing[[1]]$name, failing[[1]]$fix)
  })
  paste(lines, collapse = "\n")
}
