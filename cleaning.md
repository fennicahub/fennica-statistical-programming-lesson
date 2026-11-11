---
title: "Cleaning: From Raw Records to Tidy Text"
teaching: 40
exercises: 25
---

:::::::::::::::::::::::::::::::::::::: questions

- What do raw bibliographic records look like, and how do we get to know an unfamiliar export?
- What is "formal noise" in catalogue data, and how do we remove it?
- How does the fennica R package clean bibliographic records, and how can we reuse its approach?

::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives

- Profile a raw dataset: unique values, missing values and the most common forms.
- Clean text fields with regular expressions (`grepl()`, `gsub()`, `sub()`).
- Recognise the different ways in which a catalogue says "unknown".
- Clean personal names with `polish_author()` from the fennica package, and check its result on difficult names.
- Write each cleaning step as a function, and apply it to unique values only.
- Read a cleaning function from the fennica package and judge which parts fit another bibliography.

::::::::::::::::::::::::::::::::::::::::::::::::



## Making the data ready for analysis

Throughout this course we follow one research question:

> **How did the shift from Swedish to Finnish in publishing happen in
> 19th-century Finland, and how certain can we be about it?**

To study it we need, for every publication, at least its **language**, its
**place of publication**, its **publisher** and its **author**. None of these
exists as a clean variable in the library catalogue. The next four episodes
make the data ready for analysis, in four steps:

| Step | Question | Episode |
|------|----------|---------|
| **Cleaning** | Is the text free of formal noise? | this episode |
| **Harmonisation** | Does one thing have one name? | Harmonisation |
| **Enrichment** | What can other sources add? | Enrichment |
| **Validation** | How far can we trust the result? | Validation |

In this episode we only **clean**: we remove what is not part of the data
(cataloguing punctuation, brackets, extra spaces) and turn the many ways of
saying "unknown" into missing values. We do *not* yet decide that
*Helsingfors* and *Helsinki* are the same town; that is harmonisation.

::::::::::::::::::::::::::::::::::::: callout

### Data has a history

A catalogue record is not the book itself but a **description** of it, made by
a cataloguer, often a century or more after printing, following cataloguing
rules that have changed over time. The record was then edited, digitised,
exported and processed. Each step can add variation (many spellings of the
same name), missing values (unknown publisher) or errors. Keep asking:
*what process produced this value?* The answer decides how we clean it, and
later, how certain our conclusions can be.

::::::::::::::::::::::::::::::::::::::::::::::::

## The fennica package

