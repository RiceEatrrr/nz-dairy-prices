library(readr)
library(dplyr)
library(ggplot2)
library(lubridate)

# ── Parameters ────────────────────────────────────────────────────────────────
HERD_SIZE       <- 500
AUCTIONS_SEASON <- 24   # GDT runs ~fortnightly, ~24 auctions per June–May season

breeds <- tibble(
  breed         = c("Friesian", "Jersey", "Friesian-Jersey Cross"),
  kg_ms_per_cow = c(385, 355, 370)
)

# ── Load scraped auction data ─────────────────────────────────────────────────
milk_summary <- read_csv("data/milk_price_summary.csv",
                         col_types = cols(
                           scrape_date          = col_date(),
                           wmp_c2_usd           = col_double(),
                           wmp_c2_nzd_per_kg_ms = col_double()
                         ))

# ── Filter to current season (June 1 – May 31) ───────────────────────────────
# Work out which season we're in based on today's date
today        <- Sys.Date()
season_year  <- if_else(month(today) >= 6, year(today), year(today) - 1)
season_start <- ymd(paste0(season_year, "-06-01"))
season_end   <- ymd(paste0(season_year + 1, "-05-31"))

current_season <- milk_summary %>%
  filter(!is.na(wmp_c2_nzd_per_kg_ms),
         scrape_date >= season_start,
         scrape_date <= season_end) %>%
  group_by(scrape_date) %>%
  slice_tail(n = 1) %>%   # one entry per auction date
  ungroup() %>%
  arrange(scrape_date)

# ── Season-to-date average and projection ────────────────────────────────────
auctions_elapsed   <- nrow(current_season)
season_avg_to_date <- mean(current_season$wmp_c2_nzd_per_kg_ms)
auctions_remaining <- AUCTIONS_SEASON - auctions_elapsed

cat("Season:", season_year, "/", season_year + 1, "\n")
cat("Auctions recorded so far:", auctions_elapsed, "\n")
cat("Season-to-date avg NZD/kg MS: $", round(season_avg_to_date, 2), "\n")
cat("Auctions remaining (est.):", auctions_remaining, "\n")

# Projection: hold current average constant for remaining auctions
projected_season_avg <- season_avg_to_date   # simplest assumption

projected_revenue <- breeds %>%
  mutate(
    total_kg_ms      = kg_ms_per_cow * HERD_SIZE,
    revenue_projected = total_kg_ms * projected_season_avg
  )

cat("\nProjected full-season revenue (500-cow herd, prices hold at current avg):\n")
print(projected_revenue %>% select(breed, revenue_projected))

# ── Last season Fonterra payout for comparison ────────────────────────────────
# Fonterra farmgate milk price history (NZD/kg MS, season end year)
fonterra_history <- tibble(
  season_end = c(2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,
                 2012,2013,2014,2015,2016,2017,2018,2019,2020,2021,
                 2022,2023,2024,2025),
  milk_price = c(4.00,3.90,4.25,4.58,4.46,4.46,7.66,5.10,6.10,7.90,
                 6.08,5.84,8.40,4.40,3.90,6.12,6.69,6.35,7.14,7.54,
                 9.30,8.22,7.83,9.50)
)

last_season_row <- fonterra_history %>%
  filter(season_end <= season_year) %>%   # most recent available season
  slice_max(season_end, n = 1)

last_season_price <- last_season_row$milk_price
last_season_end   <- last_season_row$season_end

cat("\nLast season (", last_season_end - 1, "/", last_season_end,
    ") Fonterra payout: $", last_season_price, "/kg MS\n", sep = "")

# ── Plot: projected vs last season by breed ───────────────────────────────────
comparison <- breeds %>%
  mutate(
    projected  = kg_ms_per_cow * HERD_SIZE * projected_season_avg,
    last_season = kg_ms_per_cow * HERD_SIZE * last_season_price
  ) %>%
  tidyr::pivot_longer(cols = c(projected, last_season),
                      names_to = "period", values_to = "revenue_nzd") %>%
  mutate(period = recode(period,
    "projected"   = paste0(season_year, "/", season_year + 1, " (projected)"),
    "last_season" = paste0(last_season_end - 1, "/", last_season_end, " (actual)")
  ))

ggplot(comparison, aes(x = breed, y = revenue_nzd / 1e6, fill = period)) +
  geom_col(position = "dodge") +
  geom_text(aes(label = paste0("$", round(revenue_nzd / 1e6, 2), "M")),
            position = position_dodge(width = 0.9),
            vjust = -0.4, size = 3.5) +
  scale_fill_manual(values = c("#4a90d9", "#a8c6a0")) +
  labs(
    title = "Projected vs Last Season Revenue by Breed (500-cow herd)",
    subtitle = paste0(
      "Projection based on ", auctions_elapsed, " auction",
      if_else(auctions_elapsed == 1, "", "s"), " so far · ",
      "Last season Fonterra payout: $", last_season_price, "/kg MS"
    ),
    x = NULL,
    y = "Estimated Annual Revenue (NZD millions)",
    fill = NULL
  ) +
  theme_minimal() +
  theme(legend.position = "top")
