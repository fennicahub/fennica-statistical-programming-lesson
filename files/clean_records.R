# Clean the raw Fennica records (1809-1917), as in the episode "Cleaning".
#
# Input (in the folder data/):
#   priority_fields19.feather   raw catalogue records
# Run it with source("clean_records.R"). It creates, in your session:
#   raw       the raw records
#   records   the raw columns we use, with short names
# and the cleaning functions used in the following episodes.

library(arrow)
library(dplyr)
library(tidyr)
library(stringr)

# ---- Helpers ---------------------------------------------------------------

is_blank <- function(x) is.na(x) | str_trim(x) == ""
n_unique <- function(x) n_distinct(x[!is_blank(x)])

# Apply f to the unique values of x only, then map the results back
map_unique <- function(x, f, ...) {
  values <- unique(x)
  f(values, ...)[match(x, values)]
}

# ---- Cleaning functions ----------------------------------------------------

# Remove cataloguing punctuation, brackets and extra spaces
clean_place_text <- function(x) {
  x <- sub("[|].*", "", x)                 # keep the first place
  x <- gsub("\\[|\\]|\"", "", x)           # brackets and quotes
  x <- gsub("\\s*[:;,.]+\\s*$", "", x)     # final punctuation
  x <- str_squish(x)                       # extra spaces
  tolower(x)
}

# Phrases that mean "unknown" (after clean_place_text)
is_unknown <- function(x) {
  grepl("^(kustannuspaikka|kustantaja) tuntematon$|^s\\.? ?[ln]$", x)
}

# Publisher: as places, and remove "distributor"
clean_publisher_text <- function(x) {
  x <- clean_place_text(x)
  gsub(",? *(i )?(distr\\.?|jakaja)$", "", x)
}

# Author: transliteration marks, alternative name forms, brackets,
# final punctuation
clean_author <- function(x) {
  x <- gsub("\"", "", x)                       # transliterated hard sign
  x <- gsub("\\s+[\\[(][^])]*[])]", "", x)     # other forms: [Kiwi], (Jalmari)
  x <- gsub("^\\[(.*)\\][.,]*$", "\\1", x)     # whole name added by the cataloguer
  x <- gsub("[,.]+$", "", x)                   # final punctuation
  str_squish(x)                                # extra spaces
}

# ---- Run -------------------------------------------------------------------

raw <- read_ipc_file("data/priority_fields19.feather")
records <- raw |>
  select(id, field_008,
         author = author_name, author_date, asteri_id,
         language_041, language_008,
         place_260 = publication_place, place_264 = publication_place_264,
         publisher, extent = physical_extent)
