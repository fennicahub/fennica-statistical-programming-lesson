# Prepare the project's harmonised Fennica data for the analysis episodes.
# Run this script to recreate `fennica_clean` in a fresh R session:
#   source("clean_fennica.R")

library(arrow)
library(dplyr)
library(stringr)

fennica <- read_ipc_file("data/harmonized_fennica19.feather")

fennica_clean <- fennica |>
  # The place and publisher columns are swapped in the source data
  rename(place_raw = publisher, publisher_raw = publication_place) |>
  mutate(
    place_raw = str_squish(str_to_lower(place_raw)),
    place = case_when(
      place_raw %in% c("helsinki", "helsingfors", "helsingissä",
                       "gelsingfors", "helsingforsiae") ~ "Helsinki",
      place_raw %in% c("turku", "åbo", "aboae", "abo", "aboa") ~ "Turku",
      place_raw %in% c("viipuri", "wiipuri", "viipurissa",
                       "wiborg", "viborg", "vyborg") ~ "Viipuri",
      place_raw %in% c("porvoo", "porvoossa", "borgå") ~ "Porvoo",
      place_raw %in% c("tampere", "tammerfors") ~ "Tampere",
      place_raw %in% c("vaasa", "vasa") ~ "Vaasa",
      place_raw %in% c("oulu", "uleåborg") ~ "Oulu",
      place_raw %in% c("s peterburg", "st petersburg", "sankt petersburg",
                       "pietari") ~ "St Petersburg",
      place_raw == "kustannuspaikka tuntematon" ~ NA,
      .default = str_to_title(place_raw)
    ),
    publisher = if_else(publisher_raw == "Tuntematon", NA, publisher_raw),
    genre = case_when(
      genre_008 == "Tietokirjallisuus" ~ "Non-fiction",
      genre_008 == "Romaanit" ~ "Novels",
      genre_008 == "Runot" ~ "Poetry",
      genre_008 == "Novellit, kertomukset" ~ "Short stories",
      genre_008 == "Draama" ~ "Drama",
      genre_008 %in% c("Kaunokirjallisuus", "Yhdistelmä", "Puheet, esitelmät",
                       "Kirjeet", "Huumori, satiiri") ~ "Other",
      .default = NA
    ),
    type = if_else(data_element == "Kirjat", "Book", "Serial")
  ) |>
  select(
    id,
    author = author_name_100,
    author_birth,
    author_death,
    title = title_remainder,
    title_words = title_remainder_word,
    language = language_008_primary,
    year = publication_year,
    decade = publication_decade,
    place,
    publisher,
    genre,
    type
  )
