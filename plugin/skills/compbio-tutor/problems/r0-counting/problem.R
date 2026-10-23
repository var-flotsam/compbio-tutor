# Problem definition, read by the tutor with sys.source(). Lesson text: CC BY 4.0.
problem <- list(
  id = "r0-counting",
  track = 0L,
  order = 4L,
  title = "Counting letters with table()",
  goal = "Split a string into letters with strsplit() and count them with table() and max().",
  dataset = "r0.count_dna",
  answer = "r0.most_common_count",
  data_ext = "txt",
  starter = "starter.R",
  answer_format = "a whole number (for example 31)",
  background = r"(Counting things is half of bioinformatics. R has two tools that make it quick:

- `strsplit(s, "")[[1]]` splits a string into a vector of single characters.
  (`strsplit` can split many strings at once and returns a list; `[[1]]` takes
  the first, and here only, item of that list.)
- `table(x)` counts how many times each different value appears in `x`.
- `max(x)` gives the largest value, `min(x)` the smallest, and `sort(x)` puts
  values in order.

Your data file holds one DNA sequence in capital letters.)",
  prompt = r"(How many times does the most common base appear in your sequence?

Guess first: if the four bases were equally common, about how many of each would
there be?)",
  grader = list(kind = "numeric", tolerance = 0),
  hints = c(
    "First turn the string into single letters with strsplit(seq, \"\")[[1]] and print a few of them with head().",
    "table() on that vector gives a count for each of A, C, G and T. Print it.",
    "You want the biggest count in the table. Which function gives the largest value?"
  )
)
