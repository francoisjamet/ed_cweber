####################################################################
#  LAPACK make include file.                                       #
#  LAPACK, Version 3.1.1                                           #
#  February 2007                                                   #
####################################################################

#
# See the INSTALL/ directory for more examples.
#

SHELL = /bin/bash



#
#  The machine (platform) identifier to append to the library names
#

PLAT = 


#  
#  Modify the FORTRAN and OPTS definitions to refer to the
#  compiler and desired compiler options for your machine.  NOOPT
#  refers to the compiler options desired when NO OPTIMIZATION is
#  selected.  Define LOADER and LOADOPTS to refer to the loader and 
#  desired load options for your machine.
#

FORTRAN  = mpif90  
OPTS     = -O1     
DRVOPTS  = $(OPTS)
NOOPT    =
LOADER   = mpif90  
LOADOPTS = -O0 -w   




#
# Timer for the SECOND and DSECND routines
#
# Default : SECOND and DSECND will use a call to the EXTERNAL FUNCTION ETIME
TIMER    = EXT_ETIME
# For RS6K : SECOND and DSECND will use a call to the EXTERNAL FUNCTION ETIME_
# TIMER    = EXT_ETIME_
# For gfortran compiler: SECOND and DSECND will use a call to the INTERNAL FUNCTION ETIME
# TIMER    = INT_ETIME 
# If your Fortran compiler does not provide etime (like Nag Fortran Compiler, etc...)
# SECOND and DSECND will use a call to the INTERNAL FUNCTION CPU_TIME 
# TIMER    = INT_CPU_TIME
# If neither of this works...you can use the NONE value... In that case, SECOND and DSECND will always return 0
 TIMER     = NONE
#
#  The archiver and the flag(s) to use when building archive (library)
#  If you system has no ranlib, set RANLIB = echo.
#



ARCH     = ar
ARCHFLAGS= cr
RANLIB   = ranlib

#
#  The location of the libraries to which you will link.  (The 
#  machine-specific, optimized BLAS library should be used whenever
#  possible.)
#

BLASLIB      = libblas.a
LAPACKLIB    = liblapack.a
TMGLIB       = libtmglib.a
EIGSRCLIB    = libeigsrc.a
LINSRCLIB    = liblinsrc.a

