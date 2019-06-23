module specialFunction

 use genvar
! use linalg 

INTERFACE DEXPc
 MODULE PROCEDURE DEXPc_r,DEXPc_q,DEXPc_rr
END INTERFACE

contains

pure real(8) function DEXPc_r(rr)
 implicit none
  real(8),intent(in) :: rr
  if(rr<MAX_EXP) then
   if(rr<MIN_EXP)then
    DEXPc_r=0.d0
   else
    DEXPc_r=EXP(rr)
   endif
  else
    DEXPc_r=EXP(MAX_EXP)
  endif
 end function

 pure real(8) function DEXPc_rr(rr)
 implicit none
  real(4),intent(in) :: rr
  if(rr<MAX_EXP_r) then
   if(rr<MIN_EXP_r)then
    DEXPc_rr=0.d0
   else
    DEXPc_rr=EXP(rr)
   endif
  else
    DEXPc_rr=EXP(MAX_EXP_r)
  endif
 end function

 pure real(16) function DEXPc_q(rr)
 implicit none
  real(16),intent(in) :: rr
  if(rr<MAX_EXP_QUAD) then
   if(rr<MIN_EXP_QUAD)then
    DEXPc_q=0.d0
   else
    DEXPC_q=EXP(rr)
   endif
  else
    DEXPc_q=EXP(MAX_EXP_QUAD)
  endif
 end function

!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************

  FUNCTION combination(n,p)
    INTEGER,         INTENT(IN)  :: n,p
    INTEGER(KIND=8)              :: combination,Cnp
    ! THIS IS TO AVOID BRUTAL n! THAT MAY FALL OUT OF RANGE
    IF(p> n  )STOP "ERROR IN combination: n>=p REQUIRED!"
    IF(p>=n-p)THEN
      Cnp = factorial_rec(INT(n,8),INT(p,8))   / factorial_rec(INT(n-p,8))
    ELSE
      Cnp = factorial_rec(INT(n,8),INT(n-p,8)) / factorial_rec(INT(p,8))
    ENDIF
    combination=Cnp
  END FUNCTION


!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************

  complex(8) Function Inverse_Hilbert_Transform_Bethe_Lattice(zeta)
  implicit none
  complex(8) :: zeta,s
   s = sqrt(zeta**2 - 1.0)
   Inverse_Hilbert_Transform_Bethe_Lattice = 2.0/(zeta + sign(1.d0,aimag(zeta))*sign(1.d0,aimag(s))*s)
  end function

!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************

  RECURSIVE FUNCTION factorial_rec(n,p) RESULT(fact_n)
    INTEGER(KIND=8), INTENT(IN)           :: n
    INTEGER(KIND=8), INTENT(IN), OPTIONAL :: p
    INTEGER(KIND=8)                       :: fact_n
    INTEGER(KIND=8) :: p_

    IF(n==0)THEN
      fact_n = 1
      RETURN
    END IF

    p_ = 1
    IF(PRESENT(p)) p_ = p ! compute n!/p!

    IF(n==p_)THEN
      fact_n = 1
      RETURN
    END IF

    fact_n = n

    IF(fact_n==p_+1)THEN
      RETURN
    ELSE
      fact_n = fact_n * factorial_rec(fact_n-1,p_)
    END IF
  END FUNCTION

!********************************************
!********************************************
!********************************************
!********************************************

      elemental real(8) function delta_chron(rr,rr2)
      implicit none
      real(8),intent(in) :: rr,rr2
       delta_chron=0.d0
       if(abs(rr-rr2)<epsilonr)then
        delta_chron=1.d0
       endif
      end function

!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************

      elemental real(8) function lorentzien_(rr,a,delta)
      implicit none
      real(8),intent(in) :: rr,delta,a
       lorentzien_= 1.d0 / ( (rr-a)**2 + delta**2 ) 
      end function

!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************

      elemental real(8) function theta_func_(rr,rr2)
      implicit none
      real(8),intent(in) :: rr,rr2
       theta_func_=0.d0
       if(rr<rr2)then
        theta_func_=1.d0
       endif
      end function

!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************

      elemental real(8) function step_func_(rr)
      implicit none
      real(8),intent(in) :: rr
       if(rr>0.d0)then
        step_func_=1.d0
       else
        step_func_=0.d0
       endif
      end function

!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************

      elemental real(8) function fermi_dirac_(rr,mu,T)
      implicit none
      real(8),intent(in) :: rr,T,mu
      real(8)            :: aa
        aa=(rr-mu)/T
        if(aa<-100.d0) then
         fermi_dirac_=1.d0
         return
        endif
        if(aa>100.d0) then
         fermi_dirac_=0.d0
         return
        endif
        fermi_dirac_= 1.d0 / ( 1.d0  + DEXPc(aa) )
      end function


!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************

      elemental real(8) function derivative_fermi_dirac_(rr,mu,T)
      implicit none
      real(8),intent(in) :: rr,T,mu
      real(8)            :: aa
        aa =(rr-mu)/T/2.d0
        if(abs(aa)>200.d0)then
         derivative_fermi_dirac_=0.d0
         return
        endif
        derivative_fermi_dirac_= -1.d0 / T /  (DEXPc(-aa)+DEXPc(aa))**2
      end function

!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************

      elemental real(8) function bose_einstein_(rr,mu,T)
      implicit none
      real(8),intent(in) :: rr,T,mu
        bose_einstein_= 1.d0 / ( DEXPc((rr-mu)/T) -1.d0 )
      end function

!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************

      real(8) FUNCTION FX(T)
      real(8) T
      FX = SIN(T*5.0)
      RETURN
      END function

!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************

      real(8) FUNCTION FY(T)
      real(8) T
      FY = SIN(T*4.0)
      RETURN
      END function

