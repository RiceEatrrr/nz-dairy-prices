library(readr)
library(ggplot2)
library(dplyr)

# ── Load scraped auction data ─────────────────────────────────────────────────
prices <- read_csv("data/gdt_prices.csv",
                   col_types = cols(
                     product     = col_character(),
                     variant     = col_character(),
                     contract    = col_character(),
                     current     = col_double(),
                     previous    = col_double(),
                     pct_change  = col_double(),
                     scrape_date = col_date()
                   ))

milk_summary <- read_csv("data/milk_price_summary.csv",
                         col_types = cols(
                           scrape_date          = col_date(),
                           wmp_c2_usd           = col_double(),
                           wmp_c2_nzd_per_kg_ms = col_double()
                         ))

# ── Breed parameters ──────────────────────────────────────────────────────────
breeds <- tibble(
  breed         = c("Friesian", "Jersey", "Friesian-Jersey Cross"),
  kg_ms_per_cow = c(385, 355, 370)
)

# ── Plot 1: % change at latest auction (Contract 2) ───────────────────────────
prices %>%
  filter(!is.na(pct_change), contract == "Contract 2") %>%
  ggplot(aes(x = variant, y = pct_change, fill = product)) +
  geom_col() +
  geom_text(aes(label = paste0(round(pct_change, 1), "%"),
                hjust = ifelse(pct_change >= 0, -0.1, 1.1)),
            size = 3.5) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey50") +
  coord_flip() +
  scale_y_continuous(expand = expansion(mult = 0.15)) +
  labs(
    title = "Price Change at Latest GDT Auction (Contract 2)",
    x = NULL,
    y = "% Change from Previous Auction",
    fill = "Product"
  ) +
  theme_minimal()

# ── Plot 2: Estimated revenue over time (500-cow herd, by breed) ──────────────
breeds %>%
  cross_join(
    milk_summary %>%
      filter(!is.na(wmp_c2_nzd_per_kg_ms)) %>%
      group_by(scrape_date) %>%
      slice_tail(n = 1) %>%   # one entry per auction date
      ungroup()
  ) %>%
  mutate(revenue_500 = kg_ms_per_cow * 500 * wmp_c2_nzd_per_kg_ms) %>%
  ggplot(aes(x = scrape_date, y = revenue_500 / 1e6, colour = breed)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2.5) +
  labs(
    title = "Estimated Annual Revenue by Breed Over Time (500-cow herd)",
    subtitle = "Based on WMP Contract 2 price per auction · NZD at live exchange rate",
    x = "Auction Date",
    y = "Revenue (NZD millions)",
    colour = "Breed"
  ) +
  theme_minimal()
