# Problem definition, read by the tutor with sys.source(). Lesson text: CC BY 4.0.
problem <- list(
  id = "r0-strings",
  track = 0L,
  order = 3L,
  title = "Working with text: strings",
  goal = "Read a line of text and use nchar(), substr() and toupper() on it.",
  dataset = "r0.lower_dna",
  answer = "r0.substring_upper",
  data_ext = "txt",
  starter = "starter.R",
  answer_format = "10 DNA letters in capitals, with no spaces (for example ACGTTGCAAT)",
  background = r"(In R, text is called a string and is written in quotes: "gattaca". DNA
sequences are usually stored as strings.

- `readLines(file)` reads a text file, one string per line.
- `nchar(s)` counts the characters in a string.
- `substr(s, start, stop)` cuts out the characters from position `start` to
  position `stop`, including both ends. Positions start at 1.
- `toupper(s)` turns letters into capitals, and `tolower(s)` does the reverse.

Your data file holds one DNA sequence written in lowercase letters. Some tools
write DNA in lowercase, others in capitals, so converting between the two comes
up often.)",
  prompt = r"(Give the bases from position 5 to position 14 of your sequence, in capital
letters.

How many letters should your answer have? Work it out before you run the code.)",
  grader = list(kind = "exact", case_sensitive = TRUE),
  hints = c(
    "readLines() gives you the sequence as a string. Try nchar() on it to check it worked.",
    "substr(seq, 5, 14) keeps positions 5 to 14, including both. Count the letters you get.",
    "The letters come out lowercase. Which function turns them into capitals?"
  )
)
