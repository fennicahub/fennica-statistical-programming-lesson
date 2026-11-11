---
title: "Probabilistic Analysis: How Certain Can We Be?"
teaching: 45
exercises: 20
---

:::::::::::::::::::::::::::::::::::::: questions

- When did Finnish overtake Swedish in publishing, and how certain can we be about it?
- How do missing values and uncertain dates affect our conclusions?
- How can we express the uncertainty of a result with probabilities?

::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives

- Explain the difference between an estimate and its uncertainty.
- Describe sources of uncertainty in bibliographic data: missing values, selection, uncertain dates and cataloguing decisions.
- Use resampling and simulation to express the uncertainty of a result.
- Report results as ranges and probabilities rather than single numbers.

::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: caution

### In preparation

This episode is being developed. The outline below shows the planned
content.

::::::::::::::::::::::::::::::::::::::::::::::::

## Back to the running question

The whole course has followed one question:

> **How did the shift from Swedish to Finnish in publishing happen in
> 19th-century Finland, and how certain can we be about it?**

The previous parts answered the first half with single numbers: a share, a
slope, a test. But the validation episode showed that these numbers depend
on decisions: which records we keep, how we fill missing values, how we read
an uncertain date. In this part we answer the second half: **how certain can
we be?**

## Research question 4

*When did the share of Finnish-language publications pass 50%, and how
certain is that date?*

Planned content:

- The crossing point as an estimate from a model (logistic regression of
  the probability that a publication is in Finnish, by year).
- **Bootstrap**: resampling the records to get an interval for the
  crossing year.
- Comparing the intervals for different subsets (all records, records with
  a known publisher, records with a known place).

## Research question 5

*How much do missing and uncertain data change the answer?*

Planned content:

- Records without a language: simulating possible languages from what we
  know about similar records (place, publisher, decade).
- Uncertain publication dates (for example "185-?" or date ranges in field
  008): drawing possible years instead of choosing one.
- Repeating the analysis many times and reporting the **distribution** of
  results: a probability for each possible answer.

::::::::::::::::::::::::::::::::::::: keypoints

- Every result from bibliographic data has an uncertainty, which comes from the data as well as from chance.
- Resampling and simulation make that uncertainty visible.
- Report ranges and probabilities, and explain which decisions they depend on.

::::::::::::::::::::::::::::::::::::::::::::::::
