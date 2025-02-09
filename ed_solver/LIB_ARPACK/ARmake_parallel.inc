############################################################################
#
#  Program:         ARPACK
#
#  Module:          ARmake.inc
#
#  Purpose:         Top-level Definitions
#
#  Creation date:   February 22, 1996
#
#  Modified:
#
#  Send bug reports, comments or suggestions to arpack@caam.rice.edu
#
############################################################################
#
#
#  *** If you are using a VENDOR SUPPLIED VERSION of MPI, you  ***
#  *** must replace the mpif.h in the following directories    ***
#  ***                                                         ***
#  ***            ARPACK/PARPACK/SRC/MPI/mpif.h                ***
#  ***            ARPACK/PARPACK/UTIL/MPI/mpif.h               ***
#  ***            ARPACK/PARPACK/EXAMPLES/MPI/mpif.h           ***
#  ***                                                         ***
#  *** with the one for the native implementation.             ***

home="/home/cweber/MYLIBRARY/LIB_ARPACK"
PLAT          = 
COMMLIB       = MPI
BLASdir      = $(home)/BLAS
LAPACKdir    = $(home)/LAPACK
UTILdir      = $(home)/UTIL
SRCdir       = $(home)/SRC
PSRCdir      = $(home)/PARPACK/SRC/$(COMMLIB)
PUTILdir     = $(home)/PARPACK/UTIL/$(COMMLIB)
DIRS         = $(LAPACKdir) $(UTILdir) $(SRCdir)
ARPACKLIB    = $(home)/libparpack.a
LAPACKLIB    = 
BLASLIB      = -lesslp2
ALIBS        =  $(ARPACKLIB) $(LAPACKLIB) $(BLASLIB) 
PARPACKLIB   = $(home)/parpack_$(COMMLIB).a
INSTALL_DIR  = /opt/mpich2_intel11.1
ARCH         = linux
COMM         = MPI
LIB_PATH     = $(INSTALL_DIR)/lib/
MPILIBS      = -L$(LIB_PATH) -lmpich  
PLIBS        = $(PARPACKLIB) $(ALIBS) $(MPILIBS)

.SUFFIXES:
.SUFFIXES:	.f	.o
.SUFFIXES:	.F	.f
.DEFAULT:
	@$(ECHO) "Unknown target $@, try:  make help"
.f.o:
	@$(ECHO) Making $@ from $<
	@$(FC) -c $(FFLAGS) $<
.F.f:
	@$(ECHO) Making $*.f from $<
	@$(CPP) -P -DSINGLE $(CPPFLAGS) $< $*.f
	@$(ECHO) Making d$*.f from $<
	@$(CPP) -P -DDOUBLE $(CPPFLAGS) $< d$*.f

#FC       =  ifort  
#FFLAGS	 = -O3 -static  
FC      =  mpif90
FFLAGS	 = -O3 -static  
LDFLAGS  = 
CD	 = cd
AR       = ar
CHMOD	 = chmod
CHFLAGS	 = -f
COMPRESS = gzip  
CP	 = cp
CPP	 = /lib/cpp
CPPFLAGS =
ECHO	 = echo
LN	 = ln
LNFLAGS	 = -s
MAKE	 = make
MKDIR	 = mkdir
MDFLAGS	 = -p
MV	 = mv
MVFLAGS	 = -f
RM	 = rm
RMFLAGS  = -f
SHELL	 = /bin/sh
TAR	 = tar
RANLIB   = ranlib
#  This is the general help target.
help:
	@$(ECHO) "usage: make ?"
