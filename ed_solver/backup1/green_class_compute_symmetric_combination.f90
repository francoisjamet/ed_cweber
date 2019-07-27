MODULE green_class_compute_symmetric

  use green_class_compute_dynamic
  use stringmanip

  IMPLICIT NONE

  REAL(DBL),    PARAMETER, PRIVATE  :: zero=0.0_DBL,one=1.0_DBL
  LOGICAL,      PARAMETER, PRIVATE  :: F=.FALSE.,T=.TRUE.
  COMPLEX(DBL) ,PARAMETER, PRIVATE  :: coef1=1.d0,coef2=1.d0

CONTAINS

!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************

#include "green_class_compute_symmetric_combination_AA.h"
#include "green_class_compute_symmetric_combination_AB.h"
#include "green_class_compute_symmetric_combination_tools.h"

!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************

  SUBROUTINE symmetric_combineAA(Asym,iorb,jorb,ipm,jpm,iph,Apm_es,isec_back,iisector,GS,ssz)
    implicit none
    TYPE(eigensectorlist_type),INTENT(IN) :: GS
    TYPE(eigen_type),       INTENT(INOUT) :: Asym
    INTEGER,                INTENT(IN)    :: iorb,jorb,ipm,jpm,iph
    TYPE(eigensector_type), INTENT(IN)    :: Apm_es(2)
    TYPE(eigen_type), POINTER             :: Ai => NULL(), Aj => NULL()
    integer                               :: jj,isec_back,iisector,iii,ssz
    complex(8)                            :: csign,csign2,csign3 

   !---------------------------------------------------------------------------!
   !  MAKE THE SYMMETRIC COMBINATIONS OF INDEPENDANT VECTORS A(i)|GS>,A(j)|GS> !
   !  ACCORDING TO MASK 'Amask' AND STORE THEM IN    VECTORS Asym(:)|GS>       !
   !                                                                           !
   !  I.E. Asym(i,j)|GS> =             A(i)   |GS>  if  i=j                    !
   !       Asym(i,j)|GS> = ( A(i) +    A(j) ) |GS>  if  i<j  OR  REAL    H     !
   !       Asym(i,j)|GS> = ( A(i) -I * A(j) ) |GS>  if  i>j  AND COMPLEX H     !
   !---------------------------------------------------------------------------!
    ssz=0
 
    SELECT CASE(iph)
     CASE(1)
       Ai => Apm_es(3-ipm)%lowest%eigen(rank_eigen_in_list(iorb,Apm_es(3-ipm)%lowest))
       Aj => Apm_es(  jpm)%lowest%eigen(rank_eigen_in_list(jorb,Apm_es(  jpm)%lowest))
       IF ( .NOT.equal_sector(Apm_es(3-ipm)%sector,Apm_es(  jpm)%sector) ) &
        &   STOP "ERROR IN green_class_computeAA: INCONSISTENT SECTORS!"
       if(associated(Apm_es(3-ipm)%sector%sz))then
        ssz=Apm_es(3-ipm)%sector%sz%npart
        IF(isec_back/=Apm_es(3-ipm)%sector%sz%dimen) stop 'symmetrize AA iph=1 wrong sectors'
       endif
       iisector=0
        do iii=1,GS%nsector
           IF(equal_sector(GS%es(iii)%sector,Apm_es(jpm)%sector))THEN
            iisector=iii
            exit
           endif
        enddo
       csign  =  1.d0  !particle contrib.
       csign2 =  1.d0 
       csign3 =  1.d0
     CASE(2)
       Ai => Apm_es(  ipm)%lowest%eigen(rank_eigen_in_list(iorb,Apm_es(  ipm)%lowest))
       Aj => Apm_es(3-jpm)%lowest%eigen(rank_eigen_in_list(jorb,Apm_es(3-jpm)%lowest))
       IF( .NOT.equal_sector(Apm_es(ipm)%sector,Apm_es(3-jpm)%sector) ) &
        &   STOP "ERROR IN green_class_computeAA: INCONSISTENT SECTORS!"
       if(associated(Apm_es(ipm)%sector%sz))then
        ssz=Apm_es(ipm)%sector%sz%npart
        IF(isec_back/=Apm_es(ipm)%sector%sz%dimen) stop 'symmetrize AA iph=2 wrong sectors'
       endif
       iisector=0
        do iii=1,GS%nsector
           IF(equal_sector(GS%es(iii)%sector,Apm_es(ipm)%sector))THEN
            iisector=iii
            exit
           endif
        enddo
       csign  = -1.d0  !hole contrib.
       csign2 =  1.d0
       csign3 =  1.d0
     CASE DEFAULT
       stop 'error symmetrize'
    END SELECT

   CALL new_eigen(Asym,Ai)

   if(size(Ai%vec%rc) /= size(Aj%vec%rc) ) then
     write(log_unit,*) ' symmetric combination of operators AA, but they do not belong to the same sector'
     write(log_unit,*) 'Ai, size vec : ', size(Ai%vec%rc)
     write(log_unit,*) 'Aj, size vec : ', size(Aj%vec%rc)
     stop 'error critical'
   endif
   if(size(Asym%vec%rc) /= size(Aj%vec%rc) ) then
     write(log_unit,*) ' symmetric combination of operators AA, but they do not belong to the same sector'
     write(log_unit,*) 'Ai, size vec   : ', size(Ai%vec%rc)
     write(log_unit,*) 'Asym, size vec : ', size(Asym%vec%rc)
     stop 'error critical'
   endif

