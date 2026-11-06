---
title: "Summarising Data"
teaching: 25
exercises: 15
---

:::::::::::::::::::::::::::::::::::::: questions

- How do I calculate summaries for groups of records?
- How did publishing in Finland change over the 19th century?
- How do I reshape a summary table?

::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives

- Use `group_by()` and `summarise()` to calculate statistics per group.
- Calculate counts, means, medians and proportions.
- Use `n()` and `n_distinct()` to count rows and unique values.
- Reshape a summary table with `pivot_wider()`.

::::::::::::::::::::::::::::::::::::::::::::::::



## Getting started

In this episode we use `fennica_clean`: the project's harmonised data with
the place and publisher columns swapped back, the main place names merged and
the genre labels translated into English. Download the script
[`clean_fennica.R`](files/clean_fennica.R) into your project folder and run
it with `source("clean_fennica.R")`, then save the result with
`write_ipc_file(fennica_clean, "data/fennica_clean.feather")`. In a new R
session, load the packages and the clean data:

```r
library(arrow)
library(dplyr)
library(tidyr)
fennica_clean <- read_ipc_file("data/fennica_clean.feather")
```


``` r
library(tidyr)
```

## Summarising a whole dataset

`summarise()` reduces a data frame to a single row of summary values:


``` r
fennica_clean |>
  summarise(
    n_records = n(),
    n_authors = n_distinct(author, na.rm = TRUE),
    first_year = min(year, na.rm = TRUE),
    last_year = max(year, na.rm = TRUE),
    median_title_words = median(title_words)
  )
```

``` output
# A tibble: 1 × 5
  n_records n_authors first_year last_year median_title_words
      <int>     <int>      <dbl>     <dbl>              <dbl>
1     72626     10475       1809      1917                  3
```

`n()` counts rows, and `n_distinct()` counts unique values.

## Summarising by group

The real power of `summarise()` comes when we combine it with `group_by()`.
`group_by()` splits the data into groups, `summarise()` calculates the
summary for each group, and the results are combined into a new table.

How many records were published in each decade?


``` r
fennica_clean |>
  group_by(decade) |>
  summarise(n_records = n())
```

``` output
# A tibble: 13 × 2
   decade n_records
    <dbl>     <int>
 1   1800       581
 2   1810      2315
 3   1820      1788
 4   1830      1591
 5   1840      2097
 6   1850      2134
 7   1860      2286
 8   1870      3233
 9   1880      6520
10   1890     11572
11   1900     19328
12   1910     19169
13     NA        12
```

The number of publications grew enormously, from a few hundred in the first decades
to almost 20,000 in the 1900s. Remember that the decade `1800` only contains
the year 1809, and the 1910s only include the years up to 1917.

::::::::::::::::::::::::::::::::::::: callout

### `count()` is a shortcut

`count(decade)` does the same as `group_by(decade) |> summarise(n = n())`.
Use `group_by()` and `summarise()` when you need more than a count.

::::::::::::::::::::::::::::::::::::::::::::::::

We can calculate several summaries at once:


``` r
fennica_clean |>
  group_by(language) |>
  summarise(
    n_records = n(),
    mean_title_words = mean(title_words),
    median_title_words = median(title_words),
    first_year = min(year, na.rm = TRUE)
  ) |>
  arrange(desc(n_records)) |>
  head(6)
```

``` output
# A tibble: 6 × 5
  language n_records mean_title_words median_title_words first_year
  <chr>        <int>            <dbl>              <dbl>      <dbl>
1 Finnish      40378             3.90                  3       1809
2 Swedish      23338             7.00                  4       1809
3 Latin         2844            30.9                  26       1809
4 German        2357             7.26                  6       1809
5 Russian        938             6.21                  5       1811
6 French         730            10.9                   7       1809
```

And we can group by more than one column:


``` r
fennica_clean |>
  filter(language %in% c("Finnish", "Swedish")) |>
  group_by(decade, language) |>
  summarise(n_records = n(), .groups = "drop")
```

``` output
# A tibble: 26 × 3
   decade language n_records
    <dbl> <chr>        <int>
 1   1800 Finnish         39
 2   1800 Swedish        466
 3   1810 Finnish       1029
 4   1810 Swedish        429
 5   1820 Finnish        574
 6   1820 Swedish        363
 7   1830 Finnish        422
 8   1830 Swedish        610
 9   1840 Finnish        557
10   1840 Swedish        905
# ℹ 16 more rows
```

The `.groups = "drop"` argument removes the grouping from the result so that
later steps are not affected by it.

## Proportions

Counts grow with the overall number of publications. To compare languages
across decades, **proportions** are more useful. We first count, then divide
each count by the total of its decade:


``` r
language_share <- fennica_clean |>
  filter(!is.na(decade)) |>
  count(decade, language) |>
  group_by(decade) |>
  mutate(share = n / sum(n)) |>
  ungroup()

language_share |>
  filter(language == "Finnish")
```

``` output
# A tibble: 12 × 4
   decade language     n  share
    <dbl> <chr>    <int>  <dbl>
 1   1800 Finnish     39 0.0671
 2   1810 Finnish   1029 0.444 
 3   1820 Finnish    574 0.321 
 4   1830 Finnish    422 0.265 
 5   1840 Finnish    557 0.266 
 6   1850 Finnish    798 0.374 
 7   1860 Finnish   1074 0.470 
 8   1870 Finnish   1813 0.561 
 9   1880 Finnish   3292 0.505 
10   1890 Finnish   6155 0.532 
11   1900 Finnish  12284 0.636 
12   1910 Finnish  12331 0.643 
```

