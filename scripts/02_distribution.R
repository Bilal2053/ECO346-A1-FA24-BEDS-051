# 02_distribution.R -- Q2: weighted histogram of annual earnings (log scale).
source("scripts/00_setup.R")

x <- earners$earn_annual
w <- earners$hhweight

# ---- Statistics (all earners) ----
n_earners  <- nrow(earners)
med_w      <- wquantile(x, w, 0.5)
med_u      <- median(x)
p10        <- wquantile(x, w, 0.1)
p90        <- wquantile(x, w, 0.9)
ratio      <- p90 / p10

# ---- Histogram sample: earnings between Rs 10,000 and Rs 10,000,000 ----
in_range   <- x >= 1e4 & x <= 1e7
n_excluded <- sum(!in_range)
h <- earners[in_range, ]
h$log_earn <- log10(h$earn_annual)

cat("Number of earners:          ", n_earners, "\n")
cat("Weighted median (Rs):       ", round(med_w), "\n")
cat("Unweighted median (Rs):     ", round(med_u), "\n")
cat("Weighted P10 (Rs):          ", round(p10), "\n")
cat("Weighted P90 (Rs):          ", round(p90), "\n")
cat("P90/P10 ratio:              ", sprintf("%.2f", ratio), "\n")
cat("Excluded from histogram:    ", n_excluded, "\n")

# ---- Figure ----
# Bins 0.1 wide in log10 units from 4.0 to 7.0.
# y = after_stat(density) with weight = hhweight gives density per log10 unit.
lines_df <- data.frame(
  xpos  = log10(c(med_w, p90)),
  label = c(paste0("Median\n", rs(med_w)), paste0("90th percentile\n", rs(p90)))
)

p <- ggplot(h, aes(x = log_earn)) +
  geom_histogram(aes(y = after_stat(density), weight = hhweight),
                 breaks = seq(4, 7, by = 0.1),
                 fill = "#4C78A8", colour = "white", linewidth = 0.3) +
  geom_vline(data = lines_df, aes(xintercept = xpos),
             linetype = "dashed", colour = "grey20") +
  geom_label(data = lines_df, aes(x = xpos, y = 1.95, label = label),
             hjust = -0.05, size = 3.4, lineheight = 0.9,
             label.size = 0, fill = "white") +
  scale_y_continuous(limits = c(0, 2.1)) +
  scale_x_continuous(limits = c(4, 7), breaks = 4:7,
                     labels = c("Rs 10,000", "Rs 100,000",
                                "Rs 1,000,000", "Rs 10,000,000")) +
  labs(
    title = paste0("Half of urban Sindh's earners make under ", rs(med_w),
                   " a year; the top tenth earn over ", rs(p90)),
    x = "Annual earnings (log scale)",
    y = "Density per log10 unit",
    caption = paste0(SOURCE_TXT,
      " Sample: urban Sindh, ages 15-64, annual earnings > 0 (n = ",
      comma(n_earners), ").\nWeighted by household weight (hhweight). ",
      n_excluded, " earners outside Rs 10,000-10,000,000 excluded from the histogram.")
  ) +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(),
        plot.title = element_text(face = "bold", size = 11.5),
        plot.caption = element_text(hjust = 0, colour = "grey30"))

ggsave("figures/distribution.svg", p, width = 9, height = 5.5)
