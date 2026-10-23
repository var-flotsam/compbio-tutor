# Problem definition, read by the tutor with sys.source(). Lesson text: CC BY 4.0.
problem <- list(
  id = "r0-functions",
  track = 0L,
  order = 6L,
  title = "Your own functions and loops",
  goal = "Write a function, use if/else, and repeat work with a for loop.",
  dataset = "r0.short_seqs",
  answer = "r0.atg_sequences",
  data_ext = "txt",
  starter = "starter.R",
  answer_format = "a whole number (for example 4)",
  background = r"(When you do the same thing many times, write it once as a function and repeat
it with a loop.

- A function: `double_it <- function(x) { x * 2 }`. Then `double_it(4)` gives 8.
- A decision: `if (x > 3) { ... } else { ... }` runs one part or the other.
- A loop: `for (s in seqs) { ... }` runs the code once for each item in `seqs`,
  with `s` holding the current item.
- `grepl("CAT", s, fixed = TRUE)` is TRUE if the text "CAT" appears anywhere in `s`.

ATG is the start codon: the three bases where most genes begin to be read into a
protein. Your data file has 12 short DNA sequences, one per line.)",
  prompt = r"(How many of the sequences contain ATG at least once?

Write a function that checks one sequence, then use a loop to check them all.
Some sequences contain ATG more than once. Does that change your answer?)",
  grader = list(kind = "numeric", tolerance = 0),
  hints = c(
    "Start with one sequence: what does grepl(\"ATG\", seqs[1], fixed = TRUE) give?",
    "Put that check in a function that takes one sequence and returns TRUE or FALSE.",
    "Start a counter at 0 before the loop. Inside the loop, add 1 when your function says TRUE."
  )
)
