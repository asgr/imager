#ifndef IMAGER_H
#define IMAGER_H

#ifndef STRICT_R_HEADERS
#define STRICT_R_HEADERS
#endif

#if defined(Rcpp_hpp) && !defined(COMPILING_IMAGER)
#error "The file 'Rcpp.h' should not be included. Please correct to include only 'imager.h'."
#endif

#include "CImg.h"

#include <R.h>
#include <Rcpp.h>

#ifdef _OPENMP
#define cimg_use_openmp 1
#endif

#define cimg_use_abort
#ifdef cimg_use_openmp
#define cimg_test_abort() if (!omp_get_thread_num()) Rcpp::checkUserInterrupt()
#else
#define cimg_test_abort() Rcpp::checkUserInterrupt()
#define cimg_test_abort2() Rcpp::checkUserInterrupt()
#endif // #ifdef cimg_use_openmp

#undef _X
#undef _Y
#undef _Z

#include "wrappers.h"

typedef cimg_library::CImg<double> CId;
typedef cimg_library::CImg<int> CIi;
typedef cimg_library::CImg<float> CIf;
typedef cimg_library::CImg<bool> CIb;

namespace imager {

/// Utility class that temporarily adjustes R index values
/// so they make sense when used against C arrays.
struct AutoAdjustIndices {
  CId &_img;
  bool _adjust;
  AutoAdjustIndices(CId &img, bool adjust) :
    _img(img), _adjust(adjust)
  {
    if (_adjust)
      _img--;
  }

  ~AutoAdjustIndices() {
    if (_adjust)
      _img++;
  }
};

} // namespace imager

#endif
