---
title: "Data Description: The Finnish National Bibliography"
teaching: 20
exercises: 10
---

:::::::::::::::::::::::::::::::::::::: questions

- What is the Fennica bibliography and what does our dataset contain?
- How do I load a data file into R?
- How do I get an overview of a data frame?

::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives

- Describe what a bibliographic record is and what the dataset covers.
- Load the Fennica data into R as a data frame.
- Inspect the size, columns and contents of a data frame.
- Measure how much data is missing in each column.

::::::::::::::::::::::::::::::::::::::::::::::::

## The Fennica bibliography

**Fennica** is the Finnish national bibliography, maintained by the National
Library of Finland. It aims to record everything published in Finland, and
publications about Finland or by Finnish authors published abroad.

Each publication is described by a **bibliographic record**: a catalogue entry
with fields such as the author, title, year and place of publication, language
and subject. Library records are stored in a format called MARC, where fields
are identified by numbers. You will see some of these numbers in our column
names, for example `author_name_100` (MARC field 100, the main author) and
`genre_008` (MARC field 008, coded information).

Our dataset, `harmonized_fennica19.feather`, contains **72,626 records** of
publications from **1809 to 1917**, the period when Finland was an autonomous
Grand Duchy within the Russian Empire. The data has been *harmonised*: some
fields have been cleaned and standardised for research. As we will see, it
still has plenty of quirks.

## Loading the data

The data is stored in the **Feather** format, a fast binary format for data
frames, which we read with the `arrow` package. Feather files are also called
Arrow IPC files, so the function is called `read_ipc_file()`:


``` r
library(arrow)
library(dplyr)

fennica <- read_ipc_file("data/harmonized_fennica19.feather")
```

::::::::::::::::::::::::::::::::::::: callout

### File paths

The path `"data/harmonized_fennica19.feather"` is *relative* to your working
directory, which is your project folder. If R says the file does not exist,
check that the file is in the `data` folder inside your project and that you
opened the project (the `.Rproj` file).

::::::::::::::::::::::::::::::::::::::::::::::::

## A first look

`fennica` is a **data frame** (more precisely a *tibble*, the tidyverse's
version of a data frame). It is a table where each **row is one record** and
each **column is one variable**.


``` r
dim(fennica)
```

``` output
[1] 72626    79
```

``` r
nrow(fennica)
```

``` output
[1] 72626
```

``` r
ncol(fennica)
```

``` output
[1] 79
```

Typing the name of a tibble prints the first rows and as many columns as fit:


``` r
fennica
```

``` output
# A tibble: 72,626 × 79
   id      id2                  data_element genre_008  record_type biblio_level
   <chr>   <chr>                <chr>        <chr>      <chr>       <chr>       
 1 1001523 1001523|FCC005333271 Kirjat       Tietokirj… Language m… Monograph/I…
 2 1002166 1002166|FCC003328624 Kirjat       Tietokirj… Language m… Monograph/I…
 3 1003435 1003435|FCC000494839 Kirjat       Tietokirj… Language m… Monograph/I…
 4 1003442 1003442|FCC001769859 Kirjat       Tietokirj… Language m… Monograph/I…
 5 1004966 1004966|FCC000498589 Kirjat       Tietokirj… Language m… Monograph/I…
 6 1006834 1006834|FCC000450489 Kirjat       Tietokirj… Language m… Monograph/I…
 7 1015813 1015813|FCC001780036 Kirjat       Tietokirj… Language m… Monograph/I…
 8 1016174 1016174|FCC001780306 Kirjat       Tietokirj… Language m… Monograph/I…
 9 1016203 1016203|FCC003174449 Kirjat       Tietokirj… Language m… Monograph/I…
10 1029041 1029041|FCC003174253 Kirjat       Tietokirj… Language m… Monograph/I…
# ℹ 72,616 more rows
# ℹ 73 more variables: publication_status <chr>, author_name_100 <chr>,
#   first_100 <chr>, last_100 <chr>, author_birth <dbl>, author_death <dbl>,
#   author_age <dbl>, title <chr>, title_length <int>, title_word <int>,
#   title_remainder <chr>, title_remainder_length <int>,
#   title_remainder_word <int>, title2 <chr>, title2_length <int>,
#   title2_word <int>, language_full_primary <chr>, …
```

With 79 columns, `glimpse()` gives a more readable overview: one line per
column, showing its type and the first values.


``` r
glimpse(fennica)
```

