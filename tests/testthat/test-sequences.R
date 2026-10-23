test_that("genetic code and basic operations", {
  expect_length(codon_table, 64)
  expect_equal(unname(codon_table[c("ATG", "TGG", "TTT", "GGG")]), c("M", "W", "F", "G"))
  expect_setequal(names(codon_table)[codon_table == "*"], c("TAA", "TAG", "TGA"))
  expect_equal(sum(codon_table == "L"), 6)
  expect_equal(translate_dna("ATGAAAGTTTGA", to_stop = TRUE), "MKV")
  expect_equal(reverse_complement("ATGCCGTA"), "TACGGCAT")
  expect_equal(gc_fraction("GGCA"), 0.75)
})

test_that("ORF coordinates on both strands", {
  orf <- find_orfs("CCATGAAATAGCC")
  orf <- orf[orf$strand == "+", ]
  expect_equal(c(orf$start, orf$end), c(3, 11))
  expect_equal(orf$protein, "MK")
  rc <- find_orfs(reverse_complement("CCATGAAATAGCC"))
  expect_equal(c(rc$strand, rc$start, rc$end), c("-", "3", "11"))
  expect_equal(nrow(find_orfs("CCCC")), 0)
})

test_that("FASTA round trip", {
  seq <- paste(rep("ACGT", 40), collapse = "")
  expect_equal(unname(parse_fasta(to_fasta("x", seq))), seq)
  expect_error(parse_fasta("ACGT"), "header")
})
