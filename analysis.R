library(readr)
library(ggplot2)
library(dplyr)

prices <- read_csv("data/gdt_prices.csv")

glimpse(prices)


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

# ── Breed parameters ──────────────────────────────────────────────────────────
breeds <- tibble(
  breed        = c("Friesian", "Jersey", "Friesian-Jersey Cross"),
  kg_ms_per_cow = c(385, 355, 370)
)

# ── Milk price per kg MS from latest GDT data ─────────────────────────────────
# WMP Contract 2 Regular is the benchmark price we'll use
milk_price <- prices %>%
  filter(product == "WMP", contract == "Contract 2", variant == "Regular - NZ") %>%
  arrange(desc(scrape_date)) %>%
  slice(1) %>%
  pull(current)

# Pull the most recent NZD/kg MS value from milk_price_summary.csv
# (scrape.R already converts using the live USD/NZD rate, so we use that directly)
latest_summary <- read_csv("data/milk_price_summary.csv",
                            col_types = cols(
                              scrape_date            = col_date(),
                              wmp_c2_usd             = col_double(),
                              wmp_c2_nzd_per_kg_ms   = col_double()
                            )) %>%
  arrange(desc(scrape_date)) %>%
  slice(1)

milk_price_nzd_per_kg_ms <- latest_summary$wmp_c2_nzd_per_kg_ms

cat("Milk price per kg MS: NZD$", round(milk_price_nzd_per_kg_ms, 2), "\n")


# ── Revenue comparison across herd sizes ──────────────────────────────────────
herd_sizes <- seq(100, 1000, by = 100)

breed_revenue <- breeds %>%
  cross_join(tibble(herd_size = herd_sizes)) %>%
  mutate(
    total_kg_ms  = kg_ms_per_cow * herd_size,
    revenue_nzd  = total_kg_ms * milk_price_nzd_per_kg_ms
  )

# Plot
breed_revenue %>%
  ggplot(aes(x = herd_size, y = revenue_nzd / 1e6, colour = breed)) +
  geom_line(linewidth = 1) +
  geom_point() +
  labs(
    title = "Estimated Annual Revenue by Breed and Herd Size",
    subtitle = paste0("Based on WMP Contract 2 price of NZD$", 
                      round(milk_price_nzd_per_kg_ms, 2), 
                      "/kg MS · Auction date: ", 
                      format(Sys.Date(), "%d %b %Y")),
    x = "Number of Cows",
    y = "Revenue (NZD millions)",
    colour = "Breed"
  ) +
  theme_minimal()


library(readr)

milk_summary <- read_csv("data/milk_price_summary.csv",
                         col_types = cols(
                           scrape_date = col_date(),
                           wmp_c2_usd = col_double(),
                           wmp_c2_nzd_per_kg_ms = col_double()
                         ))
breeds %>%
  cross_join(
    milk_summary %>%
      filter(!is.na(wmp_c2_nzd_per_kg_ms)) %>%
      group_by(scrape_date) %>%
      slice_tail(n = 1) %>%   # keep only the last entry per date (handles duplicate scrapes)
      ungroup()
  ) %>%
  mutate(revenue_500 = kg_ms_per_cow * 500 * wmp_c2_nzd_per_kg_ms) %>%
  ggplot(aes(x = scrape_date, y = revenue_500 / 1e6, colour = breed)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2.5) +
  labs(
    title = "Estimated Annual Revenue by Breed Over Time (500-cow herd)",
    subtitle = "Based on WMP Contract 2 price per auction",
    x = "Auction Date",
    y = "Revenue (NZD millions)",
    colour = "Breed"
  ) +
  theme_minimal()
