# Clean and harmonise the raw Fennica records (1809-1917), as in the
# episodes "Cleaning" and "Harmonisation". This script is self-contained:
# it repeats the cleaning functions from clean_records.R.
#
# Input (in the folder data/):
#   priority_fields19.feather       raw catalogue records
#   language_abbreviations.csv      MARC language codes -> names (fennica package)
#   PublicationPlaceSynonymes.csv   place spellings -> standard names (fennica package)
# Run it with source("harmonise_fennica.R"). It creates, in your session:
#   records        the raw columns we use, with short names
#   fennica_ours   one row per record: id, author, author_id, language,
#                  multilingual, place, publisher

library(arrow)
library(dplyr)
library(stringr)

# ---- Helpers ---------------------------------------------------------------

is_blank <- function(x) is.na(x) | str_trim(x) == ""
n_unique <- function(x) n_distinct(x[!is_blank(x)])

# Apply f to the unique values of x only, then map the results back
map_unique <- function(x, f, ...) {
  values <- unique(x)
  f(values, ...)[match(x, values)]
}

# ---- Language: field 041, filled from field 008 ----------------------------

harmonise_language <- function(code_041, code_008, lookup) {
  code <- coalesce(sub("[|].*", "", code_041), code_008)
  code[code %in% c("|||", "und") | is_blank(code)] <- NA
  lookup$name[match(code, lookup$synonyme)]
}

# ---- Place: field 260, filled from field 264 -------------------------------

clean_place_text <- function(x) {
  x <- sub("[|].*", "", x)                 # keep the first place
  x <- gsub("\\[|\\]|\"", "", x)           # brackets and quotes
  x <- gsub("\\s*[:;,.]+\\s*$", "", x)     # final punctuation
  x <- str_squish(x)                       # extra spaces
  tolower(x)
}

fold <- function(x) chartr("åäöüé", "aaoue", x)

lookup_place <- function(x, synonyms) {
  position <- coalesce(match(x, synonyms$synonyme),
                       match(fold(x), synonyms$synonyme))
  synonyms$name[position]
}

harmonise_place <- function(place_260, place_264, extent, synonyms) {
  # Digitised copies: field 264 gives the place of digitisation (Mikkeli),
  # not the place of printing
  digitised_copy <- is_blank(place_260) & grepl("Mikkeli", place_264) &
    grepl("verkkoaineisto", extent)
  place_264[digitised_copy] <- NA
  map_unique(clean_place_text(coalesce(place_260, place_264)),
             lookup_place, synonyms)
}

# ---- Publisher: field 260b -------------------------------------------------

clean_publisher_text <- function(x) {
  x <- clean_place_text(x)
  gsub(",? *(i )?(distr\\.?|jakaja)$", "", x)
}

harmonise_publisher <- function(x) {
  x <- clean_publisher_text(x)
  case_when(
    grepl("tuntematon|^s\\.? ?n$", x)                     ~ NA,
    grepl("^(tekijä|tekijät|förf|författare|författaren)$", x) ~ "Self-published",
    grepl("söderström|wsoy", x)                           ~ "WSOY",
    grepl("otava", x)                                     ~ "Otava",
    grepl("edlund", x)                                    ~ "Edlund",
    grepl("^(suomalaisen kirjallisuuden seura|sks)\\b", x) ~ "SKS",
    grepl("frenckell", x)                                 ~ "Frenckell",
    .default = str_to_title(x)
  )
}

# ---- Author: field 100a ----------------------------------------------------

clean_author <- function(x) {
  x <- gsub("\"", "", x)                       # transliterated hard sign
  x <- gsub("\\s+[\\[(][^])]*[])]", "", x)     # other forms: [Kiwi], (Jalmari)
  x <- gsub("^\\[(.*)\\][.,]*$", "\\1", x)     # whole name added by the cataloguer
  x <- gsub("[,.]+$", "", x)                   # final punctuation
  str_squish(x)                                # extra spaces
}

# ---- The whole pipeline ----------------------------------------------------

harmonise_records <- function(records, language_table, place_synonyms) {
  records |>
    transmute(
      id,
      author       = clean_author(author),
      author_id    = asteri_id,
      language     = harmonise_language(language_041, language_008, language_table),
      multilingual = grepl("|", language_041, fixed = TRUE),
      place        = harmonise_place(place_260, place_264, extent, place_synonyms),
      publisher    = map_unique(publisher, harmonise_publisher)
    )
}

# ---- Run -------------------------------------------------------------------

raw <- read_ipc_file("data/priority_fields19.feather")
records <- raw |>
  select(id, field_008,
         author = author_name, author_date, asteri_id,
         language_041, language_008,
         place_260 = publication_place, place_264 = publication_place_264,
         publisher, extent = physical_extent)

language_table <- read.csv("data/language_abbreviations.csv", sep = "\t")
place_synonyms <- read.csv("data/PublicationPlaceSynonymes.csv", sep = ";")

fennica_ours <- harmonise_records(records, language_table, place_synonyms)
