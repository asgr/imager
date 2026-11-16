fillInit <- function(strong)
    {
        lab <- label(strong,TRUE)*strong
        #Base R instead of dplyr: cannyEdges must work without Suggests (HPC)
        df <- as.data.frame(lab)
        df <- df[df$value > 0,]
        parts <- lapply(split(df,df$value),function(d) d[1,c("x","y"),drop=FALSE])
        out <- do.call(rbind,parts)
        if (is.null(out)) data.frame(x=integer(0),y=integer(0)) else out
    }

#Starts a fill at each successive location, and accumulates the results
rescueFill <- function(strong,weak)
    {
        v <- strong
        v[weak==1] <- .9
        loc <- fillInit(strong)
        #Fold a bucket fill over each location (empty loc returns v unchanged)
        out <- purrr::reduce(purrr::transpose(loc),
                      function(v,l) bucketfill(v,l$x,l$y,color=1,sigma=.1,high_connexity=TRUE),
                      .init=v)
        as.cimg(out==1)
    }


nonmax <- function(gr)
    {
        mag <- with(gr,sqrt(x^2+y^2))
        grs <- list(x=gr$x/mag,y=gr$y/mag)
        X <- Xc(gr$x)
        Y <- Yc(gr$y)
        val.bwd <- interp(mag,data.frame(x=as.vector(X-grs$x),
                                         y=as.vector(Y -grs$y)))
        val.fwd <- interp(mag,data.frame(x=as.vector(X+grs$x),
                                         y=as.vector(Y+grs$y)))
        
        throw <- (mag < val.bwd) | (mag < val.fwd)
        mag[throw] <- 0
        mag
    }

guess.kmeans <- function(x)
{
    out <- kmeans(as.vector(x),centers=c(min(x),mean(x),max(x)))
    list(t1=max(x[out$cluster==1]),t2=max(x[out$cluster==2]))
}

##' Canny edge detector
##'
##' If the threshold parameters are missing, they are determined automatically using a k-means heuristic. Use the alpha parameter  to adjust the automatic thresholds up or down
##' The thresholds are returned as attributes.
##' The edge detection is based on a smoothed image gradient with a degree of smoothing set by the sigma parameter. 
##' @param im input image
##' @param t1 threshold for weak edges (if missing, both thresholds are determined automatically)
##' @param t2 threshold for strong edges
##' @param alpha threshold adjusment factor (default 1)
##' @param sigma smoothing
##' @examples
##' \dontshow{cimg.limit.openmp()}
##' cannyEdges(boats) %>% plot
##' #Make thresholds less strict
##' cannyEdges(boats,alpha=.4) %>% plot
##' #Make thresholds more strict
##' cannyEdges(boats,alpha=1.4) %>% plot
##' @author Simon Barthelme
##' @export
cannyEdges <- function(im,t1,t2,alpha=1,sigma=2)
{
    has.col <- spectrum(im) > 1
    if (has.col)
    {
        warning("Running Canny detector on luminance channel")
        im <- grayscale(im)
    }
    if (depth(im) > 1)
    {
        stop("Videos not supported, run the function on single frames")
    }
    mag <- isoblur(im,sigma)%>% imgradient("xy") %>% nonmax
    if (missing(t1))
    {
        guess <- guess.kmeans(mag)
        t2 <- alpha*guess$t2
        t1 <- alpha*guess$t1
    }
    strong <- as.cimg(mag>t2)
    weak <- as.cimg(mag %inr% c(t1,t2))
    out <- rescueFill(strong,weak)

    if (has.col) out <- add.colour(out)
    attr(out,"thresholds") <- c(t1,t2)
    as.pixset(out)
}

