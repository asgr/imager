% Generated by roxygen2 (4.1.1): do not edit by hand
% Please edit documentation in R/cimg_class.R
\name{imager.combine}
\alias{add}
\alias{average}
\alias{imager.combine}
\alias{mult}
\alias{parmax}
\alias{parmin}
\title{Combining images}
\usage{
add(x)

average(x)

mult(x)

parmax(x)

parmin(x)
}
\arguments{
\item{x}{a list of images}
}
\description{
These functions take a list of images and combine them by adding, multiplying, taking the parallel min or max, etc.
}
\section{Functions}{
\itemize{
\item \code{add}: 

\item \code{average}: 

\item \code{mult}: 

\item \code{parmax}: 

\item \code{parmin}: 
}}
\examples{
im1 <- as.cimg(function(x,y) x,100,100)
im2 <- as.cimg(function(x,y) y,100,100)
im3 <- as.cimg(function(x,y) cos(x/10),100,100)
l <- list(im1,im2,im3)
add(l) \%>\% plot #Add the images
average(l) \%>\% plot #Average the images
mult(l) \%>\% plot #Multiply
parmax(l) \%>\% plot #Parallel max
parmin(l) \%>\% plot #Parallel min
#Pseudo-artistic effects
llply(seq(1,35,5),function(v) boxblur(boats,v)) \%>\% parmin \%>\% plot
llply(seq(1,35,5),function(v) boxblur(boats,v)) \%>\% average \%>\% plot
}
\author{
Simon Barthelme
}
\seealso{
imsplit,Reduce
}
