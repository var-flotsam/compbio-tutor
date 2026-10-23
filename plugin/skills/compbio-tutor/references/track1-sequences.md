# Track 1: Sequences

Prerequisites: the Track 0 R basics each problem lists (`show` names them).
Students new to R do Track 0 first; others can pick up a basic just in time.
Track 1 adds `substring()`, `rev()`, `chartr()` and the Biostrings package.

| id | Title | Teaches |
|---|---|---|
| t1-gc-content | How much of this DNA is G or C? | Reading FASTA, counting, GC content |
| t1-revcomp | The other strand | Base pairing, 5'/3' direction, reverse complement |
| t1-translate | From gene to protein | Codons, the genetic code, start and stop |
| t1-reading-frames | Six ways to read a sequence | Reading frames on both strands |
| t1-longest-orf | Find the hidden gene | ORFs, loops in R, gene finding |

Suggested order is the table order. Each problem gives every student their own
dataset, so classmates can compare methods but not copy answers.

Bridges to track 2: genes sit on either strand (revcomp), real genes have introns
(translate), and real gene annotations come from databases such as Ensembl and MGI
(longest ORF).
