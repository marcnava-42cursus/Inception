#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1) {
  stop("Usage: Rscript generate_web.R <output_file>")
}

output_file <- args[1]
out_dir <- dirname(output_file)

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

suppressPackageStartupMessages(require(rmarkdown))

rmarkdown::render(
  input       = "site/index.Rmd",
  output_file = basename(output_file),
  output_dir  = out_dir,
  quiet       = TRUE
)

message("OK ✅ Generated: ", file.path(out_dir, basename(output_file)))