


AC_PREREQ([2.69])


## ---[ VERSION ]-------------------------------------------------------------

AC_INIT

: ${R_HOME=`R RHOME`}
if test -z "${R_HOME}"; then
  echo "could not determine R_HOME"
  exit 1
fi
CC=`"${R_HOME}/bin/R" CMD config CC`
CFLAGS=`"${R_HOME}/bin/R" CMD config CFLAGS`
CPPFLAGS=`"${R_HOME}/bin/R" CMD config CPPFLAGS`
LDFLAGS=`"${R_HOME}/bin/R" CMD config LDFLAGS`

CXX=`"${R_HOME}/bin/R" CMD config CXX`
if test -z "$CXX"; then
  AC_MSG_ERROR([No C++ compiler is available])
fi
CXXFLAGS=`"${R_HOME}/bin/R" CMD config CXXFLAGS`
AC_LANG(C++)

RBIN="${R_HOME}/bin/R"

## OS checking borrowed from rgl package by Duncan Murdoch
##AC_CONFIG_AUX_DIR(src/build/autoconf)
if test `uname` = "Darwin" ; then
  darwin="yes"
  ## we want the *build* cputype and not the host one.
  cmd=`echo $CC $CFLAGS | grep -E 'x86_64|ppc64|-m64'`
  if test -n "$cmd"; then
    have_64bit="yes"
  else
    have_64bit="no"
  fi 
else
  darwin="no"
fi

# check the presense of pkg-config (from Cairo package)
AC_PATH_PROG([PKGCONF],[pkg-config],[],[$PATH:/usr/local/bin:ext/bin:ext:/sw/bin:/opt/bin])


# ---[ X11 ]------------------------------------------------------------------

  AC_PATH_X
  AC_CHECK_LIB(X11, XOpenDisplay, [HAVE_LIBX11=TRUE], [HAVE_LIBX11=FALSE])
  if test "$HAVE_LIBX11" = TRUE; then
    AC_MSG_RESULT([X11 library found.])
    DONT_HAVE_X11=''
    #DONT_HAVE_X11='-Dcimg_display=0'
  else
    AC_MSG_RESULT([X11 library not found, please install X11 library if you need the display capabilities of CImg.])
    DONT_HAVE_X11='-Dcimg_display=0'
  fi
  if test x$no_x = xyes ; then
    AC_MSG_ERROR([X11 not found but required, configure aborted.])
  fi
  if test -n "${x_includes}"; then
    CPPFLAGS="${CPPFLAGS} -I${x_includes}"
  fi
  if test -n "${x_libraries}"; then
    LIBS="${LIBS} -L${x_libraries} -lX11"
  else
    LIBS="${LIBS} -lX11"
  fi

  if test x$L_LIB != x; then
    LIBS="${L_LIB} ${LIBS}"
  fi



# from mwaved package by jrwishart
# Check if the FFTW Library exists on the system
AC_MSG_NOTICE([Checking if FFTW3 library is available using pkg-config])

## --- FFTW 3 ----------------------------------------------------------------
# pkg-config is the best source of include/lib paths, but it is not always
# installed (a plain Homebrew setup without pkg-config cannot find an fftw that
# is otherwise perfectly linkable). Fall back to a direct probe so that FFTW is
# only reported missing when it really is.
HAVE_FFTW=FALSE
PKG_CHECK_MODULES(FFTW, fftw3, [HAVE_FFTW=TRUE], [:])

