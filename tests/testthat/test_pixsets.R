library(imager)

cimg.limit.openmp()

test_that("the first connected components can be plotted",{
    masks <- lapply(c(1,4,5),function(n) {
        pixels <- array(FALSE,dim=c(10,10,1,1))
        pixels[seq(2,by=2,length.out=n),2,1,1] <- TRUE
        as.pixset(pixels)
    })
    masks <- c(masks,list(isoblur(grayscale(boats),4) > .5))

    f <- tempfile(fileext=".pdf")
    grDevices::pdf(f)
    on.exit({ grDevices::dev.off(); unlink(f) })
    for (i in seq_along(masks)) {
        sp <- split_connected(masks[[i]])
        if (i <= 3) expect_length(sp,c(1,4,5)[i])
        first <- head(sp,4)
        expect_length(first,min(length(sp),4))
        expect_true(all(vapply(first,is.pixset,logical(1))))
        expect_no_error(plot(first))
    }
})
