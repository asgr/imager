library(imager)
library(testthat)
suppressPackageStartupMessages(library(magrittr))

# Regression test: forward warps scatter source pixels into the output via an
# iterated read-modify-write blend, so parallelising the loop made the result
# depend on thread scheduling order. See inst/include/NOTE_CImg.
test_that("forward warps are deterministic regardless of OpenMP thread count", {

  w <- 200; h <- 150
  set.seed(917)
  im <- imnoise(x = w, y = h, sd = 1)
  gr <- pixel.grid(im)

  # A contracting map sends many source pixels to the same destination, which is
  # what makes the forward (scatter) paths sensitive to scheduling order.
  dx <- -0.35 * gr$x + 2.25 + 0.1 * sin(gr$y / 3)
  dy <- -0.20 * gr$y + 1.75 + 0.1 * cos(gr$x / 4)
  mk <- function(a) as.cimg(array(a, c(w, h, 1, 1)))
  wf_rel <- list(mk(dx), mk(dy)) %>% imappend("c")
  wf_abs <- list(mk(dx + gr$x), mk(dy + gr$y)) %>% imappend("c")

  on.exit(cimg.use.openmp("adaptive", nthreads = 1, verbose = FALSE), add = TRUE)

  # (warpfield, mode, interpolation) cases covering the forward paths
  cases <- list(list(wf_rel, 3, 1), list(wf_rel, 3, 2),
                list(wf_abs, 2, 1), list(wf_abs, 2, 2))

  # Serial reference: no OpenMP, so no thread-scheduling effects at all.
  cimg.use.openmp("never", verbose = FALSE)
  ref <- lapply(cases, function(s)
    warp(im, s[[1]], mode = s[[2]], interpolation = s[[3]]))

  # Parallel runs must reproduce the serial result exactly. The race made the
  # parallel result differ from both the serial result and from itself.
  cimg.use.openmp("always", nthreads = 16, verbose = FALSE)
  for (i in seq_along(cases)) {
    s <- cases[[i]]
    expect_identical(warp(im, s[[1]], mode = s[[2]], interpolation = s[[3]]),
                     ref[[i]],
                     label = sprintf("mode %d, interpolation %d", s[[2]], s[[3]]))
  }
})

# Backward warps gather into disjoint output cells and were always race-free;
# keep them pinned so a future parallelism change does not silently break them.
test_that("backward warps are deterministic regardless of OpenMP thread count", {

  w <- 200; h <- 150
  set.seed(917)
  im <- imnoise(x = w, y = h, sd = 1)
  gr <- pixel.grid(im)
  mk <- function(a) as.cimg(array(a, c(w, h, 1, 1)))
  wf_rel <- list(mk(-0.35 * gr$x), mk(-0.2 * gr$y)) %>% imappend("c")
  wf_abs <- list(mk(gr$x + 5.5), mk(gr$y - 3.25)) %>% imappend("c")

  on.exit(cimg.use.openmp("adaptive", nthreads = 1, verbose = FALSE), add = TRUE)

  cases <- list(list(wf_rel, 1, 1), list(wf_rel, 1, 2),
                list(wf_abs, 0, 1), list(wf_abs, 0, 2))

  cimg.use.openmp("never", verbose = FALSE)
  ref <- lapply(cases, function(s)
    warp(im, s[[1]], mode = s[[2]], interpolation = s[[3]]))

  cimg.use.openmp("always", nthreads = 16, verbose = FALSE)
  for (i in seq_along(cases)) {
    s <- cases[[i]]
    expect_identical(warp(im, s[[1]], mode = s[[2]], interpolation = s[[3]]),
                     ref[[i]],
                     label = sprintf("mode %d, interpolation %d", s[[2]], s[[3]]))
  }
})

# imwarp() defaults to direction = "forward", i.e. the racing path.
test_that("imwarp forward warps are deterministic", {

  set.seed(917)
  im <- imnoise(x = 200, y = 150, sd = 1)

  on.exit(cimg.use.openmp("adaptive", nthreads = 1, verbose = FALSE), add = TRUE)

  # Contracting map: many source pixels land on one destination pixel
  map.contract <- function(x, y) list(x = 0.5 * x, y = 0.5 * y)

  cimg.use.openmp("never", verbose = FALSE)
  ref <- imwarp(im, map = map.contract, direction = "forward",
                interpolation = "linear")

  cimg.use.openmp("always", nthreads = 16, verbose = FALSE)
  expect_identical(imwarp(im, map = map.contract, direction = "forward",
                          interpolation = "linear"), ref)
})
