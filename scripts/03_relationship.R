# 03_relationship.R -- Q3: earnings against age with weighted band means.
# This figure is also the Q4 redesign of figures/default.svg.
source("scripts/00_setup.R")

# ---- Band table: band, number of earners, weighted mean earnings ----
bands <- earners %>%
  group_by(band, band_mid) %>%
  summarise(n = n(),
            wmean_earn = wmean(earn_annual, hhweight),
            .groups = "drop") %>%
  arrange(band_mid) %>%
  mutate(thin = n < 30)

bands_out <- bands %>%
  transmute(band, n_earners = n, weighted_mean_earnings = round(wmean_earn))
write.csv(bands_out, "figures/band_table_R.csv", row.names = FALSE, quote = FALSE)
print(as.data.frame(bands_out))

top <- bands[which.max(bands$wmean_earn), ]
cat("\n25-29 weighted mean (Rs):", round(bands$wmean_earn[bands$band == "25-29"]), "\n")
cat("45-49 weighted mean (Rs):", round(bands$wmean_earn[bands$band == "45-49"]), "\n")
cat("Band with highest mean:  ", top$band, "\n")

# ---- Figure ----
set.seed(346)  # jitter is random; fixing the seed makes the SVG reproducible

p <- ggplot() +
  # Every earner: alpha 0.15 so dense areas darken and single points stay visible
  geom_jitter(data = earners, aes(age, earn_annual),
              width = 0.4, height = 0,
              alpha = 0.15, size = 1.2, colour = "grey40") +
  geom_line(data = bands, aes(band_mid, wmean_earn),
            colour = "#C0392B", linewidth = 1) +
  # Filled marker (shape 21) for normal bands, white fill = hollow for thin bands
  geom_point(data = bands, aes(band_mid, wmean_earn, fill = thin),
             shape = 21, size = 3.5, colour = "#C0392B", stroke = 1.2,
             show.legend = FALSE) +
  scale_fill_manual(values = c(`FALSE` = "#C0392B", `TRUE` = "white")) +
  annotate("text", x = top$band_mid, y = top$wmean_earn * 2.2,
           label = paste0("Peak: ages ", top$band, "\nmean ", rs(top$wmean_earn)),
           size = 3.4, fontface = "bold", colour = "#C0392B", lineheight = 0.9) +
  annotate("segment", x = top$band_mid, xend = top$band_mid,
           y = top$wmean_earn * 1.75, yend = top$wmean_earn * 1.15,
           colour = "#C0392B") +
  scale_y_log10(limits = c(1e4, 1e7),
                breaks = c(1e4, 1e5, 1e6, 1e7),
                labels = c("Rs 10,000", "Rs 100,000", "Rs 1,000,000", "Rs 10,000,000")) +
  scale_x_continuous(limits = c(14.5, 64.5), breaks = seq(15, 65, 5)) +
  labs(
    title = paste0("Mean earnings in urban Sindh rise with age and peak at ",
                   top$band, " (", rs(top$wmean_earn), ")"),
    x = "Age (years)",
    y = "Annual earnings (log scale)",
    caption = paste0(SOURCE_TXT,
      " Sample: urban Sindh, ages 15-64, annual earnings > 0 (n = ",
      comma(nrow(earners)), ").\nRed markers: weighted mean earnings of each ",
      "five-year age band (hhweight), at the band midpoint.\nHollow markers = ",
      "thin bands (< 30 earners; none here). Grey points: individual earners, ",
      "jittered by up to 0.4 years.\nThe 2 earners outside Rs 10,000-10,000,000 lie off the log scale and are not drawn.")
  ) +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(),
        plot.title = element_text(face = "bold", size = 11.5),
        plot.caption = element_text(hjust = 0, colour = "grey30"))

ggsave("figures/relationship.svg", p, width = 9, height = 6)
