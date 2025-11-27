library(imager)

cimg.limit.openmp()

im <- structure(c(1, 1, 1), dim = c(1L, 1L, 1L, 3L), class = c("cimg", "imager_array", "numeric"))

test_that("RGBtosRGB_stays_white",
{
    expect_equal(im %>% RGBtosRGB, im, tolerance=1e-6)
})

test_that("sRGBtoRGB_stays_white",
{
    expect_equal(im %>% sRGBtoRGB, im, tolerance=1e-6)
})
