library(here)

rmarkdown::render(here("code", "github page setup.Rmd"), output_dir = "Docs", output_file = "index.html")
