# Statistical Programming for Bibliographic Data Science

Training Material 6 (Preprocessing, Harmonisation, Validation, Analysis): a
lesson on statistical programming in R as a reproducible method for
processing and analysing bibliographic data. The lesson
uses **Fennica**, the Finnish national bibliography (72,626 records published
1809–1917), as a running example.

The lesson is built with [The Carpentries Workbench][workbench].

## Episodes

1. Introduction to the Course
2. Data Description: The Finnish National Bibliography
3. Making the data ready for analysis
   1. Cleaning (the fennica package)
   2. Harmonisation
   3. Enrichment (Finto, Finna), *in preparation*
   4. Validation
4. Basic Statistical Analysis
   1. Research Question 1: Linear Regression
   2. Research Question 2: The Chi-Squared Test
   3. Research Question 3, *in preparation*
5. Probabilistic Analysis (Research Questions 4 and 5), *in preparation*

## Repository layout

| Path | Contents |
|------|----------|
| `episodes/` | Lesson episodes (R Markdown) |
| `episodes/data/harmonized_fennica19.feather` | The dataset used in the lesson (learners download it from [CSC object storage](https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/output.tables/harmonized_fennica19.feather)) |
| `episodes/data/priority_fields19.feather` | Raw catalogue records (learners download it from [CSC object storage](https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/priority_fields19.feather)) |
| `episodes/files/clean_records.R` | Cleaning functions for the raw records |
| `episodes/files/harmonise_fennica.R` | Cleaning and harmonisation pipeline from the raw records |
| `episodes/files/clean_fennica.R` | Prepares the project's harmonised data for the analysis episodes |
| `learners/` | Setup instructions and glossary |
| `instructors/` | Notes for instructors |
| `profiles/` | Learner profiles |
| `config.yaml` | Lesson configuration |

## Building the lesson locally

Install R (4.1 or later), then:

```r
install.packages(c("sandpaper", "varnish", "pegboard", "tinkr"),
                 repos = c("https://carpentries.r-universe.dev/", getOption("repos")))
install.packages(c("arrow", "dplyr", "tidyr", "stringr", "ggplot2"))

sandpaper::build_lesson()
```

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) and our
[Code of Conduct](CODE_OF_CONDUCT.md).

## License

Lesson content is licensed under [CC-BY 4.0](LICENSE.md).

[workbench]: https://carpentries.github.io/sandpaper-docs/
