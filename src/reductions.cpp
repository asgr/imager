#include <imager.h>
#include "wrappers_cimglist.h"
using namespace Rcpp;
using namespace cimg_library;




// [[Rcpp::export]]
NumericVector reduce_wsum(List x,NumericVector w,bool na_rm=false)
{
  CImgList<double> L = sharedCImgList(x);
  CId out(L.at(0),"xyzc",0.0);
  CIb valid(L.at(0),"xyzc",false);
  int n = x.size();
  for (int i = 0;  i < n; i++)
    {
      if (!na_rm)
	{
	  out += w(i)*L.at(i);
	}
      else
	{
	  cimg_forXYZC(out,x,y,z,c)
	    {
	      double v = L.at(i)(x,y,z,c);
	      if (!(std::isnan(v)))
		{
		  out(x,y,z,c) += w(i)*v;
		  valid(x,y,z,c) = true;
		}
	    }
	}
    }
    if (na_rm)
    {
      cimg_forXYZC(out,x,y,z,c){ if (!valid(x,y,z,c)) { out(x,y,z,c) = NA_REAL; } }
    }
  return wrap(out);
}


// [[Rcpp::export]]
NumericVector reduce_average(List x,bool na_rm=false)
{
  CImgList<double> L = sharedCImgList(x);
  CId out(L.at(0),"xyzc",0.0);
  CImg<int>  nn(L.at(0),"xyzc",0);
  int n = x.size();
  for (int i = 0;  i < n; i++)
    {
      if (!na_rm)
	{
	  out += L.at(i);
	}
      else
	{
	  cimg_forXYZC(out,x,y,z,c)
	    {
	      double v = L.at(i)(x,y,z,c);
	      if (!(std::isnan(v)))
		{
		  out(x,y,z,c) += v;
		  nn(x,y,z,c)+=1;
		}
	    }
	}
    }
  out = na_rm?(out.div(nn)):(out/(double) (n));
  return wrap(out);
}



// [[Rcpp::export]]
NumericVector reduce_prod(List x,bool na_rm=false)
{
  CImgList<double> L = sharedCImgList(x);
  CId out(L.at(0),"xyzc",1.0);
  CIb valid(L.at(0),"xyzc",false);
  int n = x.size();
  for (int i = 0;  i < n; i++)
    {
      if (!na_rm)
	{
	  out.mul(L.at(i));
	}
      else
	{
	  cimg_forXYZC(out,x,y,z,c)
	    {
	      double v = L.at(i)(x,y,z,c);
	      if (!(std::isnan(v)))
		{
		  out(x,y,z,c) *= v;
		  valid(x,y,z,c) = true;
		}
	    }
	}
    }
    if (na_rm)
    {
      cimg_forXYZC(out,x,y,z,c){ if (!valid(x,y,z,c)) { out(x,y,z,c) = NA_REAL; } }
    }
  return wrap(out);
}

// [[Rcpp::export]]
NumericVector reduce_minmax(List x,bool na_rm=false,bool max=true)
{
  CImgList<double> L = sharedCImgList(x);
  CId out(L.at(0),"xyzc", (max?(-DBL_MAX):DBL_MAX));
  CIb valid(L.at(0),"xyzc",false);
  int n = x.size();
  double v;
  for (int i = 0;  i < n; i++)
    {
      cimg_forXYZC(out,x,y,z,c)
	{
	  v = L.at(i)(x,y,z,c);
	  if (std::isnan(v))
	    {
	      if (!na_rm)
		{
		  out(x,y,z,c) = v;
		}
	    }
	  else
	    {
	      if (na_rm)
		{
		  valid(x,y,z,c) = true;
		}
	      if (!std::isnan(out(x,y,z,c))) //Once NaN, always NaN
		{
		  if (max)
		    {
		      out(x,y,z,c) = (out(x,y,z,c) > v)? out(x,y,z,c): v;
		    }
		  else
		    {
		      out(x,y,z,c) = (out(x,y,z,c) < v)? out(x,y,z,c): v;
		    }
		}
	    }
	}
    }
  if (na_rm)
    {
      cimg_forXYZC(out,x,y,z,c){ if (!valid(x,y,z,c)) { out(x,y,z,c) = NA_REAL; } }
    }
  return wrap(out);
}


