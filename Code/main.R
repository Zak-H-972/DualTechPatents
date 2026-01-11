# run time: (including data creation)

# setup ------------------------------------------------------------------------

tic <- Sys.time()

library(here)


# Calculate similarity ---------------------------------------------------------

if (F) { # only need to run once
  source(here("code", "data - patent similartity.R"))
}

# Create Github page for results -----------------------------------------------

rmarkdown::render(here("code", "github page setup.Rmd"), output_dir = "Docs", output_file = "index.html")

# ------------------------------------------------------------------------------

toc <- Sys.time()
toc - tic
rm(tic, toc)