!********************************************
!********************************************
!********************************************
!********************************************

      REAL FUNCTION PGBSJ1(XX)
      REAL XX
 !-----------------------------------------------------------------------!
 ! Bessel function of order 1 (approximate).
 ! Reference: Abramowitz and Stegun: Handbook of Mathematical Functions.
 !-----------------------------------------------------------------------!
      REAL X, XO3, T, F1, THETA1
      X = ABS(XX)
      IF (X .LE. 3.0) THEN
         XO3 = X/3.0
         T = XO3*XO3
         PGBSJ1 = 0.5 + &
     &       T*(-0.56249985 + &
     &       T*( 0.21093573 + &
     &       T*(-0.03954289 + &
     &       T*( 0.00443319 + &
     &       T*(-0.00031761 + &
     &       T*( 0.00001109))))))
         PGBSJ1 = PGBSJ1*XX
      ELSE
         T = 3.0/X
         F1 =    0.79788456 + &
     &       T*( 0.00000156 + &
     &       T*( 0.01659667 + &
     &       T*( 0.00017105 + & 
     &       T*(-0.00249511 + &
     &       T*( 0.00113653 + &
     &       T*(-0.00020033))))))
         THETA1 = X   -2.35619449 + &
     &       T*( 0.12499612 + &
     &       T*( 0.00005650 + &
     &       T*(-0.00637879 + &
     &       T*( 0.00074348 + &
     &       T*( 0.00079824 + &
     &       T*(-0.00029166))))))
         PGBSJ1 = F1*COS(THETA1)/SQRT(X)
      END IF
      IF (XX .LT. 0.0) PGBSJ1 = -PGBSJ1
      END function

!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************

    REAL FUNCTION PGBSJ0(XX)
    REAL :: XX

 !-----------------------------------------------------------------------!
 ! Bessel function of order 0 (approximate).
 ! Reference: Abramowitz and Stegun: Handbook of Mathematical Functions.
 !-----------------------------------------------------------------------!

      REAL :: X, XO3, T, F0, THETA0

      X = ABS(XX)
      IF (X .LE. 3.0) THEN
         XO3 = X/3.0
         T   = XO3*XO3
         PGBSJ0 = 1.0 + &
     &        T*(-2.2499997 + &
     &        T*( 1.2656208 + &
     &        T*(-0.3163866 + &
     &        T*( 0.0444479 + &
     &        T*(-0.0039444 + &
     &        T*( 0.0002100))))))
      ELSE
         T = 3.0/X
         F0 =     0.79788456 + &
     &        T*(-0.00000077 + &
     &        T*(-0.00552740 + &
     &        T*(-0.00009512 + &
     &        T*( 0.00137237 + &
     &        T*(-0.00072805 + &
     &        T*( 0.00014476))))))
         THETA0 = X - 0.78539816 + &
     &        T*(-0.04166397 + &
     &        T*(-0.00003954 + &
     &        T*( 0.00262573 + &
     &        T*(-0.00054125 + &
     &        T*(-0.00029333 + &
     &        T*( 0.00013558))))))
         PGBSJ0 = F0*COS(THETA0)/SQRT(X)
      END IF
      END function

!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
 
      SUBROUTINE AITOFF(B,L,X,Y)
  !       Hammer-Aitoff projection.
  !       Input: latitude and longitude (B,L) in radians
  !       Output: cartesian (X,Y) in range +/-2, +/-1
      REAL L,B,X,Y,L2,DEN
      L2 = L/2.0
      DEN = SQRT(1.0+COS(B)*COS(L2))
      X = 2.0*COS(B)*SIN(L2)/DEN
      Y = SIN(B)/DEN
      END subroutine

!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************

      SUBROUTINE GALACT(RA,DEC,GLAT,GLONG)

! Convert 1950.0 equatorial coordinates (RA, DEC) to galactic
! latitude and longitude (GLAT, GLONG).

! Arguments:
! RA, DEC (input): 1950.0 RA and Dec (radians).
! GLAT, GLONG (output): galactic latitude and longitude (degrees).
! Reference: e.g., D. R. H. Johnson and D. R. Soderblom, A. J. v93, p864 (1987).

      REAL    :: RA, RRA, DEC, RDEC, CDEC, R(3,3), E(3), G(3)
      REAL    :: RADDEG, GLAT, GLONG
      INTEGER :: I, J

      DATA R/-.066988740D0, .492728466D0,-.867600811D0,-.872755766D0, &
     &       -.450346958D0,-.188374601D0,-.483538915D0, .744584633D0,.460199785D0/
      DATA RADDEG/57.29577951D0/

      RRA  = RA
      RDEC = DEC
      CDEC = COS(RDEC)
      E(1) = CDEC*COS(RRA)
      E(2) = CDEC*SIN(RRA)
      E(3) = SIN(RDEC)
      DO I=1,3
      G(I) = 0.0
      DO J=1,3
        G(I) = G(I) + E(J)*R(I,J)
      enddo 
      enddo 
      GLAT  = ASIN(G(3))*RADDEG
      GLONG = ATAN2(G(2),G(1))*RADDEG
      IF (GLONG.LT.0.0) GLONG = GLONG+360.0
      RETURN
      END subroutine

!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************
!********************************************

   SUBROUTINE FUNCTEST(F, M, N, FMIN, FMAX)
    INTEGER :: M,N
    REAL    :: F(M,N), FMIN, FMAX
    INTEGER :: I, J
    REAL    :: R

      FMIN = 1E30
      FMAX = -1E30
      DO  I=1,M
         DO J=1,N
            R = SQRT(REAL(I)**2 + REAL(J)**2)
            F(I,J) = COS(0.6*SQRT(I*80./M)-16.0*J/(3.*N))* &
     &           COS(16.0*I/(3.*M))+(I/REAL(M)-J/REAL(N)) +  &
     &           0.05*SIN(R)
            FMIN = MIN(F(I,J),FMIN)
            FMAX = MAX(F(I,J),FMAX)
         enddo
      enddo

   END subroutine

