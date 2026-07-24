# What the project is

This project is based around the New Zealand dairy market, and compares the data between breeds of cows, the inspected variables are Friesian, Jersey-Friesian cross and Jersey cows. The function of this project is to project what a full season's revenue would look like at current prices for each breed, to show how much each product's price changed at the latest auction and a time series which shows an estimated annual revenue for a 500-cow farm by breed. This project also includes 24 years of Fonterra farmgate milk price to be able to visualise how volatile dairy prices have been over time and where the current seasons sits relative to the long-run average.

# How it works

This project works by scraping the NZX website every fortnight via GitHub Actions, pulling the auction prices for all four dairy products (AMF, BTR, SMP, WMP), these auction prices are then cleaned up and are saved to two CSV's one with all raw contract and the other being WMP contract 2 price converted into NZD per kg of milk solids using a live exchange rate.

```         
nz-dairy-prices/
├── scrape.R          — scrapes GDT prices and saves to CSV
├── analysis.R        — auction price change chart and revenue time series
├── projection.R      — projected season payout vs last season comparison
├── load_history.R    — 24 years of Fonterra farmgate milk price history
└── data/
    ├── gdt_prices.csv          — full auction price history
    └── milk_price_summary.csv  — WMP Contract 2 price per scrape in NZD/kg MS
```

# How to run this project

1.  Clone the repo from GitHub
2.  Open RStudio and set your working directory to the `nz-dairy-prices` folder
3.  Install the required packages — `rvest`, `dplyr`, `tidyr`, `stringr`, `readr`, `ggplot2`, `jsonlite`, `lubridate`, `readxl`
4.  Run `scrape.R` to pull the latest GDT prices and save to CSV
5.  Run `load_history.R` for the Fonterra historical analysis
6.  Run `analysis.R` for the current auction plots and breed comparison
7.  Run `projection.R` for the projected season payout vs last season comparison

## **For automated scraping**

1.  Fork the repo on GitHub
2.  The GitHub Action runs automatically on the 1st and 15th of each month
3.  You can also trigger it manually from the Actions tab

# Terminology

- Fonterra - New Zealand's largest dairy co-operative, responsible for collecting and processing the majority of New Zealand's milk supply and also setting the annual farmgate milk prices paid to farmers.

<!-- -->

- WMP - Whole Milk Powder

- SMP - Skim Milk Powder

- AMF - Anhydrous Milk Fat

- BTR - Butter

- Cow breeds - Jersey, Friesian

- GDT (Global Dairy Trade) - Fortnightly online auction which sets global dairy commodity prices

- kg MS (kilograms of milk solids) - The unit that NZ farmers are paid per, combining fat and protein content of milk

- Contract 2 - the GDT contract used as the benchmark, representing delivery roughly 2 months out

# Data Sources

- [NZX GDT Price Report](https://www.nzx.com/markets/nzx-dairy-derivatives/global-dairy-trade/price-report)

- [Frankfurter API](https://www.frankfurter.app)

- [Fonterra historical farmgate milk prices](https://www.interest.co.nz/rural/fonterra-farmgate-milk-price)
