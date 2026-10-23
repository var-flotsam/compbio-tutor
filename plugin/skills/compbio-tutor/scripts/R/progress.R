# Per-student progress, stored as a plain-text DCF file in the course folder.

default_seed <- 1L
progress_fields <- c("seed", "attempts", "hints_used", "solved", "revealed", "last_code")

# The tutor reads and writes only inside the course folder: the folder the
# student started Claude Code in, which is R's working directory.
course_dir <- function() normalizePath(getwd(), winslash = "/")

# Remove "." and ".." segments from an absolute path without touching the disk.
collapse_dots <- function(path) {
  out <- character(0)
  for (part in strsplit(path, "/", fixed = TRUE)[[1]]) {
    if (part == "..") {
      if (length(out) > 1) out <- out[-length(out)]
    } else if (part != "." && (nzchar(part) || length(out) == 0)) {
      out <- c(out, part)
    }
  }
  if (length(out) == 1) paste0(out, "/") else paste(out, collapse = "/")
}

# TRUE if `path` (existing or not) resolves to somewhere inside the course folder.
inside_course <- function(path) {
  path <- path.expand(path)
  if (!grepl("^([/\\\\]|[A-Za-z]:)", path)) path <- file.path(getwd(), path)
  full <- collapse_dots(gsub("\\\\", "/", path))
  # Resolve symlinks in the part that exists, so a link can't lead outside.
  parent <- dirname(full)
  while (!dir.exists(parent) && dirname(parent) != parent) parent <- dirname(parent)
  rest <- substring(full, nchar(parent) + 1)
  full <- paste0(normalizePath(parent, winslash = "/"), rest)
  root <- course_dir()
  full == root || startsWith(full, paste0(sub("/$", "", root), "/"))
}

# Stops instead of touching a file outside the course folder.
course_path <- function(...) {
  path <- file.path(course_dir(), ...)
  if (!inside_course(path)) stop(sprintf("refusing to use %s: it is outside the course folder", path))
  path
}

state_dir <- function() course_path(".compbio-tutor")

# The student's own copy of a problem's starter code, and their data file.
work_path <- function(pid) course_path("work", paste0(pid, ".R"))
data_path <- function(pid, ext = "fasta") course_path("data", paste0(pid, ".", ext))

new_problem_progress <- function() {
  list(
    seed = default_seed, attempts = 0L, hints_used = 0L,
    solved = FALSE, revealed = FALSE, last_code = ""
  )
}

load_progress <- function() {
  path <- file.path(state_dir(), "progress.dcf")
  if (!file.exists(path)) return(list())
  rows <- tryCatch(read.dcf(path), error = function(err) NULL)
  ok <- !is.null(rows) && all(c("id", progress_fields) %in% colnames(rows))
  if (!ok) {
    # A damaged file shouldn't block a lesson; keep a copy and start fresh.
    file.rename(path, paste0(path, ".bad"))
    return(list())
  }
  out <- list()
  for (i in seq_len(nrow(rows))) {
    out[[rows[i, "id"]]] <- list(
      seed = as.integer(rows[i, "seed"]),
      attempts = as.integer(rows[i, "attempts"]),
      hints_used = as.integer(rows[i, "hints_used"]),
      solved = as.logical(rows[i, "solved"]),
      revealed = as.logical(rows[i, "revealed"]),
      last_code = sub("^-$", "", unname(rows[i, "last_code"]))
    )
  }
  out
}

save_progress <- function(progress) {
  dir.create(state_dir(), showWarnings = FALSE, recursive = TRUE)
  if (length(progress) == 0) return(invisible())
  rows <- do.call(rbind, lapply(names(progress), function(pid) {
    p <- progress[[pid]]
    values <- vapply(progress_fields, function(f) as.character(p[[f]]), "")
    # DCF can't store an empty value, so an empty code is written as "-".
    values[!nzchar(values)] <- "-"
    c(id = pid, values)
  }))
  tmp <- file.path(state_dir(), "progress.dcf.tmp")
  write.dcf(rows, tmp)
  file.rename(tmp, file.path(state_dir(), "progress.dcf"))
  invisible()
}

get_progress <- function(progress, pid) {
  if (is.null(progress[[pid]])) new_problem_progress() else progress[[pid]]
}
