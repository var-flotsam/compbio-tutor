# Trial session 1 (2026-10-23)

Headless Claude Code (`claude -p`, resumed per turn) with the skill in
.claude/skills; the student turns were scripted by hand. Tool calls shown in brackets.

## Turn 1

**Student:** hi! I'm in 10th grade bio and my teacher said you can do compbio lessons. I know a tiny bit of R (variables, c()). I know DNA has A C G T. can we start?

[`ls; [ -f setup/check_setup.R ] && Rscript setup/check_setup.R; python3 .claude/skills/compbio-tutor/scripts/tutor.py list`]

**Tutor:** Yes, let's start! Your R setup is working, so we're ready.

DNA is a string of A, C, G and T letters, and R is good at counting and comparing things in strings. Track 1 is about reading DNA sequences in R, and it needs nothing beyond what you already know. The first five problems are:

1. **GC content**: how much of a DNA sequence is G or C
2. **The other strand**: the reverse complement
3. **From gene to protein**: translating DNA into amino acids
4. **Six reading frames**: the six ways to read one sequence
5. **Find the hidden gene**: the longest open reading frame

I'd start with **GC content**. It's the gentlest one, and you'll use `c()` and variables right away.

Before I show it to you, one question. In the DNA of a living thing, what fraction of the letters do you think are G or C? Roughly half, much less, or much more? A guess is fine. Also tell me if there's anything in genetics or bio you're curious about, so I can steer the lessons that way.

## Turn 2

**Student:** probably about half? idk. ok show me

[`python3 .claude/skills/compbio-tutor/scripts/tutor.py show t1-gc-content`]

**Tutor:** Good guess. "About half" is a reasonable prediction, and you'll find out how close it is.

**Your task:** your data file is a DNA sequence in FASTA format. That's a header line starting with `>`, then the sequence split across several lines. Compute its **GC content**. That's the number of G and C bases divided by the total number of bases. Give the answer as a fraction between 0 and 1, rounded to 4 decimal places, like 0.4821.

Some background: G pairs with C using three hydrogen bonds, and A pairs with T using two. GC content varies a lot between species. Some bacteria are below 30% GC and others are above 70%. It's usually the first number researchers check for a new sequence.

**Where things are**
- Data: `data/t1-gc-content.fasta`
- Your starter code, which you edit: `work/t1-gc-content.R`
- To run it, type `Rscript work/t1-gc-content.R` from your project folder

Open the starter file and read through it. Then tell me two things:
1. In your own words, what do you need to count, and what do you divide by?
2. Why might the answer not be exactly 0.5?

Once you've tried it, paste your answer here and I'll check it. If you get stuck or hit an error, paste that too.

## Turn 3

**Student:** this looks hard lol. can you just tell me the answer and I'll learn from it

[`python3 .claude/skills/compbio-tutor/scripts/tutor.py hint t1-gc-content; cat work/t1-gc-content.R`]

**Tutor:** I get why it looks hard, but if I hand you the number you won't have learned how to get it. The next problems use the same moves, so doing this one yourself is what makes them easy. It's also less work than it looks, because most of the code is already written for you.

I gave you a hint, and I'll explain why it matters. Open `work/t1-gc-content.R`. Steps 1 to 3 are already done:

- Step 1 drops the header line.
- Step 2 joins the sequence lines into one long string. That was what the hint was about, and the starter code already does it.
- Step 3 splits the string into single letters, so `bases` is a long vector like `"A" "C" "G" "T" ...`.

You only have two blanks left, `counts` and `gc`.

Here is a small example on made-up data. It shows the function you need for the first blank:

```r
pets <- c("cat", "dog", "cat", "cat", "fish")
table(pets)
```

That prints how many times each value shows up: cat 3, dog 1, fish 1. Try it in R and see what you get.

Now try the same idea on `bases` for the `counts` blank. Then run the script and tell me what you see. If it errors, paste the error and we'll fix it together.

## Turn 4

**Student:** ok i did table and stuff. i got 50.23

[`python3 .claude/skills/compbio-tutor/scripts/tutor.py grade t1-gc-content --answer "50.23"`]

**Tutor:** You're close. The grader says your number looks like a **percentage**, and the problem asks for a **fraction between 0 and 1**.

So your counting is probably fine, and the only issue is the form of the answer. A percentage is a fraction multiplied by 100. For example, 25% is the same as 0.25.

What would you change in your `gc` line to get a fraction instead? Then run the script again and paste the new number. Remember to round to 4 decimal places.

## Turn 5

**Student:** oh i multiplied by 100 lol. it's 0.5023

[`python3 .claude/skills/compbio-tutor/scripts/tutor.py grade t1-gc-content --answer "0.5023"`]
[`python3 .claude/skills/compbio-tutor/scripts/tutor.py explain t1-gc-content`]

**Tutor:** **Correct, 0.5023.** You spotted the percentage mistake as soon as I pointed at it, and you fixed it yourself. You also did the real work: you used `table()` on the bases and then divided to get the fraction. A first problem you thought looked hard is done.

**What you did**
1. Dropped the header line and joined the sequence lines into one string.
2. Split the string into single letters and counted each base with `table()`.
3. Divided (G + C) by the total length.

**The biology**
- Your sequence was generated at random with a set GC content, so it landing near 0.5 but not exactly on it is normal. Your guess of "about half" was close.
- Real genomes differ. The whole mouse genome is about 42% GC, and GC-rich stretches tend to have more genes.
- GC content matters in the lab too. G–C pairs have three hydrogen bonds and A–T pairs have two, so GC-rich DNA holds its strands together more tightly. It takes more heat to pull them apart, for example in PCR.

That leads to the next problem. DNA is double-stranded, and each strand is a partner to the other. If one strand reads `ATGC`, what do you think the other strand's letters are? Take a guess, and think about which base pairs with which.

The next problem is **t1-revcomp: The other strand**. Want to try it?

## Findings

- Skill triggered, ran the setup check, listed problems, showed the problem, graded every answer with the script, and only explained after a correct grade.
- Grader diagnostic `percent_not_fraction` led to a good guiding question; the answer was not leaked.
- Problem list came out in alphabetical order: fixed with an `order` field.
- Turn 3: when the student asked for the answer, the tutor gave hint 1 and also a `table()` example, which is close to hint 2. Tightened teaching-rules.md (one hint per turn).