``` output
Rows: 72,626
Columns: 79
$ id                        <chr> "1001523", "1002166", "1003435", "1003442", …
$ id2                       <chr> "1001523|FCC005333271", "1002166|FCC00332862…
$ data_element              <chr> "Kirjat", "Kirjat", "Kirjat", "Kirjat", "Kir…
$ genre_008                 <chr> "Tietokirjallisuus", "Tietokirjallisuus", "T…
$ record_type               <chr> "Language material", "Language material", "L…
$ biblio_level              <chr> "Monograph/Item", "Monograph/Item", "Monogra…
$ publication_status        <chr> "Single known date/probable date", "Single k…
$ author_name_100           <chr> "Schauman, Frans Ludvig", "Hällsten, Jakob",…
$ first_100                 <chr> "Frans Ludvig", "Jakob", "Santeri", "Erik Al…
$ last_100                  <chr> "Schauman, Frans Ludvig", "Hällsten, Jakob",…
$ author_birth              <dbl> 1810, 1807, 1866, 1810, 1837, 1841, 1875, 18…
$ author_death              <dbl> 1877, 1851, 1937, 1858, 1877, 1894, 1953, 19…
$ author_age                <dbl> 67, 44, 71, 48, 40, 53, 78, 78, 68, 78, 68, …
$ title                     <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
$ title_length              <int> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
$ title_word                <int> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
$ title_remainder           <chr> "den finska kyrkans barndopsritual, historis…
$ title_remainder_length    <int> 69, 82, 56, 71, 40, 48, 46, 50, 45, 87, 91, …
$ title_remainder_word      <int> 8, 11, 5, 12, 5, 7, 4, 5, 5, 10, 11, 10, 9, …
$ title2                    <chr> "Na  den finska kyrkans barndopsritual, hist…
$ title2_length             <int> 73, 86, 60, 75, 44, 52, 50, 54, 49, 91, 95, …
$ title2_word               <int> 9, 12, 6, 13, 6, 8, 5, 6, 6, 11, 12, 11, 10,…
$ language_full_primary     <chr> "Unrecognized", "Latin", "Unrecognized", "Un…
$ language_full_multi       <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FA…
$ lang_full_orig            <chr> "swe", "lat", "fin", "swe", "swe", "swe|fin"…
$ language_041_primary      <chr> "Unrecognized", NA, "Unrecognized", "Unrecog…
$ language_041_multi        <lgl> FALSE, NA, FALSE, FALSE, FALSE, FALSE, NA, N…
$ lang_041_orig             <chr> "swe", "lat", "fin", "swe", "swe", "swe|fin"…
$ language_008_primary      <chr> "Swedish", "Latin", "Finnish", "Swedish", "S…
$ language_008_multi        <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FA…
$ lang_008_orig             <chr> "swe", "lat", "fin", "swe", "swe", "swe|fin"…
$ language_original_primary <chr> "Swedish", "Latin", "Finnish", "Swedish", "S…
$ language_original_multi   <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, TRUE, FAL…
$ lang_original_orig        <chr> "swe", "lat", "fin", "swe", "swe", "swe|fin"…
$ publication_year_from     <dbl> 1860, 1837, 1890, 1858, 1874, 1871, 1902, 19…
$ publication_year_till     <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
$ publication_year          <dbl> 1860, 1837, 1890, 1858, 1874, 1871, 1902, 19…
$ publication_decade        <dbl> 1860, 1830, 1890, 1850, 1870, 1870, 1900, 19…
$ publication_place         <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
$ publication_country       <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
$ publisher                 <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
$ signum                    <chr> "Diss. HY", "Diss. HY", "Suom. hist. 3 Ingma…
$ genre_655                 <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
$ gatherings.original       <fct> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
$ width.original            <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
$ height.original           <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
$ obl.original              <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FA…
$ original                  <chr> "helsingfors tohelsingfors", "helsingforsiae…
$ gatherings                <fct> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
$ width                     <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
$ height                    <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
$ obl                       <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,…
$ area                      <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
$ pagecount.multiplier.x    <dbl> 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,…
$ pagecount.squarebracket.x <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,…
$ pagecount.plate.x         <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,…
$ pagecount.arabic.x        <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,…
$ pagecount.roman.x         <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,…
$ pagecount.sheet.x         <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,…
$ pagecount.x               <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
$ volnumber.x               <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
$ volcount.x                <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
$ parts.x                   <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
$ pagecount.multiplier.y    <dbl> 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,…
$ pagecount.squarebracket.y <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,…
$ pagecount.plate.y         <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,…
$ pagecount.arabic.y        <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,…
$ pagecount.roman.y         <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,…
$ pagecount.sheet.y         <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,…
$ pagecount.y               <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
$ volnumber.y               <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
$ volcount.y                <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
$ parts.y                   <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
$ udk_orig                  <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
$ udk_harm                  <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
$ udk_aux                   <chr> "25", "82", "948.0", "613", "55", "809.454.1…
$ udk                       <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
$ udk_primary               <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
$ udk_multi                 <lgl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
```

