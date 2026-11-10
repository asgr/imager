#!/usr/bin/env Rscript
#
# Guard the set of local patches imager applies to the vendored CImg header.
#
# Why this exists
# ---------------
# inst/include/CImg.h is no longer committed. It is generated at build time from
# tools/cimg/CImg_vanilla.h by applying tools/cimg/patches/*.patch, so the
# patches are the source of truth for what imager changed in CImg.
#
# That is an improvement over the previous arrangement (a pre-patched header),
# because the diff against upstream is now always exactly the patch set. But it
# moves the failure mode: instead of a re-vendor silently dropping a fix, a
# re-vendor can now silently leave a patch failing to apply (caught at build
# time by configure), or a patch can be deleted outright (not caught at all, if
# nothing needs that fix on the developer's machine that day).
#
# Three of these fixes only matter under specific compilers or input shapes, so
# a normal build and a normal test run will not notice their absence. This
# script is the checklist. It is deliberately about the patch files, not about a
# generated header, so it runs before any build has happened.
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

# The patches must still apply to the vanilla header they claim to patch. This
# is what configure does, checked earlier and with a clearer message.
if (!nzchar(Sys.which("patch"))) {
  message("note: 'patch' not found; skipped the apply check")
} else if (!length(failures)) {
  # Resolve to absolute paths BEFORE changing directory, otherwise the patch
  # paths stop resolving and every patch silently reports "not found".
  # -F0 is deliberate: GNU patch fuzzes by default, which can place a stale
  # hunk at the wrong offset and still report success. We want the exact
  # context or an error.
  pats <- sort(list.files(normalizePath(patchdir), pattern = "[.]patch$",
                          full.names = TRUE))
  tmp <- tempfile("cimgcheck")
  dir.create(file.path(tmp, "inst", "include"), recursive = TRUE)
  file.copy(normalizePath(vanilla), file.path(tmp, "inst", "include", "CImg.h"))
  old <- setwd(tmp)
  for (p in pats) {
    out <- suppressWarnings(
      system2("patch", c("-p1", "-F0", "--no-backup-if-mismatch", "-s", "-i", p),
              stdout = TRUE, stderr = TRUE))
    st <- attr(out, "status")
    if (!is.null(st) && st != 0) {
      failures <- c(failures,
                    paste0("PATCH FAILS TO APPLY: ", basename(p),
                           "\n  ", paste(out, collapse = "\n  ")))
    }
  }
  setwd(old)
  unlink(tmp, recursive = TRUE)
}

if (length(failures)) {
  cat("CImg patch check FAILED\n\n")
  cat(paste0("  - ", failures, collapse = "\n"), "\n\n")
  cat("If this is a deliberate re-vendor, port each failing patch to the new\n",
      "upstream header, regenerate it, and update inst/include/NOTE_CImg.\n",
      "Do not delete a patch to make the build pass without deciding what\n",
      "happened to the fix it carries.\n",
      sep = "")
  quit(status = 1)
}

cat("CImg patch check passed (", length(must_have),
    " patches present and applicable)\n", sep = "")