!**********************************************
!**********************************************
!**********************************************
!**********************************************
!**********************************************
!**********************************************
!**********************************************

  real(8) FUNCTION POT(X,Y)
     REAL X,Y
     REAL X2,Y2,XX,YY
     REAL AA1,AA2,AA3,AA4
     COMMON/COEFS/AA1,AA2,AA3,AA4
      Y2=Y*Y
      X2=12.*X*X
      XX=.5*(Y2+X2)
      YY=Y2/3.+Y*X2
      POT=1.-AA1*XX-AA2*YY+AA3*XX*XX+AA4*XX*YY

  RETURN
  END function

!**********************************************
!**********************************************
!**********************************************
!**********************************************
!**********************************************
!**********************************************
!**********************************************

 real(8) function iFactorial(j)
  IMPLICIT NONE
  INTEGER, intent(in) :: j
  INTEGER             :: i
  real(8)             :: x
  if (j<0) print *, "iFactorial defined only for non-negative numbers!"
  x=1
  iFactorial = x
  if (j.eq.1) return
  DO i=2,j
     x = x*i
  END DO
  iFactorial = x
  return
 end function

!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************

real(8) function dFactorial(x)
  IMPLICIT NONE
  real(8), intent(in) :: x
  real(8), PARAMETER :: spi2 = 0.8862269254527579
  real(8) :: y, r
  r=1
  y=x
  DO WHILE(y.gt.1.0)
     r = r * y
     y = y -1.
  ENDDO
  IF (abs(y-0.5).LT.1e-10) r = r*spi2
  dFactorial = r
  return
END function

!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************

real(8) function mone(i)
  INTEGER, intent(in) :: i
  mone = 1 - 2*MOD(abs(i),2)
  return
end function

!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************

real(8) function Delta__(j1, j2, j)
  IMPLICIT NONE
  real(8), intent(in) :: j1, j2, j
   Delta__ = sqrt(dFactorial(j1+j2-j)*dFactorial(j1-j2+j)*dFactorial(-j1+j2+j)/dFactorial(j1+j2+j+1))
  return
END function

!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************

real(8) function ClebschG(j,m,j1,m1,j2,m2)
  IMPLICIT NONE
  real(8), intent(in) :: j,m,j1,m1,j2,m2
  INTEGER             :: tmin, tmax, t
  real(8)             :: sum, v1, v2

  ClebschG = 0
  IF (m1+m2 .NE. m) return
  tmin = INT(max(max(0.d0,j2-j-m1),j1-j+m2)+1d-14)
  tmax = INT(min(min(j1+j2-j,j1-m1),j2+m2)+1d-14)
  sum=0;
  DO t=tmin, tmax
     v1 = sqrt((2*j+1)*dFactorial(j1+m1)*dFactorial(j1-m1)*dFactorial(j2+m2)*dFactorial(j2-m2)*dFactorial(j+m)*dFactorial(j-m))
     v2 = iFactorial(t)*dFactorial(j1+j2-j-t)*dFactorial(j1-m1-t)*dFactorial(j2+m2-t)*dFactorial(j-j2+m1+t)*dFactorial(j-j1-m2+t)
     sum = sum + mone(t)*v1/v2
  END DO
  ClebschG = sum*Delta__(j1,j2,j)
  return
END function

!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************

real(8) function f6j(j1, j2, j3, m1, m2, m3)
  IMPLICIT NONE
  real(8), intent(in) :: j1, j2, j3, m1, m2, m3
  INTEGER             :: tmin, tmax, t
  real(8)             :: sum, v1, v2
  tmin = INT(max(max(max(j1+j2+j3,j1+m2+m3),m1+j2+m3),m1+m2+j3)+1d-14)
  tmax = INT(min(min(j1+j2+m1+m2,j1+j3+m1+m3),j2+j3+m2+m3)+1d-14)
  sum=0
  DO t=tmin, tmax
     v1 = dFactorial(t-j1-j2-j3)*dFactorial(t-j1-m2-m3)*dFactorial(t-m1-j2-m3)*dFactorial(t-m1-m2-j3)
     v2 = dFactorial(j1+j2+m1+m2-t)*dFactorial(j1+j3+m1+m3-t)*dFactorial(j2+j3+m2+m3-t)
     sum = sum + mone(t)*iFactorial(t+1)/(v1*v2)
  END DO
  f6j = Delta__(j1,j2,j3)*Delta__(j1,m2,m3)*Delta__(m1,m2,j3)*sum;
  return 
END function

!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************

real(8) function f3j(j1, m1, j2, m2, j3, m3)
  IMPLICIT NONE
  real(8), intent(in) :: j1, j2, j3, m1, m2, m3
  INTEGER             :: tmin, tmax, t
  real(8)             :: sum, v1, v2, dn
  f3j=0
  IF (abs(m1+m2+m3) .GT. 1e-10) return
  IF (abs(j1-j2)-1e-14 .GT. j3 .OR. j3 .GT. j1+j2+1e-14) return
  if (abs(m1) .GT. j1 .OR. abs(m2) .GT. j2 .OR. abs(m3) .GT. j3) return
  tmin = INT(max(max(0.d0,j2-j3-m1),j1-j3+m2)+1d-14)
  tmax = INT(min(min(j1+j2-j3,j1-m1),j2+m2)+1d-14)
  sum=0
  DO t=tmin, tmax
     v1 = dFactorial(j3-j2+m1+t)*dFactorial(j3-j1-m2+t)
     v2 = dFactorial(j1+j2-j3-t)*dFactorial(j1-m1-t)*dFactorial(j2+m2-t)
     sum = sum + mone(t)/(iFactorial(t)*v1*v2)
  END DO
  dn = dFactorial(j1+m1)*dFactorial(j1-m1)*dFactorial(j2+m2)*dFactorial(j2-m2)*dFactorial(j3+m3)*dFactorial(j3-m3)
  f3j = mone(INT(j1-j2-m3))*Delta__(j1,j2,j3)*sqrt(dn)*sum
  return
