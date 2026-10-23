# The tutor's command line. `tutor.R` sources this file and calls tutor_main().
# Everything printed is safe to show the student: no command prints an expected
# answer except `explain` once its conditions are met.

usage <- paste(
  "Usage: Rscript tutor.R <verb> [problem-id] [options]",
  "",
  "  doctor [--install-packages]   check this computer is ready for the lessons",
  "  list                          problems by track",
  "  show <id>                     the problem, its data file and starter code",
  "  dataset <id> [--seed N]       a new dataset for a fresh attempt",
  "  grade <id> --from-script work/<id>.R  run the student's script and check its `answer`",
  "  grade <id> --answer TEXT      check a typed answer (or --answer-file PATH)",
  "  hint <id>                     the next hint",
  "  explain <id> [--student-asked]  the worked explanation, when allowed",
  "  progress                      attempts, hints and status per problem",
  "  guide [name]                  print one of the tutor's guides (no name: list them)",
  sep = "\n"
)

json_escape <- function(x) {
  x <- gsub("\\", "\\\\", x, fixed = TRUE)
  x <- gsub("\"", "\\\"", x, fixed = TRUE)
  x <- gsub("\n", "\\n", x, fixed = TRUE)
  x <- gsub("\t", "\\t", x, fixed = TRUE)
  paste0("\"", x, "\"")
}

# A flat named list of strings, numbers and logicals as pretty JSON.
to_json <- function(fields) {
  value <- function(v) {
    if (is.logical(v)) tolower(as.character(v))
    else if (is.numeric(v)) format(v, scientific = FALSE, trim = TRUE)
    else json_escape(as.character(v))
  }
  body <- vapply(names(fields), function(k) {
    sprintf("  %s: %s", json_escape(k), value(fields[[k]]))
  }, "")
  paste0("{\n", paste(body, collapse = ",\n"), "\n}")
}

# Pull `--name value` / `--name=value` options and a flag list out of args.
parse_args <- function(args) {
  positional <- character(0)
  options <- list()
  i <- 1
  while (i <= length(args)) {
    arg <- args[i]
    if (startsWith(arg, "--")) {
      parts <- strsplit(sub("^--", "", arg), "=", fixed = TRUE)[[1]]
      name <- parts[1]
      if (length(parts) > 1) {
        options[[name]] <- paste(parts[-1], collapse = "=")
      } else if (name %in% c("answer", "answer-file", "from-script", "seed")) {
        if (i == length(args)) stop(sprintf("--%s needs a value", name), call. = FALSE)
        options[[name]] <- args[i + 1]
        i <- i + 1
      } else {
        options[[name]] <- TRUE
      }
    } else {
      positional <- c(positional, arg)
    }
    i <- i + 1
  }
  list(positional = positional, options = options)
}

track_names <- c("0" = "R basics", "1" = "Sequences", "2" = "Genes and genomes",
  "3" = "Mouse genetics of insulin secretion")

ensure_dataset <- function(problem, state) {
  path <- data_path(problem$id, problem$data_ext)
  if (!file.exists(path)) {
    dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
    writeLines(make_dataset(problem, state$seed), path, sep = "")
  }
  path
}

cmd_list <- function(problems, progress) {
  track <- -1
  for (p in problems) {
    if (p$track != track) {
      track <- p$track
      name <- track_names[as.character(track)]
      cat(sprintf("\nTrack %d%s\n", track, if (is.na(name)) "" else paste(":", name)))
    }
    state <- progress[[p$id]]
    mark <- if (is.null(state)) "" else if (state$solved) "solved" else "started"
    cat(trimws(sprintf("  %-26s %s  %s", p$id, p$title, mark), "right"), "\n", sep = "")
  }
}

cmd_show <- function(problem, progress) {
  state <- get_progress(progress, problem$id)
  path <- ensure_dataset(problem, state)
  progress[[problem$id]] <- state
  save_progress(progress)
  cat(sprintf("# %s  (%s)\n\n", problem$title, problem$id))
  cat(sprintf("Learning goal: %s\n\n", problem$goal))
  cat(problem$background, "\n\n## Your task\n\n", problem$prompt, "\n\n", sep = "")
  cat(sprintf("Answer format: %s\n", problem$answer_format))
  if (length(problem$r_basics) > 0) {
    done <- vapply(problem$r_basics, function(id) isTRUE(progress[[id]]$solved), logical(1))
    cat(sprintf("R basics this uses: %s\n", paste0(
      problem$r_basics, ifelse(done, " (solved)", " (not done yet)"), collapse = ", "
    )))
  }
  cat(sprintf("Your data file: %s\n", file.path("data", basename(path))))
  if (nzchar(problem$starter)) {
    work <- work_path(problem$id)
    if (!file.exists(work)) {
      dir.create(dirname(work), showWarnings = FALSE, recursive = TRUE)
      file.copy(file.path(problem$folder, problem$starter), work)
    }
    rel <- file.path("work", basename(work))
    cat(sprintf("Starter code (your copy to edit): %s\n", rel))
    cat(sprintf("Run it from this folder with: Rscript %s\n", rel))
  }
}

