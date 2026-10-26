# 00_setup.R -- shared data preparation, sourced by every R script.
# Variant 3 (reg. no. FA24-BEDS-051: 51 = 6*8 + 3) = Sindh urban.

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(scales)
  library(svglite)
})

# Read the local copies of the data (no internet needed)
person <- read.csv("data/pslm_person_subset.csv")
hh     <- read.csv("data/pslm_hh_subset.csv")

# Attach weight, province and area from the household file by hhid
hh_vars <- hh[, c("hhid", "hhweight", "prov_code", "urban_rural")]
df <- merge(person, hh_vars, by = "hhid")

# Variant 3: prov_code 3 = Sindh, urban_rural 2 = urban
# Earners: aged 15-64 with annual earnings > 0
earners <- df %>%
  filter(prov_code == 3, urban_rural == 2,
         age >= 15, age <= 64,
         !is.na(earn_annual), earn_annual > 0)

# Five-year age bands 15-19, ..., 60-64, plotted at midpoints 17, ..., 62
earners$band_lo  <- 15 + 5 * floor((earners$age - 15) / 5)
earners$band     <- paste0(earners$band_lo, "-", earners$band_lo + 4)
earners$band_mid <- earners$band_lo + 2

# Weighted quantile, exactly as defined in the assignment:
# sort by x, cumulative share of weight, smallest x whose share >= p
wquantile <- function(x, w, p) {
  o <- order(x)
  x <- x[o]; w <- w[o]
  share <- cumsum(w) / sum(w)
  x[which(share >= p)[1]]
}

# Weighted mean: sum(w * x) / sum(w)
wmean <- function(x, w) sum(w * x) / sum(w)

# Rupee label helper: 10000 -> "Rs 10,000"
rs <- function(v) paste0("Rs ", comma(round(v)))

dir.create("figures", showWarnings = FALSE)
SOURCE_TXT <- "Source: PSLM 2019-20 person and household files."
