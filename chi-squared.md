---
title: "Research Question 2: The Chi-Squared Test"
teaching: 30
exercises: 15
---

:::::::::::::::::::::::::::::::::::::: questions

- Did Finnish- and Swedish-language publishing differ in what kinds of books were published?
- How do we test whether two categorical variables are associated?
- Why do p-values say little in a very large dataset?

::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives

- Build a contingency table and calculate row proportions.
- Test the association between two categorical variables with `chisq.test()`.
- Compare observed and expected counts to see where the association comes from.
- Report an effect size (Cramér's V) together with the p-value.

::::::::::::::::::::::::::::::::::::::::::::::::



**Research question 2:** *Did Finnish- and Swedish-language publishing
differ in what kinds of books were published?*

If the two languages had the same profile, the shift would be a simple
replacement: the same books, in another language. If they differ, the shift
also changed **what** was published. We start from `fennica_clean`, as in
the previous episode.

## A contingency table

We keep the Finnish and Swedish records with a known genre, and compare
fiction and non-fiction:


``` r
fi_sv <- fennica_clean |>
  filter(language %in% c("Finnish", "Swedish"), !is.na(genre), genre != "Other") |>
  mutate(fiction = if_else(genre == "Non-fiction", "Non-fiction", "Fiction"))

fiction_table <- table(fi_sv$language, fi_sv$fiction)
fiction_table
```

``` output
         
          Fiction Non-fiction
  Finnish   10235       21934
  Swedish    3767       14242
```

A table of counts of two categorical variables is a **contingency table**.
Counts are hard to compare when the groups have different sizes, so we look
at proportions within each row (language):


``` r
round(prop.table(fiction_table, margin = 1), 3)
```

``` output
         
          Fiction Non-fiction
  Finnish   0.318       0.682
  Swedish   0.209       0.791
```

## The chi-squared test

The **chi-squared test** asks whether the two variables are
**independent**: would the share of fiction be the same in both languages,
apart from random variation?


``` r
test <- chisq.test(fiction_table)
test
```

``` output

	Pearson's Chi-squared test with Yates' continuity correction

data:  fiction_table
X-squared = 681.18, df = 1, p-value < 2.2e-16
```

The test compares the **observed** counts with the counts we would
**expect** if the variables were independent:


``` r
round(test$expected)
```

``` output
         
          Fiction Non-fiction
  Finnish    8977       23192
  Swedish    5025       12984
```

Where the observed count is larger than the expected one, that combination
is more common than independence would predict.

::::::::::::::::::::::::::::::::::::: callout

### Big data, tiny p-values

With tens of thousands of records, even tiny differences give very small
p-values. A small p-value tells us that a difference is unlikely to be pure
chance, not that it is large or important. Always report **how large** the
difference is. For a contingency table, a common measure is **Cramér's V**,
from 0 (no association) to 1 (complete association):


``` r
cramers_v <- function(table) {
  chi2 <- suppressWarnings(chisq.test(table, correct = FALSE)$statistic)
  unname(sqrt(chi2 / (sum(table) * (min(dim(table)) - 1))))
}
cramers_v(fiction_table)
```

``` output
[1] 0.116559
```

Remember also that Fennica is not a random sample: it aims to cover *all*
publications. A test then tells us whether a pattern is strong compared to
random variation, not whether it holds in some larger "population".

::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: challenge

## Challenge 1: Language and place

Was Finnish-language publishing concentrated in different towns than
Swedish? Make a contingency table of `language` (Finnish and Swedish only)
and `place`, with the four groups Helsinki, Turku, Viipuri and Other. Look at
the row proportions, run the chi-squared test and calculate Cramér's V.

Hint: `case_when(place %in% c("Helsinki", "Turku", "Viipuri") ~ place,
.default = "Other")`.

:::::::::::::::::::::::: solution


``` r
place_table <- fennica_clean |>
  filter(language %in% c("Finnish", "Swedish"), !is.na(place)) |>
  mutate(town = case_when(place %in% c("Helsinki", "Turku", "Viipuri") ~ place,
                          .default = "Other")) |>
  select(language, town) |>
  table()

round(prop.table(place_table, margin = 1), 3)
```

``` output
         town
language  Helsinki Other Turku Viipuri
  Finnish    0.461 0.464 0.046   0.029
  Swedish    0.699 0.226 0.062   0.013
```

``` r
chisq.test(place_table)
```

``` output

	Pearson's Chi-squared test

data:  place_table
X-squared = 2655, df = 3, p-value < 2.2e-16
```

``` r
cramers_v(place_table)
```

``` output
[1] 0.2418737
```

Swedish-language publishing was concentrated in Helsinki (about 70% of the
records with a known place), while almost half of the Finnish-language
records were published outside the three largest towns. The association is
clear, but look at the size of Cramér's V before calling it strong.

:::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: keypoints

- A contingency table counts the combinations of two categorical variables; compare row proportions, not counts.
- `chisq.test()` tests whether two categorical variables are independent.
- Compare observed and expected counts to see where an association comes from.
- In large datasets, report an effect size such as Cramér's V, not only the p-value.

::::::::::::::::::::::::::::::::::::::::::::::::
