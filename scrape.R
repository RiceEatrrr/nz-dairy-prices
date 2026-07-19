# scrape.R
# NZ Dairy Prices — scrape + clean
# Pulls GDT price tables from NZX and tidies into long format

library(rvest)
library(dplyr)
library(tidyr)
library(stringr)
library(readr)

url <- "https://www.nzx.com/markets/nzx-dairy-derivatives/global-dairy-trade/price-report"

cat("Reading page...\n")
page <- read_html(url)
tables <- page %>% html_table(fill = TRUE)

# ── Helper ────────────────────────────────────────────────────────────────────
# Strips commas, % signs, and converts placeholders to NA
clean_num <- function(x) {
  x <- str_trim(x)
  x[x %in% c("n.s", "N/A", "—", "n.a.", "")] <- NA
  x <- str_remove_all(x, ",|%")
  as.numeric(x)
}

# ── Table 1: GDT Price Index summary ─────────────────────────────────────────
# 4 products, current vs previous event, % change
gdt_index <- tables[[1]] %>%
  rename(product = Products, current = 2, previous = 3, pct_change = Change) %>%
  mutate(
    current    = clean_num(current),
    previous   = clean_num(previous),
    pct_change = clean_num(pct_change),
    scrape_date = Sys.Date()
  )

cat("\nGDT Price Index (Table 1):\n")
print(gdt_index)

# ── Tables 2–5: per-product contract breakdowns ───────────────────────────────
# Each table: 18 rows = 6 contracts × 3 row types (Current / Previous / Change)
# Contract column only filled on every 3rd row — needs filling down
# Columns 3 & 4 are product variants (e.g. Regular NZ, Instant NZ)

clean_contract_table <- function(tbl, product_name) {
  names(tbl)[1] <- "contract"
  names(tbl)[2] <- "row_type"
  
  tbl %>%
    mutate(contract = na_if(contract, "")) %>%
    fill(contract, .direction = "down") %>%
    pivot_longer(cols = 3:4, names_to = "variant", values_to = "value") %>%
    mutate(value = clean_num(value)) %>%
    pivot_wider(names_from = row_type, values_from = value) %>%
    rename(current = Current, previous = Previous, pct_change = Change) %>%
    mutate(
      product     = product_name,
      scrape_date = Sys.Date()
    ) %>%
    select(product, variant, contract, current, previous, pct_change, scrape_date)
}

all_contracts <- bind_rows(
  clean_contract_table(tables[[2]], "WMP"),
  clean_contract_table(tables[[3]], "SMP"),
  clean_contract_table(tables[[4]], "AMF"),
  clean_contract_table(tables[[5]], "BTR")
)

cat("\nAll contract prices (Tables 2–5):\n")
print(all_contracts, n = 20)

# ── Save / append to CSV ──────────────────────────────────────────────────────
dir.create("data", showWarnings = FALSE)
csv_path <- "data/gdt_prices.csv"

if (file.exists(csv_path)) {
  write_csv(all_contracts, csv_path, append = TRUE, col_names = FALSE)
  cat("\nAppended to", csv_path, "\n")
} else {
  write_csv(all_contracts, csv_path)
  cat("\nCreated", csv_path, "\n")
}

# ── Live USD/NZD exchange rate ─────────────────────────────────────────────────
library(jsonlite)
fx_url <- "https://api.frankfurter.app/latest?from=USD&to=NZD"
fx_data <- fromJSON(fx_url)
usd_nzd <- fx_data$rates$NZD
cat("Live USD/NZD rate:", usd_nzd, "\n")

# ── Save milk price summary per scrape ────────────────────────────────────────
price_summary <- all_contracts %>%
  filter(product == "WMP", contract == "Contract 2", variant == "Regular - NZ") %>%
  select(scrape_date, current) %>%
  rename(wmp_c2_usd = current) %>%
  mutate(wmp_c2_nzd_per_kg_ms = (wmp_c2_usd / 870) * usd_nzd)

summary_path <- "data/milk_price_summary.csv"

if (file.exists(summary_path)) {
  write_csv(price_summary, summary_path, append = TRUE, col_names = FALSE)
} else {
  write_csv(price_summary, summary_path)
}