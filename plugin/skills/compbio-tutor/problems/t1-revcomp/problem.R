# Problem definition, read by the tutor with sys.source(). Lesson text: CC BY 4.0.
problem <- list(
  id = "t1-revcomp",
  track = 1L,
  order = 2L,
  title = "The other strand",
  goal = "Explain why DNA strands run in opposite directions, and write the reverse complement in R.",
  dataset = "t1.short_dna",
  answer = "t1.reverse_complement",
  starter = "starter.R",
  r_basics = c("r0-strings", "r0-files"),
  answer_format = "the reverse complement as one DNA sequence, written 5' to 3' (letters A, C, G, T)",
  background = r"(A DNA molecule has two strands that pair base by base: A with T, and C with G.
The strands also run in opposite directions. Each strand has a 5' end and a 3'
end, named after carbon atoms in the sugar, and the two strands point in opposite
directions, like two lanes of a road.

By convention, sequences are always written from 5' to 3'. A file holds only one
strand. If a gene sits on the other strand, you have to work out that strand's
sequence yourself, also written 5' to 3'. That sequence is called the reverse
complement.)",
  prompt = r"(Write the sequence of the other strand, 5' to 3', for the fragment in your data file.

Before you start: if the given strand starts with 5'-ATG..., what is the last base
of your answer?)",
  grader = list(kind = "sequence", alphabet = "dna"),
  hints = c(
    "Two things change when you go to the other strand. What are they?",
    "chartr('ACGT', 'TGCA', seq) swaps every base for its partner. Is that enough on its own?",
    "After swapping bases, reverse the order of the letters: split the string, use rev(), and paste it back together."
  )
)
