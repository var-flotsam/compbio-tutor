# Runs a student's script in a fresh R process and saves its `answer` object as
# text for the grader. Started by `grade --from-script`, from the course folder:
#   Rscript answer_runner.R work/<id>.R <output file>
# Exit status 3 means the script ran but made no `answer`.
args <- commandArgs(trailingOnly = TRUE)
student <- new.env()
invisible(utils::capture.output(source(args[1], local = student)))
if (!exists("answer", envir = student, inherits = FALSE)) quit(status = 3)
value <- get("answer", envir = student)
if (is.factor(value)) value <- as.character(value)
value <- unname(unlist(value))
writeLines(paste(as.character(value), collapse = ", "), args[2])
