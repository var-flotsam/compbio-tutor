counts <- scan("data/r0-variables.txt", quiet = TRUE)
cat(sprintf("%.4f\n", round(counts[3] / sum(counts), 4)))
