# imager 1.0.10 CImg update and forward-warp correctness fix

* Re-vendored the bundled CImg header from 3.3.4 to **4.0.7**. The local patches
  imager carries are re-applied and now guarded by
  `tools/check_cimg_patches.R`, which CI runs; see `inst/include/NOTE_CImg` for
  the per-patch record. Two patches became unnecessary because 4.0.7 contains
  the fix upstream (the gcc-14 sprintf buffer and the forward-warp OpenMP
  removal), and two upstream API removals had to be restored because imager's
  interface depends on them: `CImg::resize_halfXY()` (used by
  `imager::resize_halfXY()` and so by `resize_uniform()`) and the
  dimension-string `assign()` overloads (`CImg(other,"xyzc",0)`), which 4.0.x
  dropped while leaving the constructors that call them. Without the latter the
  `const char*` decays to `bool` and binds the `is_shared` overload, so `add()`,
  `wsum()` and several filters failed or silently aliased buffers.

* **Forward warps now give correct pixels, not just deterministic ones.** The
  forward (scatter) paths accumulate several source pixels into one destination
  with `set_linear_atXY()`, which without `is_added` is an iterated blend
  `dest = w1*value + (1-w1)*dest`. At an integer destination `w1=1`, so that
  degenerates to `dest = value` and the last source pixel scanned wins: a
  contracting forward warp kept one arbitrary pixel per destination instead of
  averaging. Measured on a 40x40 noise image with every 8x8 block collapsing to
  one pixel, the output had the sd of a single pixel (1.0) instead of the 0.125
  of a 64-pixel mean. CImg 4.0.6 introduced accumulate-then-normalise (an `accu`
  count divided out at the end), which is order-independent and correct; 4.0.7
  is what imager now vendors.

  This changes forward-warp output. `imwarp()` defaults to
  `direction = "forward"`, so images produced through it — and anything that was
  relying on the old decimation behaviour — will differ. Backward warps, and
  forward warps whose destinations are all distinct, are unaffected.

* The 1.0.9 fix for the same code path serialised the forward loops. That made
  repeated runs agree but left the last-write-wins error in place, and it was
  unverifiable on this repository's macOS/CRAN builds, which have no OpenMP:
  `cimg.use.openmp()` is a no-op without OpenMP support, so
  `test_warp_determinism.R` was comparing two identical serial runs. Those
  thread-count tests now `skip_if_not(has_omp(), ...)` instead of reporting a
  pass they cannot earn, and a new OpenMP-free test,
  "forward warps average their contributions", pins the correctness property.
  It fails on the 1.0.9 code.

# imager 1.0.9 Bug fix release

* Fixed a data race in `warp()` (and therefore `imwarp()`) affecting forward warps
  (`direction = "forward"`, the default in `imwarp()`) with linear or cubic
  interpolation. These paths scatter source pixels into the output via an
  accumulating read-modify-write blend, so running them under OpenMP made the
  result depend on thread scheduling: repeated calls on the same input could
  return different images once more than a handful of threads were active
  (`OMP_NUM_THREADS` above roughly 6 on the machine where this was found).
  The affected CImg loops are now serialised, which makes forward warps
  deterministic and bit-identical to the single-thread result. Forward warps are
  consequently no longer sped up by OpenMP; backward warps are unaffected.

# imager 1.0.0 Major release

* Switch of maintained (Aaron Robotham and Rodrigo Tobar)
* Improved support for OpenMP threading for Cimg functions, most notably median stacking of images (parmed).
* Added support for .webp format

# imager 0.41.2 Minor release

* Fixed bug in imsub: imsub had a nasty side-effect, that effectively redefined variables "x",y","z", and "cc" if they happened to exist in the current environment. 

# imager 0.41.1 Minor release

* Prof. Brian Ripley contributed fixes for compiler errors on Solaris

# imager 0.41 Major release

* Functions based on **plyr** are gradually being phased out in favour of ones based on **purrr** and **dplyr**. **plyr** is no longer loaded by default, which solves some conflicts, but may break existing code! If that's the case just add ```require(plyr)``` somewhere. 
* new functions imeval and imchange. These create custom execution environments for functions, and simplify image pipelines: for example,
``` imeval(boats,~ xs*.) ```
is equivalent to: ``` (Xc(boats)/width(boats))*boats ``` and creates a fading effect. 
``` imchange(boats,~ c==1,~ xs*.) ```
is the same thing but applied only to the first colour channel (R) 
* (experimental feature) quick-and-dirty interactive interfaces are now easy to program using the interact() function. Use it to explore filter parameters, interactive segmentation. For more sophisticated needs, use e.g. shiny. 
* (experimental feature) as.igraph methods for images and pixsets convert images into graph representations. Nodes are pixels, and edges are drawn between neighbouring pixels. On pixsets, this allows some interesting morphological operations, e.g. contour tracing. On images, it could be used for various graph-based image processing algorithms, like spectral graph clustering
* new function "inpaint", which fills in missing parts of an image with a weighted avg. of the neighbours. Useful for salt-and-pepper-ish noise, e.g:
  ```
  im <- boats
  im[sample(nPix(im),1e4)] <- NA
  inpaint(im,1) %>% imlist(im,.) %>%
              setNames(c("before","after")) %>% 
			  plot(layout="row")
  ```
