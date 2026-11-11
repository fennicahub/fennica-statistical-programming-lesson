---
title: "Harmonisation: One Name for One Thing"
teaching: 40
exercises: 20
---

:::::::::::::::::::::::::::::::::::::: questions

- How do we turn cleaned catalogue fields into consistent variables we can analyse?
- How do we combine information from several MARC fields?
- How can harmonisation be written as reusable, reproducible code?

::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives

- Harmonise codes and name variants with lookup tables and `match()`.
- Combine information from several MARC fields with `coalesce()`, and recognise when a field measures something else than you think.
- Use authority identifiers to tell persons apart.
- Collect all steps into one pipeline function that runs from the raw data.

::::::::::::::::::::::::::::::::::::::::::::::::



## Getting started

In the previous episode we **cleaned** the records: the text is free of
punctuation and brackets, and "unknown" phrases are recognised. But
*Helsingfors* and *Helsinki* are still two different values, and a language
code is not yet a language. **Harmonisation** gives one thing one name.

If you are starting a new R session, download
[`clean_records.R`](files/clean_records.R) into your project folder and run
it. It loads the raw records and defines the cleaning functions:


``` r
source("clean_records.R")
```

## 1. Language


``` r
records |> count(language_041, sort = TRUE) |> head(12)
```

``` output
# A tibble: 12 × 2
   language_041     n
   <chr>        <int>
 1 fin          37707
 2 swe          22270
 3 lat           2506
 4 ger           2283
 5 fin|swe       1740
 6 <NA>          1330
 7 rus            848
 8 fre            702
 9 eng            452
10 swe|fin        252
11 swe|lat        203
12 dan            157
```

The values are three-letter **MARC language codes** (`fin` Finnish, `swe`
Swedish, `lat` Latin, `ger` German, …). Several languages are joined with
`|`, which is why there are so many "languages". How many records are
multilingual, and how many have no code at all?


``` r
sum(grepl("|", records$language_041, fixed = TRUE))
```

``` output
[1] 3843
```

``` r
sum(is_blank(records$language_041))
```

``` output
[1] 1330
```

`fixed = TRUE` treats `|` as plain text rather than as "or". We keep the
first code, the **primary language**:


``` r
primary_041 <- sub("[|].*", "", records$language_041)
n_unique(records$language_041)
```

``` output
[1] 241
```

``` r
n_unique(primary_041)
```

``` output
[1] 40
```

### A second source: field 008

The language is recorded **twice** in a MARC record: in field 041 and inside
the fixed-length field 008 (positions 36–38). Two independent records of the
same thing are valuable: we can fill gaps, and we can check one against the
other.


``` r
mean(primary_041 == records$language_008, na.rm = TRUE)
```

``` output
[1] 0.9958904
```

``` r
records |>
  mutate(primary_041 = primary_041) |>
  filter(primary_041 != language_008) |>
  count(primary_041, language_008, sort = TRUE) |>
  head(6)
```

``` output
# A tibble: 6 × 3
  primary_041 language_008     n
  <chr>       <chr>        <int>
1 fin         "mul"          192
2 swe         "fin"           22
3 fin         "swe"           21
4 swe         "mul"           12
5 fin         "   "            6
6 gem         "mul"            6
```

The two agree for more than 99.5% of the records. Most disagreements are
books that 041 calls Finnish and 008 calls `mul` (multiple languages). And
the records without field 041?


``` r
records |>
  filter(is_blank(language_041)) |>
  count(language_008, sort = TRUE) |>
  head(6)
```

``` output
# A tibble: 6 × 2
  language_008     n
  <chr>        <int>
1 "   "          568
2 "swe"          326
3 "fin"          318
4 "lat"           38
5 "|||"           34
6 "rus"           25
```