#ifdef _complex

   IF(iorb==jorb.and.ipm==jpm)THEN
      if(ipm==1) Asym%vec%rc = csign3*Ai%vec%rc + csign2    * Aj%vec%rc
      if(ipm==2) Asym%vec%rc = csign3*Ai%vec%rc - imi*csign * Aj%vec%rc
   ENDIF

   IF(iorb>jorb) Asym%vec%rc = csign3*Ai%vec%rc - imi*csign * Aj%vec%rc
   IF(iorb<jorb) Asym%vec%rc = csign3*Ai%vec%rc + csign2    * Aj%vec%rc

#else

   IF(iorb==jorb.and.ipm==jpm)THEN 
      if(ipm==1) Asym%vec%rc = csign3*Ai%vec%rc + csign2    * Aj%vec%rc
      if(ipm==2) Asym%vec%rc = csign3*Ai%vec%rc + csign2    * Aj%vec%rc
   ENDIF
   IF(iorb>jorb) Asym%vec%rc = csign3*Ai%vec%rc + csign2    * Aj%vec%rc
   IF(iorb<jorb) Asym%vec%rc = csign3*Ai%vec%rc + csign2    * Aj%vec%rc

#endif

  END SUBROUTINE

!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************

  SUBROUTINE symmetric_combineAB(ABsym,iorb,jorb,ipm,jpm,iph,Apm_es,Bpm_es,BA,isec_back,iisector,GS,ssz)
    implicit none
    TYPE(eigensectorlist_type), INTENT(IN):: GS
    TYPE(eigen_type),       INTENT(INOUT) :: ABsym
    INTEGER,                INTENT(IN)    :: iorb,jorb,ipm,jpm,iph
    TYPE(eigensector_type), INTENT(IN)    :: Apm_es(2),Bpm_es(2)
    LOGICAL,                INTENT(IN)    :: BA
    TYPE(eigen_type), POINTER             :: Ai => NULL(),Bj => NULL()
    complex(8)                            :: csign,csign2,csign3 
    INTEGER                               :: isec_back,iisector,iii,ssz

    !------------------------------------------------------------------------------------------!
    ! MAKE THE SYMMETRIC COMBINATIONS OF INDEPENDANT VECTORS A(i),B(i)|GS> AND A(j),B(j)|GS>   !
    ! AND STORE THEM IN VECTORS ABsym(:)|GS>                                                   !
    !                                                                                          !
    ! I.E. ABsym(i,j)|GS> = (A(i) +    B(j))|GS> if i<=j OR  REAL    H                         !
    !      ABsym(i,j)|GS> = (A(i) -I * B(j))|GS> if i> j AND COMPLEX H                         !
    ! case iph=1     : Ai^+  +   Bj                                                            !
    ! case iph=1 BA  : Bi^+  +   Aj                                                            !
    ! case iph=2     : Ai    +   Bj^+                                                          !
    ! case iph=2 BA  : Bi    +   Aj^+                                                          !
    !------------------------------------------------------------------------------------------!

    SELECT CASE(iph)
     CASE(1)
       Ai => Apm_es(3-ipm)%lowest%eigen(rank_eigen_in_list(iorb,Apm_es(3-ipm)%lowest))
       Bj => Bpm_es(  jpm)%lowest%eigen(rank_eigen_in_list(jorb,Bpm_es(  jpm)%lowest))
       if(associated(Apm_es(3-ipm)%sector%sz))then
        ssz=Apm_es(3-ipm)%sector%sz%npart
        if(isec_back/=APm_es(3-ipm)%sector%sz%dimen) stop 'error not good sectors'
       endif
        IF( .NOT.equal_sector(Apm_es(3-ipm)%sector,Bpm_es(  jpm)%sector) ) &
        &   STOP "ERROR IN green_class_computeAB: INCONSISTENT SECTORS!"
        iisector=0
        do iii=1,GS%nsector
           IF(equal_sector(GS%es(iii)%sector,Apm_es(3-ipm)%sector))THEN
            iisector=iii
            exit
           endif
        enddo
       csign  =      1.   !particle contrib.
       csign2 =      1.
       csign3 =      1.
     CASE(2)
       Ai => Apm_es(  ipm)%lowest%eigen(rank_eigen_in_list(iorb,Apm_es(  ipm)%lowest))
       Bj => Bpm_es(3-jpm)%lowest%eigen(rank_eigen_in_list(jorb,Bpm_es(3-jpm)%lowest))
       if(associated(Apm_es(ipm)%sector%sz))then
        ssz=Apm_es(ipm)%sector%sz%npart
        if(isec_back/=APm_es(ipm)%sector%sz%dimen) stop 'error not good sectors'
       endif
       IF( .NOT.equal_sector(Apm_es(ipm)%sector,Bpm_es(3-jpm)%sector) ) &
        &   STOP "ERROR IN green_class_computeAB: INCONSISTENT SECTORS!"
       iisector=0
        do iii=1,GS%nsector
           IF(equal_sector(GS%es(iii)%sector,Apm_es(ipm)%sector))THEN
            iisector=iii
            exit
           endif
        enddo
      csign  =      -1.   !hole contrib.
      csign2 =       1.
      csign3 =       1.
     CASE DEFAULT
      stop 'error symmetrize'
    END SELECT

    CALL new_eigen(ABsym,Ai)

    if(size(Ai%vec%rc) /= size(Bj%vec%rc) ) then
     write(log_unit,*) ' symmetric combination of operators AB, but they do not belong to the same sector'
     write(log_unit,*) 'Ai, size vec : ', size(Ai%vec%rc)
     write(log_unit,*) 'Bj, size vec : ', size(Bj%vec%rc)
     stop 'error critical'
    endif
    if(size(ABsym%vec%rc) /= size(Ai%vec%rc) ) then
     write(log_unit,*) ' symmetric combination of operators AA, but they do not belong to the same sector'
     write(log_unit,*) 'Ai, size vec   : ', size(Ai%vec%rc)
     write(log_unit,*) 'Asym, size vec : ', size(ABsym%vec%rc)
     stop 'error critical'
    endif

#ifdef _complex
    IF(               iorb>jorb) ABsym%vec%rc = csign2 * Ai%vec%rc - imi*csign * Bj%vec%rc
    IF(               iorb<jorb) ABsym%vec%rc = csign2 * Ai%vec%rc + csign3    * Bj%vec%rc
    IF(     BA .and. iorb==jorb) ABsym%vec%rc = csign2 * Ai%vec%rc - imi*csign * Bj%vec%rc
    if(.not.BA .and. iorb==jorb) ABsym%vec%rc = csign2 * Ai%vec%rc + csign3    * Bj%vec%rc
#else
    IF(iorb>jorb)                ABsym%vec%rc = csign2 * Ai%vec%rc + csign3    * Bj%vec%rc
    IF(iorb<jorb)                ABsym%vec%rc = csign2 * Ai%vec%rc + csign3    * Bj%vec%rc
    IF(iorb==jorb)               ABsym%vec%rc = csign2 * Ai%vec%rc + csign3    * Bj%vec%rc
#endif

  return
  END SUBROUTINE

!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************

END MODULE 
