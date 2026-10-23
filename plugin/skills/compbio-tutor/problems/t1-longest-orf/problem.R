# Problem definition, read by the tutor with sys.source(). Lesson text: CC BY 4.0.
problem <- list(
  id = "t1-longest-orf",
  track = 1L,
  order = 5L,
  title = "Find the hidden gene",
  goal = "Find open reading frames on both strands and translate the longest one.",
  dataset = "t1.orf_dna",
  answer = "t1.longest_orf_protein",
  starter = "starter.R",
  r_basics = c("r0-functions", "r0-vectors"),
  answer_format = "the protein of the longest ORF in one-letter codes, without the stop",
  background = r"(An open reading frame (ORF) is a stretch that starts with ATG and runs, codon by
codon in the same frame, to the first stop codon. Long ORFs are good candidates for
protein-coding genes, because random DNA rarely goes long without a stop.

Finding ORFs is one of the first steps in annotating a new genome. Real gene
finders also use other clues, such as splice sites and similarity to known
proteins, but the ORF idea is the core.)",
  prompt = r"(Your data file holds a stretch of DNA with one ORF that is much longer than the
others. It could be on either strand. Find it and give its protein sequence.)",
  grader = list(kind = "sequence", alphabet = "protein"),
  hints = c(
    "An ORF can start at any ATG, in any frame, on either strand. What would you need to check for each ATG?",
    "gregexpr('ATG', s) finds every ATG position. From each one, step forward 3 bases at a time until you reach TAA, TAG or TGA.",
    "Run your ORF search on both seq and its reverse complement, keep the longest ORF, and translate it without the stop codon."
  )
)
