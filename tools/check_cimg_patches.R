#!/usr/bin/env Rscript
#
# Inventory guard for the local patches imager applies to the vendored CImg
# header. This is deliberately NOT a "do the patches still apply" check.
#
# Why this exists
# ---------------
# inst/include/CImg.h is not committed. It is generated at build time from
# tools/cimg/CImg_vanilla.h by applying tools/cimg/patches/*.patch, so the patch
# files are the source of truth for what imager changed in CImg.
#
# A patch that no longer applies is already fatal: configure stops with
# "could not apply the CImg patches" and the build fails. Re-checking that here
# would only duplicate configure, and two copies of the same logic drift apart.
#
# What configure cannot see is a patch that is *gone*. Deleting a patch file
# leaves the remaining set applying perfectly, so the build stays green and the
# fix silently disappears from the generated header. That is not hypothetical:
# this project lost the 2021 ss.back() fix and the 2025 vector() fix exactly
# this way, years apart, and neither was noticed for a long time.
#
# Three of these fixes only matter under specific compilers or input shapes, so
# a normal build and a normal test run will not notice an absence either. This
# script is therefore the inventory: it knows which fixes are supposed to exist,
# and fails if one is missing, emptied, or if an unlisted patch appears.
#
# Run: Rscript tools/check_cimg_patches.R
# Wired into CI (.github/workflows/R-CMD-check.yaml).

patchdir <- file.path("tools", "cimg", "patches")
vanilla <- file.path("tools", "cimg", "CImg_vanilla.h")

if (!file.exists(vanilla)) {
  stop("cannot find ", vanilla, "; run from the package root")
}
if (!dir.exists(patchdir)) {
  stop("cannot find ", patchdir, "; run from the package root")
}

# Each entry: the patch file's base name, a human label, and a regex that must
# appear as an ADDED line inside that patch. Checking the content as well as the
# name means a patch cannot be emptied or flipped into a removal unnoticed.
must_have <- list(
  list(
    id = "01-restore-dimension-string-assign",
    label = "dimension-string assign restored (removed upstream in 4.0.x)",
    pattern = 'CImg<T>& assign\\(const CImg<t>& img, const char \\*const dimensions\\)'
  ),
  list(
    id = "02-fix-vector-tainted-argument",
    label = "vector() tainted-argument fix (commit dcf8333, 2025)",
    pattern = 'ss6<se1 && \\*ss6!=.\\(. && \\(s=std::strchr\\(ss6,.\\('
  ),
  list(
    id = "03-guard-strellipsize-null-data",
    label = "strellipsize null _data guard (commit f174543, 2024)",
    pattern = 'if \\(str\\._data != nullptr\\)'
  ),
  list(
    id = "04-restore-resize-halfXY",
    label = "resize_halfXY restored (removed upstream between 3.3.4 and 4.0.0)",
    pattern = 'CImg<T>& resize_halfXY\\(\\)'
  ),
  list(
    id = "05-guard-load-analyze-null-data",
    label = "load_analyze null _data guard (commit f174543, 2024)",
    pattern = 'if \\(body\\._data != nullptr\\)'
  ),
  list(
    id = "06-no-eof-to-stdout-in-r-mode",
    label = "save() must not touch stdout in R mode (commit 7bd7e3e, 2024)",
    pattern = '#ifndef cimg_use_r'
  )
)

present <- sub("\\.patch$", "", list.files(patchdir, pattern = "\\.patch$"))
failures <- character()

for (p in must_have) {
  if (!(p$id %in% present)) {
    failures <- c(failures, paste("MISSING PATCH FILE:", p$label))
    next
  }
  lines <- readLines(file.path(patchdir, paste0(p$id, ".patch")), warn = FALSE)
  # Only added lines: a '-' match would mean the fix is being removed rather
  # than applied.
  added <- lines[startsWith(lines, "+") & !startsWith(lines, "+++")]
  if (!any(grepl(p$pattern, added, perl = TRUE))) {
    failures <- c(failures,
                  paste("PATCH DOES NOT CONTAIN THE FIX:", p$label,
                        sprintf("(expected an added line matching /%s/)", p$pattern)))
  }
}

# Anything present but unlisted is suspicious: a new patch not recorded here, or
# a leftover from a re-vendor.
extra <- setdiff(present, vapply(must_have, `[[`, character(1), "id"))
if (length(extra)) {
  failures <- c(failures,
                paste0("UNEXPECTED PATCH FILE(S) not listed in this check: ",
                       paste(extra, collapse = ", "),
                       "\n  Add them to tools/check_cimg_patches.R so they are guarded too."))
}

if (length(failures)) {
  cat("CImg patch inventory check FAILED\n\n")
  cat(paste0("  - ", failures, collapse = "\n"), "\n\n")
  cat("If this is a deliberate re-vendor, port each missing fix to the new\n",
      "upstream header and add it back as a patch, or delete the patch file\n",
      "and remove its entry here if upstream has fixed it. A deleted patch no\n",
      "longer fails the build, so this list is the only thing that notices.\n",
      sep = "")
  quit(status = 1)
}

cat("CImg patch inventory OK (", length(must_have), " patches accounted for)\n",
    sep = "")