For about half of them, field 008 has a language code; the rest are blank
(`"   "`) or not coded (`|||`). Notice also that more of the recovered
records are Swedish than Finnish: a gap in one field is not spread evenly
over the languages. We use 041 when it exists and 008 otherwise.
`coalesce()` from dplyr takes the first non-missing value. Codes like `|||`
("not coded"), `und` ("undetermined") and blanks are not languages, so we
make them `NA`:


``` r
language_code <- coalesce(primary_041, records$language_008)
language_code[language_code %in% c("|||", "und") | is_blank(language_code)] <- NA
sum(is.na(language_code))
```

``` output
[1] 617
```

### From codes to names with a lookup table

To translate codes into names we use a **lookup table**: the file
`language_abbreviations.csv` from the fennica package. `match(x, table)`
returns, for each value of `x`, its position in `table`:


``` r
language_table <- read.csv("data/language_abbreviations.csv", sep = "\t")
head(language_table, 3)
```

``` output
  synonyme     name comment
1      aar     Afar      NA
2      abk   Abkhaz      NA
3      ace Achinese      NA
```

``` r
language <- language_table$name[match(language_code, language_table$synonyme)]
sort(table(language), decreasing = TRUE)[1:6]
```

``` output
language
Finnish Swedish   Latin  German Russian  French 
  40581   23352    2844    2355     937     732 
```

A lookup table is easier to read, check and extend than a long chain of
`gsub()` calls. It is also **data**, which can be shared and corrected
independently of the code.

### Writing it as a function

We will want to repeat these steps on new exports of the catalogue, so we
collect them into a function:


``` r
harmonise_language <- function(code_041, code_008, lookup) {
  code <- coalesce(sub("[|].*", "", code_041), code_008)
  code[code %in% c("|||", "und") | is_blank(code)] <- NA
  lookup$name[match(code, lookup$synonyme)]
}

language <- harmonise_language(records$language_041, records$language_008,
                               language_table)
```

::::::::::::::::::::::::::::::::::::: challenge

## Challenge 1: Bilingual publications

Make a logical variable `multilingual` that is `TRUE` when field 041 has more
than one language code. Which language combinations are the most common
among the multilingual records? What would you lose for the running question
if you kept only the primary language?

:::::::::::::::::::::::: solution


``` r
multilingual <- grepl("|", records$language_041, fixed = TRUE)
sum(multilingual)
```

``` output
[1] 3843
```

``` r
records |>
  filter(multilingual) |>
  count(language_041, sort = TRUE) |>
  head(5)
```

``` output
# A tibble: 5 × 2
  language_041     n
  <chr>        <int>
1 fin|swe       1740
2 swe|fin        252
3 swe|lat        203
4 fin|ger        146
5 fin|eng        122
```

Finnish–Swedish publications (both orders) are by far the most common. They
are exactly the books where the language shift becomes visible: official
announcements and textbooks printed in both languages. Keeping only the
primary language turns them into "Finnish" or "Swedish" depending on which
was listed first. That is why we keep `multilingual` as a separate variable.

:::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::

## 2. Place of publication

After cleaning, the place names are free of punctuation, but the same town
still has many names. How many ways are there to write Helsinki?


``` r
place_text <- clean_place_text(records$place_260)
helsinki_like <- grep("^(hels|gels)", place_text, value = TRUE)
n_unique(helsinki_like)
```

``` output
[1] 36
```

``` r
head(sort(table(helsinki_like), decreasing = TRUE), 10)
```

``` output
helsinki_like
       helsinki     helsingfors     helsingissä  helsingforsiae     gelsingfors 
          14105           11556             520              10               6 
helsingissä hki     helsingfros       helsingis      helsigfors     helsingborg 
              5               4               4               3               3 
```

`grep(..., value = TRUE)` returns the matching values themselves. There are
**different languages** (*Helsingfors* in Swedish, *Gel'singfors* in
Russian), **inflected forms** (*Helsingissä*, "in Helsinki") and also
*Helsingborg*, a town in **Sweden**: always look at what a pattern matches
before trusting it.