END function

!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************

SUBROUTINE SlaterF(Fn, U, J)
  IMPLICIT NONE
  real(8), intent(in)  :: U, J
  real(8), intent(out) :: Fn(0:3,0:3)

  Fn=0
  ! F0 for s-electrons
  Fn(0,0) = U
  ! F2 for p-electrons
  Fn(0,1) = U
  Fn(1,1) = 5*J
  ! F2 and F4 for d-electrons
  Fn(0,2) = U
  Fn(1,2) = 14./(1.+0.625)*J
  Fn(2,2) = 0.625*Fn(1,2)
  ! F2, F4 and F6 for f-electrons
  Fn(0,3) = U
  Fn(1,3) = 6435./(286.+195.*0.668+250.*0.494)*J
  Fn(2,3) = 0.668*Fn(1,3)
  Fn(3,3) = 0.494*Fn(1,3)
END SUBROUTINE

!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************

SUBROUTINE cmp_all_Gaunt(gck)
  IMPLICIT NONE
  real(8), intent(out) :: gck(0:3,-3:3,-3:3,0:3)
  real(8), parameter   :: pi = 3.14159266
  INTEGER              :: m1, m2, k, l
  real(8)              :: c
  DO l=0,3
     DO m1=-l,l
        DO m2=-l,l
           DO k=0,2*l,2
              c = Gaunt(l,m1,k,m1-m2,l,m2)*sqrt(4.d0*pi/(2.d0*dble(k)+1.d0))
              if (abs(c)<1.d-10) c=0.d0
              gck(l,m1,m2,k/2) = c
           ENDDO
        ENDDO
     ENDDO
  ENDDO
END SUBROUTINE

!***************************************************
!***************************************************
!***************************************************
!***************************************************

real(8) function Gaunt(l1, m1, l2, m2, l3, m3)
  IMPLICIT NONE
  INTEGER, intent(in) :: l1, m1, l2, m2, l3, m3
  real(8) :: l1_, l2_, l3_, mm1_, m2_, m3_, zero
  l1_ = l1;   l2_ = l2;   l3_ = l3
  mm1_ = -m1; m2_ = m2; m3_ = m3
  zero = 0
  ! Calculates <Y_{l1m1}|Y_{l2m2}|Y_{l3m3}>
  if (l1.LT.0 .OR. l2.LT.0 .OR. l3.LT.0) print *, "Quantum number l must be non-negative!"
  Gaunt = mone(m1)*sqrt(dble(2*l1+1)*dble(2*l2+1)* &
        & dble(2*l3+1)/(4.d0*pi))*f3j(l1_,zero,l2_,zero,l3_,zero)*f3j(l1_,mm1_,l2_,m2_,l3_,m3_)
  return
END function

