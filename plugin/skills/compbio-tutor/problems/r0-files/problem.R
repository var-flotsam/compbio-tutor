# Problem definition, read by the tutor with sys.source(). Lesson text: CC BY 4.0.
problem <- list(
  id = "r0-files",
  track = 0L,
  order = 5L,
  title = "Reading a sequence file",
  goal = "Read a FASTA file, keep only the sequence lines, and join them with paste().",
  dataset = "r0.fasta_lines",
  answer = "r0.total_bases",
  starter = "starter.R",
  answer_format = "a whole number (for example 312)",
  background = r"(DNA sequences are usually shared as FASTA files. A FASTA file starts with a
header line that begins with `>` and describes the sequence. The sequence itself
follows, wrapped over several lines so they don't get too long.

- `readLines(file)` gives one string per line, header included.
- `startsWith(x, ">")` is TRUE for lines that begin with `>`.
- `!` flips TRUE and FALSE, so `x[!startsWith(x, ">")]` keeps the other lines.
- `paste(x, collapse = "")` glues a vector of strings into one string.

R looks for `data/r0-files.fasta` starting from the working directory: the folder
R is running in, which for these lessons is your course folder.)",
  prompt = r"(How many bases long is the sequence in your FASTA file?

Before you count, open the file and look: how many lines are there, and which ones
hold bases?)",
  grader = list(kind = "numeric", tolerance = 0),
  hints = c(
    "Print `lines` and `length(lines)`. Which line is the header?",
    "Keep only the lines that don't start with '>'. Then join them into one string with paste(..., collapse = \"\").",
    "nchar() on the joined string gives the number of bases."
  )
)