cmd_dataset <- function(problem, progress, seed) {
  state <- get_progress(progress, problem$id)
  if (!is.null(seed) && seed != state$seed) {
    state <- new_problem_progress()
    state$seed <- seed
  }
  path <- data_path(problem$id, problem$data_ext)
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  writeLines(make_dataset(problem, state$seed), path, sep = "")
  progress[[problem$id]] <- state
  save_progress(progress)
  cat(sprintf("Wrote %s (seed %d).\n", file.path("data", basename(path)), state$seed))
}

cmd_grade <- function(problem, progress, answer) {
  state <- get_progress(progress, problem$id)
  # Grade against data rebuilt from the seed, so editing the file can't change the key.
  v <- grade_problem(problem, answer, make_dataset(problem, state$seed))
  if (v$status != "invalid") state$attempts <- state$attempts + 1L
  if (v$status == "correct") state$solved <- TRUE
  state$last_code <- v$code
  progress[[problem$id]] <- state
  save_progress(progress)
  cat(to_json(c(
    list(
      problem = problem$id, status = v$status, code = v$code, message = v$message,
      attempts = state$attempts, hints_used = state$hints_used,
      hints_left = length(problem$hints) - state$hints_used
    ),
    v$details
  )), "\n", sep = "")
}

cmd_hint <- function(problem, progress) {
  state <- get_progress(progress, problem$id)
  total <- length(problem$hints)
  if (state$hints_used >= total) {
    cat(sprintf(paste(
      "All %d hints are used. If the student still wants the answer, they can ask",
      "for it: run `explain %s --student-asked`.\n"
    ), total, problem$id))
    return(invisible())
  }
  state$hints_used <- state$hints_used + 1L
  progress[[problem$id]] <- state
  save_progress(progress)
  cat(sprintf("Hint %d of %d: %s\n", state$hints_used, total, problem$hints[state$hints_used]))
}

cmd_explain <- function(problem, progress, student_asked) {
  state <- get_progress(progress, problem$id)
  hints_done <- state$hints_used >= length(problem$hints)
  if (state$solved || (student_asked && hints_done)) {
    if (!state$solved) {
      state$revealed <- TRUE
      progress[[problem$id]] <- state
      save_progress(progress)
    }
    cat(readLines(file.path(problem$folder, "explanation.md"), warn = FALSE), sep = "\n")
    return(invisible())
  }
  if (student_asked) {
    cat(sprintf(paste(
      "Not yet: %d hint(s) are left. Offer the next hint (`hint %s`) and encourage",
      "another try.\n"
    ), length(problem$hints) - state$hints_used, problem$id))
  } else {
    cat(paste(
      "Not yet: the problem isn't solved. The explanation unlocks after a correct",
      "answer, or after all hints are used and the student asks for the answer.\n"
    ))
  }
}

# The tutor's own guides, printed so Claude needs no file access outside the
# course folder to read them.
cmd_guide <- function(name, guides_dir) {
  names <- sub("\\.md$", "", sort(list.files(guides_dir, "\\.md$")))
  if (is.na(name)) {
    cat("Guides:", paste(names, collapse = ", "), "\n")
    return(0L)
  }
  if (!name %in% names) {
    message(sprintf("Unknown guide '%s'. Guides: %s", name, paste(names, collapse = ", ")))
    return(1L)
  }
  cat(readLines(file.path(guides_dir, paste0(name, ".md")), warn = FALSE), sep = "\n")
  0L
}

cmd_progress <- function(problems, progress) {
  if (length(progress) == 0) {
    cat("No problems started yet.\n")
    return(invisible())
  }
  for (pid in names(progress)) {
    s <- progress[[pid]]
    title <- if (is.null(problems[[pid]])) "(unknown problem)" else problems[[pid]]$title
    status <- if (s$solved) "solved" else if (s$revealed) "answer shown" else "open"
    cat(sprintf(
      "%-26s %-12s attempts=%d hints=%d  %s\n", pid, status, s$attempts, s$hints_used, title
    ))
  }
}

# The --seed option as an integer, NULL if absent, or NA (after a message) if bad.
read_seed <- function(opts) {
  if (is.null(opts$seed)) return(NULL)
  seed <- suppressWarnings(as.integer(opts$seed))
  if (is.na(seed)) message("--seed must be a whole number")
  seed
}

