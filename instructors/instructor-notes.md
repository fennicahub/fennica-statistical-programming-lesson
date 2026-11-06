---
title: 'Instructor Notes'
---

## Overview

This module (Training Material 6: *Statistical programming for bibliographic
data science*) uses the Fennica national bibliography (1809–1917) as a
single running example. It covers preprocessing, harmonisation, validation
and analysis. Learners are expected to know basic R (running scripts,
loading packages, importing data, simple data-frame operations); no prior
experience with bibliographic data is required. Episodes 2–4 (Meet the
Fennica Data, harmonisation and validation) form Part 1 of the course: from
raw records to analysis-ready, validated data. The analysis episodes are
being redesigned to lead from descriptive statistics to statistical models
and probabilistic analysis.

## Before the workshop

- Ask learners to complete the [Setup](../learners/setup.md) in advance.
  Installing `arrow` can take a while on some systems.
- Have the data file available on a USB stick or shared drive in case of slow
  internet.
- Test that `arrow::read_ipc_file()` works on the workshop machines.

## Episode notes

### Introduction to the Course

- Introduce the running question and the course stages (table in the
  episode). Many learners know library catalogues but not MARC 21: walk
  through the example record field by field.
- Challenge 1 (reading a real record) prepares the harmonisation episode:
  the place is in field 264, not 260, and field 008 hides the year.
- Challenge 2 is a discussion; it works well in pairs, especially with
  participants from other countries.
- Demonstrate RStudio projects live: most later file path problems come from
  not working inside the project.

### Meet the Fennica Data

- Challenge 2 (swapped columns) is a good moment for discussion: how would you
  notice this in your own data? The validation episode returns to it.

### The running question

Episodes 4 onwards follow one question: *how did the shift from Swedish to
Finnish in publishing happen, and how certain can we be about it?* Return to
it at the start and end of every episode. The harmonisation and validation
episodes build the variables (language, place, publisher, author) and show
that the answer depends on data decisions; later parts of the course
quantify that uncertainty.

### Preprocessing and Harmonisation (about 80 minutes)

- Uses the raw records `priority_fields19.feather` (all 72,626 records; the
  `id` matches the harmonised data exactly). Columns are named, but the
  episode maps each to its MARC field.
- Rhythm for every field: profile, find a pattern, clean with a function,
  count again. Each field ends as a function; the episode ends with
  `harmonise_records()`, which is also in `files/harmonise_fennica.R`.
- Key teaching moments:
  - **Two sources for the same information:** 041 vs 008 for language,
    260 vs 264 for place. Combine them with `coalesce()`.
  - **Mikkeli (Challenge 2):** field 264 of about 8,650 digitised copies gives
    the National Library's digitisation centre in Mikkeli as the place. Let
    learners discover this themselves; it is the central "a clean value can
    measure the wrong thing" example.
  - **Synonym table:** entries are partly ASCII-folded (`abo`, `borga`), hence
    `fold()`. Unmatched values include Russian forms and Finnish emigrant
    presses in the USA.
  - **Authority IDs:** `asteri_id` separates the Runebergs and the two
    Alexandre Dumas. Among records with an ID there are more persons than
    name strings.
- Regular expressions are new to many learners: build each pattern live on
  the small `places` vector first.
- If time is short, skip the publisher section.

### Validation (about 70 minutes)

- Three kinds of validation: rules, comparison with an independent
  harmonisation (the project's file), and consequences for the research
  question.
- Rule failures lead back to raw records: numbers as author names, dates in
  the name field (`|`), and *S.l*/*S.a* in the publisher field.
- The comparison shows several problems in the project's harmonised file:
  - its place and publisher columns are swapped;
  - it keeps language-specific place names (Helsingfors vs Helsinki);
  - `Turku` appears as a publisher for "... i Finland" societies;
  - `polish_author()` reverses patronymics (`Ragvaldinpoika, Thomas`).
- Missingness: Swedish records lack a publisher (52%) and a place (21%) more
  often than Finnish ones (30% and 16%). The sensitivity plot shows the
  Finnish share by decade for four subsets. Restricting to records with a
  known publisher moves the 50% crossing from the 1870s to the 1850s.
- Challenge 3 (Helsinki vs Helsingfors: 95% vs 4% Finnish) prepares the later
  modelling episodes: a raw place name is partly the outcome itself.
- The 1810s value is inflated by questionable dates; this is left for the
  publication-time episode.
- The lookup tables in `episodes/data/` are from `inst/extdata` of the
  [fennica](https://github.com/fennicahub/fennica) package (BSD-2 licence).

### From the harmonised data to `fennica_clean`

- The analysis episodes use `fennica_clean`, created from the project's
  harmonised file by `files/clean_fennica.R` (swap fixed, places merged,
  English genre labels).
- Further findings from running the real `polish_*()` functions:
  `polish_author_years()` turns *syntynyt 1875* ("born 1875") into
  birth = death = 1875 (the "age zero" authors in the visualisation episode),
  and the harmonised `title` column is the uniform title (field 240).

### Summarising Data

- Stress the difference between counts and proportions; the language shift
  from Swedish to Finnish is the key historical story.

### Visualising Data with ggplot2

- Build plots incrementally, adding one layer at a time.
- The faceting example with `scales = "free_y"` is a good prompt to discuss how
  plot choices can mislead.

### Basic Statistical Analysis

- Learners may have no statistics background. Focus on interpretation rather
  than formulas.
- The key messages are: medians for skewed data, correlation is not causation,
  and with large data effect sizes matter more than p-values.

## Known data issues

- `publisher` and `publication_place` are swapped in the source data; this is
  discovered in the validation episode.
- `title2` contains a `"Na  "` prefix when `title` is missing.
- `genre_008` contains character-set values (e.g. "Laajennettu latinalainen").
- The page count and physical dimension columns are mostly empty or unreliable
  and are not used in the lesson.
- Decade `1800` contains only records from 1809, and the 1910s end in 1917.