The most common column types are:

| Type | Meaning | Example column |
|------|---------|----------------|
| `<chr>` | character (text) | `author_name_100` |
| `<dbl>` | double (number) | `publication_year` |
| `<int>` | integer (whole number) | `title_remainder_word` |
| `<lgl>` | logical (`TRUE`/`FALSE`) | `language_008_multi` |

## Working with single columns

We pull out one column as a vector with `$`:


``` r
head(fennica$publication_year)
```

``` output
[1] 1860 1837 1890 1858 1874 1871
```

``` r
range(fennica$publication_year, na.rm = TRUE)
```

``` output
[1] 1809 1917
```

`table()` counts how often each value occurs, which is handy for categorical
columns:


``` r
table(fennica$data_element)
```

``` output

Jatkuvat julkaisut             Kirjat 
              7320              65306 
```

`Kirjat` means *books* and `Jatkuvat julkaisut` means *serials* (newspapers,
magazines and other continuing publications). Some columns use Finnish labels
because they come from Finnish cataloguing practice.

`summary()` gives a quick statistical overview of a numeric column:


``` r
summary(fennica$author_birth)
```

``` output
   Min. 1st Qu.  Median    Mean 3rd Qu.    Max.     NAs 
    354    1819    1853    1837    1868    1941   41287 
```

## How complete is the data?

Bibliographic records are rarely complete. `is.na()` tells us which values are
missing, and `colMeans()` computes the share of `TRUE` values per column.
Here we look at a few key columns:


``` r
key_columns <- c("author_name_100", "author_birth", "title_remainder",
                 "publication_year", "language_008_primary", "publisher",
                 "publication_place", "genre_008")

round(colMeans(is.na(fennica[key_columns])) * 100)
```

``` output
     author_name_100         author_birth      title_remainder 
                  38                   57                    0 
    publication_year language_008_primary            publisher 
                   0                    0                   30 
   publication_place            genre_008 
                  37                    0 
```

More than a third of the records have no author. This is not necessarily an
error: many publications, such as official documents, almanacs and serials,
have no personal author. Missing data can carry meaning, and it shapes which
questions we can answer.

::::::::::::::::::::::::::::::::::::: challenge

## Challenge 1: Explore a column

Use `table()` to look at the column `language_008_primary`.
Which are the three most common languages?

Hint: `sort(..., decreasing = TRUE)` sorts a table from largest to smallest.

:::::::::::::::::::::::: solution


``` r
sort(table(fennica$language_008_primary), decreasing = TRUE)[1:5]
```

``` output

Finnish Swedish   Latin  German Russian 
  40378   23338    2844    2357     938 
```

Finnish, Swedish and Latin. Note how many Swedish-language publications there
are: Swedish was the main language of administration and education for much
of the 19th century.

:::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: challenge

## Challenge 2: Suspicious values

Look at the first values of the columns `publisher` and `publication_place`:

```r
head(unique(fennica$publisher), 10)
head(unique(fennica$publication_place), 10)
```

Does anything look strange?

:::::::::::::::::::::::: solution


``` r
head(unique(fennica$publisher), 10)
```

``` output
 [1] NA                           "wiipurissa"                
 [3] "helsingfors"                "turku"                     
 [5] "åbo"                        "turussa"                   
 [7] "kustannuspaikka tuntematon" "stockholm"                 
 [9] "turusa"                     "kuopiossa"                 
```

``` r
head(unique(fennica$publication_place), 10)
```

``` output
 [1] NA              "F cederwaller" "Stycket"       "Första delen" 
 [5] "Nen osa"       "Första boken"  "Andra boken"   "Fjerde boken" 
 [9] "Osa"           "Part"         
```

The `publisher` column contains **places** (helsinki, helsingfors…), while
`publication_place` contains **publishers** (WSOY, Otava…). The two columns
appear to have been swapped somewhere in the processing. We come back to this in
the episode on validation. Always check that your data contains what the
column names promise!

:::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: keypoints

- Fennica is the Finnish national bibliography; our data covers 1809–1917.
- Each row of the data frame is one bibliographic record, each column one variable.
- Use `read_ipc_file()` from `arrow` to read Feather files.
- `dim()`, `glimpse()`, `summary()` and `table()` give a quick overview of the data.
- Check how much data is missing, and whether columns contain what their names suggest.

::::::::::::::::::::::::::::::::::::::::::::::::
