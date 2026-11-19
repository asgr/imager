# imager — project memory

R package wrapping the CImg C++ library for image/video processing in up to 4 dimensions (x, y, z/time, colour). CRAN package, LGPL-3, Rcpp-based. Repo: https://github.com/asgr/imager, docs site: https://asgr.github.io/imager/.

## Layout

- `R/` — R layer: `cimg` class (`cimg_class.R`), `imlist`, `pixset`, conversions, loading/saving, filtering, transformations, interactive display.
- `src/` — Rcpp/C++ wrappers around CImg (`wrappers.cpp`, `unity.cpp` is the single compilation unit; `OBJECTS = unity.o` in Makevars).
- `tools/cimg/` — vendored upstream CImg header (`CImg_vanilla.h`) plus numbered local patches in `patches/` and `apply_patches.sh`.
- `inst/include/CImg.h` — **generated at build time, not committed**. `configure` (and `configure.win`) apply the patch set to the vanilla header. Never hand-edit it; add/modify a patch in `tools/cimg/patches/` instead, and update `inst/include/NOTE_CImg` records. When re-vendoring a new CImg version, re-base the patches; `configure` fails loudly if a patch no longer applies.
- `configure.ac` — source of truth for the build; regenerate `configure` with autoconf (pkg.m4 is vendored in `m4/`, so pkg-config is not needed). Windows uses `configure.win`.
- `tests/testthat/` — tests; `vignettes/` — `gettingstarted.Rmd`, `pixsets.Rmd`.
- `NEWS.md` — detailed changelog with rationale for fixes; consult it before touching warp/CImg-patch code.

## Build / check

- Standard devtools workflow: `devtools::document()`, `devtools::test()`, `devtools::check()` (roxygen2 for docs, RoxygenNote in DESCRIPTION).
- X11, FFTW, libtiff and OpenMP are all **optional**; configure falls back gracefully (`cimg_display=0` etc.) so the package builds headless (HPC, e.g. Pawsey Setonix). Interactive functions (`display()`, `play()`, `grab*()`) error informatively without X11.
- On macOS/CRAN builds there is typically no OpenMP: thread-count tests must `skip_if_not(has_omp(), ...)`; `cimg.use.openmp()` is a no-op there. Don't write determinism tests that only compare two serial runs.
- CI: `.github/workflows/R-CMD-check.yaml` and `headless-check.yaml` (minimal-installation check).

## Minimal-installation policy (important)

- `png`, `jpeg`, `tiff`, `readbitmap`, dplyr/ggplot2 etc. are **Suggests, not Imports**. Core code paths must work with none of them installed.
- Use `has.image.reader(format, action)` / `has.magick()` to gate IO in examples, tests and vignettes; use base R instead of dplyr/purrr-row-binding in package code.
- Image IO preference order: format-specific package → readbitmap → CImg native (BMP/PNM/.cimg/Analyze/INR always work) → external ImageMagick/GraphicsMagick. BMP is the dependency-free fallback (also for `save.video()` frames).
- Keep `R CMD check` passing on a minimal installation.

## Known subtleties

- Forward warps (`warp()`/`imwarp()` default `direction = "forward"`) had a last-write-wins bug fixed via CImg 4.0.7's accumulate-then-normalise; correctness is pinned by the "forward warps average their contributions" test.
- Two upstream API removals are deliberately restored by patches: `resize_halfXY()` and the dimension-string `assign()` overloads (`CImg(other,"xyzc",0)`); without the latter, `const char*` binds the `is_shared` overload and silently aliases buffers.
- The package depends on magrittr (historical API); new internal code should prefer the base pipe `|>`.