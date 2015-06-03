% Generated by roxygen2 (4.1.1): do not edit by hand
% Please edit documentation in R/RcppExports.R
\name{boxblur}
\alias{boxblur}
\title{Blur image with a box filter.}
\usage{
boxblur(inp, sigma, boundary_conditions = TRUE)
}
\arguments{
\item{sigma}{Size of the box window.}

\item{boundary_conditions}{Boundary conditions. Can be <tt>{ 0=dirichlet | 1=neumann }</tt>.a}
}
\description{
Blur image with a box filter.
}
\seealso{
deriche(), vanvliet().
}
