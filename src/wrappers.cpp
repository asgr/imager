#include <array>
#include <cassert>
#include <numeric>
#include <functional>

#include <imager.h>
#include "wrappers_cimglist.h"

using namespace Rcpp;
using namespace cimg_library;

//Return a CImg object for in-place modification
CId sharedCImg(SEXP inp) {
    Rcpp::NumericVector Rvec(inp);
    IntegerVector d = Rvec.attr("dim");
    if (d.length() < 4)
      {
	Rcpp::stop("Expecting a four-dimensional array");
      }
    CId img(Rvec.begin(),d[0],d[1],d[2],d[3],true);
    return img;		
  }

CImg<int> sharedCImg_bool(SEXP inp) {
    Rcpp::LogicalVector Rvec(inp);
    IntegerVector d = Rvec.attr("dim");
    if (d.length() < 4)
      {
	Rcpp::stop("Expecting a four-dimensional array");
      }
    CImg<int> img(Rvec.begin(),d[0],d[1],d[2],d[3],true);
    return img;		
  }

//Return a CImg object for in-place modification
CImgList<double > sharedCImgList(SEXP inp) {
  Rcpp::List L(inp);
  int n = L.length();
  CImgList<double > CL;
  CImg<double > tmp;
  for (int i=0;i < n;i++)
    {
      CL.insert(sharedCImg(L[i]),i,true);
    }
  return CL;
}

//NB:: For some obscure reason R stores booleans as integers 
CImgList<int > sharedCImgList_bool(SEXP inp) {
  Rcpp::List L(inp);
  int n = L.length();
  CImgList<int > CL;
  CImg<int > tmp;
  for (int i=0;i < n;i++)
    {
      CL.insert(sharedCImg_bool(L[i]),i,true);
    }
  return CL;
}


namespace imager {

static std::array<unsigned int, 4> get_4dims(const std::array<int, 4> &dims)
{
    assert(std::all(dims.begin(), dims.end(), [](int value) { return value >= 0; ));
    std::array<unsigned int, 4> output;
    std::copy(dims.begin(), dims.end(), output.begin());
    return output;
}

static std::array<unsigned int, 4> get_4dims(const Rcpp::NumericVector &input)
{
    Rcpp::IntegerVector dims = input.attr("dim");
    if (dims.length() < 4) {
        Rcpp::stop("Expecting a four-dimensional array");
    }
    assert(std::all(dims.begin(), dims.end(), [](int value) { return value >= 0; }));
    using uint = unsigned int;
    return {uint(dims[0]), uint(dims[1]), uint(dims[2]), uint(dims[3])};
}

template <typename RawType, typename RcppType, typename InputType>
static std::tuple<cimg_library::CImg<RawType>, RcppType> _create_shared_objects(const InputType &input)
{
    auto dims = get_4dims(input);
    auto size = std::accumulate(dims.begin(), dims.end(), std::size_t(1), std::multiplies<std::size_t>{});
    RcppType output(size, RawType(0));
    set_cimg_attributes(output, Rcpp::IntegerVector{dims.begin(), dims.end()});
    auto img = cimg_library::CImg<RawType>{output.begin(), dims[0], dims[1], dims[2], dims[3], true};
    return std::make_tuple(img, output);
}

template <typename RawType, typename RcppType>
OutputCImg<RawType, RcppType>::OutputCImg()
 : _data(CImg<RawType>{}, RcppType{})
{
}

template <typename RawType, typename RcppType>
OutputCImg<RawType, RcppType>::OutputCImg(const RcppType &input)
 : _data(_create_shared_objects<RawType, RcppType>(input))
{
}

template <typename RawType, typename RcppType>
OutputCImg<RawType, RcppType>::OutputCImg(int width, int height, int depth, int spectrum)
 : _data(_create_shared_objects<RawType, RcppType>(std::array<int, 4>{width, height, depth, spectrum}))
{
}

template class imager::OutputCImg<double, Rcpp::NumericVector>;

} // namespace imager