### Harmonising names with a synonym table

Merging the variants (Helsingfors → Helsinki, Åbo → Turku, …) with one
`grepl()` line per town would never end. The fennica package keeps a
**synonym table**, `PublicationPlaceSynonymes.csv`, with known spellings
(`synonyme`) and the standard name (`name`), collected over years of work:


``` r
place_synonyms <- read.csv("data/PublicationPlaceSynonymes.csv", sep = ";")
nrow(place_synonyms)
```

``` output
[1] 9921
```

``` r
place_synonyms |> filter(name == "Helsinki") |> nrow()
```

``` output
[1] 85
```

``` r
place_synonyms |> filter(name == "Turku") |> pull(synonyme) |> head(15)
```

``` output
 [1] "aabo"                   "aàbo"                   "abae"                  
 [4] "a bl"                   "a bo"                   "abo"                   
 [7] "aboa"                   "aboae"                  "aboae abo"             
[10] "aboae abo finland"      "aboae fennorum"         "aboae finland"         
[13] "aboae finnorum"         "aboae ime"              "aboae impensis autoris"
```

Many entries are written without special characters (`abo`, `borga`), because
the fennica pipeline replaces å, ä and ö before the lookup. We do the same
with `chartr()`, which replaces characters one by one, and look up both the
original and the simplified form:


``` r
fold <- function(x) chartr("åäöüé", "aaoue", x)

lookup_place <- function(x, synonyms) {
  position <- coalesce(match(x, synonyms$synonyme),
                       match(fold(x), synonyms$synonyme))
  synonyms$name[position]
}

place <- map_unique(place_text, lookup_place, place_synonyms)
n_unique(place_text)
```

``` output
[1] 897
```

``` r
n_unique(place)
```

``` output
[1] 375
```

``` r
sort(table(place), decreasing = TRUE)[1:10]
```

``` output
place
   Helsinki      Porvoo       Turku     Tampere      Kuopio Hämeenlinna 
      26305        3254        3086        2461        1488        1261 
     Vyborg   Stockholm   Jyväskylä       Vaasa 
       1156        1046        1003         744 
```

One lookup merges hundreds of variants. Which frequent values were **not**
found?


``` r
tibble(place_text, place) |>
  filter(is.na(place), !is.na(place_text)) |>
  count(place_text, sort = TRUE) |>
  head(8)
```

``` output
# A tibble: 8 × 2
  place_text                     n
  <chr>                      <int>
1 kustannuspaikka tuntematon  1103
2 s.l.                         692
3 s.-peterburg                 210
4 hancock (mich.)              187
5 gel'singfors                 112
6 fitchburg (mass.)            109
7 brooklyn (n.y.)               53
8 duluth (minn.)                51
```

First the "unknown place" phrases, which should be missing values anyway.
Then Russian transliterations (`s.-peterburg`, `gel'singfors`) and towns
in the United States such as Hancock, Michigan, where Finnish emigrants ran
their own printing presses. A synonym table is never finished: when you find
missing entries like these, you add rows to the table, not code.

### A second place field: 264

Almost a third of the records have no field 260. Newer cataloguing rules
(RDA) record the place in field **264** instead:


``` r
sum(is_blank(records$place_260))
```

``` output
[1] 20812
```

``` r
sum(is_blank(records$place_260) & !is_blank(records$place_264))
```

``` output
[1] 19424
```

So we can fill most of the gaps from 264, just like we filled the language
from 008:


``` r
place_combined <- map_unique(
  clean_place_text(coalesce(records$place_260, records$place_264)),
  lookup_place, place_synonyms)

sort(table(place_combined), decreasing = TRUE)[1:6]
```

``` output
place_combined
Helsinki  Mikkeli    Turku   Porvoo  Tampere   Kuopio 
   31496     8895     3936     3900     2734     1636 
```

::::::::::::::::::::::::::::::::::::: challenge

## Challenge 2: A surprising printing centre