!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************

 !**************************************************************
 !*   Function sinintegral(x) to integrate the real function   *
 !*   FUNC(t) = sin(t)/t from t=0 to t=x by Simpson's method   *
 !* ---------------------------------------------------------- *
 !*   REFERENCE:  (for Simpson's method)                       * 
 !*              "Mathematiques en Turbo-Pascal (Part 1) by    *
 !*               Marc Ducamp and Alain Reverchon, Eyrolles,   *
 !*               Paris, 1987" [BIBLI 03].                     *
 !* ---------------------------------------------------------- *
 !*                                                            *
 !*                                F90 Version By J-P Moreau.  *
 !**************************************************************

real(8) Function FUNC_sincosInt(kind,t)
implicit none
real(8)  :: t
integer  :: kind
  if(kind==1) then
    if(dabs(t)<1.d-10) then
      FUNC_sincosInt = 1.d0
    else
      FUNC_sincosInt = dsin(t)/t
    endif
  else
    if(dabs(t)<1.d-10) then
      FUNC_sincosInt = 0.d0
    else
      FUNC_sincosInt = (dcos(t)-1.d0)/t
    endif
  endif
  return
End Function 

!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************

 !*******************************************************
 !* Integral of a function FUNC(X) by Simpson's method  *
 !* --------------------------------------------------- *
 !* INPUTS:                                             *
 !*          kind   =1 for sinintegral                  *
 !*                 =2 for cosintegral                  * 
 !*          a      begin value of x variable           *
 !*          b      end value of x variable             *
 !*          n      number of integration steps         *
 !*                                                     *
 !* OUTPUT:                                             *
 !*          res    the integral of FUNC(X) from a to b *
 !*                                                     *
 !*******************************************************

Subroutine Integral_Simpson(kind, a, b, n, res)
implicit none
  real(8) :: a,b,res, step,r
  integer :: kind,n,i,j

  step=(b-a)/2/n
  r=FUNC_sincosInt(kind,a)
  res=(r+FUNC_sincosInt(kind,b))/2.d0
  do i=1, 2*n-1
    r=FUNC_sincosInt(kind,a+i*step)
    if (Mod(i,2).ne.0) then  
          res = res + r + r
    else 
          res = res + r
    end if
  end do
  res = res * step*2/3
  return
End Subroutine

!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
          
real(8) Function sinintegral(x)
implicit none
  real(8)  :: x0, x 
  integer  :: nstep  
  real(8)  :: res     

  x0=0.d0
  nstep=800    !this should ensure about 14 exact digits
  call Integral_Simpson(1,x0,x,nstep,res)   !kind=1
  sinintegral = res

return
End Function

!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************

complex(8) Function cosintegral(x)
implicit none
  real(8) :: x0,x
  integer :: nstep 
  real(8) :: res 

  x0=0.d0
  nstep = 800   !this should ensure about 14 exact digits
  call Integral_Simpson(2,x0,abs(x),nstep,res)   !kind=2
  cosintegral = gamma_euler + dlog(abs(x)) + res
  if(x<0.) cosintegral=cosintegral+imi*pi

return
End Function 

!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************

FUNCTION dcosint(xvalue) RESULT(fn_val)

!   This program calculates the value of the cosine-integral
!   defined as
!   DCOSINT(x) = Gamma + Ln(x) + Integral (0 to x) [cos(t)-1]/t  dt
!                where Gamma is Euler's constant.
!   The code uses rational approximations with a maximum accuracy of 20sf.
!   INPUT PARAMETER:
!     XVALUE - DOUBLE PRECISION - The argument to the function
!   MACHINE-DEPENDENT PARAMETERS:
!     XLOW - DOUBLE PRECISION - The absolute value below which
!                                   DCOSINT( x ) = gamma + LN(x) ,
!                               to machine precision.
!                               The recommended value is SQRT(2*EPSNEG)
!     XHIGH1 - DOUBLE PRECISION - The value above which
!                                    DCOSINT(x) = sin(x)/x - cos(x)/x^2
!                                 to machine precision.
!                                 The recommended value is SQRT(6/EPSNEG)
!     XHIGH2 - DOUBLE PRECISION - The value above which the trig. functions
!                                 cannot be accurately determined.
!                                 The value of the function is
!                                        DCOSINT(x) = 0.0
!                                 The recommended value is pi/EPS.
!      Values of EPS and EPSNEG for certain machine/compiler
!      combinations can be found in the paper
!      W.J. CODY  Algorithm 665: MACHAR: A subroutine to dynamically
!      determine machine parameters, ACM Trans. Math. Soft. 14 (1988) 303-311.
!      The current code gives numerical values for XLOW,XHIGH1,XHIGH2
!      suitable for machines whose arithmetic conforms to the IEEE
!      standard. The codes will probably work on other machines
!      but might overflow or underflow for certain arguments.

IMPLICIT NONE

REAL (dp), INTENT(IN) :: xvalue
REAL (dp)             :: fn_val
INTEGER               :: i
REAL (dp)             :: cx, dif, fival, gival, logval, root, sum, sumden, sumnum,sx,x,xsq
REAL (dp), PARAMETER  :: zero = 0.0_dp, one = 1.0_dp, three = 3.0_dp, six = 6.0_dp, twelve = 12.0_dp
REAL (dp), PARAMETER  :: logl1 = 0.046875_dp, logl2 = 0.25_dp
REAL (dp), PARAMETER  :: xlow = 1.48996E-8_dp, xhigh1 = 2.324953E8_dp, xhigh2 = 1.4148475E16_dp


!  VALUES FOR COS-INTEGRAL FOR 0 < X <= 3

REAL (dp), PARAMETER :: ac1n(0:5) = (/ -0.24607411378767540707_dp,   &
                 0.72113492241301534559E-2_dp, -0.11867127836204767056E-3_dp,  &
                 0.90542655466969866243E-6_dp, -0.34322242412444409037E-8_dp,  &
                 0.51950683460656886834E-11_dp /)
REAL (dp), PARAMETER :: ac1d(0:5) = (/ 1.0_dp, 0.12670095552700637845E-1_dp, &
                 0.78168450570724148921E-4_dp, 0.29959200177005821677E-6_dp, &
                 0.73191677761328838216E-9_dp, 0.94351174530907529061E-12_dp /)

!  VALUES FOR COS-INTEGRAL FOR 3 < X <= 6

REAL (dp), PARAMETER :: ac2n(0:7) = (/ -0.15684781827145408780_dp,     &
                 0.66253165609605468916E-2_dp,  -0.12822297297864512864E-3_dp,  &
                 0.12360964097729408891E-5_dp,  -0.66450975112876224532E-8_dp,  &
                 0.20326936466803159446E-10_dp, -0.33590883135343844613E-13_dp, &
                 0.23686934961435015119E-16_dp /)
REAL (dp), PARAMETER :: ac2d(0:6) = (/ 1.0_dp, 0.96166044388828741188E-2_dp,  &
                 0.45257514591257035006E-4_dp, 0.13544922659627723233E-6_dp,  &
                 0.27715365686570002081E-9_dp, 0.37718676301688932926E-12_dp, &
                 0.27706844497155995398E-15_dp /)

!  VALUES FOR FI(X) FOR 6 <= X <= 12

REAL (dp), PARAMETER :: afn1(0:7) = (/ 0.99999999962173909991E0_dp,  &
                  0.36451060338631902917E3_dp, 0.44218548041288440874E5_dp,  &
                  0.22467569405961151887E7_dp, 0.49315316723035561922E8_dp,  &
                  0.43186795279670283193E9_dp, 0.11847992519956804350E10_dp, &
                  0.45573267593795103181E9_dp /)

REAL (dp), PARAMETER :: afd1(0:7) = (/ 1.0_dp, 0.36651060273229347594E3_dp,  &
                  0.44927569814970692777E5_dp, 0.23285354882204041700E7_dp,  &
                  0.53117852017228262911E8_dp, 0.50335310667241870372E9_dp,  &
                  0.16575285015623175410E10_dp, 0.11746532837038341076E10_dp /)

!   VALUES OF GI(X) FOR 6 <= X <=12

REAL (dp), PARAMETER :: agn1(0:8) = (/ 0.99999999920484901956E0_dp,  &
                  0.51385504875307321394E3_dp,  0.92293483452013810811E5_dp,  &
                  0.74071341863359841727E7_dp,  0.28142356162841356551E9_dp,  &
                  0.49280890357734623984E10_dp, 0.35524762685554302472E11_dp, &
                  0.79194271662085049376E11_dp, 0.17942522624413898907E11_dp /)
REAL (dp), PARAMETER :: agd1(0:8) = (/ 1.0_dp,  0.51985504708814870209E3_dp,  &
                  0.95292615508125947321E5_dp,  0.79215459679762667578E7_dp,  &
                  0.31977567790733781460E9_dp,  0.62273134702439012114E10_dp, &
                  0.54570971054996441467E11_dp, 0.18241750166645704670E12_dp, &
                  0.15407148148861454434E12_dp /)

!   VALUES FOR FI(X) FOR X > 12

REAL (dp), PARAMETER :: afn2(0:7) = (/ 0.19999999999999978257E1_dp,   &
                  0.22206119380434958727E4_dp, 0.84749007623988236808E6_dp,   &
                  0.13959267954823943232E9_dp, 0.10197205463267975592E11_dp,  &
                  0.30229865264524075951E12_dp, 0.27504053804288471142E13_dp, &
                  0.21818989704686874983E13_dp /)
REAL (dp), PARAMETER :: afd2(0:7) = (/ 1.0_dp,  0.11223059690217167788E4_dp,  &
                  0.43685270974851313242E6_dp,  0.74654702140658116258E8_dp,  &
                  0.58580034751805687471E10_dp, 0.20157980379272098841E12_dp, &
                  0.26229141857684496445E13_dp, 0.87852907334918467516E13_dp /)

!   VALUES FOR GI(X) FOR X > 12

REAL (dp), PARAMETER :: agn2(0:8) = (/  0.59999999999999993089E1_dp,  &
                  0.96527746044997139158E4_dp,  0.56077626996568834185E7_dp,  &
                  0.15022667718927317198E10_dp, 0.19644271064733088465E12_dp, &
                  0.12191368281163225043E14_dp, 0.31924389898645609533E15_dp, &
                  0.25876053010027485934E16_dp, 0.12754978896268878403E16_dp /)
REAL (dp), PARAMETER :: agd2(0:8) = (/ 1.0_dp,  0.16287957674166143196E4_dp,   &
                  0.96636303195787870963E6_dp,  0.26839734750950667021E9_dp,   &
                  0.37388510548029219241E11_dp, 0.26028585666152144496E13_dp,  &
                  0.85134283716950697226E14_dp, 0.11304079361627952930E16_dp,  &
                  0.42519841479489798424E16_dp /)

!   VALUES FOR AN APPROXIMATION TO LN(X/ROOT)

REAL (dp), PARAMETER :: p(0:2) = (/   0.83930008362695945726E1_dp, -0.65306663899493304675E1_dp, 0.569155722227490223_dp /)
REAL (dp), PARAMETER :: q(0:1) = (/ 0.41965004181347972847E1_dp,  -0.46641666676862479585E1_dp /)

!   VALUES OF THE FIRST TWO ROOTS OF THE COSINE-INTEGRAL

REAL (dp), PARAMETER :: rt1n = 631.0_dp, rt1d = 1024.0_dp, rt1r = 0.29454812071623379711E-3_dp
REAL (dp), PARAMETER :: rt2n = 3465.0_dp, rt2d = 1024.0_dp, rt2r = 0.39136005118642639785E-3_dp

!   START COMPUTATION

x = xvalue
IF ( x <= zero ) THEN
  fn_val = zero
  RETURN
END IF
IF ( x <= six ) THEN
  
!   CODE FOR 3 < X < =  6
  
  IF ( x > three ) THEN
    sumnum = zero
    sumden = zero
    xsq = x * x
    DO i = 7 , 0 , -1
      sumnum = sumnum * xsq + ac2n( i )
    END DO
    DO i = 6 , 0 , -1
      sumden = sumden * xsq + ac2d( i )
    END DO
    root = rt2n / rt2d
    dif = ( x - root ) - rt2r
    sum = root + rt2r
    IF ( ABS(dif) < logl2 ) THEN
      cx = dif / ( sum + x )
      xsq = cx * cx
      sx = p(0) + xsq * ( p(1) + xsq * p(2) )
      sx = sx / ( q(0) + xsq * ( q(1) + xsq ) )
      logval = cx * sx
    ELSE
      logval = LOG( x / sum )
    END IF
    fn_val = logval + dif * ( x + sum ) * sumnum / sumden
  ELSE
!   CODE FOR 0 < X < =  3
    
    IF ( x > xlow ) THEN
      sumnum = zero
      sumden = zero
      xsq = x * x
      DO i = 5 , 0 , -1
        sumnum = sumnum * xsq + ac1n( i )
        sumden = sumden * xsq + ac1d( i )
      END DO
      root = rt1n / rt1d
      dif = ( x - root ) - rt1r
      sum = root + rt1r
      IF ( ABS(dif) < logl1 ) THEN
        cx = dif / ( sum + x )
        xsq = cx * cx
        sx = p(0) + xsq * ( p(1) + xsq * p(2) )
        sx = sx / ( q(0) + xsq * ( q(1) + xsq ) )
        logval = cx * sx
      ELSE
        logval = LOG( x / sum )
      END IF
      fn_val = logval + dif * ( x + sum ) * sumnum / sumden
    ELSE
      fn_val = gamma_euler + LOG( x )
    END IF
  END IF
END IF

!   CODE FOR 6 < X < =  12

IF ( x > six .AND. x <= twelve ) THEN
  sumnum = zero
  sumden = zero
  xsq = one / ( x * x )
  DO i = 7 , 0 , -1
    sumnum = sumnum * xsq + afn1( i )
    sumden = sumden * xsq + afd1( i )
  END DO
  fival = sumnum / ( x * sumden )
  sumnum = zero
  sumden = zero
  DO i = 8 , 0 , -1
    sumnum = sumnum * xsq + agn1( i )
    sumden = sumden * xsq + agd1( i )
  END DO
  gival = xsq * sumnum / sumden
  fn_val = fival * SIN( x ) - gival * COS( x )
END IF

!   CODE FOR X > 12

IF ( x > twelve ) THEN
  IF ( x > xhigh2 ) THEN
    fn_val = zero
  ELSE
    cx = COS( x )
    sx = SIN( x )
    xsq = one / ( x * x )
    IF ( x > xhigh1 ) THEN
      fn_val = sx / x - cx * xsq
    ELSE
      sumnum = zero
      sumden = zero
      DO i = 7 , 0 , -1
        sumnum = sumnum * xsq + afn2( i )
        sumden = sumden * xsq + afd2( i )
      END DO
      fival = ( one - xsq * sumnum / sumden ) / x
      sumnum = zero
      sumden = zero
      DO i = 8 , 0 , -1
        sumnum = sumnum * xsq + agn2( i )
        sumden = sumden * xsq + agd2( i )
      END DO
      gival = ( one - xsq * sumnum / sumden ) * xsq
      fn_val = sx * fival - cx * gival
    END IF
  END IF
END IF

RETURN
END FUNCTION 

!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************

complex(8) function expint(x)
implicit none
real(8) :: x
 expint = gamma_euler + log(abs(x)) + x + x**2.d0/4.d0 + x**3.d0/18.d0 + x**4.d0/96.d0 + x**5.d0/600.d0
end function

!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************

complex(8) function ccosint(z)
implicit none
complex(8) :: z
 if(abs(real(z))>1.d-3) stop 'error ccosint only for pure imaginary number'
 ccosint = gamma_euler + Sign(1.d0,aimag(z))*imi*pi/2.d0 + log(abs(z)) - &
         &  z**2.d0/4.d0 + z**4.d0/96.d0 - z**6.d0/4320.d0 + z**8.d0/322560.d0 - z**10.d0/36288000.d0
end function

!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************

FUNCTION dsinint(xvalue) RESULT(fn_val)

!   DEFINITION:
!   This program calculates the value of the sine-integral defined as
!       DSININT(x) = Integral (0 to x) sin(t)/t  dt
!   The program uses rational approximations with the coefficients
!   given to 20sf. accuracy.
!   INPUT PARAMETER:
!     XVALUE - DOUBLE PRECISION - The argument to the function
!   MACHINE-DEPENDENT PARAMETERS:
!     XLOW - DOUBLE PRECISION - The absolute value below which
!                                    DSININT( x ) = x,
!                               to machine precision.
!                               The recommended value is
!                                    SQRT(18*EPSNEG)
!     XHIGH1 - DOUBLE PRECISION - The value above which
!                                DSININT(x) = pi/2 - cos(x)/x -sin(x)/x*x
!                                 to machine precision.
!                                 The recommended value is
!                                   SQRT(6/EPSNEG)
!     XHIGH2 - DOUBLE PRECISION - The value above which
!                                     DSININT(x) = pi/2
!                                 to machine precision.
!                                 The recommended value is
!                                     2 / min(EPS,EPSNEG)
!     XHIGH3 - DOUBLE PRECISION - The value above which it is not sensible
!                                 to compute COS or SIN. The recommended
!                                 value is     pi/EPS
!      Values of EPS and EPSNEG for certain machine/compiler
!      combinations can be found in the paper
!      W.J. CODY  Algorithm 665: MACHAR: A subroutine to dynamically
!      determine machine parameters, ACM Trans. Math. Soft. 14 (1988) 303-311.
!      The current code gives numerical values for XLOW,XHIGH1,XHIGH2,XHIGH3,
!      suitable for machines whose arithmetic conforms to the IEEE
!      standard. The codes will probably work on other machines
!      but might overflow or underflow for certain arguments.

IMPLICIT NONE

REAL (dp), INTENT(IN) :: xvalue
REAL (dp)             :: fn_val
INTEGER               :: i, indsgn
REAL (dp)             :: cx, fival, gival, sumden, sumnum, sx, x, xhigh, xsq
REAL (dp), PARAMETER  :: zero = 0.0_dp, one = 1.0_dp, six = 6.0_dp, twelve = 12.0_dp
REAL (dp), PARAMETER  :: piby2 = 1.5707963267948966192_dp
REAL (dp), PARAMETER  :: xlow = 4.47E-8_dp, xhigh1 = 2.32472E8_dp
REAL (dp), PARAMETER  :: xhigh2 = 9.0072E15_dp, xhigh3 = 1.4148475E16_dp

!  VALUES FOR SINE-INTEGRAL FOR 0 <= |X| <= 6

REAL (dp), PARAMETER :: asintn(0:7) = (/ 1.0_dp,  &
          -0.44663998931312457298E-1_dp, 0.11209146443112369449E-2_dp,  &
          -0.13276124407928422367E-4_dp, 0.85118014179823463879E-7_dp,  &
          -0.29989314303147656479E-9_dp, 0.55401971660186204711E-12_dp, &
          -0.42406353433133212926E-15_dp /)
REAL (dp), PARAMETER :: asintd(0:7) = (/ 1.0_dp,  &
           0.10891556624243098264E-1_dp, 0.59334456769186835896E-4_dp,  &
           0.21231112954641805908E-6_dp, 0.54747121846510390750E-9_dp,  &
           0.10378561511331814674E-11_dp, 0.13754880327250272679E-14_dp,&
           0.10223981202236205703E-17_dp /)

!  VALUES FOR FI(X) FOR 6 <= X <= 12

REAL (dp), PARAMETER :: afn1(0:7) = (/ 0.99999999962173909991_dp,   &
           0.36451060338631902917E3_dp, 0.44218548041288440874E5_dp, &
           0.22467569405961151887E7_dp, 0.49315316723035561922E8_dp, &
           0.43186795279670283193E9_dp, 0.11847992519956804350E10_dp,&
           0.45573267593795103181E9_dp /)

REAL (dp), PARAMETER :: afd1(0:7) = (/ 1.0_dp, 0.36651060273229347594E3_dp,  &
           0.44927569814970692777E5_dp, 0.23285354882204041700E7_dp,  &
           0.53117852017228262911E8_dp, 0.50335310667241870372E9_dp,  &
           0.16575285015623175410E10_dp, 0.11746532837038341076E10_dp /)

!   VALUES OF GI(X) FOR 6 <= X <=12

REAL (dp), PARAMETER :: agn1(0:8) = (/ 0.99999999920484901956_dp,     &
           0.51385504875307321394E3_dp, 0.92293483452013810811E5_dp,   &
           0.74071341863359841727E7_dp, 0.28142356162841356551E9_dp,   &
           0.49280890357734623984E10_dp, 0.35524762685554302472E11_dp, &
           0.79194271662085049376E11_dp, 0.17942522624413898907E11_dp /)
REAL (dp), PARAMETER :: agd1(0:8) = (/ 1.0_dp, 0.51985504708814870209E3_dp,  &
           0.95292615508125947321E5_dp, 0.79215459679762667578E7_dp,  &
           0.31977567790733781460E9_dp, 0.62273134702439012114E10_dp,  &
           0.54570971054996441467E11_dp, 0.18241750166645704670E12_dp,  &
           0.15407148148861454434E12_dp /)

!   VALUES FOR FI(X) FOR X > 12

REAL (dp), PARAMETER :: afn2(0:7) = (/ 0.19999999999999978257E1_dp,   &
           0.22206119380434958727E4_dp, 0.84749007623988236808E6_dp,   &
           0.13959267954823943232E9_dp, 0.10197205463267975592E11_dp,  &
           0.30229865264524075951E12_dp, 0.27504053804288471142E13_dp, &
           0.21818989704686874983E13_dp /)
REAL (dp), PARAMETER :: afd2(0:7) = (/ 1.0_dp, 0.11223059690217167788E4_dp,  &
           0.43685270974851313242E6_dp, 0.74654702140658116258E8_dp,  &
           0.58580034751805687471E10_dp, 0.20157980379272098841E12_dp,  &
           0.26229141857684496445E13_dp, 0.87852907334918467516E13_dp /)

!   VALUES FOR GI(X) FOR X > 12

REAL (dp), PARAMETER :: agn2(0:8) = (/ 0.59999999999999993089E1_dp,   &
           0.96527746044997139158E4_dp, 0.56077626996568834185E7_dp,   &
           0.15022667718927317198E10_dp, 0.19644271064733088465E12_dp, &
           0.12191368281163225043E14_dp, 0.31924389898645609533E15_dp, &
           0.25876053010027485934E16_dp, 0.12754978896268878403E16_dp /)
REAL (dp), PARAMETER :: agd2(0:8) = (/ 1.0_dp, 0.16287957674166143196E4_dp,  &
           0.96636303195787870963E6_dp, 0.26839734750950667021E9_dp,  &
           0.37388510548029219241E11_dp, 0.26028585666152144496E13_dp,  &
           0.85134283716950697226E14_dp, 0.11304079361627952930E16_dp,  &
           0.42519841479489798424E16_dp /)

!   START COMPUTATION

x = xvalue
indsgn = 1
IF ( x < zero ) THEN
  x = -x
  indsgn = -1
END IF

!   CODE FOR 0 <= |X| <= 6

IF ( x <= six ) THEN
  IF ( x < xlow ) THEN
    fn_val = x
  ELSE
    sumnum = zero
    sumden = zero
    xsq = x * x
    DO i = 7 , 0 , -1
      sumnum = sumnum * xsq + asintn(i)
      sumden = sumden * xsq + asintd(i)
    END DO
    fn_val = x * sumnum / sumden
  END IF
END IF

!   CODE FOR 6 < |X| <= 12

IF ( x > six .AND. x <= twelve ) THEN
  sumnum = zero
  sumden = zero
  xsq = one / ( x * x )
  DO i = 7 , 0 , -1
    sumnum = sumnum * xsq + afn1(i)
    sumden = sumden * xsq + afd1(i)
  END DO
  fival = sumnum / ( x * sumden )
  sumnum = zero
  sumden = zero
  DO i = 8 , 0 , -1
    sumnum = sumnum * xsq + agn1(i)
    sumden = sumden * xsq + agd1(i)
  END DO
  gival = xsq * sumnum / sumden
  fn_val = piby2 - fival * COS(x) - gival * SIN(x)
END IF

!   CODE FOR |X| > 12

IF ( x > twelve ) THEN
  xhigh = MIN(xhigh2, xhigh3)
  IF ( x > xhigh ) THEN
    fn_val = piby2
  ELSE
    cx = COS(x)
    sx = SIN(x)
    xsq = one / ( x * x )
    IF ( x > xhigh1 ) THEN
      fn_val = piby2 - cx / x - sx * xsq
    ELSE
      sumnum = zero
      sumden = zero
      DO i = 7 , 0 , -1
        sumnum = sumnum * xsq + afn2(i)
        sumden = sumden * xsq + afd2(i)
      END DO
      fival =  ( one - xsq * sumnum / sumden ) / x
      sumnum = zero
      sumden = zero
      DO i = 8 , 0 , -1
        sumnum = sumnum * xsq + agn2(i)
        sumden = sumden * xsq + agd2(i)
      END DO
      gival =  ( one - xsq * sumnum / sumden ) * xsq
      fn_val = piby2 - cx * fival - sx * gival
    END IF
  END IF
END IF
IF ( indsgn == -1 ) fn_val = -fn_val

RETURN
END FUNCTION

!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************
!***************************************************

end module
