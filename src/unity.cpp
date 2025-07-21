// Unity build for imager
//
// We use such a build for a number of reasons:
//
//  * Parsing the CImg.h header for each compilation unit is an expesive operations on its own
//  * We have been hit with unexpected LTO issues in the past
//  * When compiling with g++ -fsanitize=undefined there are also ODR issues that are difficult to pinpoint
//
// Overall the compilation of this package has always been dominated by wrappers.cpp,
// and this unity build's performance seems to be comparable to that.

#include "colourspace.cpp"
#include "coordinates.cpp"
#include "display.cpp"
#include "drawing.cpp"
#include "filtering.cpp"
#include "hough.cpp"
#include "imgraphs.cpp"
#include "interact.cpp"
#include "interpolation.cpp"
#include "morphology.cpp"
#include "RcppExports.cpp"
#include "reductions.cpp"
#include "transformations.cpp"
#include "utils.cpp"
#include "wrappers.cpp"
