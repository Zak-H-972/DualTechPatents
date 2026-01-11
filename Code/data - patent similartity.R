
# setup ------------------------------------------------------------------------
library(stringr)
library(dplyr)
library(tidytext)

library(readtext)
library(text2vec)
# library(text)

# read data  -----------------------------------------------------------------
wa_docs <-  
  readtext(here("data", "WA_list", "*.docx")) 

# patent data 
patent_data <- 
  read.csv(here("data", "lens-patent-data.csv"))

aux_patent_data <- # save extra data on the patents for the plot
  patent_data |> 
  select(Title, Abstract, Owners)

# vectorize text data ----------------------------------------------------------

# WA docs

# preparation for TF-IDF
wa_docs <-  
  wa_docs |> 
  group_by(doc_id) |> 
  unnest_tokens(word, text) |> # Tokenize
  ungroup() |> 
  filter(str_detect(word, "^[[:alpha:]]+$")) |> # keep ONLY letters (no digits, no punctuation)
  anti_join(stop_words, by = "word") # Remove common stopwords

# Compute TF-IDF per WA document
wa_docs <- 
  wa_docs |> 
  count(doc_id, word, sort = FALSE) |> # term counts within doc
  bind_tf_idf(term = word, document = doc_id, n) # adds tf, idf, tf_idf columns

# Patent abstracts

# preparation for TF-IDF
patent_data <- 
  patent_data |> 
  group_by(Lens.ID, Title) |> 
  unnest_tokens(word, Abstract) |> # Tokenize
  ungroup() |> 
  filter(str_detect(word, "^[[:alpha:]]+$")) |> # keep ONLY letters (no digits, no punctuation)
  anti_join(stop_words, by = "word") # Remove common stopwords

# Compute TF-IDF weights per patent
patent_data <- 
  patent_data |> 
  count(Lens.ID, Title, word, sort = FALSE) |> # term counts within doc
  bind_tf_idf(term = word, document = Lens.ID, n) # adds tf, idf, tf_idf columns

# compute similarity -----------------------------------------------------------

# Make a sparse document-term matrix (DTM) from TF-IDF weights
#    rows = docs, columns = terms, entries = tf-idf
dtm <- 
  bind_rows(
    wa_docs,
    patent_data |> rename(doc_id = Title)
  ) |> 
  select(doc_id, word, tf_idf) |> 
  cast_sparse(doc_id, word, tf_idf)

# some organisition 
# ids you want
row_ids <- unique(wa_docs$doc_id)
col_ids <- unique(patent_data$Title)

# split the matrix
dtm_rows <- dtm[row_ids, , drop = FALSE]
dtm_cols <- dtm[col_ids, , drop = FALSE]

# Cosine similarity between documents (analogue to embeddings cosine)
sim_rect <- sim2(x = dtm_rows, y = dtm_cols, method = "cosine", norm = "l2")

# back to data frame
sim_data <- 
  as.matrix(sim_rect) |> 
  as.data.frame() |> 
  tibble::rownames_to_column("WA_catagory") |> 
  tidyr::pivot_longer(
    cols = -WA_catagory,
    names_to = "patent_title",
    values_to = "cosine_sim"
  ) 

# Keep max cosine_sim
sim_data <- 
  sim_data |> 
  group_by(patent_title) |> 
  filter(cosine_sim == max(cosine_sim)) |>
  slice(1) |> 
  ungroup()

# save and clean up ------------------------------------------------------------

# add aux data
sim_data <- 
  sim_data |> 
  left_join(
    aux_patent_data,
    by = c("patent_title" = "Title")
  )

# save
saveRDS(sim_data, here("data", "patent_daul_tech_sim_data.RDS"))

rm(wa_docs, patent_data, aux_patent_data, col_ids, row_ids, dtm_cols, dtm_rows, dtm, sim_rect, sim_data)
gc()