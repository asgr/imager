library(imager)
library(testthat)
suppressPackageStartupMessages(library(magrittr))

# Regression tests for forward warps. Two distinct properties are pinned here,
# and they are NOT the same test:
#
#  1. correctness — a contracting forward warp must AVERAGE the source pixels
#     that land in one destination cell. Before CImg 4.0.6 the scatter used
#     set_linear_atXY() without is_added, which is an iterated blend
#     dest = w1*value + (1-w1)*dest. At an integer destination dx=dy=0, so
#     w1=1 and the blend degenerates to dest = value: last write wins, and a
#     decimating warp keeps one arbitrary source pixel instead of the mean.
#     This is order-independent but wrong, so no amount of serialising fixes it.
#     Guarded by "forward warps average their contributions" below, which runs
#     everywhere and needs no OpenMP.
#
#  2. determinism — the scatter must not depend on thread scheduling. Now that
#     CImg accumulates with is_added and normalises by an accu count afterwards,
#     the forward loops are a commutative reduction and are serial again in
#     CImg 4.0.7, so this is belt-and-braces rather than load-bearing.
#
# WATCH OUT: `cimg.use.openmp()` is a no-op when the build has no OpenMP
# (has_omp() FALSE), which is the default on macOS. The thread-count tests below
# would then compare two identical serial runs and pass vacuously. They are
# therefore skipped explicitly rather than allowed to report a false pass.
test_that("forward warps average their contributions", {
  # 2x2 image, all four pixels collapsed onto (1,1). Values 1..4 in
  # column-major order, so the mean is 2.5 and the last write is 4.
  im <- as.cimg(array(1:4, c(2, 2, 1, 1)))
  ones <- as.cimg(array(1, c(2, 2, 1, 1)))
  wf <- list(ones, ones) %>% imappend("c")

  out <- warp(im, wf, mode = 2, interpolation = 1)
  expect_equal(as.numeric(out[1, 1, 1, 1]), 2.5)

  # Nothing is created or destroyed: the single populated cell holds the mean,
  # not the sum and not one of the inputs.
  expect_equal(sum(as.array(out)), 2.5)
  expect_equal(sum(as.array(out) != 0), 1)

  # The same contract through the relative-mode scatter.
  rel <- list(as.cimg(array(1 - rep(1:2, each = 2), c(2, 2, 1, 1))),
              as.cimg(array(1 - rep(1:2, times = 2), c(2, 2, 1, 1)))) %>% imappend("c")
  expect_equal(as.numeric(warp(im, rel, mode = 3, interpolation = 1)[1, 1, 1, 1]), 2.5)

  # A larger collapse exercises the accu normalisation over many contributors:
  # every 8x8 block of a 40x40 image onto its first pixel. A correct mean of 64
  # draws from N(0,1) has sd ~ 1/8; last-write-wins would give sd ~ 1.
  set.seed(5)
  im2 <- imnoise(x = 40, y = 40, sd = 1)
  gr <- pixel.grid(im2)
  ax <- gr$x - (gr$x - 1) %% 8
  ay <- gr$y - (gr$y - 1) %% 8
  wf2 <- list(as.cimg(array(ax, c(40, 40, 1, 1))),
              as.cimg(array(ay, c(40, 40, 1, 1)))) %>% imappend("c")
  m <- as.array(warp(im2, wf2, mode = 2, interpolation = 1))[,,1,1]
  origins <- m[seq(1, 40, 8), seq(1, 40, 8)]
  expect_lt(sd(origins), 0.4)

  # And the mean is the block mean, not the last pixel scanned.
  src <- as.array(im2)[,,1,1]
  expect_equal(m[1,1], mean(src[1:8, 1:8]), tolerance = 1e-12)
})

test_that("forward warps are deterministic regardless of OpenMP thread count", {
  skip_if_not(has_omp(),
              paste("imager built without OpenMP: cimg.use.openmp() is a no-op here,",
                    "so thread-count comparisons cannot fail"))

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
  skip_if_not(has_omp(),
              paste("imager built without OpenMP: cimg.use.openmp() is a no-op here,",
                    "so thread-count comparisons cannot fail"))

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

# imwarp() defaults to direction = "forward", i.e. the scatter path.
test_that("imwarp forward warps are deterministic", {
  skip_if_not(has_omp(),
              paste("imager built without OpenMP: cimg.use.openmp() is a no-op here,",
                    "so thread-count comparisons cannot fail"))

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
