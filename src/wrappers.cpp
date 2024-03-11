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