// NumericVector reduce_prod(List x,int summary = 0)
// {
//   CImgList<double> L = sharedCImgList(x);
//   CId out(L.at(0),false);
//   int n = x.size();
//   for (int i = 1;  i < n; i++)
//     {
//       out = out.mul(L.at(i));
//     }
//   return wrap(out);
// }


// [[Rcpp::export]]
NumericVector reduce_list(List x,int summary = 0)
{
  CImgList<double> L = sharedCImgList(x);
  CId out(L.at(0),false);
  int n = x.size();
  cimg_pragma_openmp(parallel for cimg_openmp_if(out.size()>=65536))
  cimg_forXYZC(out,x,y,z,c)
    {
      CId vec(n,1,1,1);
      for (int i = 0; i <n; i++)
	{
	  vec[i] = L.at(i)(x,y,z,c);
	  //	  vec[i] = L.atNXYZC(i,x,y,z,c);
	}
      switch (summary)
	{
	case 1:
	  out(x,y,z,c) = vec.min(); break;
	case 2:
	  out(x,y,z,c) = vec.max(); break;
	case 3:
	  out(x,y,z,c) = vec.median(); break;
	case 4:
	  out(x,y,z,c) = vec.variance(); break;
	case 5:
	  out(x,y,z,c) = sqrt(vec.pow(2).sum()); break;
	}
    }
  return wrap(out);
}


//OpenMP seems not to do anything for these functions on certain platforms. Don't know why yet. 

// [[Rcpp::export]]
NumericVector reduce_list2(List x,int summary = 0)
{
  CImgList<double> L = sharedCImgList(x);
  CId out(L.at(0),false);
  int n = x.size();
  //  cimg_pragma_openmp(parallel for collapse(2))
  cimg_forXYZC(out,x,y,z,c)
    {
      NumericVector vec(n);
      for (int i = 0; i <n; i++)
	{
	  vec(i) = L.at(i)(x,y,z,c);
	}
      //out(x,y,z,c) = mean(vec);
      switch (summary)
      	{
      	case 1:
      	  out(x,y,z,c) = min(vec); break;
      	case 2:
      	  out(x,y,z,c) = max(vec); break;
      	case 3:
      	  out(x,y,z,c) = median(vec); break;
	}
      // 	// case 4:
      // 	//   out(x,y,z,c) = vec.variance(); break;
      // 	// case 5:
      // 	//   out(x,y,z,c) = sqrt(vec.pow(2).sum()); break;
      // 	}
    }
  return wrap(out);
}

static double _get_median(std::vector<double>::iterator begin, std::vector<double>::iterator end, bool na_rm)
{
  if (!na_rm && std::any_of(begin, end, R_IsNA))
    return NA_REAL;
  auto size = std::distance(begin, end);
  if (size == 0)
    return NA_REAL;
  auto n = size / 2;
  std::nth_element(begin, begin + n, end);
  auto value_in_middle = *(begin + n);
  if (size % 2)
    return value_in_middle;
  return (value_in_middle + *std::max_element(begin, begin + n)) / 2;
}

static double _get_quantile(std::vector<double>::iterator begin, std::vector<double>::iterator end, double prob, bool na_rm)
{
  if (!na_rm && std::any_of(begin, end, R_IsNA))
    return NA_REAL;
  auto size = std::distance(begin, end);
  if (size == 0)
    return NA_REAL;
  
  if(prob == 1){ // just return the max element
    return *std::max_element(begin, end);
  }
  
  double size_prob = (double)(size - 1) * prob; // size if like R length, so 1 larger than the diff on the limits
  std::size_t n = ceil(size_prob);  
  
  if(n == 0){ // just return the min element
    return *std::min_element(begin, end);
  }
  
  std::nth_element(begin, begin + n, end);
  auto value_in_hi_bin = *(begin + n);
  
  double wgt = 1 - ((double)n - size_prob); // the brackets matter for ensuring the correct type conversion
  
  if(wgt == 1){
    return value_in_hi_bin;
  }
  
  auto value_in_lo_bin = *std::max_element(begin, begin + n);

  return value_in_hi_bin * wgt + value_in_lo_bin * (1 - wgt);
}


