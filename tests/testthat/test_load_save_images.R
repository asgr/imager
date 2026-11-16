library(imager)
library(Rcpp)

cimg.limit.openmp()

test_that("BMP round-trip works without any suggested package",{
    im <- imfill(10,10,val=c(0,0,0))

    ff <- tempfile(fileext=".bmp")
    save.image(im,ff)
    im2 <- load.image(ff)
    unlink(ff)
    expect_equal(im,im2)
})

test_that("BMP is always readable and writable",{
    expect_identical(has.image.reader("bmp"),TRUE)
    expect_identical(has.image.reader("bmp","save"),TRUE)
    expect_identical(has.image.reader(".BMP"),TRUE)
})

test_that("images load and save through CImg when no reader is installed",{
    local_mocked_bindings(first.available=function(pkgs) NULL)

    ff <- tempfile(fileext=".bmp")
    save.image(boats,ff)
    im <- load.image(ff)
    unlink(ff)
    expect_equal(dim(im),dim(boats))
})

test_that("missing readers are reported with actionable advice",{
    local_edition(3)
    local_mocked_bindings(first.available=function(pkgs) NULL,
                          has.magick=function() FALSE)

    ff <- tempfile(fileext=".png")
    file.create(ff)
    expect_snapshot(error=TRUE,load.image(ff))
    expect_snapshot(error=TRUE,save.image(boats,ff))
    unlink(ff)
})

test_that("PNG round-trip works when png is available",{
    skip_if_not_installed("png")
    im <- imfill(10,10,val=c(0,0,0))

    ff <- tempfile(fileext=".png")
    save.image(im,ff)
    im2 <- load.image(ff)
    unlink(ff)
    expect_equal(im,im2)
})

test_that("JPEG round-trip works when jpeg is available",{
    skip_if_not_installed("jpeg")
    im <- imfill(10,10,val=c(.2,.5,.8))

    ff <- tempfile(fileext=".jpg")
    save.image(im,ff)
    im2 <- load.image(ff)
    unlink(ff)
    expect_equal(im,im2,tolerance=.1)
})

test_that("TIFF round-trip works when a TIFF writer is available",{
    skip_if(!has.image.reader("tiff","save"),"no TIFF support")
    im <- imfill(10,10,val=c(0,0,0))

    ff <- tempfile(fileext=".tif")
    save.image(im,ff)
    im2 <- load.image(ff)
    unlink(ff)
    expect_equal(im,im2,tolerance=1/255)
})