(We drop the few records without a known year first.)

The share of Finnish does not grow in a straight line. It is high in the 1810s
and 1820s, falls in the 1830s and 1840s when Swedish-language publishing
expands, and then rises steadily from the 1850s onwards. (The high early
values should be treated with caution: most records dated 1810 have an
uncertain date, as we will see in the next episode.) By the early 20th
century about two thirds of all publications were in Finnish. This long-term
rise coincides with the Finnish language movement and the expansion of
Finnish-language education and publishing.

## Reshaping with `pivot_wider()`

The table above is in *long* format: one row per decade *and* language.
For reading, a *wide* table with one column per language can be easier.
`pivot_wider()` from **tidyr** does this:


``` r
language_share |>
  filter(language %in% c("Finnish", "Swedish", "Latin", "German")) |>
  mutate(share = round(share * 100, 1)) |>
  select(decade, language, share) |>
  pivot_wider(names_from = language, values_from = share)
```

``` output
# A tibble: 12 × 5
   decade Finnish German Latin Swedish
    <dbl>   <dbl>  <dbl> <dbl>   <dbl>
 1   1800     6.7    2.8   9      80.2
 2   1810    44.4    1.8  32      18.5
 3   1820    32.1    2.1  43.1    20.3
 4   1830    26.5    0.7  31.2    38.3
 5   1840    26.6    2.5  23.1    43.2
 6   1850    37.4    2.4   4.5    49.7
 7   1860    47      1.4   0.8    47.2
 8   1870    56.1    2.1   0.6    35.9
 9   1880    50.5    2.4   0.6    41.5
10   1890    53.2    3.4   0.4    38.1
11   1900    63.6    3.7   0.2    27.1
12   1910    64.3    4.1   0.2    25.6
```

The numbers are percentages of all records in each decade. Notice how Latin,
the language of the university, almost disappears.

::::::::::::::::::::::::::::::::::::: challenge

## Challenge 1: Most productive authors

Find the ten authors with the most records. For each, also show the first and
last year in which they have a publication. Remember to remove records without
an author.

:::::::::::::::::::::::: solution


``` r
fennica_clean |>
  filter(!is.na(author)) |>
  group_by(author) |>
  summarise(
    n_records = n(),
    first_year = min(year, na.rm = TRUE),
    last_year = max(year, na.rm = TRUE)
  ) |>
  arrange(desc(n_records)) |>
  head(10)
```

``` output
# A tibble: 10 × 4
   author                       n_records first_year last_year
   <chr>                            <int>      <dbl>     <dbl>
 1 Topelius, Zacharias                711       1822      1917
 2 Runeberg, Johan Ludvig             483       1830      1916
 3 Sjöström, Axel Gabriel             326       1816      1846
 4 Luther, Martti                     262       1820      1917
 5 Aho, Juhani                        208       1884      1917
 6 Rein, Gabriel                      153       1825      1911
 7 Sahlberg, Carolus Reginaldus       138       1817      1839
 8 Leino, Eino                        137       1896      1917
 9 Bonsdorff, E                       136       1869      1916
10 Juteini, Jaakko                    136       1810      1907
```

:::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: challenge

## Challenge 2: Genres by language

For Finnish and Swedish records with a known genre, calculate the share of each
genre within each language. Which language has the larger share of novels?

:::::::::::::::::::::::: solution


``` r
fennica_clean |>
  filter(language %in% c("Finnish", "Swedish"), !is.na(genre)) |>
  count(language, genre) |>
  group_by(language) |>
  mutate(share = round(n / sum(n) * 100, 1)) |>
  ungroup() |>
  select(-n) |>
  pivot_wider(names_from = language, values_from = share)
```

``` output
# A tibble: 6 × 3
  genre         Finnish Swedish
  <chr>           <dbl>   <dbl>
1 Drama             4.9     1.6
2 Non-fiction      67.2    77.5
3 Novels           13.6     7.3
4 Other             1.4     2  
5 Poetry            8.4     6.5
6 Short stories     4.6     5.2
```

:::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: challenge

## Challenge 3: Publishing places

For each of the five most common places, calculate the number of records and
the share of them that are in Finnish. Which place published the largest share
of Finnish-language material?

Hint: `mean(language == "Finnish")` gives the proportion of `TRUE` values.

:::::::::::::::::::::::: solution


``` r
fennica_clean |>
  filter(!is.na(place)) |>
  group_by(place) |>
  summarise(
    n_records = n(),
    share_finnish = mean(language == "Finnish")
  ) |>
  arrange(desc(n_records)) |>
  head(5)
```

``` output
# A tibble: 5 × 3
  place    n_records share_finnish
  <chr>        <int>         <dbl>
1 Helsinki     26294         0.538
2 Porvoo        3224         0.850
3 Turku         2996         0.473
4 Tampere       2401         0.930
5 Kuopio        1459         0.888
```

Taking the mean of a logical vector works because `TRUE` counts as 1 and
`FALSE` as 0.

:::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: keypoints

- `group_by()` + `summarise()` calculates summaries for each group.
- `n()` counts rows and `n_distinct()` counts unique values.
- Use proportions rather than raw counts to compare groups of different sizes.
- `ungroup()` or `.groups = "drop"` removes grouping when you no longer need it.
- `pivot_wider()` turns a long table into a wide one that is easier to read.

::::::::::::::::::::::::::::::::::::::::::::::::