* isoblur now has optional na.rm argument, and can ignore missing values. 
* new function: colorise, to fill in regions with a certain colour. Also comes with a formula interface, just like imeval. Ex: highlight central region in image
    ``` colorise(boats,~ sqrt(xc^2+yc^2) < 140,"blue",alpha=.2) %>% plot ```
see ?colorise for more. 
* new function: load.dir, to load all images in a directory  
* new function: Hough transforms for circles and lines are now available, see hough_circle and hough_line
* most functions that take a colour argument now accept colour names, e.g.:
       ```imfill(10,10,val="red")``` or ```autocrop(im,col="black")```
* fixed problem with recent versions of ImageMagick that weren't detected properly
	
# imager 0.40.2 Minor release
	* added crop.bbox for cropping image to the bounding box of a pixset
	* updated CImg: fixes issues with Intel C compiler and libtiff giving pop-up warnings on Windows 
	* threshold now has an "adjust" argument, to adjust the auto-thresholding
	* switched to C++11 
	
# imager 0.40.1 Minor release
	* Updated CImg, imager should now compile on Solaris
	* Fixed memory access bug in px.flood

# imager 0.40 Major release
   * added pixset class to represent sets of pixels in an image (implemented as binary images). A test on an image (e.g., im > 0) results in a pixset object. Pixsets come with many convenience functions for plotting, manipulation, morphology, etc. They are described in the "pixsets" vignette. 
   * improved reductions (parmax, parmin, etc.). Most are now implemented in C++ and some run in parallel using OpenMP. A median combine operation (parmedian) has been added.
   * added load.video, save.video, make.video functions. Loading and saving videos used to be a bit fragile and platform-dependent, it should now be easier and more robust (also slower, sorry). It's now possible to load individual frames from a video. *You still need ffmpeg*. 
   * to load images from URLs imager now uses the *downloader* package, which is more robust than the previous solution
   * it's now possible to import images from the raster package and from the magick package.
   * unified RGB representations so that every function expects RGB values to be in the [0-1] range. There used to be a conflict in expectations here, with R expecting [0-1] and CImg [0-255]. *This might break existing code* (albeit in minor ways). 
   * new function implot, lets you draw on an image using R's base graphics. 
   * improved interactive functions for grabbing image regions (grabRect, grabLine, etc.)
   * improved grayscale conversion
   * improved plotting. The default is now to have a constant aspect ratio that matches the aspect ratio of the image. 
   * save.image now accepts a quality argument when saving JPEGs.
   * native support for TIFF, now supports non-integer values in TIFF files
   * rm.alpha removes alpha channel, flatten.alpha flattens it
   * imfill now accepts  colour names, e.g. `imfill(10,10,val='red')`
   * improved documentation and examples
   * added functions for conversion to/from CIELAB 
   
# imager 0.31 Minor release
   * fixed inline C++ plugin, this time for OS X systems
   * added interpolation option to plot.cimg (to prevent systematic antialiasing when plotting small images)
   
# imager 0.30 Major release. 
  * new S3 class imlist improves support for image lists 
  * enabled OpenMP. Many CImg primitives now run in parallel. 
  * experimental support for CImg's DSL via imeval, patch_summary. 
  * improved as.raster,plot. Now support palettes via colourscale argument.
  * new interactive functions for selecting image regions (grabRect,grabPoint,grabLine)
  * new patchstat function for fast extraction of patch statistics
  * new patchmatch function 
  * cleaned up the API, improved the documentation
  * fixed bug in inline C++ plugin, should now work on Windows. 
  * improved configure script. FFTW3 is now optional (should be less confusing to OSX users)


# imager 0.20. Major release
  * added a tutorial (vignette), which includes a worked-out example of multi-scale blob detection
  * new functions: 
    + iminfo gives you information on an image file (uses ImageMagick)
    + load.example loads test images
    + crop.borders (self-explanatory)
  * long computations can now be interrupted thanks to update in CImg
  * the array subset operator is now more intelligent: you do not have to specify flat dimensions, i.e. 
    `imfill(10,10)[3,1]`   does what you'd expect (i.e., the same as `imfill(10,10)[3,1,1,1]`)
  * improvements and bugs fixed in print.cimg, as.cimg, imresize, frame, plot.cimg, subim, as.raster, renorm
  * improved documentation and examples 

# imager 0.16. Bugfix + minor features
  * as.data.frame.cimg now has optional "wide" formats
  * load.image now uses readbitmap by default (should work better on Windows) 
  * Made the test for ImageMagick more stringent, which fixes a bug in load.image on certain machines
  * Added new reductions which.parmax, which.parmin 

# imager 0.15: Substantial update
  * User-visible changes:
    + the threshold function now supports auto-thresholding (based on k-means)
    + new accessor functions: imrow, imcol
    + new replacement functions: channel(im,1) <-, R(im) <- , etc.
    + new reduction function: enorm (Euclidean norm of a list of images)
    + improved as.cimg.function, pixel.grid
    + subim is now called imsub for greater consistency (imsub still available as alias)
    + improved documentation
  * Other: 
    + Reorganised R code into separate files for clarity

# 0.14 Minor update
  * Build system now uses configure
  * Fixed paths in Makevars
  * Hopeful bugfix in load.image for Windows 7 users 

# 0.13 Initial release on CRAN
  * This is the first release onto CRAN
  