After adding field 264, **Mikkeli**, a small town in eastern Finland,
suddenly becomes one of the largest publishing places in the country. Is that
plausible? Look at the raw records of these publications: their `place_264`,
`extent` and `field_008`. What is going on, and how should we handle these
records?

Hint: in field 008, position 7 is the type of date, and positions 8–11 the
first date.

:::::::::::::::::::::::: solution


``` r
from_mikkeli <- is_blank(records$place_260) & grepl("Mikkeli", records$place_264)
sum(from_mikkeli)
```

``` output
[1] 8673
```

``` r
records |>
  filter(from_mikkeli) |>
  count(online = grepl("verkkoaineisto", extent),
        date_type = substr(field_008, 7, 7),
        sort = TRUE) |>
  head(4)
```

``` output
# A tibble: 4 × 3
  online date_type     n
  <lgl>  <chr>     <int>
1 TRUE   r          8637
2 FALSE  s            19
3 TRUE   d            11
4 FALSE  d             3
```

``` r
records |>
  filter(from_mikkeli, grepl("verkkoaineisto", extent)) |>
  transmute(place_264, extent, date_type = substr(field_008, 7, 7),
            date1 = substr(field_008, 8, 11), date2 = substr(field_008, 12, 15)) |>
  head(4)
```

``` output
# A tibble: 4 × 5
  place_264                            extent              date_type date1 date2
  <chr>                                <chr>               <chr>     <chr> <chr>
1 Mikkeli :|[Mikkeli] :|Jyväskylä :    1 verkkoaineisto    c         1917  9999 
2 Savonlinna :|[Mikkeli] :|Jyväskylä : 1 verkkoaineisto    c         1917  9999 
3 [Mikkeli] :                          1 verkkoaineisto (… r         2010  1861 
4 Mikkeli :                            1 verkkoaineisto    d         1888  1892 
```

Almost all of them have the extent *verkkoaineisto* ("online resource") and
the date type `r` (reproduction): the first date is in the 2010s or 2020s,
and the second date is the original 19th-century year. These records
describe **digitised copies**. The National Library of Finland's digitisation
centre is in Mikkeli, so field 264 gives the place of **digitisation**, not of
printing! The 19th-century place of publication is simply not recorded.
The honest value is `NA`:


``` r
digitised_copy <- from_mikkeli & grepl("verkkoaineisto", records$extent)
place_combined[digitised_copy] <- NA
sort(table(place_combined), decreasing = TRUE)[1:6]
```

``` output
place_combined
Helsinki    Turku   Porvoo  Tampere   Kuopio   Vyborg 
   31495     3936     3900     2734     1636     1472 
```

Field 260 also has a few hundred books really printed in Mikkeli; they are
not affected, because they have a field 260.

This is the most important lesson of the episode: a field can be perfectly
clean and still **measure something else** than you think.

:::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::

We put the place steps together in one function:


``` r
harmonise_place <- function(place_260, place_264, extent, synonyms) {
  digitised_copy <- is_blank(place_260) & grepl("Mikkeli", place_264) &
    grepl("verkkoaineisto", extent)
  place_264[digitised_copy] <- NA
  map_unique(clean_place_text(coalesce(place_260, place_264)),
             lookup_place, synonyms)
}

place <- harmonise_place(records$place_260, records$place_264,
                         records$extent, place_synonyms)
```

## 3. Publisher

After cleaning, the publisher names still have many variants. Look at one
large publisher, Werner Söderström (today WSOY):


``` r
records |>
  filter(grepl("Söderström|WSOY", publisher)) |>
  count(publisher = clean_publisher_text(publisher), sort = TRUE) |>
  head(8)
```

``` output
# A tibble: 8 × 2
  publisher             n
  <chr>             <int>
1 wsoy               2451
2 söderström         1058
3 werner söderström   142
4 söderström & c:o     67
5 g. l. söderström     22
6 w. söderström        12
7 söderström & co       7
8 söderström ja k       6
```

