test_that("numeric grader: tolerance, diagnostics and bad input", {
  exp <- expected(0.4821, list(diagnostic("percent_not_fraction", 48.21, "pct", tolerance = 0.01)))
  expect_equal(grade_numeric("0.48214", exp, tolerance = 1e-4)$status, "correct")
  v <- grade_numeric("0.5", exp, tolerance = 1e-4)
  expect_equal(c(v$status, v$code), c("incorrect", "wrong_value"))
  expect_false(grepl("0.48", v$message))
  expect_equal(grade_numeric("48.2", exp, tolerance = 1e-4)$code, "percent_not_fraction")
  for (bad in c("", "abc", "48%", "nan", "Inf", "1/2")) {
    expect_error(grade_numeric(bad, exp, tolerance = 1e-4), class = "answer_format_error")
  }
})

test_that("exact grader", {
  expect_equal(grade_exact("  chromosome   16 ", expected("Chromosome 16"))$status, "correct")
  expect_equal(grade_exact("HUNK", expected("Hunk"), case_sensitive = TRUE)$status, "incorrect")
  exp <- expected("Hunk", list(diagnostic("human_symbol", "HUNK-human", "m")))
  expect_equal(grade_exact("hunk-human", exp)$code, "human_symbol")
  expect_error(grade_exact("   ", expected("x")), class = "answer_format_error")
})

test_that("sequence grader", {
  exp <- expected("ATGCC", list(diagnostic("reverse_not_complement", "CCGTA", "rev")))
  expect_equal(grade_sequence("atg\n cc", exp, "dna")$status, "correct")
  expect_equal(grade_sequence("1 ATG\n4 CC", exp, "dna")$status, "correct")
  expect_equal(grade_sequence("CCGTA", exp, "dna")$code, "reverse_not_complement")
  expect_equal(grade_sequence("ATGC", exp, "dna")$code, "wrong_length")
  v <- grade_sequence("ATGCA", exp, "dna")
  expect_equal(v$code, "mismatch")
  expect_equal(v$details$first_mismatch, 5)
  expect_false(grepl("ATGCC", v$message))
  expect_error(grade_sequence("ATGXC", exp, "dna"), "X", class = "answer_format_error")
  expect_equal(grade_sequence("mkv", expected("MKV"), "protein")$status, "correct")
  expect_error(grade_sequence("MKB", expected("MKV"), "protein"), class = "answer_format_error")
})

test_that("set grader", {
  exp <- expected(c("+1", "-2"))
  expect_equal(grade_set("-2, +1", exp)$status, "correct")
  v <- grade_set("+1", exp)
  expect_equal(c(v$status, v$details$missing, v$details$extra), c("partial", 1, 0))
  expect_equal(grade_set("+3", exp)$status, "incorrect")
  exp2 <- expected(c("+1", "-2"), list(diagnostic("forward_only", "+1", "m")))
  expect_equal(grade_set("+1", exp2)$code, "forward_only")
  expect_error(grade_set(" , ", exp), class = "answer_format_error")
})

test_that("choice grader", {
  exp <- expected("B")
  expect_equal(grade_choice("(b)", exp, options = c("A", "B", "C", "D"))$status, "correct")
  expect_equal(grade_choice("A", exp, options = c("A", "B", "C", "D"))$status, "incorrect")
  expect_error(grade_choice("E", exp, options = c("A", "B")), class = "answer_format_error")
})

test_that("interval grader", {
  exp <- expected(interval("16", 88, 92))
  expect_equal(grade_interval("chr16:88.2-91.9", exp, 0.5)$status, "correct")
  expect_equal(grade_interval("1:88-92", exp, 0.5)$code, "wrong_chromosome")
  expect_equal(grade_interval("16:89.5-90.5", exp, 0.5)$code, "interval_too_narrow")
  expect_equal(grade_interval("16:80-100", exp, 0.5)$code, "interval_too_wide")
  expect_equal(grade_interval("16:89-93", exp, 0.5)$code, "interval_shifted")
  expect_equal(grade_interval("16:10-20", exp, 0.5)$code, "no_overlap")
  for (bad in c("16", "16:92-88", "sixteen:1-2", "88-92")) {
    expect_error(grade_interval(bad, exp, 0.5), class = "answer_format_error")
  }
})

test_that("ranking grader", {
  exp <- expected(c("Hunk", "Zfp148", "Ptpn18", "Other"))
  expect_equal(grade_ranking("zfp148, hunk, x", exp, top_k = 2)$status, "correct")
  expect_equal(grade_ranking("zfp148, hunk", exp, top_k = 2, ordered = TRUE)$status, "partial")
  expect_equal(grade_ranking("a, b", exp, top_k = 2)$status, "incorrect")
  expect_error(grade_ranking("hunk", exp, top_k = 2), class = "answer_format_error")
})
