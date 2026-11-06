---
title: 'Reference'
---

## Glossary

Aesthetic (`aes()`)
:   In ggplot2, a mapping from a column of the data to a visual property of the
    plot, such as the x position, y position, colour or fill.

Argument
:   An input given to a function, e.g. `digits = 1` in `round(55.597, digits = 1)`.

Bibliographic record
:   A catalogue entry describing one publication: author, title, year, place,
    language and so on.

Chi-squared test
:   A statistical test of whether two categorical variables are independent
    (`chisq.test()`).

Correlation
:   A number between −1 and 1 describing how strongly two numeric variables vary
    together (`cor()`).

Data frame / tibble
:   A table in which each column is a variable and each row an observation.
    A tibble is the tidyverse version of a data frame.

Effect size
:   How large a difference or relationship is in real terms, as opposed to
    whether it is statistically significant.

Feather
:   A fast binary file format for data frames, read with `arrow::read_ipc_file()`.

Fennica
:   The Finnish national bibliography, maintained by the National Library of
    Finland.

Function
:   A named piece of code that takes arguments and returns a result, such as
    `mean()` or `filter()`.

Geom
:   In ggplot2, the type of mark used to draw data: `geom_point()`, `geom_line()`,
    `geom_bar()` and so on.

Harmonisation
:   Cleaning and standardising data from different sources or conventions so that
    values can be compared.

Linear regression
:   A model that describes the relationship between variables with a straight
    line (`lm()`).

MARC
:   MAchine-Readable Cataloguing, the standard format for library records. Fields
    are identified by numbers such as 100 (main author) and 008 (coded data).

Median
:   The middle value of sorted data; robust to extreme values.

`NA`
:   R's marker for a missing value.

Package
:   A collection of R functions, data and documentation that extends R.

Pipe (`|>`)
:   Passes the result on its left as the first argument to the function on its
    right. Read it as "and then".

p-value
:   The probability of seeing a result at least as extreme as the observed one
    if there were really no effect.

Regular expression
:   A pattern for matching text, e.g. `"^hels"` matches texts starting with "hels".

Skewed distribution
:   A distribution with a long tail on one side, so that the mean and median
    differ.

Working directory
:   The folder R uses as the starting point for relative file paths.

## Functions used in this lesson

| Task | Functions |
|------|-----------|
| Read data | `arrow::read_ipc_file()`, `arrow::write_ipc_file()` |
| Inspect | `dim()`, `glimpse()`, `head()`, `summary()`, `table()`, `is.na()` |
| Choose | `select()`, `filter()`, `arrange()`, `distinct()` |
| Change | `mutate()`, `rename()`, `if_else()`, `case_when()` |
| Text | `str_detect()`, `str_remove()`, `str_to_title()`, `str_squish()` |
| Summarise | `count()`, `group_by()`, `summarise()`, `n()`, `n_distinct()` |
| Reshape | `pivot_wider()` |
| Plot | `ggplot()`, `aes()`, `geom_*()`, `facet_wrap()`, `labs()`, `ggsave()` |
| Statistics | `mean()`, `median()`, `sd()`, `quantile()`, `cor()`, `t.test()`, `wilcox.test()`, `chisq.test()`, `lm()` |

## Further reading

- Wickham, Çetinkaya-Rundel & Grolemund: [R for Data Science](https://r4ds.hadley.nz/) (free online book)
- [ggplot2 documentation](https://ggplot2.tidyverse.org/)
- [dplyr documentation](https://dplyr.tidyverse.org/)
- [National Library of Finland](https://www.kansalliskirjasto.fi/en)
