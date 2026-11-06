---
site: sandpaper::sandpaper_site
---

*Training Material 6 · Preprocessing, Harmonisation, Validation, Analysis*

This module shows how **statistical programming** can be used as a
reproducible method for processing, harmonising, integrating, validating and
analysing bibliographic data. Systematically refined bibliographic records
are combined with a case study in the statistical analysis of open-access
bibliographic data: **Fennica**, the Finnish national bibliography, with more
than 70,000 publications from 1809 to 1917.

The whole module follows one research question:

> **How did the shift from Swedish to Finnish in publishing happen in
> 19th-century Finland, and how certain can we be about it?**

We start from the raw library catalogue records, turn them into
analysis-ready variables with reusable R code, check how far the result can
be trusted, and then move on to descriptive statistics, statistical models
and, finally, probabilistic analysis of the uncertainty in the data.

::::::::::::::::::::::::::::::::::::::::::  prereq

## Prerequisites

Basic knowledge of R, including running scripts, loading packages, importing
data, and performing simple data-frame operations. No prior experience with
bibliographic data is required.

Please complete the [Setup](learners/setup.md) instructions before the
workshop.

::::::::::::::::::::::::::::::::::::::::::::::::::

## What you will learn

- **Preprocessing:** profiling raw MARC records, cleaning text fields with regular expressions
- **Harmonisation:** lookup and synonym tables, combining MARC fields, authority identifiers, writing the pipeline as reusable functions
- **Validation:** rule-based checks, comparison of independent harmonisations, non-random missingness, sensitivity of results to cleaning decisions
- **Analysis:** summarising, visualising and modelling the data
