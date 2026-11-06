---
title: Setup
---

This lesson uses **R** and **RStudio**, the packages **arrow**, **dplyr**,
**tidyr**, **stringr** and **ggplot2**, and one dataset. Please complete the
steps below before the workshop. It takes about 20–30 minutes.

## Software Setup

::::::::::::::::::::::::::::::::::::::: discussion

### Details

You need a recent version of R (4.1 or later) and RStudio Desktop. Both are
free. If you already have them installed, make sure R is up to date: the code
uses the native pipe `|>`, which requires R 4.1 or later. Check your version by
typing `R.version.string` in the R console.

:::::::::::::::::::::::::::::::::::::::::::::::::::

:::::::::::::::: spoiler

### Windows

1. Download and install R from [CRAN](https://cran.r-project.org/bin/windows/base/).
2. Download and install [RStudio Desktop](https://posit.co/download/rstudio-desktop/).

::::::::::::::::::::::::

:::::::::::::::: spoiler

### MacOS

1. Download and install R from [CRAN](https://cran.r-project.org/bin/macosx/).
   Choose the version for your processor (Apple silicon or Intel).
2. Download and install [RStudio Desktop](https://posit.co/download/rstudio-desktop/).

::::::::::::::::::::::::

:::::::::::::::: spoiler

### Linux

1. Install R by following the instructions for your distribution on
   [CRAN](https://cran.r-project.org/bin/linux/).
2. Download and install [RStudio Desktop](https://posit.co/download/rstudio-desktop/).

::::::::::::::::::::::::

### Install the R packages

Open RStudio and run this line in the console:

```r
install.packages(c("arrow", "dplyr", "tidyr", "stringr", "ggplot2"))
```

Check that the installation worked by loading each package. You should not see
any errors (messages about masked objects are fine):

```r
library(arrow)
library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)
```

## Data Sets

We use a harmonised extract of **Fennica**, the Finnish national bibliography,
covering publications from 1809 to 1917 (72,626 records, about 16 MB).

1. In RStudio, create a new project: *File > New Project > New Directory >
   New Project*. Call it, for example, `fennica-r`.
2. In the project folder, create a folder called `data`.
3. Download the data file
   [harmonized_fennica19.feather](https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/output.tables/harmonized_fennica19.feather)
   from CSC's object storage and save it in the `data` folder.

   You can also download it directly from R. Run this in the RStudio console
   with your project open:

   ```r
   dir.create("data", showWarnings = FALSE)
   download.file(
     "https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/output.tables/harmonized_fennica19.feather",
     destfile = "data/harmonized_fennica19.feather",
     mode = "wb"
   )
   ```

   (`mode = "wb"` makes sure the file is saved correctly on Windows.)

4. For the episodes on harmonisation and validation you also need the
   **raw** catalogue records, `priority_fields19.feather` (about 21 MB).
   Download it from
   [priority_fields19.feather](https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/priority_fields19.feather)
   and save it in the same `data` folder, or in R:

   ```r
   download.file(
     "https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/priority_fields19.feather",
     destfile = "data/priority_fields19.feather",
     mode = "wb"
   )
   ```

   Save also two lookup tables from the
   [fennica](https://github.com/fennicahub/fennica) R package, which was used
   to harmonise the data:
   [language_abbreviations.csv](https://raw.githubusercontent.com/fennicahub/fennica/master/inst/extdata/language_abbreviations.csv)
   and
   [PublicationPlaceSynonymes.csv](https://raw.githubusercontent.com/fennicahub/fennica/master/inst/extdata/PublicationPlaceSynonymes.csv)
   (right-click the links and choose *Save link as…*).

Your project should now look like this:

```
fennica-r/
├── fennica-r.Rproj
└── data/
    ├── harmonized_fennica19.feather
    ├── priority_fields19.feather
    ├── language_abbreviations.csv
    └── PublicationPlaceSynonymes.csv
```

Test that everything works by running:

```r
fennica <- arrow::read_ipc_file("data/harmonized_fennica19.feather")
dim(fennica)
```

You should see `72626 79`.