// [[Rcpp::export]]
NumericVector reduce_med(List x, bool na_rm=false, bool doquan=false, double prob=0.5)
{
  CImgList<double> L = sharedCImgList(x);
  CId out(L.at(0),false);
  
  if(doquan){ // ensure prob is between 0-1
    if(prob < 0){
      prob = 0;
    }
    if(prob > 1){
      prob = 1;
    }
  }
  
  int n = x.size();
  
#if cimg_use_openmp == 1
  int num_threads = omp_get_max_threads();
#else
  int num_threads = 1;
#endif
  std::vector<std::vector<double> > vectors;
  vectors.reserve(num_threads);
  for (int i = 0; i < num_threads; i++)
    vectors.emplace_back(n);
  
  cimg_pragma_openmp(parallel for schedule(static))
    cimg_forX(out, x)
    {
#if cimg_use_openmp == 1
      int thread_num = omp_get_thread_num();
#else
      int thread_num = 0;
#endif
      auto &vec = vectors[thread_num];
      cimg_forYZC(out, y, z, c)
      {
        std::vector<double>::iterator vec_end = vec.begin();
        if (na_rm) {
          for (auto &image: L) {
            auto value = image(x, y, z, c);
            if (!ISNAN(value)) {
              *vec_end = value;
              vec_end++;
            }
          };
        }
        else {
          for (auto &image: L) {
            *vec_end = image(x, y, z, c);
            vec_end++;
          }
        }
        if(doquan){
          out(x,y,z,c) = _get_quantile(vec.begin(), vec_end, prob, na_rm);
        }else{
          out(x,y,z,c) = _get_median(vec.begin(), vec_end, na_rm);
        }
      }
    }
  return wrap(out);
}


// [[Rcpp::export]]
List psort(List x,bool increasing = true)
{
  CImgList<double> L = sharedCImgList(x);
  CImgList<double> out(L,false);
  int n = x.size();
  cimg_pragma_openmp(parallel for cimg_openmp_if(out.size()>=65536))
    cimg_forXYZC(L.at(0),x,y,z,c)
    {
      CId vec(n,1,1,1),perm(n,1,1,1);
      
      for (int i = 0; i <n; i++)
	{
	  vec[i] = L.at(i)(x,y,z,c);
	  //	  vec[i] = L.atNXYZC(i,x,y,z,c);
	}
      vec.sort(perm,increasing);
      for (int i = 0; i <n; i++)
	{
	  out.at(i)(x,y,z,c) = vec[i];
	}

    }
  return wrap(out);
}

// [[Rcpp::export]]
List porder(List x,bool increasing = true)
{
  CImgList<double> L = sharedCImgList(x);
  CImgList<double> out(L,false);
  int n = x.size();
  cimg_pragma_openmp(parallel for cimg_openmp_if(out.size()>=65536))
    cimg_forXYZC(L.at(0),x,y,z,c)
    {
      CId vec(n,1,1,1),perm(n,1,1,1);
      
      for (int i = 0; i <n; i++)
	{
	  vec[i] = L.at(i)(x,y,z,c);
	  //	  vec[i] = L.atNXYZC(i,x,y,z,c);
	}
      vec.sort(perm,increasing);
      for (int i = 0; i <n; i++)
	{
	  out.at(i)(x,y,z,c) = perm[i] + 1;
	}

    }
  return wrap(out);
}


// [[Rcpp::export]]
List prank(List x,bool increasing = true)
{
  CImgList<double> L = sharedCImgList(x);
  CImgList<double> out(L,false);
  int n = x.size();
  cimg_pragma_openmp(parallel for cimg_openmp_if(out.size()>=65536))
    cimg_forXYZC(L.at(0),x,y,z,c)
    {
      CId vec(n,1,1,1),perm(n,1,1,1);
      
      for (int i = 0; i <n; i++)
	{
	  vec[i] = L.at(i)(x,y,z,c);
	  //	  vec[i] = L.atNXYZC(i,x,y,z,c);
	}
      vec.sort(perm,increasing);
      for (int i = 0; i <n; i++)
	{
	  out.at(perm(i))(x,y,z,c) = i + 1;
	}

    }
  return wrap(out);
}
