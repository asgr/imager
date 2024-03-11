#ifndef CIMG_WRAP
#define CIMG_WRAP

#include <tuple>

namespace imager {

template <typename RcppVector>
inline void set_common_attributes(const char *image_type, RcppVector &out, Rcpp::IntegerVector dims)
{
    out.attr("class") = Rcpp::CharacterVector::create(image_type, "imager_array", "numeric");
    out.attr("dim") = dims;
}

/// Set the class/dim attributes used by the imager package on the output numeric vector
inline void set_cimg_attributes(Rcpp::NumericVector &out, Rcpp::IntegerVector dims)
{
    set_common_attributes("cimg", out, dims);
}

/// Set the class/dim attributes used by the imager package on the output logical vector
inline void set_pixset_attributes(Rcpp::LogicalVector &out, Rcpp::IntegerVector dims)
{
    set_common_attributes("pixset", out, dims);
}

/// A CImg that shares storage with a Rcpp Vector.
/// Operations done on the CImg will thus be visibile in the Vector,
/// which can be then directly returned to R without a further copy.
template <typename RawType, typename RcppType>
class OutputCImg {

public:
    using CImgType = cimg_library::CImg<RawType>;

    /// Create an empty object, no operations should be performed on such instance.
    OutputCImg();

    /// Create a CImg and an Rcpp vector sharing storage.
    /// The size and initial contents of the shared storage are copied from the input vector.
    OutputCImg(const RcppType &input);

    /// Create a CImg and an Rcpp vector sharing storage.
    /// The size of the shared storage is determined from the given parameters.
    OutputCImg(int width, int height, int depth, int spectrum);

    /// A reference to the CImg object to perform operations on it
    CImgType &img() { return std::get<0>(_data); }

    /// The output Rcpp vector sharing storage with the CImg instance
    RcppType rcpp_vector() const { return std::get<1>(_data); }

    /// C++ -> R integration via Rcpp
    operator SEXP() const { return Rcpp::wrap(rcpp_vector()); }

private:
    std::tuple<CImgType, RcppType> _data;
};

using OutputCId = OutputCImg<double, Rcpp::NumericVector>;

}


//#ifndef CIMG_COMPILING
namespace Rcpp {
  //Convert a R cimg object to a C++ CImg object
  template <> inline cimg_library::CImg<double> as(SEXP inp) {
    Rcpp::NumericVector Rvec(inp);
    IntegerVector d = Rvec.attr("dim");
    if (d.length() < 4)
      {
	Rcpp::stop("Expecting a four-dimensional array");
      }
    cimg_library::CImg<double> img(Rvec.begin(),d[0],d[1],d[2],d[3],false);
    return img;		
  }
  
  template <> inline cimg_library::CImg<bool> as(SEXP inp) {
    Rcpp::LogicalVector Rvec(inp);
    IntegerVector d = Rvec.attr("dim");
    if (d.length() < 4)
      {
	Rcpp::stop("Expecting a four-dimensional array");
      }
    cimg_library::CImg<bool> img(Rvec.begin(),d[0],d[1],d[2],d[3],false);
    return img;		
  }


  //Convert a CImg object to an R cimg object
  template <> inline SEXP wrap(const cimg_library::CImg<double> &img) 
  {
    IntegerVector dims(4);
    dims[0] = img.width();
    dims[1] = img.height();
    dims[2] = img.depth();
    dims[3] = img.spectrum();
    Rcpp::NumericVector out(img.begin(),img.end());
    imager::set_cimg_attributes(out, dims);
    return Rcpp::wrap(out);
  }


  template <> inline SEXP wrap(const cimg_library::CImg<bool> &img) 
  {
    IntegerVector dims(4);
    dims[0] = img.width();
    dims[1] = img.height();
    dims[2] = img.depth();
    dims[3] = img.spectrum();
    Rcpp::LogicalVector out(img.begin(),img.end());
    imager::set_pixset_attributes(out, dims);
    return Rcpp::wrap(out);
  }


  //Convert a CImgList to an R list
  template <> inline SEXP wrap(const cimg_library::CImgList<double> &ilist) 
  {
    Rcpp::List out(ilist.size());
    for (unsigned int i = 0;i < ilist.size(); i++)
      {
	out[i] = wrap(ilist(i));
      }
    out.attr("class") = CharacterVector::create("imlist","list");
    return Rcpp::wrap(out);
  }

  template <> inline SEXP wrap(const cimg_library::CImgList<bool > &ilist) 
  {
    Rcpp::List out(ilist.size());
    for (unsigned int i = 0;i < ilist.size(); i++)
      {
	out[i] = wrap(ilist(i));
      }
    out.attr("class") = CharacterVector::create("imlist","list");
    return Rcpp::wrap(out);
  }

}
//#else
/* namespace Rcpp { */
/*   template <> cimg_library::CImg<double> as(SEXP inp); */
/*   template <> cimg_library::CImgList<double> as(SEXP inp); */
/*   template <> SEXP wrap(const cimg_library::CImg<double> &img);  */
/*   template <> SEXP wrap(const cimg_library::CImgList<double> &ilist);  */
/* }  */
//#endif

#endif
