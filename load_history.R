# load_history.R
# Fonterra farmgate milk price history (NZD per kg MS)
# Source: interest.co.nz/rural-data/dairy-industry-payout-history

library(dplyr)
library(ggplot2)
library(readr)

# ── Fonterra farmgate milk price history ──────────────────────────────────────
fonterra_history <- tibble(
  season     = c("2001/02","2002/03","2003/04","2004/05","2005/06",
                 "2006/07","2007/08","2008/09","2009/10","2010/11",
                 "2011/12","2012/13","2013/14","2014/15","2015/16",
                 "2016/17","2017/18","2018/19","2019/20","2020/21",
                 "2021/22","2022/23","2023/24","2024/25"),
  milk_price = c(4.00, 3.90, 4.25, 4.58, 4.46,
                 4.46, 7.66, 5.10, 6.10, 7.90,
                 6.08, 5.84, 8.40, 4.40, 3.90,
                 6.12, 6.69, 6.35, 7.14, 7.54,
                 9.30, 8.22, 7.83, 9.50),
  season_end = c(2002,2003,2004,2005,2006,
                 2007,2008,2009,2010,2011,
                 2012,2013,2014,2015,2016,
                 2017,2018,2019,2020,2021,
                 2022,2023,2024,2025)
)

# ── Plot: milk price over time ─────────────────────────────────────────────────
fonterra_history %>%
  ggplot(aes(x = season_end, y = milk_price)) +
  geom_line(colour = "#2a78d6", linewidth = 1) +
  geom_point(colour = "#2a78d6", size = 2.5) +
  geom_hline(yintercept = mean(fonterra_history$milk_price),
             linetype = "dashed", colour = "grey50") +
  annotate("text", x = 2004, y = mean(fonterra_history$milk_price) + 0.2,
           label = paste0("Average: $", round(mean(fonterra_history$milk_price), 2)),
           size = 3.5, colour = "grey40") +
  labs(
    title = "Fonterra Farmgate Milk Price History",
    subtitle = "NZD per kg milk solids (MS) · 2002-2025",
    x = "Season ending",
    y = "NZD per kg MS"
  ) +
  scale_x_continuous(breaks = seq(2002, 2025, by = 2)) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# ── Breed revenue using historical prices ──────────────────────────────────────
breeds <- tibble(
  breed         = c("Friesian", "Jersey", "Friesian-Jersey Cross"),
  kg_ms_per_cow = c(385, 355, 370)
)

breeds %>%
  cross_join(fonterra_history) %>%
  mutate(revenue_nzd = kg_ms_per_cow * 500 * milk_price) %>%
  ggplot(aes(x = season_end, y = revenue_nzd / 1e6, colour = breed)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  labs(
    title = "Estimated Annual Revenue by Breed (500-cow herd)",
    subtitle = "Based on Fonterra farmgate milk price history",
    x = "Season ending",
    y = "Revenue (NZD millions)",
    colour = "Breed"
  ) +
  scale_x_continuous(breaks = seq(2002, 2025, by = 2)) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
