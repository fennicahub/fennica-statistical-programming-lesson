---
title: "Introduction to the Course"
teaching: 30
exercises: 15
---

:::::::::::::::::::::::::::::::::::::: questions

- What is bibliographic data, and what can we learn from it?
- How is a library catalogue record (MARC 21) structured?
- How do we clean raw records and make them ready for statistical research?
- Which R packages do we use, and how?

::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives

- Explain what bibliographic data is and why it is useful for research.
- Recognise the basic structure of a MARC 21 record: fields, subfields and fixed-length codes.
- Describe the stages of the course: preprocessing, harmonisation, validation and analysis.
- Explain how a ready-made harmonisation package can be adapted to another bibliography (country, language, cataloguing practice).
- Set up an RStudio project and load the packages used in the course.

::::::::::::::::::::::::::::::::::::::::::::::::



## What is bibliographic data?

In this course we analyse **Fennica**, the Finnish national bibliography,
using the programming language **R**. A national bibliography aims to
describe everything published in a country. Each publication is described by
a **bibliographic record**: who wrote it, what it is called, where, when and
by whom it was published, in which language, how many pages it has, what it
is about.

Taken one at a time, these records help readers find books. Taken together,
tens of thousands of them become a **dataset** about the history of
publishing: book history, language history and cultural history. We can ask
how much was printed and where, which publishers dominated, which genres grew,
and in which languages people read and wrote.

### The running question

The whole course follows one research question:

> **How did the shift from Swedish to Finnish in publishing happen in
> 19th-century Finland, and how certain can we be about it?**

In 1809 Finland became an autonomous Grand Duchy of the Russian Empire.
Swedish was the language of administration, education and most printing;
Latin was still used at the university. By 1917, when Finland became
independent, most books were printed in Finnish. The bibliography lets us
follow this shift year by year, place by place and publisher by publisher.
But only if we understand how the data was made, and how far we can trust it.

## Library records: MARC 21

Library catalogues store records in a format called **MARC 21** (*MAchine-
Readable Cataloging*). A MARC record consists of:

- **Control fields** with a number below 010, for example field `001`
  (the record identifier) and field `008`, a fixed-length code in which every
  **position** has a meaning (the type of date, the year, the country, the
  language, …).
- **Data fields** with a three-digit number, for example `100` (main author),
  `245` (title) or `260` (publication). Each data field is divided into
  **subfields** marked with a letter: in field 260, `$a` is the place, `$b`
  the publisher and `$c` the date.

A record for a book might look like this in the catalogue:

```
100 1# $a Runeberg, Johan Ludvig, $d 1804-1877.
245 10 $a Fänrik Ståls sägner : $b en sångcykel /
260 ## $a Helsingfors : $b G. W. Edlund, $c 1873.
```

The punctuation at the end of each subfield (` :`, `,`, ` /`) is not part of
the data: it is a cataloguing rule that separates the subfields. The two
characters after the field number are **indicators**, which refine the
meaning of the field.

The fields we use most in this course are:

| MARC field | Content |
|-----------|---------|
| `001` | record identifier |
| `008` | fixed-length codes: date type, years, language |
| `041 $a` | language code(s) |
| `100 $a`, `100 $d` | main author: name and years of life |
| `245 $a` | title |
| `260 $a`, `260 $b` | place of publication, publisher |
| `264 $a` | place of publication (newer cataloguing rules) |
| `300 $a` | extent (number of pages) |

### A real record

Here is one real record from the raw data we use later in the course (see
the [Setup](../learners/setup.md) page for how to download it). Each MARC
field has been put into its own column:


``` r
raw <- read_ipc_file("data/priority_fields19.feather")

raw |>
  filter(id == "1001523") |>
  select(id, field_008, author_name, author_date, language_041,
         title, title_remainder, publication_place, publication_place_264,
         physical_extent, note_500) |>
  glimpse()
```

``` output
Rows: 1
Columns: 11
$ id                    <chr> "1001523"
$ field_008             <chr> "930122s1860    fi ||||  m    |0| 0|swe| "
$ author_name           <chr> "Schauman, Frans Ludvig,"
$ author_date           <chr> "1810-1877,"
$ language_041          <chr> "swe"
$ title                 <chr> "Den finska kyrkans barndopsritual, historiskt o…
$ title_remainder       <chr> "akademisk afhandling /"
$ publication_place     <chr> NA
$ publication_place_264 <chr> "[Helsingfors] :|Helsingfors :"
$ physical_extent       <chr> "81, XXV sivua ;"
$ note_500              <chr> "Tarkastuspäivämäärä: 8.2.1860."
```

::::::::::::::::::::::::::::::::::::: challenge

## Challenge 1: Read a record

Look at the record above.

1. Who is the author, and when did he live?
2. In which language and where was the book published? In which field did
   you find the place, and which field is empty?
3. Field 008 starts with `930122`. The year of publication is also hidden in
   this field. Can you find it?
4. Which characters in the record are cataloguing punctuation rather than
   data?

:::::::::::::::::::::::: solution

1. Frans Ludvig Schauman, 1810–1877 (`author_name`, `author_date`).
2. Swedish (`swe`), in Helsingfors (Helsinki). Field 260 (`publication_place`)
   is empty; the place is in field 264 (`publication_place_264`), once in
   square brackets (added by the cataloguer) and once as printed on the title
   page.