There is no synonym table for publishers, so we merge the largest ones with
rules. *Tekijä* and *förf.* ("the author") mean that the author published
the book:


``` r
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

publisher <- map_unique(records$publisher, harmonise_publisher)
n_unique(records$publisher)
```

``` output
[1] 9889
```

``` r
n_unique(publisher)
```

``` output
[1] 8159
```

``` r
sort(table(publisher), decreasing = TRUE)[1:8]
```

``` output
publisher
              WSOY     Self-published             Edlund              Otava 
              3787               2096               2006               1951 
         Frenckell                SKS            Karisto Raittiuden Ystävät 
              1166                800                560                427 
```

`case_when()` tests the conditions in order and uses the first one that is
`TRUE`; `.default` is used when none is.

::::::::::::::::::::::::::::::::::::: callout

### When to stop?

Thousands of publisher names remain, most of them small printing houses that
appear once or twice. A good rule: harmonise what affects **your research
question**, usually the frequent values, and **document** what you left as
it is.

::::::::::::::::::::::::::::::::::::::::::::::::

## 4. Author

### Name strings are not persons

Cleaning removed the punctuation from the names, but it cannot tell us
**who** a name refers to. Look at the Runebergs:


``` r
records |>
  filter(grepl("^Runeberg", author)) |>
  count(author, asteri_id)
```

``` output
# A tibble: 10 × 3
   author                   asteri_id     n
   <chr>                    <chr>     <int>
 1 Runeberg, Birger,        <NA>          2
 2 Runeberg, Carolina,      000119432     2
 3 Runeberg, Efraim Otto,   000095244     1
 4 Runeberg, Fredrika,      000057304     5
 5 Runeberg, J. L.          <NA>          5
 6 Runeberg, Johan Ludvig,  000057305   483
 7 Runeberg, Johan Wilhelm, 000086231    17
 8 Runeberg, Lorenzo,       000114079     2
 9 Runeberg, Nino,          000057307    16
10 Runeberg, Robert,        000114080     2
```

The column `asteri_id` is the person's identifier in **Asteri**, the Finnish
national authority file. It tells us that *Johan Ludvig* (the national poet),
*Johan Wilhelm* (his son), *Fredrika* (his wife) and *Nino* are different
people. It also shows a limit: `Runeberg, J. L.` has no identifier, so
nothing in the data says for certain that it is the poet.

The identifier also separates people who share **the same name**:


``` r
records |>
  filter(grepl("^Dumas, Alexandre", author)) |>
  count(author = clean_author(author), asteri_id, author_date)
```

``` output
# A tibble: 4 × 4
  author           asteri_id author_date     n
  <chr>            <chr>     <chr>       <int>
1 Dumas, Alexandre 000041746 1824-1895,      1
2 Dumas, Alexandre 000041747 1802-1870,     12
3 Dumas, Alexandre 000041747 1802-1870.     27
4 Dumas, Alexandre <NA>      <NA>            2
```

Alexandre Dumas the father (1802–1870, *The Three Musketeers*) and the son
(1824–1895, *The Lady of the Camellias*) have exactly the same name string.
When an identifier exists, it is the better way to count persons:


``` r
author <- clean_author(records$author)
has_id <- !is.na(records$asteri_id)
mean(has_id)
```

``` output
[1] 0.4757112
```

``` r
n_unique(author[has_id])
```

``` output
[1] 4668
```

``` r
n_unique(records$asteri_id[has_id])
```

``` output
[1] 4692
```

Among the records that have an identifier, there are slightly **more**
persons than name strings: identical names hide different people. For the
other half of the records we only have the string. In the episode on
enrichment we look at how external authority data can help.

::::::::::::::::::::::::::::::::::::: challenge

## Challenge 3: Anonymous books

