#!/usr/bin/env Rscript
#
# Guard the patches imager carries in its vendored copy of CImg.h.
#
# Why this exists
# ---------------
# inst/include/CImg.h is a vendored third-party header that upstream keeps
# changing. imager applies a small number of local patches on top of it, and
# they are easy to lose:
#
#   - the 2023 re-vendor to CImg 3.3.4 silently dropped the 2021 "ss.back() = 0"
#     fix; it is absent from the current header, and nothing noticed.
#   - NOTE_CImg is not a reliable inventory either: it omits the 2025 vector()
#     patch (commit dcf8333) entirely.
#
# So neither memory nor NOTE_CImg can be trusted as the checklist. This script
# is the checklist. It is deliberately a set of greps rather than a compile test,
# because the failures it guards against are silent: three of the four patches
# only matter under specific compilers or input shapes, so a normal build and
# a normal test run will not catch their absence.
#
# Run: Rscript tools/check_cimg_patches.R
# Wired into CI (.github/workflows/R-CMD-check.yaml) so a re-vendor that drops a
# patch fails the build rather than being found years later.

hdr <- file.path("inst", "include", "CImg.h")
if (!file.exists(hdr)) stop("cannot find ", hdr, "; run from the package root")

lines <- readLines(hdr, warn = FALSE)
txt <- paste(lines, collapse = "\n")

# Each entry: a label, and a regex that must match the patched form.
must_have <- list(
  list(
    label = "vector() tainted-argument fix (commit dcf8333, 2025)",
    pattern = '!std::strncmp\\(ss,"vector",6\\) && ss6<se1 && \\*ss6!=.\\(. && \\(s=std::strchr\\(ss6,.\\('
  ),
  list(
    label = "strellipsize null _data guard (commit f174543, 2024)",
    pattern = 'if \\(str\\._data != nullptr\\)'
  ),
  list(
    label = "load_analyze null _data guard (commit f174543, 2024)",
    pattern = 'if \\(body\\._data != nullptr\\)'
  ),
  list(
    label = "save() must not touch stdout in R mode (commit 7bd7e3e, 2024)",
    pattern = '#ifndef cimg_use_r'
  ),
  list(
    label = "resize_halfXY restored (removed upstream between 3.3.4 and 4.0.0)",
    pattern = 'CImg<T>& resize_halfXY\\(\\)'
  ),
  list(
    label = "dimension-string assign restored (removed upstream in 4.0.x)",
    pattern = 'CImg<T>& assign\\(const CImg<t>& img, const char \\*const dimensions\\)'
  ),
  list(
    label = "forward warp accumulates before normalising (fixes last-write-wins)",
    pattern = 'accu\\.assign\\('
  ),
  list(
    label = "forward warp normalises by the accumulator",
    pattern = 'Normalize result by accumulated values'
  )
)

# A pragma inside a forward-warp branch would re-introduce the scatter race.
# Look for a parallel pragma within a few lines after a forward-warp marker.
forbidden <- function() {
  bad <- character()
  markers <- grep("Forward-(absolute|relative) warp", lines)
  for (m in markers) {
    window <- lines[m:min(length(lines), m + 12)]
    if (any(grepl("cimg_pragma_openmp\\(parallel", window))) {
      bad <- c(bad, sprintf("line %d: parallel pragma inside a forward-warp branch", m))
    }
  }
  bad
}

failures <- character()
for (p in must_have) {
  if (!grepl(p$pattern, txt, perl = TRUE)) {
    failures <- c(failures, paste("MISSING:", p$label))
  }
}
failures <- c(failures, forbidden())

if (length(failures)) {
  cat("CImg patch check FAILED for", hdr, "\n\n")
  cat(paste0("  - ", failures, collapse = "\n"), "\n\n")
  cat("If this is a deliberate re-vendor, re-apply the patches and update\n",
      "inst/include/NOTE_CImg, then re-run this script. Do not delete a check\n",
      "to make the build pass without deciding what happened to the patch.\n",
      sep = "")
  quit(status = 1)
}

cat("CImg patch check passed (", length(must_have), " patches present)\n", sep = "")