3. `930122` is the date when the record was created (22 January 1993).
   Position 7 is the type of date (`s` = a single known date) and positions
   8–11 are the year: **1860**.
4. The final ` :`, `,`, ` /` and `;`, and the square brackets.

:::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::

## From raw records to statistics

A catalogue is made for finding books, not for statistics. Before we can
count and model, the records have to go through several stages, which also
form the structure of this course:

| Part | What we do | Episodes |
|------|-----------|----------|
| **1. Introduction** | Bibliographic data, MARC 21 and the tools of the course | Introduction to the Course |
| **2. Data description** | Load the Finnish national bibliography; see what it contains and what is missing | The Finnish National Bibliography |
| **3. Making the data ready for analysis** | **Cleaning** (remove formal noise), **harmonisation** (one name for one thing), **enrichment** (add data from Finto and Finna) and **validation** (how far can we trust the result?) | Cleaning, Harmonisation, Enrichment, Validation |
| **4. Basic statistical analysis** | Answer research questions with linear regression, the chi-squared test and other basic methods | Research Questions 1–3 |
| **5. Probabilistic analysis** | Express how certain our answers are, given missing and uncertain data | Probabilistic Analysis |

We do all of this in R scripts, so that every step is **documented and
repeatable**: when the library publishes a new export of the catalogue, or
when we find an error, we fix the code and run it again.

### Using a ready-made package, and adapting it

We don't have to start from zero. The Fennica data was harmonised with the
R package [**fennica**](https://github.com/fennicahub/fennica), developed by
the Computational History group. It contains one
`polish_*()` function per field (`polish_author()`, `polish_languages()`,
`polish_place()`, `polish_publisher()`, …) and a set of **lookup tables**,
for example all known spellings of Finnish towns.

Much of this work transfers to other bibliographies, but some of it is
**specific to one country, language and catalogue**:

- Place names have different forms in different languages (*Helsinki*,
  *Helsingfors*, *Helsingforsiae*), and Finnish inflects them
  (*Helsingissä*, "in Helsinki").
- Each library writes its own phrases for missing information
  (*Kustannuspaikka tuntematon*, "place of publication unknown").
- Cataloguing practices change over time (fields 260 and 264), and each
  library has its own history of digitisation and record conversion.

In this course you learn to read and reuse such functions, and to adapt the
rules and lookup tables when they don't fit your data.

::::::::::::::::::::::::::::::::::::: challenge

## Challenge 2: Your own bibliography

Think of a bibliography or catalogue you know, for example the national
bibliography of your own country. Discuss with your neighbour:

1. In which languages, and in how many different forms, are place names and
   personal names written?
2. Which information would you expect to be missing most often, and why?
3. Which research question could you ask with it?

:::::::::::::::::::::::: solution

There is no single right answer. Typical points: multilingual countries
have several names for the same town; older publications often lack a
publisher or a precise date; anonymous and pseudonymous works lack a reliable
author; and borders change, so "published in the country" can mean different
things in different periods.

:::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::

## Why a programming language?

With tens of thousands of records, spreadsheets quickly become hard to
manage. A programming language lets us:

- work with large datasets quickly,
- record every step of an analysis, so that it can be **repeated and
  checked** by others,
- combine data cleaning, statistics and visualisation in one place.

**R** is a free, open-source language designed for statistics and data
analysis. **RStudio** is a program that makes working with R more
comfortable.

::::::::::::::::::::::::::::::::::::: callout

### Work in an RStudio project

Create a project for this course with *File > New Project > New Directory*.
A project keeps your scripts, data and results together, and sets the
**working directory** so that file paths like `data/my_file.feather` work.
Inside the project, create a folder called `data` and put the course data
there (see the [Setup](../learners/setup.md) page).

::::::::::::::::::::::::::::::::::::::::::::::::

## Packages

R's abilities are extended by **packages**. In this course we use:

| Package | Used for |
|---------|----------|
| **arrow** | reading the data files (Feather format) |
| **dplyr** | selecting, filtering, transforming and summarising data |
| **tidyr** | reshaping data |
| **stringr** | working with text |
| **stringi** | text tools used by the fennica functions |
| **ggplot2** | plots |
| **jsonlite** | reading data from web APIs |

You install a package once:

```r
install.packages(c("arrow", "dplyr", "tidyr", "stringr", "stringi", "ggplot2", "jsonlite"))
```

and load it each time you start a new R session:


``` r
library(dplyr)
```

The fennica package is not installed from CRAN. We do not need to install it:
we read its code on GitHub and reuse its lookup tables directly.

::::::::::::::::::::::::::::::::::::: callout

### Getting help

- `?function_name` opens the help page for a function.
- Error messages usually tell you what went wrong. Read them carefully, and
  try searching for the message online.
- Common errors are typos in object names, missing commas or parentheses,
  and forgetting to load a package.

::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: keypoints

- Bibliographic records, taken together, are a dataset about the history of publishing.
- MARC 21 records consist of numbered fields and lettered subfields; field 008 is a fixed-length code.
- Cataloguing punctuation and conventions must be removed or interpreted before analysis.
- The course moves from preprocessing and harmonisation through validation to analysis and modelling.
- Ready-made harmonisation code, such as the fennica package, can be reused, but its rules and lookup tables must be adapted to each bibliography.
- Work in an RStudio project and keep every step in a script, so your work is reproducible.

::::::::::::::::::::::::::::::::::::::::::::::::