About a third of the records have no author. Use `records` and the `language`
variable to calculate the share of records **without** an author for each
of the five most common languages. Is a missing author equally likely in
every language? Why might that matter for the running question?

:::::::::::::::::::::::: solution


``` r
records |>
  mutate(language = language, no_author = is_blank(author)) |>
  filter(language %in% c("Finnish", "Swedish", "Latin", "German", "Russian")) |>
  group_by(language) |>
  summarise(records = n(), pct_no_author = round(100 * mean(no_author), 1))
```

``` output
# A tibble: 5 × 3
  language records pct_no_author
  <chr>      <int>         <dbl>
1 Finnish    40581          38.5
2 German      2355          11.6
3 Latin       2844          10.9
4 Russian      937          42.3
5 Swedish    23352          42.2
```

Latin and German publications (often academic dissertations) almost always
have an author; Finnish, Swedish and Russian ones much less often (official
publications, hymn books, almanacs, popular prints). If we analysed only
records with a known author, we would look at a **selected** part of the
bibliography. We come back to this in the episode on validation.

:::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::

## Putting it together: a reproducible pipeline

We now have one function per field. A final function applies them all and
returns one analysis-ready table:


``` r
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

fennica_ours <- harmonise_records(records, language_table, place_synonyms)
glimpse(fennica_ours)
```

``` output
Rows: 72,626
Columns: 7
$ id           <chr> "1001523", "1002166", "1003435", "1003442", "1004966", "1…
$ author       <chr> "Schauman, Frans Ludvig", "Hällsten, Jakob", "Ingman, San…
$ author_id    <chr> "000106938", NA, "000091801", "000096656", "000162696", "…
$ language     <chr> "Swedish", "Latin", "Finnish", "Swedish", "Swedish", "Swe…
$ multilingual <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, FA…
$ place        <chr> "Helsinki", "Helsinki", "Helsinki", "Helsinki", "Helsinki…
$ publisher    <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
```

How much did cleaning and harmonisation reduce the variation?


``` r
tibble(
  field = c("author", "language", "place", "publisher"),
  raw = c(n_unique(records$author), n_unique(records$language_041),
          n_unique(records$place_260), n_unique(records$publisher)),
  harmonised = c(n_unique(fennica_ours$author), n_unique(fennica_ours$language),
                 n_unique(fennica_ours$place), n_unique(fennica_ours$publisher))
)
```

``` output
# A tibble: 4 × 3
  field       raw harmonised
  <chr>     <int>      <int>
1 author    11103      10507
2 language    241         39
3 place      1299        395
4 publisher  9889       8159
```

Language and place became much tidier; author and publisher improved less,
because much of their variation is real (there really were thousands of
authors and printers), and the rest needs external knowledge such as
authority files.

::::::::::::::::::::::::::::::::::::: callout

### Keep the pipeline in a script

Save all the functions in one script, for example `harmonise_fennica.R`, and
run it from the raw data every time. When the library publishes a new
export, or when you find a new problem (like Mikkeli), you fix the script
and rerun it, and every result downstream is updated. Our version, with the
cleaning functions included, is here:
[`harmonise_fennica.R`](files/harmonise_fennica.R).

::::::::::::::::::::::::::::::::::::::::::::::::

We save the result for the next episodes:


``` r
write_ipc_file(fennica_ours, "data/fennica_ours.feather")
```

::::::::::::::::::::::::::::::::::::: keypoints

- Harmonisation gives one thing one name: one code for one language, one name for one town.
- Lookup and synonym tables translate codes and merge variants; they are data that can be shared and corrected.
- The same information is often recorded in several MARC fields (041 and 008, 260 and 264); combine them with `coalesce()`, but check what each field really records.
- A clean value can still measure the wrong thing: for digitised copies, field 264 gives the place of digitisation.
- Name strings are not persons; authority identifiers are needed to tell people apart.
- Write each step as a function and run the whole pipeline from the raw data.

::::::::::::::::::::::::::::::::::::::::::::::::