The Fennica data has already been cleaned and harmonised once, with the R
package [**fennica**](https://github.com/fennicahub/fennica). It has one
`polish_*()` function per field, for example
[`polish_publisher()`](https://github.com/fennicahub/fennica/blob/master/R/polish_publisher.R),
`polish_place()`, `polish_author()` and `polish_languages()`, and a set of
lookup tables in the folder `inst/extdata`.

We do not install the package. Instead, we build simplified versions of its
functions step by step, so that we understand every decision, and we read
the real functions to see how the project solved the same problems. This is
also how you would adapt the package to another bibliography.

## A first look at the raw records

The file `priority_fields19.feather` contains the raw catalogue records of all
Fennica publications from 1809 to 1917, exported from the National Library of
Finland's catalogue. Only the most important (*priority*) MARC fields are
included.


``` r
raw <- read_ipc_file("data/priority_fields19.feather")
dim(raw)
```

``` output
[1] 72626    60
```

``` r
names(raw)
```

``` output
 [1] "id"                    "fikka_id"              "leader"               
 [4] "field_008"             "other_system_id"       "author_name"          
 [7] "author_date"           "language_work"         "asteri_id"            
[10] "language_041"          "language_original"     "title_uniform"        
[13] "title"                 "title_remainder"       "title_part_number"    
[16] "publication_place"     "publisher"             "publication_place_264"
[19] "physical_dimensions"   "physical_extent"       "publication_frequency"
[22] "publication_dates"     "UDC"                   "UDC_aux"              
[25] "classification_084"    "genre_655"             "genre_655_source"     
[28] "subject_650"           "note_500"              "content_type_336"     
[31] "contents_505"          "summary_520"           "variant_title_246"    
[34] "title_uniform_130"     "title2"                "type_of_record"       
[37] "bibliographic_level"   "Date_entered"          "publication_status"   
[40] "publication_time"      "field_008_33"          "data_element_008"     
[43] "converted_008_33"      "language_008"          "location_a"           
[46] "institution_code"      "sublocation"           "shelving_location"    
[49] "address"               "coded_location"        "noncoded_location"    
[52] "url"                   "call_number"           "item_part"            
[55] "shelving_control"      "call_number_prefix"    "call_number_suffix"   
[58] "piece_designation"     "nonpublic_note"        "public_note"          
```

The columns have readable names, but each one comes from a **MARC field**:
a three-digit field number and a subfield letter. The ones we use are:

| Column | MARC field | Content |
|--------|-----------|---------|
| `id` | 001 | record identifier |
| `field_008` | 008 | fixed-length coded data (dates, language, …) |
| `author_name` | 100a | main author: name |
| `author_date` | 100d | main author: years of life |
| `asteri_id` | 100 (authority link) | main author: identifier in the authority file |
| `language_041` | 041a | language code(s) |
| `language_008` | 008/35–37 | language code inside field 008 |
| `publication_place` | 260a | place of publication |
| `publisher` | 260b | publisher |
| `publication_place_264` | 264a | place of publication (newer rules) |
| `physical_extent` | 300a | number of pages, or type of resource |

We keep only these columns, with short names:


``` r
records <- raw |>
  select(id, field_008,
         author = author_name, author_date, asteri_id,
         language_041, language_008,
         place_260 = publication_place, place_264 = publication_place_264,
         publisher, extent = physical_extent)
```

### Profiling: how messy is each column?

Before cleaning anything we want an overview: how many **different** values
does each column have, and how much is **missing**? We write a function for
it, because we will use it again and again:


``` r
is_blank <- function(x) is.na(x) | str_trim(x) == ""

profile <- function(data) {
  data |>
    summarise(across(everything(), list(
      n_unique = \(x) n_distinct(x[!is_blank(x)]),
      pct_missing = \(x) round(100 * mean(is_blank(x)), 1)
    ))) |>
    pivot_longer(everything(),
                 names_to = c("column", ".value"),
                 names_pattern = "(.*)_(n_unique|pct_missing)")
}

profile(records)
```

``` output
# A tibble: 11 × 3
   column       n_unique pct_missing
   <chr>           <int>       <dbl>
 1 id              72626         0  
 2 field_008       51019         0  
 3 author          11103        37.5
 4 author_date      3758        56.7
 5 asteri_id        4692        52.4
 6 language_041      241         1.8
 7 language_008       42         0.8
 8 place_260        1299        28.7
 9 place_264        1272        73.2
10 publisher        9889        29.3
11 extent          17080         9.1
```

`across()` applies the two summaries to every column, and `pivot_longer()`
turns the one-row result into one row per column. (`\(x)` is a short way of
writing `function(x)`.) We will also often need the number of unique,
non-missing values of a single column:


``` r
n_unique <- function(x) n_distinct(x[!is_blank(x)])
n_unique(records$place_260)
```

``` output
[1] 1299
```

A few numbers stand out already:

- 1,299 different places
  of publication, although Finland had only a few dozen printing towns;
- 9,889 different
  publishers;
- 241 different
  "languages";
- about a third of the records have no author, and almost a third have no
  place in field 260.

## Regular expressions: a quick reference

We clean text with **regular expressions** (regex), small patterns that
describe text:

- `grepl(pattern, x)`: does each value **contain** the pattern? (`TRUE`/`FALSE`)
- `sub(pattern, replacement, x)`: replace the **first** match;
  `gsub()` replaces **all** matches.

| Pattern | Meaning | Example | Matches |
|---------|---------|---------|---------|
| `^` / `$` | start / end of the text | `^Hels` | "**Hels**inki" |
| `.` | any character | `H.lsinki` | "Helsinki", "Hälsinki" |
| `[abc]` | one of these characters | `[,.:]` | a comma, full stop or colon |
| `\\s` | a space | `\\s*:` | ":", " :", "   :" |
| `+` / `*` | one or more / zero or more | `[,.]+$` | ",", ".," at the end |
| `a\|b` | a or b | `Turku\|Åbo` | "Turku" or "Åbo" |
| `( )` and `\\1` | capture a group, and reuse it | `^([0-9]{4})-.*` | "1818-1898" → "1818" |
| `\\b` | word boundary | `\\bförf\\b` | "förf", not "förfat" |

Characters such as `[ ] . | ( )` have special meanings; to match them
literally, escape them (`\\[`, `\\.`) or put them inside brackets (`[|]`).


``` r
places <- c("Helsinki :", "[Helsinki] :", "Turku,", "Helsingfors :")
gsub("\\s*[:,]$", "", places)   # remove a final colon or comma
```

``` output
[1] "Helsinki"    "[Helsinki]"  "Turku"       "Helsingfors"
```

``` r
gsub("\\[|\\]", "", places)     # remove square brackets
```

``` output
[1] "Helsinki :"    "Helsinki :"    "Turku,"        "Helsingfors :"
```

## Formal noise: punctuation and brackets


``` r
records |> count(place_260, sort = TRUE) |> head(15)
```

``` output
# A tibble: 15 × 2
   place_260                          n
   <chr>                          <int>
 1 <NA>                           20812
 2 Helsinki :                     13566
 3 Helsingfors :                  11025
 4 Porvoo :                        2580
 5 Tampere :                       2176
 6 Kuopio :                        1417
 7 Turku :                         1367
 8 Hämeenlinna :                   1113
 9 [Kustannuspaikka tuntematon] :  1067
10 Jyväskylä :                      924
11 Stockholm :                      917
12 Åbo :                            875
13 [S.l.] :                         692
14 Aboae :                          619
15 Pori :                           616
```

Two kinds of problems are mixed here. Some are **formal noise**, which is
not part of the data:

- cataloguing punctuation (`Helsinki :`): it separates MARC subfields;
- square brackets (`[Helsinki] :`): the place is not printed in the book but
  was added by the cataloguer;
- extra spaces and differences in upper and lower case.

Others are real **variation** in the names: *Helsingfors* is the Swedish name
of Helsinki, and *Helsingissä* means "in Helsinki". We leave those for the
next episode. A cleaning function removes only the formal noise:


``` r
clean_place_text <- function(x) {
  x <- sub("[|].*", "", x)                 # keep the first place
  x <- gsub("\\[|\\]|\"", "", x)           # brackets and quotes
  x <- gsub("\\s*[:;,.]+\\s*$", "", x)     # final punctuation
  x <- str_squish(x)                       # extra spaces
  tolower(x)
}

place_text <- clean_place_text(records$place_260)
n_unique(records$place_260)
```

``` output
[1] 1299
```

``` r
n_unique(place_text)
```

``` output
[1] 897
```

Cleaning alone removes a large part of the apparent variation.

::::::::::::::::::::::::::::::::::::: challenge

## Challenge 1: Brackets carry information

Square brackets mean that the cataloguer **added** the place: it is not
printed in the book. What share of the non-missing places in field 260 are
in brackets? Our `clean_place_text()` removes the brackets. What do we lose,
and how could we keep that information?

:::::::::::::::::::::::: solution


``` r
has_place <- !is_blank(records$place_260)
mean(grepl("^\\[", records$place_260[has_place]))
```

``` output
[1] 0.06598603
```

About 7% of
the places were added by a cataloguer. They are usually right, but they are
an **inference**, not a fact printed in the book. Removing the brackets
silently throws that difference away. A good solution is to keep it in a
separate variable before cleaning:


``` r
place_inferred <- grepl("^\\[", records$place_260)
```

Cleaning should never remove information we may need later; if in doubt,
store it in a new column.

:::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::

## Many ways to say "unknown"

A catalogue rarely leaves a field empty when the information is unknown.
It writes a phrase instead:


``` r
tibble(place = place_text) |>
  filter(grepl("tuntematon|^s\\.? ?l$", place)) |>
  count(place, sort = TRUE) |>
  head(6)
```

``` output
# A tibble: 6 × 2
  place                                                                        n
  <chr>                                                                    <int>
1 kustannuspaikka tuntematon                                                1103
2 kustantaja tuntematon                                                        7
3 s.l                                                                          4
4 helsinki kustantaja tuntematon                                               2
5 kristinestad? : kustantaja tuntematon                                        2
6 kustannuspaikka tuntematon : ohion, pennsylvanian ja west virginian suo…     2
```

*Kustannuspaikka tuntematon* is Finnish for "place of publication unknown",
*kustantaja tuntematon* for "publisher unknown", and *s.l.* (*sine loco*) and
*s.n.* (*sine nomine*) are the Latin equivalents. For statistics, they are
all **missing values**, and they must become `NA`. Otherwise "kustannuspaikka
tuntematon" would appear as one of the largest publishing places in
Finland!


``` r
is_unknown <- function(x) {
  grepl("^(kustannuspaikka|kustantaja) tuntematon$|^s\\.? ?[ln]$", x)
}

place_text[is_unknown(place_text)] <- NA
sum(is.na(place_text))
```

``` output
[1] 21928
```

::::::::::::::::::::::::::::::::::::: challenge

## Challenge 2: Why `^` and `$`?

The pattern in `is_unknown()` starts with `^` and ends with `$`, so it only
matches values that are **nothing but** an unknown phrase. Find the values
of `clean_place_text(records$place_260)` that contain "tuntematon" but are
not caught by `is_unknown()`. What would have happened if we had simply used
`grepl("tuntematon", x)`?

:::::::::::::::::::::::: solution


``` r
all_places <- clean_place_text(records$place_260)
all_places[grepl("tuntematon", all_places) & !is_unknown(all_places)] |>
  table() |>
  sort(decreasing = TRUE) |>
  head(5)
```

``` output

                                                                helsinki kustantaja tuntematon 
                                                                                             2 
                                                             käkisalmi : kustantaja tuntematon 
                                                                                             2 
                                                         kristinestad? : kustantaja tuntematon 
                                                                                             2 
kustannuspaikka tuntematon : ohion, pennsylvanian ja west virginian suomalainen raittiusliitto 
                                                                                             2 
                                                                  ekenäs kustantaja tuntematon 
                                                                                             1 
```

In these records the place **and** the publisher ended up in the same
subfield: "helsinki kustantaja tuntematon" means "Helsinki, publisher
unknown". The place is known! A pattern without `^` and `$` would have
deleted it. Anchoring makes a rule stricter, and a strict rule is easier to
trust.

:::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::

## Publisher

The same cleaning works for the publisher. One extra rule removes the word
*distr.* or *jakaja* ("distributor"):


``` r
clean_publisher_text <- function(x) {
  x <- clean_place_text(x)
  gsub(",? *(i )?(distr\\.?|jakaja)$", "", x)
}

publisher_text <- clean_publisher_text(records$publisher)
n_unique(records$publisher)
```

``` output
[1] 9889
```

``` r
n_unique(publisher_text)
```

``` output
[1] 8305
```

The real
[`polish_publisher()`](https://github.com/fennicahub/fennica/blob/master/R/polish_publisher.R)
contains dozens of rules like ours, for example:

```r
x <- gsub("\\bförfattaren\\b|\\bförfattare\\b|\\bförf\\b|\\btekijät\\b",
          "tekijä", x, perl = TRUE)
x <- gsub("\\bsöderstörm\\b", "söderström", x, perl = TRUE)  # a typo
```

`\\b` is a **word boundary**: it makes sure that `\\bförf\\b` matches the
abbreviation *förf*, but not the start of a longer word:


``` r
words <- c("förf", "förf.", "förfat", "en förf")
grepl("förf", words)
```

``` output
[1] TRUE TRUE TRUE TRUE
```

``` r
grepl("\\bförf\\b", words)
```

``` output
[1]  TRUE  TRUE FALSE  TRUE
```

## Author names

The main author is in MARC field 100, subfield `$a`, written in inverted form:
*surname, first names*. Let's look at the most common values:


``` r
records |> count(author, sort = TRUE) |> head(8)
```

``` output
# A tibble: 8 × 2
  author                            n
  <chr>                         <int>
1 <NA>                          27270
2 Topelius, Zacharias,            711
3 Runeberg, Johan Ludvig,         483
4 Sjöström, Axel Gabriel,         326
5 Luther, Martti,                 259
6 Aho, Juhani,                    207
7 Rein, Gabriel,                  153
8 Sahlberg, Carolus Reginaldus,   138
```

### Cataloguing punctuation

Every name ends with cataloguing punctuation, and not always the same one:


``` r
table(str_sub(records$author, -1)) |> sort(decreasing = TRUE) |> head(4)
```

``` output

    ,     .     n     i 
33406 11893    10     8 
```

Most names end with a comma (field 100 continues with the years of life in
subfield `$d`), others with a full stop. As a result, the same person
appears several times:


``` r
records |>
  filter(grepl("^Benedix, Julius", author)) |>
  count(author)
```

``` output
# A tibble: 3 × 2
  author                         n
  <chr>                      <int>
1 Benedix, Julius Roderich,      1
2 Benedix, Julius Roderich.     12
3 Benedix, Julius Roderich.,     1
```

### Brackets and parentheses

A few names contain a second form of the name in brackets or parentheses:


``` r
records |>
  filter(grepl("[][()]", author)) |>
  count(author)
```

``` output
# A tibble: 8 × 2
  author                                        n
  <chr>                                     <int>
1 A[sup ***].                                   1
2 Heikel, Fredrik Hjalmar (Jalmari).            1
3 Krüger, Stephanus Johannes Paulus (Paul).     1
4 Ridge, John James [Jaakko].                   1
5 Siltala (Silfvenius), A. J.                   1
6 Stenwall, Hanna [Kiwi].                       1
7 Tollstadius, Erik [Eerikki].                  1
8 [Engelberg, G.].                              1
```

Look at them carefully. *Stenwall, Hanna [Kiwi]*, *Tollstadius, Erik
[Eerikki]* and *Heikel, Fredrik Hjalmar (Jalmari)* add the **Finnish form**
of a Swedish name: these authors used both. That is exactly the kind of
detail our running question is about, so we keep it in its own column
before we remove it from the name. `str_match()` returns the part of the
text inside the parentheses `( )` of the pattern:


``` r
other_name <- str_match(records$author, "\\s[\\[(]([^])]*)[])]")[, 2]
table(other_name)
```

``` output
other_name
   Eerikki     Jaakko    Jalmari       Kiwi       Paul Silfvenius 
         1          1          1          1          1          1 
```

One name is different: in *[Engelberg, G.]* the **whole** name is in
brackets. As with places, this means the name is not printed in the book:
the cataloguer identified the author. Here we remove only the brackets.

### Transliterated names

Names from Russian are transliterated from the Cyrillic alphabet:


``` r
records |>
  filter(grepl("\"", author)) |>
  count(author)
```

``` output
# A tibble: 6 × 2
  author                              n
  <chr>                           <int>
1 "Buslaev\", F̀. I."                  1
2 "Fedorov\", F. A."                  1
3 "Gogol', Nikolaj Vasil'evič\"."     1
4 "Granstrem\", È,"                   2
5 "Kaulbars\", N."                    1
6 "Kaulbars\", Nikolai,"              1
```

The `"` after *Fedorov* or *Kaulbars* stands for the Russian "hard sign" (ъ),
which the old Russian spelling wrote at the end of many words. It is not
part of the name in Finnish or Swedish texts, so we remove it.


### The fennica function: `polish_author()`

The fennica package has a function for exactly this job:
[`polish_author()`](https://github.com/fennicahub/fennica/blob/master/R/polish_author.R).
We do not need to install the whole package to use it. An R function is just
code, and `source()` can run code directly from GitHub. `polish_author()`
uses five small helper functions from the package, so we load those too:


``` r
fennica_code <- paste0("https://raw.githubusercontent.com/fennicahub/fennica/",
                       "e1c7bbd7337b84d3acc9d890ed843a80b0f14fba/R/")

for (f in c("polish_author", "pick_firstname", "pick_lastname",
            "capitalize", "condense_spaces", "clean_name_col")) {
  source(paste0(fennica_code, f, ".R"))
}
```

The long code in the address is a **commit**: one fixed version of the
package. If the package changes later, our results stay the same. This is
an important habit for reproducible research: always know *which version*
of someone else's code you used. (`polish_author()` also needs the package
**stringi**; install it with `install.packages("stringi")` if you don't have
it.)

Let's try it on the names we have seen:


``` r
examples <- c("Benedix, Julius Roderich.,", "Runeberg, Johan Ludvig,",
              "Setälä, E. N.,", "Kaulbars\", Nikolai,",
              "Stenwall, Hanna [Kiwi].")
polish_author(examples)
```

``` output
                 full_name           first      last
1 Benedix, Julius Roderich Julius Roderich   Benedix
2   Runeberg, Johan Ludvig    Johan Ludvig  Runeberg
3              Setälä, E N             E N    Setälä
4       Kaulbars", Nikolai         Nikolai Kaulbars"
5   Stenwall, Hanna [kiwi]    Hanna [kiwi]  Stenwall
```

`polish_author()` returns a data frame with three columns: the full name
and, separately, the **last** and **first** names. Reading its code on
GitHub, we can see the steps:

1. convert to lower case, and work on unique values only;
2. remove final commas, digits and (meant to remove) brackets;
3. split the name into last and first name: at the comma if there is one,
   otherwise at the last space;
4. capitalise each word, and replace full stops with spaces (`E. N.` →
   `E N`);
5. glue the parts together again as *last, first*.

Now on all records:


``` r
polished <- polish_author(records$author)
n_unique(records$author)
```

``` output
[1] 11103
```

``` r
n_unique(polished$full_name)
```

``` output
[1] 10475
```

### Checking what the function did

A ready-made function is a set of decisions made by someone else, for their
data. Before we trust it, we look at what it does to **our** data. Some
harder cases:


``` r
harder <- c("Thomas Ragvaldinpoika,", "K. H. T.", "Larin-Kyösti,",
            "Åkerman, Anna", "Daniel Henkikäsi, numero 3.",
            "Lindroth, Hjalmar,|1878-1947,")
tibble(raw = harder, polished = polish_author(harder)$full_name)
```

``` output
# A tibble: 6 × 2
  raw                           polished                
  <chr>                         <chr>                   
1 Thomas Ragvaldinpoika,        Ragvaldinpoika, Thomas  
2 K. H. T.                      T, K                    
3 Larin-Kyösti,                 Larin-kyösti            
4 Åkerman, Anna                 åkerman, Anna           
5 Daniel Henkikäsi, numero 3.   Daniel Henkikäsi, Numero
6 Lindroth, Hjalmar,|1878-1947, Lindroth, Hjalmar,|-    
```

Each line shows a decision that does not fit every name:

- *Thomas Ragvaldinpoika* is a **patronymic** ("son of Ragvald"), an older
  Nordic naming practice: there is no surname. The rule "the last word is
  the surname" turns it into *Ragvaldinpoika, Thomas*.
- *K. H. T.* is a **signature**, not a name, and is split as if it were one.
- *Larin-Kyösti* is a **pseudonym**; capitalising "each word" lower-cases
  the part after the hyphen.
- *Åkerman* stays in lower case: the capitalisation only knows the letters
  a–z, not å, ä and ö.
- Removing all digits changes *numero 3* (part of a pseudonym) and leaves a
  dash behind from the years of life in *Lindroth*.
- The brackets in *Stenwall, Hanna [Kiwi]* above were not removed: inside
  `[ ]`, R's regular expressions do not treat `\\` as an escape character,
  so the pattern in the function does not match brackets. The pattern
  `"[][()?]"` would.

None of this makes the function useless: for the large majority of names it
does exactly the right thing. But it shows what a cleaning function really
is: **rules that fit most of the data**. Our job is to find the cases they
don't fit, and to decide whether to change the rules, add exceptions, or
flag the records.

::::::::::::::::::::::::::::::::::::: challenge

## Challenge 3: Names that start in lower case

After `polish_author()`, a name should start with a capital letter. Count
the polished names that start with a **lower-case** letter. Which letters
are they? How would you fix the problem: in the function, or after it?

:::::::::::::::::::::::: solution


``` r
polished |>
  filter(grepl("^[[:lower:]]", full_name)) |>
  count(first_letter = str_sub(full_name, 1, 1), sort = TRUE)
```

``` output
  first_letter   n
1            å 139
2            ö 128
3            ä  18
4            š   8
5            á   1
6            ż   1
```

``` r
polished |>
  filter(grepl("^[[:lower:]]", full_name)) |>
  count(full_name, sort = TRUE) |>
  head(5)
```

``` output
          full_name  n
1 öhquist, Johannes 33
2 åberg, Johan Olof 31
3         åström, N 24
4        åberg, J O 21
5  åkerblom, Rudolf 12
```

Almost all of them are Swedish and Finnish names starting with Å, Ö or Ä,
plus a few names with letters from other alphabets (š, á, ż). The clean fix is
in the function: `capitalize()` loops over `letters`, the 26 letters of the
English alphabet. Using `toupper()` on the first character, which knows all
letters, fixes it for every language. Fixing it **in the function** helps
everyone who uses the package; fixing it after the function only helps us.
This is how open-source tools improve: users find a case that does not fit,
and report or fix it.

:::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: challenge

## Challenge 4: Names that are not names

An author name in field 100 normally has the form *surname, first names*.
Find the raw author names (after removing the final punctuation) that
contain **no comma**. What are they? What does `polish_author()` do with
them, and what should be done with them?

:::::::::::::::::::::::: solution


``` r
no_comma <- records |>
  mutate(author = str_squish(gsub("[,.]+$", "", author))) |>
  filter(!is_blank(author), !grepl(",", author)) |>
  count(author, sort = TRUE) |>
  head(8)

no_comma |>
  mutate(polished = polish_author(author)$full_name)
```

``` output
# A tibble: 8 × 3
  author                         n polished                   
  <chr>                      <int> <chr>                      
1 Larin-Kyösti                  80 Larin-kyösti               
2 Aina                          79 Aina                       
3 Thomas Ragvaldinpoika         78 Ragvaldinpoika, Thomas     
4 Maria                         71 Maria                      
5 Kauppis-Heikki                35 Kauppis-heikki             
6 Parus Ater                    25 Ater, Parus                
7 Catharina Johanneksentytär    20 Johanneksentytär, Catharina
8 Suonio                        19 Suonio                     
```

Several different things are hidden here:

- **pseudonyms**: *Larin-Kyösti* (Karl Gustaf Larson), *Suonio* (Julius
  Krohn), *Kauppis-Heikki* (Heikki Kauppinen), and *Parus Ater* (Latin for
  "coal tit"), which `polish_author()` turns into *Ater, Parus*;
- **patronymics** without a surname: *Thomas Ragvaldinpoika* ("son of
  Ragvald"), *Catharina Johanneksentytär* ("daughter of Johannes");
- **single first names**, such as *Aina* and *Maria*, and **initials** with
  which authors signed their books.

Patronymics are real names and should be kept as they are: reversing them
into "surname, first name" is wrong. Pseudonyms and initials cannot be
turned into persons with a regular expression. We can only **flag** these
records, for example with a variable `author_no_surname`, and leave the
identification to authority data and research. Other differences, such as
*Setälä, E. N.* and *Setälä, Emil Nestor*, are not formal noise either:
merging them is **harmonisation**, the topic of the next episode.

:::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::

### A second, simpler version

The Fennica project's harmonised data already contains the output of
`polish_author()`. To be able to **check** it in the episode on validation,
we also write a deliberately simple cleaning function of our own. It removes
only formal noise, and keeps the name order as the cataloguer wrote it:


``` r
clean_author <- function(x) {
  x <- gsub("\"", "", x)                       # transliterated hard sign
  x <- gsub("\\s+[\\[(][^])]*[])]", "", x)     # other forms: [Kiwi], (Jalmari)
  x <- gsub("^\\[(.*)\\][.,]*$", "\\1", x)     # whole name added by the cataloguer
  x <- gsub("[,.]+$", "", x)                   # final punctuation
  str_squish(x)                                # extra spaces
}

clean_author(c("Benedix, Julius Roderich.,", "Stenwall, Hanna [Kiwi].",
               "[Engelberg, G.].", "Thomas Ragvaldinpoika,"))
```

``` output
[1] "Benedix, Julius Roderich" "Stenwall, Hanna"         
[3] "Engelberg, G"             "Thomas Ragvaldinpoika"   
```

``` r
author <- clean_author(records$author)
n_unique(author)
```

``` output
[1] 10507
```

The order of the steps matters: the inner brackets go first, so that a name
entirely in brackets is not deleted. Two independent versions of the same
variable are a powerful check: wherever they disagree, at least one of them
is wrong.

## Applying a function to unique values only

Our cleaning functions look at every record, but there are only
9,889 different publisher
values for 72,626 records. The fennica
functions therefore clean each **unique** value once and map the result back
to all records with `match()`. We can write this pattern as a general helper:


``` r
map_unique <- function(x, f, ...) {
  values <- unique(x)
  f(values, ...)[match(x, values)]
}

publisher_text <- map_unique(records$publisher, clean_publisher_text)
```

The result is identical, but for slow functions (and millions of records) the
difference in speed is enormous.

::::::::::::::::::::::::::::::::::::: challenge

## Challenge 5: Reuse or rewrite?

Open
[`polish_publisher()`](https://github.com/fennicahub/fennica/blob/master/R/polish_publisher.R)
on GitHub. Find two rules that would work for any bibliography, and two that
only make sense for Fennica. What would you change to use the function on
the national bibliography of another country?

:::::::::::::::::::::::: solution

There is no single right answer. Rules that remove punctuation, brackets and
extra spaces are general. Rules that recognise Finnish and Swedish words
(*tekijä*, *förf*, *tuntematon*), fix typos in specific publisher names, or
merge the names of Finnish publishing houses are specific to Fennica. To
reuse the function, keep the general steps, move the language- and
country-specific words into a **lookup table**, and replace that table for
the new bibliography.

:::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: callout

### Keep the cleaning in a script

Save the cleaning functions in one script and run it from the raw data every
time. Never edit the raw data by hand. Our version is here:
[`clean_records.R`](files/clean_records.R). The next episode starts from it.

::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: keypoints

- Start with a profile of the data: unique values, missing values and the most common forms.
- Cleaning removes formal noise (punctuation, brackets, spaces); harmonisation, in the next episode, merges real variants.
- Catalogues have many ways of saying "unknown"; turn them into `NA`, with strict, anchored patterns.
- Cleaning should not destroy information: keep things like "added by the cataloguer" or an alternative name form in a separate column.
- A ready-made function such as `polish_author()` is a set of rules that fit most of the data: check what it does to yours, and load a fixed version (commit) of it.
- Some values, such as patronymics, initials and pseudonyms, do not fit the rules; keep or flag them instead.
- Write each cleaning step as a function, and apply slow functions to unique values only.
- The fennica package can be reused, but its language- and country-specific rules must be adapted.

::::::::::::::::::::::::::::::::::::::::::::::::
