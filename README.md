<!-- badges: start -->
[![R-CMD-check](https://github.com/asgr/imager/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/asgr/imager/actions/workflows/R-CMD-check.yaml)
[![CRAN Version](https://www.r-pkg.org/badges/version/imager)](https://cran.r-project.org/package=imager)
[![LGPL licensed](https://img.shields.io/badge/license-LGPL--3-blue.svg)](./LICENSE)
[![Codecov test coverage](https://codecov.io/gh/asgr/imager/graph/badge.svg)](https://app.codecov.io/gh/asgr/imager)
<!-- badges: end -->

Imager is an image/video processing package for R, based on [CImg](http://cimg.eu/), a C++ library by David Tschumperlé. CImg provides an easy-to-use and consistent API for image processing, which imager largely replicates. CImg supports images in up to four dimensions, which makes it suitable for applications like video processing/hyperspectral imaging/MRI.

## Installing the package

Imager is on CRAN, so

```r
install.packages("imager")
```

should do the trick. You may also want to install ImageMagick and ffmpeg, see "External Dependencies" below. 

The version of CRAN will often lag the one on github. If you'd like to install the latest version, you'll have to build the package from source. 

Install the devtools package if you haven't already. Run:

```r
devtools::install_github("asgr/imager")
```

If that doesn't work then you're probably missing a build environment or a library, see below.


### OS X

Install [XQuartz](https://www.xquartz.org/) if you haven't already (it's required for the interactive functions). 
You'll need Xcode (OS X's development environment) to compile source packages. The FFTW library is needed, and the easiest way to install it is via [Homebrew](http://brew.sh/). Install Homebrew, then run:

```sh
brew install fftw
```

Optionally, install libtiff for better support of TIFF files. 

### Windows

Building R packages on Windows is a bit of a pain so you're probably better off with the binary package (which may not be up-to-date). If you need the latest version of imager, you'll have to:

- Install [Rtools](https://cran.r-project.org/bin/windows/Rtools/index.html)
- Install [additional libraries](http://www.stats.ox.ac.uk/pub/Rtools/libs.html) for Rtools. You want the package that's called "local tree". Put those libraries somewhere gcc can find them. 

### Linux

To build imager from source under Linux, make sure you have the headers for `libfftw3`, `libx11` (if not using [Wayland](https://en.wikipedia.org/wiki/Wayland_(protocol))), and optionally `libtiff` installed. To determine a complete list of all required system dependencies (incl. transitive ones), you can query the [SystemRequirements database](https://github.com/r-hub/sysreqsdb) via the R package [sysreqs](https://github.com/r-hub/sysreqs).

<details><summary>Example R code to determine all required system dependencies for Ubuntu Linux:</summary>

``` r
# install necessary R packages
if (!("remotes" %in% rownames(installed.packages()))) {
    install.packages(pkgs = "remotes",
                     repos = "https://cloud.r-project.org/")
}
remotes::install_github(repo = "r-hub/sysreqs",
                        quiet = TRUE)

# download imager's DESCRIPTION file (to parse it for system requirements later on)
tmp <- tempfile(pattern = "DESCRIPTION")
download.file(url = "https://github.com/asgr/imager/raw/master/DESCRIPTION",
              destfile = tmp)

# print system package names
sysreqs::sysreqs(desc = tmp,
                 # set platform identifier (here we use the one for Ubuntu Linux)
                 # supported platforms are listed here: https://github.com/r-hub/sysreqsdb/tree/master/platforms
                 platform = "linux-x86_64-ubuntu-gcc",
                 soft = FALSE) |>
    cat()
#> libfftw3-dev libtiff-dev libxml2-dev libicu-dev libgmp-dev libpng-dev libglpk-dev
```

<sup>Created on 2023-04-13 with [reprex v2.0.2](https://reprex.tidyverse.org)</sup>

The last line above indicates the required system packages.

</details>

On Ubuntu (or Debian) Linux you would install them via

```sh
sudo apt install libfftw3-dev libtiff-dev libxml2-dev libicu-dev libgmp-dev libpng-dev libglpk-dev
```

### External dependencies

OS X users need [XQuartz](https://www.xquartz.org/). 
On its own imager supports JPEG, PNG, TIFF and BMP formats. If you need support for other file types install [ImageMagick](http://www.imagemagick.org/script/download.php).
To load and save videos you'll need [ffmpeg](http://ffmpeg.org/download.html), no file formats are supported natively.


## Getting started 

Here's a small demo that actually demonstrates an interesting property of colour perception:

```r
library(imager)
library(purrr)
parrots <- load.example("parrots")
plot(parrots)
#Define a function that converts to YUV, blurs a specific channel, and converts back
bchan <- function(im,ind,sigma=5) { 
	im <- RGBtoYUV(im)
	channel(im,ind) <- isoblur(channel(im,ind),sigma); 
	YUVtoRGB(im)
}
#Run the function on all three channels and collect the results as a list
blurred <- map_il(1:3,~ bchan(parrots,.))
names(blurred) <- c("Luminance blur (Y)","Chrominance blur (U)","Chrominance blur (V)")
plot(blurred)
```
	
We're much more [sensitive to luminance edges than we are to colour edges](https://en.wikipedia.org/wiki/Chroma_subsampling). 

Documentation is available [here](http://asgr.github.io/imager/). To get a list of all package functions, run:

```r
ls(pos = "package:imager")
```

## Important warning on memory usage

All images are stored as standard R numeric vectors (i.e., double-precision), meaning that they take up a lot of memory. It's easy to underestimate how much storage you need for videos, because they take up so little space in a compressed format. Before you can work on it in R a video has to be fully decompressed and stored as double-precision floats. To get a sense of the size, consider a low-resolution (400x300), colour video lasting 120 sec. The video might take up a few MBs when compressed. To store it in memory, you'll need:
(400x300) x (25x120) x 3
values, corresponding to (space)x(time)x(colour). In addition, each value costs 8 bytes of storage, for a grand total of 8GB of memory.

For out-of-memory processing of videos, see the experimental package [imagerstreams](https://github.com/asgr/imagerstreams). 


## Current status

Imager is fully functional but still young, so the API might change. Open an issue on Github or email me if you've found a bug or would like to suggest a feature.

## Contributing to imager

If you want to add features or fix a bug, just fork this repository and send me a pull request (they're welcome). Consider contributing documentation too: imager has got quite large over time, and it's in need of more how-to's and tutorials! 

## Contributors 

The package's author is Simon Barthelmé (Gipsa-lab, CNRS). The following people have gracefully contributed code, bug fixes or testing:

- Stefan Roediger
- Aaron Robotham
- Martin Roth
- Jan Wijffels
- Hong Ooi

Let me know if you're missing from the list! 

## Test pictures

Imager ships with four test pictures and a video. Two (parrots and boats) come from the [Kodak set](http://r0k.us/graphics/kodak/). Another is a sketch of birds by Leonardo, from Wikimedia. Also from Wikimedia: the Hubble Deep field. 
The test video comes from [xiph.org](https://media.xiph.org/video/derf/)'s collection.
