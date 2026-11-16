library(imager)

cimg.limit.openmp()

test_that("cannyEdges works without suggested packages",{
    px <- cannyEdges(grayscale(boats))
    expect_s3_class(px,"pixset")
    expect_identical(dim(px),dim(grayscale(boats)))
})

test_that("cannyEdges returns an empty pixset when no edges are found",{
    px <- cannyEdges(grayscale(boats),t1=10,t2=20)
    expect_equal(sum(px),0)
})