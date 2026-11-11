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

The course has five parts:

1. **Introduction** to bibliographic data, MARC 21 and the tools of the course.
2. **Data description** of the Finnish national bibliography.
3. **Making the data ready for analysis**: cleaning with the fennica R
   package, harmonisation, enrichment with Finto and Finna, and validation.
4. **Basic statistical analysis**: research questions answered with linear
   regression, the chi-squared test and other basic methods.
5. **Probabilistic analysis** of how certain our answers are.

Some episodes are still in preparation and are marked as such.

::::::::::::::::::::::::::::::::::::::::::  prereq

## Prerequisites

Basic knowledge of R, including running scripts, loading packages, importing
data, and performing simple data-frame operations. No prior experience with
bibliographic data is required.

Please complete the [Setup](learners/setup.md) instructions before the
workshop.

::::::::::::::::::::::::::::::::::::::::::::::::::

## What you will learn

- **Cleaning:** profiling raw MARC records, cleaning text fields with regular expressions, reusing the fennica package
- **Harmonisation:** lookup and synonym tables, combining MARC fields, authority identifiers, writing the pipeline as reusable functions
- **Enrichment:** linking records to external vocabularies and collections (Finto, Finna) through identifiers and open APIs
- **Validation:** rule-based checks, comparison of independent harmonisations, non-random missingness, sensitivity of results to cleaning decisions
- **Basic statistical analysis:** linear regression, the chi-squared test and other basic methods, applied to research questions
- **Probabilistic analysis:** expressing the uncertainty of results based on incomplete and inconsistent data
