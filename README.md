# What the project is


# How to run this project

1. Clone the repo from GitHub
2. Open RStudio and set your working directory to the `nz-dairy-prices` folder
3. Install the required packages — `rvest`, `dplyr`, `tidyr`, `stringr`, `readr`, `ggplot2`, `jsonlite`, `lubridate`, `readxl`
4. Run `scrape.R` to pull the latest GDT prices and save to CSV
5. Run `load_history.R` for the Fonterra historical analysis
6. Run `analysis.R` for the current auction plots and breed comparison

## **For automated scraping**
1. Fork the repo on GitHub
2. The GitHub Action runs automatically on the 1st and 15th of each month
3. You can also trigger it manually from the Actions tab