# Run the student's script in a fresh R process from the course folder and return
# its `answer` object as text, or an exit status after explaining the problem.
answer_from_script <- function(path, runner = getOption("compbio.answer_runner")) {
  if (!inside_course(path) || !grepl("\\.[Rr]$", path)) {
    message("--from-script takes an R file inside the course folder, such as work/r0-variables.R")
    return(2L)
  }
  if (!file.exists(path)) {
    message(sprintf("There's no file %s yet. Run show <id> to make it.", path))
    return(1L)
  }
  out <- course_path(".compbio-tutor", "script-answer.txt")
  dir.create(dirname(out), showWarnings = FALSE)
  unlink(out)
  rscript <- file.path(R.home("bin"), if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript")
  log <- suppressWarnings(system2(
    rscript, shQuote(c(runner, path, out)), stdout = TRUE, stderr = TRUE, timeout = 120
  ))
  status <- attr(log, "status")
  if (identical(status, 3L)) {
    message(sprintf("%s ran, but it doesn't create `answer`. The last step should be `answer <- ...`.", path))
    return(1L)
  }
  if (!is.null(status) && status != 0L || !file.exists(out)) {
    message(sprintf(
      "%s stopped with an error, so there's nothing to grade yet (it doesn't count as an attempt).\n%s",
      path, paste(utils::tail(log, 6), collapse = "\n")
    ))
    return(1L)
  }
  paste(readLines(out, warn = FALSE), collapse = "\n")
}

# The student's answer from --from-script, --answer or --answer-file, or an exit
# status on error.
read_answer <- function(opts) {
  if (!is.null(opts[["from-script"]])) return(answer_from_script(opts[["from-script"]]))
  path <- opts[["answer-file"]]
  if (!is.null(path)) {
    if (!inside_course(path)) {
      message(sprintf(
        "The answer file must be inside the course folder (%s). Copy it there first.", course_dir()
      ))
      return(1L)
    }
    if (!file.exists(path)) {
      message(sprintf("Couldn't read the answer file: %s", path))
      return(1L)
    }
    return(paste(readLines(path, warn = FALSE), collapse = "\n"))
  }
  if (!is.null(opts$answer) && !isTRUE(opts$answer)) return(opts$answer)
  message("grade needs --from-script work/<id>.R, --answer TEXT or --answer-file PATH")
  2L
}

# Returns an exit status instead of quitting, so tests can call it directly.
tutor_main <- function(args, problems_dir) {
  options(compbio.answer_runner = file.path(dirname(problems_dir), "scripts", "answer_runner.R"))
  parsed <- tryCatch(parse_args(args), error = function(err) err)
  if (inherits(parsed, "error")) {
    message(conditionMessage(parsed), "\n\n", usage)
    return(2L)
  }
  verb <- parsed$positional[1]
  opts <- parsed$options
  if (is.na(verb) || verb %in% c("help", "-h")) {
    cat(usage, "\n")
    return(if (is.na(verb)) 2L else 0L)
  }
  if (verb == "guide") {
    return(cmd_guide(parsed$positional[2], file.path(dirname(problems_dir), "references")))
  }
  if (verb == "doctor") {
    cat(render_doctor(run_doctor(install_packages = isTRUE(opts[["install-packages"]]))), "\n")
    return(0L)
  }
  problems <- tryCatch(load_all(problems_dir), problem_error = function(err) err)
  if (inherits(problems, "error")) {
    message("Problem files are broken (tell the teacher): ", conditionMessage(problems))
    return(1L)
  }
  progress <- load_progress()
  if (verb == "list") {
    cmd_list(problems, progress)
    return(0L)
  }
  if (verb == "progress") {
    cmd_progress(problems, progress)
    return(0L)
  }
  if (!verb %in% c("show", "dataset", "grade", "hint", "explain")) {
    message(sprintf("Unknown command '%s'.\n\n%s", verb, usage))
    return(2L)
  }
  run_problem_verb(verb, parsed$positional[2], opts, problems, progress)
}

# show, dataset, grade, hint and explain: the verbs that act on one problem.
run_problem_verb <- function(verb, pid, opts, problems, progress) {
  if (is.na(pid) || is.null(problems[[pid]])) {
    message(sprintf(
      "Unknown problem '%s'. Known problems: %s", pid, paste(names(problems), collapse = ", ")
    ))
    return(1L)
  }
  problem <- problems[[pid]]
  switch(verb,
    show = cmd_show(problem, progress),
    dataset = {
      seed <- read_seed(opts)
      if (is.numeric(seed) && is.na(seed)) return(2L)
      cmd_dataset(problem, progress, seed)
    },
    grade = {
      answer <- read_answer(opts)
      if (is.integer(answer)) return(answer)
      cmd_grade(problem, progress, answer)
    },
    hint = cmd_hint(problem, progress),
    explain = cmd_explain(problem, progress, isTRUE(opts[["student-asked"]]))
  )
  0L
}