if test "$HAVE_FFTW" != TRUE; then
  AC_MSG_CHECKING([for fftw3 without pkg-config])
  ac_save_LIBS=$LIBS
  LIBS="$LIBS -lfftw3"
  AC_LINK_IFELSE([AC_LANG_PROGRAM([[#include <fftw3.h>]],
    [[fftw_complex *p = (fftw_complex*) fftw_malloc(sizeof(fftw_complex));
      fftw_free(p); return 0;]])],
    [HAVE_FFTW=TRUE
     FFTW_CFLAGS=""
     FFTW_LIBS="-lfftw3"
     AC_MSG_RESULT([yes])],
    [AC_MSG_RESULT([no])])
  LIBS=$ac_save_LIBS
fi

if test "$HAVE_FFTW" = TRUE; then
  HAVE_FFTW='-Dcimg_use_fftw3'
  AC_MSG_RESULT([FFTW3 found!])
else
  HAVE_FFTW=''
  # Return message that package requires FFTW3 library
  AC_MSG_RESULT([FFTW library not found, please install fftw3 for better FFT support.])
fi


#check for libtiff 
#(from Cairo and modified)
if test "xx$PKGCONF" != "xx"; then
  AC_MSG_CHECKING([whether pkg-config knows about libtiff-4])
  if "${PKGCONF}" --exists libtiff-4; then
    AC_MSG_RESULT([yes])
    AC_MSG_CHECKING([for configurable backends])
    TIFF_LIBS=`"${PKGCONF}" --libs libtiff-4`
    TIFF_CFLAGS=`"${PKGCONF}" --cflags libtiff-4`
    TIFF_CFLAGS="${TIFF_CFLAGS} -Dcimg_use_tiff"
    AC_MSG_CHECKING([whether --static is needed])
    saveLIBS="$LIBS"
    LIBS="$saveLIBS ${TIFF_LIBS}"
    AC_LINK_IFELSE([AC_LANG_FUNC_LINK_TRY(TIFFOpen)],
      [AC_MSG_RESULT([no])],
      [TIFF_LIBS=`"${PKGCONF}" --libs --static libtiff-4`
       LIBS="$saveLIBS ${TIFF_LIBS}"
       AC_LINK_IFELSE([AC_LANG_FUNC_LINK_TRY(TIFFOpen)],
        [AC_MSG_RESULT([yes])],
        [AC_MSG_RESULT([neither works, abandoning pkg-config])
        # Both must go: leaving -Dcimg_use_tiff in TIFF_CFLAGS would compile
        # CImg's TIFF code with no library behind it and fail at link time.
        TIFF_LIBS=''
        TIFF_CFLAGS=''
       ])
      ])
    LIBS="$saveLIBS"
  else
    AC_MSG_RESULT([no])
  fi
else
  #(from rtiff package) 
  AC_CHECK_LIB([tiff], [TIFFOpen], [have_tiff=yes], [have_tiff=no])
  if test "x${have_tiff}" = xyes; then
  TIFF_LIBS="-ltiff"
  TIFF_CFLAGS="-Dcimg_use_tiff"
  else
    ## version for Mac macOS, static libtiff 4.0.x
    unset ac_cv_lib_tiff_TIFFOpen
    echo 'Try static libs needed on macOS'
    AC_CHECK_LIB([tiff], [TIFFOpen], [have_tiff=yes], [have_tiff=no],
                 [-llzma -ljpeg -lz])
    if test "x${have_tiff}" = xyes; then
      TIFF_CFLAGS="-Dcimg_use_tiff"
      TIFF_LIBS="-ltiff -llzma -ljpeg -lz"
    else
      echo Could not find libtiff. Install libtiff for better tiff support
      TIFF_CFLAGS=""
      TIFF_LIBS=""
    fi
  fi
fi


## ---[ OpenMP ]--------------------------------------------------------------

# R's own answer is authoritative: when the R build has OpenMP, it defines
# SHLIB_OPENMP_CXXFLAGS and src/Makevars.in uses it, so there is nothing left
# for us to decide. Several macOS R builds, however, ship a working libomp yet
# leave that variable empty. Packages that rely on it then compile and link
# serially with no warning at all, which is how imager ended up with threading
# silently disabled on macOS. So when R gives us nothing, look for a usable
# runtime ourselves.
#
# OPENMP_CXXFLAGS/OPENMP_LIBS are what we found (both empty when OpenMP is
# unavailable or --disable-openmp was given); SHLIB_OPENMP_CXXFLAGS, if R set
# it, is left to do its job through src/Makevars.in.

AC_ARG_ENABLE([openmp],
  [AS_HELP_STRING([--disable-openmp], [do not use OpenMP])],
  [], [enable_openmp=yes])

OPENMP_CXXFLAGS=""
OPENMP_LIBS=""
ac_omp_found=no

if test "x$enable_openmp" != xno; then

  AC_CACHE_CHECK([for R's OpenMP flags],
    [imager_cv_openmp_from_r],
    [imager_cv_openmp_from_r=`"${RBIN}" CMD config SHLIB_OPENMP_CXXFLAGS 2>/dev/null`
     # R prints an ERROR line on stdout (with exit status 1) for a variable it
     # does not know about, which is the normal case on these builds.
     case "$imager_cv_openmp_from_r" in
       *ERROR*) imager_cv_openmp_from_r="" ;;
     esac])

  if test -n "$imager_cv_openmp_from_r"; then
    AC_MSG_NOTICE([R reports OpenMP flags: $imager_cv_openmp_from_r])
    ac_omp_found=yes
  else
    AC_LANG(C++)

    # Try one candidate flag pair by link-testing a program that needs both the
    # header and the runtime, i.e. exactly what CImg will need. Returns true on
    # success. $1 goes in CXXFLAGS, $2 in LIBS.
    ac_omp_save_CXXFLAGS=$CXXFLAGS
    ac_omp_save_LIBS=$LIBS
    imager_try_openmp () {
      CXXFLAGS="$ac_omp_save_CXXFLAGS $1"
      LIBS="$2 $ac_omp_save_LIBS"
      AC_LINK_IFELSE([AC_LANG_PROGRAM([[#ifndef _OPENMP
#error OpenMP not enabled by the compiler flags
#endif
#include <omp.h>]], [[return omp_get_num_threads()]])],
        [true], [false])
    }

    # Apple clang first: it has no -fopenmp at all, it spells the switch
    # -Xclang -fopenmp, and that alone links nothing. The runtime must be named
    # explicitly, and R for macOS ships one in ${R_HOME}/lib but no omp.h to go
    # with it. Homebrew's libomp is keg-only, so its include dir is also worth
    # passing. Naming the library by full path matters: a bare -lomp resolves
    # against whatever is first on the linker's search path, and a stray
    # /usr/local/lib/libomp.dylib from another toolchain would then be linked
    # against the R-bundled header expectations of whoever built it.
    if test "$darwin" = "yes"; then
      for ac_p in "${R_HOME}" /usr/local/opt/libomp /opt/homebrew/opt/libomp; do
        if test -f "$ac_p/lib/libomp.dylib"; then
          ac_omp_inc=""
          if test -f "$ac_p/include/omp.h"; then
            ac_omp_inc="-I$ac_p/include"
          fi
          if imager_try_openmp "-Xclang -fopenmp $ac_omp_inc" "$ac_p/lib/libomp.dylib"; then
            OPENMP_CXXFLAGS="-Xclang -fopenmp $ac_omp_inc"
            OPENMP_LIBS="$ac_p/lib/libomp.dylib"
            ac_omp_found=yes
            break
          fi
        fi
      done
    fi

    # GCC, Intel and friends take a single flag that both compiles and links.
    if test "$ac_omp_found" = no; then
      for ac_f in -fopenmp -xopenmp -qopenmp -openmp -mp -omp -qsmp=omp -homp -fopenmp=libomp; do
        if imager_try_openmp "$ac_f" ""; then
          OPENMP_CXXFLAGS="$ac_f"
          OPENMP_LIBS=""
          ac_omp_found=yes
          break
        fi
      done
    fi

    CXXFLAGS=$ac_omp_save_CXXFLAGS
    LIBS=$ac_omp_save_LIBS

    if test "$ac_omp_found" = yes; then
      AC_MSG_NOTICE([using OpenMP: CXXFLAGS="$OPENMP_CXXFLAGS" LIBS="$OPENMP_LIBS"])
    else
      AC_MSG_WARN([OpenMP was not found; imager will be built serially.])
    fi
  fi
elif test "x$enable_openmp" = xno; then
  AC_MSG_NOTICE([OpenMP disabled by --disable-openmp])
fi

AC_SUBST(OPENMP_CXXFLAGS)
AC_SUBST(OPENMP_LIBS)

# Now substitute these variables in src/Makevars.in to create src/Makevars
AC_SUBST(DONT_HAVE_X11)
AC_SUBST(HAVE_FFTW)
AC_SUBST(FFTW_CFLAGS)
AC_SUBST(FFTW_LIBS)

AC_SUBST(TIFF_CFLAGS)
AC_SUBST(TIFF_LIBS)


## --- Output ----------------------------------------------------------------

AC_SUBST(CPPFLAGS)
AC_SUBST(CXXFLAGS)
AC_SUBST(LIBS)

AC_CONFIG_FILES([src/Makevars])
AC_OUTPUT
