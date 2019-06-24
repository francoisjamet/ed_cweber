MODULE bath_class_hybrid

  !$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
  !$$ MAKE HYBRIDIZATION FROM BATH $$
  !$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

  USE bath_class_vec
  USE minimization_wrapping
  use stringmanip
  use correl_class, only : swap

  IMPLICIT NONE

  REAL(DBL),PARAMETER,      PRIVATE          :: zero=0.0_DBL,one=1.0_DBL,two=2.0_DBL
  LOGICAL,  PARAMETER,      PRIVATE          :: F=.FALSE.,T=.TRUE.
  TYPE(correl_type),        PRIVATE,SAVE     :: hybrid2fit
  TYPE(bath_type),          PRIVATE,SAVE     :: batht
  integer,                  PRIVATE          :: icount_=0

INTERFACE MATMUL_x
  MODULE PROCEDURE MATMUL_x_c,MATMUL_x_r
END INTERFACE

INTERFACE bande_mat
 MODULE PROCEDURE bande_matr,bande_matc
END INTERFACE

CONTAINS


function matrixinverse(j,q)
implicit none
complex(8)                           :: q
complex(8),dimension(3,3),intent(in) :: j
complex(8),dimension(3,3)            :: matrixinverse

    q=-j(3,1)*j(2,2)*j(1,3)+j(2,1)*j(3,2)*j(1,3)+j(3,1)*j(1,2)*j(2,3) &
    & -j(1,1)*j(3,2)*j(2,3)-j(2,1)*j(1,2)*j(3,3)+j(1,1)*j(2,2)*j(3,3)

    if(abs(q)<epsilonr) q=epsilonr

    matrixinverse(1,1)=(-j(3,2)*j(2,3)+j(2,2)*j(3,3))/q
    matrixinverse(2,1)=(j(3,1)*j(2,3)-j(2,1)*j(3,3))/q
    matrixinverse(3,1)=(-j(3,1)*j(2,2)+j(2,1)*j(3,2))/q
    matrixinverse(1,2)=(j(3,2)*j(1,3)-j(1,2)*j(3,3))/q
    matrixinverse(2,2)=(-j(3,1)*j(1,3)+j(1,1)*j(3,3))/q
    matrixinverse(3,2)=(j(3,1)*j(1,2)-j(1,1)*j(3,2))/q
    matrixinverse(1,3)=(-j(2,2)*j(1,3)+j(1,2)*j(2,3))/q
    matrixinverse(2,3)=(j(2,1)*j(1,3)-j(1,1)*j(2,3))/q
    matrixinverse(3,3)=(-j(2,1)*j(1,2)+j(1,1)*j(2,2))/q

return
end function


  logical function mat_3_3_c(mat,detb,detb2,pdetb)
  implicit none
    integer                   :: n,i,j
    integer,optional          :: pdetb
    real(8),optional          :: detb
    complex(8),intent(inout)  :: mat(:,:)
    complex(8),optional       :: detb2
    complex(8)                :: q

     n=size(mat,1)
     mat_3_3_c=n<4
     if(n>=4) return

      SELECT CASE(n)

       CASE(3)

        mat=matrixinverse(mat,q)
        if(present(detb2))then
         detb2=q; pdetb=0; detb=1.
        endif

       CASE(1)

        q=mat(1,1)
        if(abs(q)<epsilonr) q=epsilonr
        mat=1.d0/q
        if(present(detb2))then
         detb2=q; pdetb=0; detb=1.
        endif

       CASE(2)

        q=mat(1,1)*mat(2,2)-mat(1,2)*mat(2,1)
        if(abs(q)<epsilonr) q=epsilonr
        call swap(mat(1,1),mat(2,2))
        mat(1,2)=-mat(1,2)
        mat(2,1)=-mat(2,1)
        mat=mat/q
        if(present(detb2))then
         detb2=q; pdetb=0; detb=1.
        endif

       END SELECT

  end function

SUBROUTINE invmat_jordan_c(nn,a)
  IMPLICIT NONE
  COMPLEX(8), DIMENSION(:,:), INTENT(INOUT) :: a

  !--------------------------------------------------------------------------!
  ! Linear equation solution by Gauss-Jordan elimination                     !
  ! a is an N x N input coefficient matrix. On output, a is replaced by its  !
  ! matrix inverse.                                                          !
  !--------------------------------------------------------------------------!

  INTEGER, DIMENSION(SIZE(a,1))      :: ipiv,indxr,indxc

  !These arrays are used for bookkeeping on the pivoting.

  INTEGER                            :: nn
  LOGICAL, DIMENSION(SIZE(a,1))      :: lpiv
  COMPLEX(8)                         :: pivinv
  COMPLEX(8), DIMENSION(SIZE(a,1))   :: dumc
  INTEGER, TARGET                    :: irc(2)
  INTEGER                            :: i,l,n
  INTEGER, POINTER                   :: irow,icol

  n=SIZE(a,1)

  irow => irc(1)
  icol => irc(2)

  ipiv=0

  DO i=1,n
     !Main loop over columns to be reduced.
     lpiv = (ipiv == 0)
     !Begin search for a pivot element.
     irc=MAXLOC(ABS(a),outerand(lpiv,lpiv))
     ipiv(icol)=ipiv(icol)+1
     IF (ipiv(icol) > 1) STOP 'gaussj:singular matrix (1)'

     !We now have the pivot element, so we interchange
     !rows, if needed, to put the pivot element on the diagonal. The columns
     !are not physically interchanged, only relabeled:
     !indxc(i),the column of the ith pivot element, is the ith column that is
     !reduced, while indxr(i) is the row in which that pivot element was
     !originally located. If indxr(i) = indxc(i) there is an implied column
     !interchange. With this form of bookkeeping, the inverse matrix will be
     !scrambled by
     !columns.

     IF (irow /= icol) CALL swap(a(irow,:),a(icol,:))

     indxr(i)=irow !We are now ready to divide the pivot row by the pivot element,
                   !located at irow and icol.
     indxc(i)=icol

     IF (a(icol,icol) == zero) STOP 'gaussj:singular matrix (2)'
     pivinv=one/a(icol,icol)
     a(icol,icol)=CMPLX(one,zero)
     a(icol,:)=a(icol,:)*pivinv
     dumc=a(:,icol)

     !Next, we reduce the rows, except for the pivot one, of course.
     a(:,icol)     = CMPLX(zero,zero)
     a(icol,icol)  = pivinv
     a(1:icol-1,:) = a(1:icol-1,:) - outerprod_c(dumc(1:icol-1),a(icol,:))
     a(icol+1:,:)  = a(icol+1:,:)  - outerprod_c(dumc(icol+1:),a(icol,:))
  END DO

  !It only remains to unscramble the solution in view of the column
  !interchanges.
  !We do this by interchanging pairs of columns in the reverse order that the
  !permutation
  !was built up.

  DO l=n,1,-1
     CALL swap(a(:,indxr(l)),a(:,indxc(l)))
  END DO

CONTAINS

  FUNCTION outerprod_c(a,b)
    COMPLEX(8), DIMENSION(:), INTENT(in) :: a,b
    COMPLEX(8), DIMENSION(SIZE(a),SIZE(b)) :: outerprod_c
    outerprod_c=SPREAD(a,dim=2,ncopies=SIZE(b))*SPREAD(b,dim=1,ncopies=SIZE(a))
  END FUNCTION

 FUNCTION outerand(a,b)
   IMPLICIT NONE
   LOGICAL, DIMENSION(:), INTENT(IN)   :: a,b
   LOGICAL, DIMENSION(SIZE(a),SIZE(b)) :: outerand
   outerand = SPREAD(a,dim=2,ncopies=SIZE(b)).AND.SPREAD(b,dim=1,ncopies=SIZE(a))
 END FUNCTION

END SUBROUTINE




    subroutine invmat(n,mat,det2b,detb,pdetb,check_nan,c,block_matrix,diagmat)
      implicit none
      integer                   :: pdet,ppdet,n,nnn,i,j
      real(8)                   :: big,det,ddet,rcond
      complex(8),intent(inout)  :: mat(:,:)
      real(8),optional          :: detb
      integer,optional          :: pdetb
      complex(8),optional       :: det2b
      complex(8)                :: det2,ddet2,deti(2),q
      complex(8)                :: WORK(2*size(mat,1)),WORK2(size(mat,1))
      integer(4)                :: INFO,INFO2
      integer                   :: piv(size(mat,1))
      logical,optional          :: check_nan,block_matrix,diagmat
      integer,optional          :: c

     if(present(diagmat))then
      if(diagmat)then
       do i=1,size(mat,1)
        if(abs(mat(i,i))>1.d-20)then
         mat(i,i)=1.d0/mat(i,i)
        else
         mat(i,i)=1.d20
        endif
       enddo
       return
      endif
     endif

     if(size(mat,1)/=size(mat,2)) then
       write(*,*) 'DIMENSION OF MATRIX : ', shape(mat)
       stop 'error invmat_comp try to inverse rectangular matrix'
     endif

     if(present(det2b)) det2b=0.; if(present(detb))  detb=0.; if(present(pdetb)) pdetb=0

      if(present(block_matrix))then
       if(block_matrix)then
         nnn=n/2
         if(mod(n,2)>0) stop 'error invmat_comp block_matrix, but linear size is odd'
         if(present(detb))then
           call invit(1,nnn,det,det2,pdet)
           call invit(nnn+1,n,ddet,ddet2,ppdet)
           mat(1:nnn,nnn+1:n)=0.
           mat(nnn+1:n,1:nnn)=0.
           pdetb = pdet + ppdet
           detb  = det  * ddet
           det2b = det2 * ddet2
         else
           call invit(1,nnn)
           call invit(nnn+1,n)
           mat(1:nnn,nnn+1:n)=0.
           mat(nnn+1:n,1:nnn)=0.
         endif
         goto 35
       endif
      endif

      call invit(1,n,detb,det2b,pdetb)
35    continue

      return

      contains

    !------------------!
    !------------------!
    !------------------!

 subroutine gecoc__(nnn,mat,piv)
 implicit none
 integer      :: nnn
 real(8)      :: rcond
 integer      :: piv(nnn)
 complex(8)   :: mat(nnn,nnn),WORK2(size(mat,1))
     call zgeco(mat,nnn,nnn,piv,rcond,WORK2)
 end subroutine

 subroutine gedic__(nnn,mat,piv,deti)
 implicit none
 integer      :: nnn
 real(8)      :: rcond
 integer      :: piv(nnn)
 complex(8)   :: mat(nnn,nnn),WORK(2*size(mat,1)),deti(2)
     call zgedi(mat,nnn,nnn,piv,deti,WORK,11)
 end subroutine

   subroutine zgeco_zgedi(i1,i2)
   implicit none
   integer :: i1,i2,nnn
     nnn=i2-i1+1
     call gecoc__(nnn,mat(i1:i2,i1:i2),piv(i1:i2))
     call gedic__(nnn,mat(i1:i2,i1:i2),piv(i1:i2),deti)
   end subroutine

    !------------------!
    !------------------!
    !------------------!
    !------------------!

    subroutine invit(i1,i2,det,det2,pdet)
    implicit none
    integer                   :: i1,i2
    real(8),optional          :: det
    integer,optional          :: pdet
    complex(8),optional       :: det2
    integer                   :: nn
      nn = i2-i1+1
      if(mat_3_3_c(mat(i1:i2,i1:i2),det,det2,pdet)) return
      call invmat_jordan_c(n,mat(i1:i2,i1:i2))
    end subroutine

end subroutine

    !------------------!
    !------------------!
    !------------------!
    !------------------!
    !------------------!

 function bande_matr(n,bande)
 implicit none
 integer :: n,i
 real(8) :: bande(n),bande_matr(n,n)
  bande_matr=0
  do i=1,n
    bande_matr(i,i)=bande(i)
  enddo
 end function

   !-------!

 function bande_matc(n,bande)
 implicit none
 integer    :: n,i
 complex(8) :: bande(n),bande_matc(n,n)
  bande_matc=0
  do i=1,n
    bande_matc(i,i)=bande(i)
  enddo
 end function

   !-------!

function MATMUL_x_c(aa,bb,ind,n,IdL,IdR,byblock,a_by_block)
implicit none
integer                :: ii,i,j,k,l,s1,s2,smiddle
complex(8),intent(in)  :: aa(:,:),bb(:,:)
complex(8)             :: MATMUL_x_c(size(aa(:,1)),size(bb(1,:)))
integer,optional       :: n,ind(:)
logical,optional       :: IdL,IdR,byblock,a_by_block

if(present(byblock))then
 if(byblock)then
   ii=size(aa(:,1))
   i =size(aa(1,:))
   if(i/=ii) stop 'MATMUL_x by block should be only for square matrices'
   if(mod(ii,2)>0) stop 'MATMUL_x by block should only be for even linear sizes'
   ii=ii/2
   MATMUL_x_c(1    :   ii, ii+1 : 2*ii)= 0.0
   MATMUL_x_c(ii+1 : 2*ii,    1 :   ii)= 0.0
   MATMUL_x_c(   1 :   ii,    1 :   ii)= MATMUL(aa(    1:   ii,    1 :   ii),bb(    1 :  ii,    1 :  ii))
   MATMUL_x_c(ii+1 : 2*ii, ii+1 : 2*ii)= MATMUL(aa(ii +1: 2*ii, ii+1 : 2*ii),bb( ii+1 :2*ii, ii+1 :2*ii))
   return
 endif
endif

!ind: matrice aa n a que les lignes dans ind qui different de l identite

s1=size(aa(:,1)); s2=size(bb(1,:)); smiddle=size(aa(1,:))
if(smiddle/=size(bb(:,1))) stop 'error MATMUL_x_c'

if(present(IdL))then
 if(testing)then
  if(abs(aa(1,2))>1.d-3) stop 'MATMUL_x_c bad diagonal matrix IdL'
 endif
 do i=1,size(bb(:,1))
  MATMUL_x_c(i,:)=bb(i,:)*aa(i,i)
 enddo
 return
endif

if(present(IdR))then
 if(testing)then
  if(abs(aa(1,2))>1.d-3) stop 'MATMUL_x_c bad diagonal matrix IdR'
 endif
 do i=1,size(bb(1,:))
  MATMUL_x_c(:,i)=bb(:,i)*aa(i,i)
 enddo
 return
endif

 if(present(ind))then
  MATMUL_x_c=bb
  if(size(ind)/=n) stop 'error MATMUL_x_c bad ind shape'
  do ii=1,n
   i=ind(ii)
   do j=1,s2
    MATMUL_x_c(i,j)=0.
    do k=1,smiddle
     MATMUL_x_c(i,j)=MATMUL_x_c(i,j)+aa(i,k)*bb(k,j)
    enddo
   enddo
  enddo
 return
 endif

 if(present(a_by_block))then
 if(a_by_block)then
 do i=1,s1
  do j=1,s2
   MATMUL_x_c(i,j)=0.d0
   if(i<=s1/2)then
    do k=1,smiddle/2
      MATMUL_x_c(i,j)=MATMUL_x_c(i,j)+aa(i,k)*bb(k,j)
    enddo
   else
    do k=smiddle/2+1,smiddle
      MATMUL_x_c(i,j)=MATMUL_x_c(i,j)+aa(i,k)*bb(k,j)
    enddo
   endif
   enddo
  enddo
 return
 endif
 endif

 do i=1,s1
  do j=1,s2
    MATMUL_x_c(i,j)=0.d0
   do k=1,smiddle
     MATMUL_x_c(i,j)=MATMUL_x_c(i,j)+aa(i,k)*bb(k,j)
   enddo
  enddo
 enddo

return
end function

function MATMUL_x_r(aa,bb,ind,n,IdL,IdR,byblock,a_by_block)
implicit none
integer             :: ii,i,j,k,l,s1,s2,smiddle
real(8),intent(in)  :: aa(:,:),bb(:,:)
real(8)             :: MATMUL_x_r(size(aa(:,1)),size(bb(1,:)))
integer,optional    :: n,ind(:)
logical,optional    :: IdL,IdR,byblock,a_by_block

if(present(byblock))then
 if(byblock)then
   ii=size(aa(:,1))
   i =size(aa(1,:))
   if(i/=ii) stop 'MATMUL_x by block should be only for square matrices'
   if(mod(ii,2)>0) stop 'MATMUL_x by block should only be for even linear sizes'
   ii=ii/2
   MATMUL_x_r(1    :   ii, ii+1 : 2*ii)=0.
   MATMUL_x_r(ii+1 : 2*ii,    1 :   ii)=0.
   MATMUL_x_r(   1 :   ii,    1 :   ii)= MATMUL(aa(    1:   ii,    1 :   ii),bb( 1 :  ii,    1 :  ii))
   MATMUL_x_r(ii+1 : 2*ii, ii+1 : 2*ii)= MATMUL(aa(ii +1: 2*ii, ii+1 : 2*ii),bb( ii+1 :2*ii, ii+1 :2*ii))
   return
 endif
endif


!ind: matrice aa n a que les lignes dans ind qui different de l identite

s1=size(aa(:,1)); s2=size(bb(1,:)); smiddle=size(aa(1,:))
if(smiddle/=size(bb(:,1))) stop 'error MATMUL_x_r'

if(present(IdL))then
 if(testing)then
  if(abs(aa(1,2))>1.d-3) stop 'MATMUL_x_r bad diagonal matrix IdL'
 endif
 do i=1,size(bb(:,1))
  MATMUL_x_r(i,:)=bb(i,:)*aa(i,i)
 enddo
 return
endif

if(present(IdR))then
 if(testing)then
  if(abs(aa(1,2))>1.d-3) stop 'MATMUL_x_r bad diagonal matrix IdR'
 endif
 do i=1,size(bb(1,:))
  MATMUL_x_r(:,i)=bb(:,i)*aa(i,i)
 enddo
 return
endif

if(present(ind))then
 MATMUL_x_r=bb
 if(size(ind)/=n) stop 'error MATMUL_x_r bad ind shape'
 do ii=1,n
  i=ind(ii)
  do j=1,s2
   MATMUL_x_r(i,j)=0.
   do k=1,smiddle
    MATMUL_x_r(i,j)=MATMUL_x_r(i,j)+aa(i,k)*bb(k,j)
   enddo
  enddo
 enddo
return
endif

 if(present(a_by_block))then
 if(a_by_block)then
 do i=1,s1
  do j=1,s2
   MATMUL_x_r(i,j)=0.d0
   if(i<=s1/2)then
    do k=1,smiddle/2
      MATMUL_x_r(i,j)=MATMUL_x_r(i,j)+aa(i,k)*bb(k,j)
    enddo
   else
    do k=smiddle/2+1,smiddle
      MATMUL_x_r(i,j)=MATMUL_x_r(i,j)+aa(i,k)*bb(k,j)
    enddo
   endif
   enddo
  enddo
 return
 endif
 endif

do i=1,s1
 do j=1,s2
  MATMUL_x_r(i,j)=0.d0
  do k=1,smiddle
   MATMUL_x_r(i,j)=MATMUL_x_r(i,j)+aa(i,k)*bb(k,j)
  enddo
 enddo
enddo

return
end function


subroutine eigenvector_matrix_c(lsize,mat,vaps,eigenvec)
implicit none
integer     :: lsize,i
real(8)     :: RWORK(3*lsize)
complex(8)  :: WORK(3*lsize)
complex(8)  :: mat(lsize,lsize)
complex(8)  :: eigenvec(lsize,lsize)
complex(8)  :: rrr
integer     :: INFO,order(lsize)
real(8)     :: vaps(lsize)
   eigenvec=mat
   call ZHEEV('V','U',lsize,eigenvec,lsize,vaps,WORK,3*lsize,RWORK,INFO)
   if(INFO/=0)then
     write(*,*) 'BAD eigenvalue calculation , info = :', INFO
     write(*,*) 'stop calculations...'
     stop
   endif
end subroutine


!*********************************************
!*********************************************
!*********************************************
!*********************************************
!*********************************************
!*********************************************
!*********************************************

   function fill_mat_from_vector(n,vec)
   implicit none
   integer    :: n,i,j,k
   real(8)    :: vec(n*(n+1)/2),fill_mat_from_vector(n,n)
     k=0
     do i=1,n
      do j=i,n
        k=k+1
                 fill_mat_from_vector(i,j)=vec(k)
        if(i/=j) fill_mat_from_vector(j,i)=fill_mat_from_vector(i,j)
      enddo
     enddo
     if(k/=size(vec))then
        write(*,*) 'ERROR fill_mat_from_vector'
        stop
     endif
   end function

!*********************************************
!*********************************************
!*********************************************
!*********************************************
!*********************************************
!*********************************************

  SUBROUTINE bath2hybrid(BATH,FREQTYPE,WRITE_HYBRID,short,cptvec,cpt_build_matrix,Vweight)

    TYPE(bath_type)                ::  BATH
    CHARACTER(LEN=9),  INTENT(IN)  ::  FREQTYPE
    LOGICAL, OPTIONAL, INTENT(IN)  ::  WRITE_HYBRID,short
    TYPE(masked_matrix_type)       ::  EbNambu,VbcNambu
    COMPLEX(DBL)                   ::     Eb((BATH%Nb+ncpt_approx_tot)*2,(BATH%Nb+ncpt_approx_tot)*2)
    COMPLEX(DBL)                   ::   Ebm1((BATH%Nb+ncpt_approx_tot)*2,(BATH%Nb+ncpt_approx_tot)*2)
    COMPLEX(DBL)                   ::    Vbc((BATH%Nb+ncpt_approx_tot)*2,BATH%Nc*2),Vcb(BATH%Nc*2,(BATH%Nb+ncpt_approx_tot)*2)
    REAL(DBL)                      ::  ratio,eigenvalues(2*(BATH%Nb+ncpt_approx_tot))
    COMPLEX(DBL), POINTER          ::  hybrid(:,:,:) => NULL(),freq(:) => NULL()
    INTEGER                        ::  iw,Nw,i,j,k,Nb,Ntot,Nc,bl,mm,ll,mmstep
    LOGICAL                        ::  write_,block,diagmat
    REAL(8),TARGET,OPTIONAL        ::  cptvec(ncpt_para*ncpt_tot)
    REAL(8),POINTER                ::  cptup(:)=>NULL(), cptdn(:)=>NULL(), cptbcs(:)=>NULL()
    LOGICAL,OPTIONAL               ::  cpt_build_matrix
    REAL(8),OPTIONAL               ::  Vweight

    Nb=BATH%Nb; Ntot=Nb+ncpt_approx_tot;Nc=BATH%Nc

                              write_ = F
    IF(PRESENT(WRITE_HYBRID)) write_ = WRITE_HYBRID

    CALL Nambu_Eb (EbNambu, BATH%Eb, BATH%Pb)
    CALL Nambu_Vbc(VbcNambu,BATH%Vbc,BATH%PVbc)

    if(ncpt_approx_tot==0)then

      Eb  = -EbNambu%rc%mat
      Vbc =  VbcNambu%rc%mat
      Vcb =  TRANSPOSE(conjg(Vbc))

    else

      Vbc=0.d0; Vcb=0.d0; Eb=0.d0;

      Eb(     1:     Nb,     1     :Nb)   =   EbNambu%rc%mat(   1:  Nb,   1:  Nb)
      Eb(Ntot+1:Ntot+Nb,Ntot+1:Ntot+Nb)   =   EbNambu%rc%mat(Nb+1:2*Nb,Nb+1:2*Nb)
      Vbc(     1     :Nb,1:2*Nc)          =   VbcNambu%rc%mat(   1:  Nb,1:2*Nc)
      Vbc(Ntot+1:Ntot+Nb,1:2*Nc)          =   VbcNambu%rc%mat(Nb+1:2*Nb,1:2*Nc)
      Vcb                                 =   TRANSPOSE(conjg(Vbc))

      if(present(cptvec))then
            cptup =>cptvec(           1:  ncpt_tot)
         if(supersc_state.and..not.force_nupdn_basis.and..not.force_no_pairing)then
          if(ncpt_para==3)then
            cptdn =>cptvec(  ncpt_tot+1:2*ncpt_tot)
            cptbcs=>cptvec(2*ncpt_tot+1:3*ncpt_tot)
           else
            cptdn =>cptvec(           1:  ncpt_tot)
            cptbcs=>cptvec(  ncpt_tot+1:2*ncpt_tot)
           endif
         else
           if(ncpt_para==2)then
            cptdn=>cptvec(ncpt_tot+1:2*ncpt_tot)
           else
            cptdn=>cptvec(         1:  ncpt_tot)
           endif
         endif

         do i=1,ncpt_chain_coup*Nb
            if(abs(cptup(i))>cpt_upper_bound) cptup(i)=cptup(i)/abs(cptup(i))*cpt_upper_bound
            if(abs(cptdn(i))>cpt_upper_bound) cptdn(i)=cptdn(i)/abs(cptdn(i))*cpt_upper_bound
            if(supersc_state.and..not.force_nupdn_basis.and..not.force_no_pairing)then
             if(abs(cptbcs(i))>cpt_upper_bound) cptbcs(i)=cptbcs(i)/abs(cptbcs(i))*cpt_upper_bound
            endif
         enddo

         if(present(Vweight)) then
            Vweight=sum(abs(cptup( 1:ncpt_chain_coup*Nb ))**2)+sum(abs(cptdn( 1:ncpt_chain_coup*Nb   ))**2)
           if(supersc_state.and..not.force_nupdn_basis.and..not.force_no_pairing)then
            Vweight=Vweight + sum(abs(cptbcs( 1:ncpt_chain_coup*Nb ))**2)
           endif
         endif

         if(present(cpt_build_matrix))then
           if(.not.allocated(epsilon_cpt)) allocate(epsilon_cpt(2*(Ntot+Nc),2*(Ntot+Nc)))
           if(.not.allocated(T_cpt))       allocate(      T_cpt(2*(Ntot+Nc),2*(Ntot+Nc)))
           epsilon_cpt=0.d0

           do k=0,ncpt_chain_coup-1
            do i=1,Nb
             j=Nb+k+(i-1)*ncpt_approx+1
             epsilon_cpt(i,j)=cptup(i+k*Nb)
             epsilon_cpt(j,i)=conjg(epsilon_cpt(i,j))
            enddo
            do i=1,Nb
             j=Nb+k+(i-1)*ncpt_approx+1
             epsilon_cpt(Ntot+i,Ntot+j)=-cptdn(i+k*Nb)
             epsilon_cpt(Ntot+j,Ntot+i)=conjg(epsilon_cpt(Ntot+i,Ntot+j))
            enddo
           enddo
           if(supersc_state.and..not.force_nupdn_basis.and..not.force_no_pairing)then
            do k=0,ncpt_chain_coup-1
             do i=1,Nb
               j=Nb+k+(i-1)*ncpt_approx+1
               epsilon_cpt(i,Ntot+j)=cptbcs(i+k*Nb)
               epsilon_cpt(j,Ntot+i)=cptbcs(i+k*Nb)
               epsilon_cpt(Ntot+j,i)=cptbcs(i+k*Nb)
               epsilon_cpt(Ntot+i,j)=cptbcs(i+k*Nb)
             enddo
            enddo
           endif
           T_cpt=epsilon_cpt
           epsilon_cpt=0.d0
           epsilon_cpt(2*Nc+1:2*Nc+2*Ntot,2*Nc+1:2*Nc+2*Ntot)=T_cpt(1:2*Ntot,1:2*Ntot)
           T_cpt=0.d0
         endif
         do k=0,ncpt_chain_coup-1
          do i=1,Nb
           j=Nb+k+(i-1)*ncpt_approx+1
           Eb(i,j)=cptup(i+k*Nb)
           Eb(j,i)=conjg(Eb(i,j))
          enddo
          do i=1,Nb
           j=Nb+k+(i-1)*ncpt_approx+1
           Eb(Ntot+i,Ntot+j)=-cptdn(i+k*Nb)
           Eb(Ntot+j,Ntot+i)=conjg(Eb(Ntot+i,Ntot+j))
          enddo
         enddo
         if(supersc_state.and..not.force_nupdn_basis.and..not.force_no_pairing)then
           do k=0,ncpt_chain_coup-1
            do i=1,Nb
              j=Nb+k+(i-1)*ncpt_approx+1
              Eb(i,Ntot+j)=cptbcs(i+k*Nb)
              Eb(j,Ntot+i)=cptbcs(i+k*Nb)
              Eb(Ntot+j,i)=cptbcs(i+k*Nb)
              Eb(Ntot+i,j)=cptbcs(i+k*Nb)
            enddo
           enddo
         endif
         do i=1,Nb
           bl=ncpt_approx*(ncpt_approx+1)/2
           j=ncpt_chain_coup*Nb+(i-1)*ncpt_approx
           Eb(j+1:j+ncpt_approx,j+1:j+ncpt_approx)=fill_mat_from_vector(ncpt_approx,cptup(ncpt_chain_coup*Nb+(i-1)*bl+1:ncpt_chain_coup*Nb+i*bl))
         enddo
         do i=1,Nb
           bl=ncpt_approx*(ncpt_approx+1)/2
           j=ncpt_chain_coup*Nb+(i-1)*ncpt_approx
           Eb(Ntot+j+1:Ntot+j+ncpt_approx,Ntot+j+1:Ntot+j+ncpt_approx)=-transpose(fill_mat_from_vector(ncpt_approx,cptdn(ncpt_chain_coup*Nb+(i-1)*bl+1:ncpt_chain_coup*Nb+i*bl)))
         enddo
         if(supersc_state.and..not.force_nupdn_basis.and..not.force_no_pairing)then
            do i=1,Nb
              bl=ncpt_approx*(ncpt_approx+1)/2
              j=ncpt_chain_coup*Nb+(i-1)*ncpt_approx
              Eb(j+1:j+ncpt_approx,Ntot+j+1:Ntot+j+ncpt_approx)=fill_mat_from_vector(ncpt_approx,cptbcs(ncpt_chain_coup*Nb+(i-1)*bl+1:ncpt_chain_coup*Nb+i*bl))
              Eb(Ntot+j+1:Ntot+j+ncpt_approx,j+1:j+ncpt_approx)=Eb(j+1:j+ncpt_approx,Ntot+j+1:Ntot+j+ncpt_approx)
            enddo
         endif
         if(present(cpt_build_matrix))then
           T_cpt                                             = 0.d0
           T_cpt (    1:  Nc, 2*Nc     +1:2*Nc        + Nb ) = Vcb (    1 :   Nc,      1:     Nb )
           T_cpt ( Nc+1:2*Nc, 2*Nc+Ntot+1:2*Nc + Ntot + Nb ) = Vcb ( Nc+1 : 2*Nc, Ntot+1:Ntot+Nb )
           T_cpt                                             = T_cpt+transpose(conjg(T_cpt))
           T_cpt (    1:2*Nc,           1:2*Nc             ) = Eccc%rc%mat
           T_cpt (2*Nc+1:2*Nc+2*Ntot,2*Nc+1:2*Nc+2*Ntot)     = Eb
           if(maxval(abs( T_cpt - transpose(conjg( T_cpt )) ))>1.d-4)then
             write(*,*) 'error T_cpt non hermitian'
             stop
           endif
         endif

      endif

      Eb=-Eb

    endif

    !-------------------------------------!
    SELECT CASE (FREQTYPE)
      CASE(FERMIONIC)
         hybrid => BATH%hybrid%fctn
         freq   => BATH%hybrid%freq%vec
      CASE(RETARDED)
         hybrid => BATH%hybridret%fctn
         freq   => BATH%hybridret%freq%vec
      CASE DEFAULT
         write(*,*) "ERROR IN bath2hybrid: ALLOWED FREQUENCY TYPES ARE "//FERMIONIC//" AND "//RETARDED
         stop
    END SELECT
    !-------------------------------------!

    Nw=SIZE(freq);if(present(short))then;if(fit_nw>0)Nw=min(Nw,fit_nw);endif

  !-----------------------------------------------!
  ! Delta(iw) = Vcb * ( iw 1 - Ebath )^(-1) * Vbc !
  !-----------------------------------------------!

    hybrid  =  zero
    block   = .not.BATH%SUPER.or.(maxval(abs(BATH%Pb%rc%mat))     <cutoff_rvb.and. &
                                & maxval(abs(BATH%PVbc(1)%rc%mat))<cutoff_rvb.and. &
                                & maxval(abs(BATH%PVbc(2)%rc%mat))<cutoff_rvb)
    diagmat =  diag_bath.and..not.bath_nearest_hop

!---------------------------------------------------------------------------!
!---------------------------------------------------------------------------!
if(freeze_poles_delta)then
   if(ncpt_tot>0)then
    write(*,*) 'ERROR freezing pole with CPT approximation, not implemented...'
    stop
   endif
   if(.not.allocated(FROZEN_POLES)) allocate(FROZEN_POLES(2*BATH%Nb))
   Ebm1=-Eb; CALL eigenvector_matrix_c(lsize=size(Ebm1,1),mat=Ebm1,vaps=eigenvalues,eigenvec=Ebm1);
   Vcb=MATMUL(Vcb,Ebm1)
   Vbc=MATMUL(conjg(transpose(Ebm1)),Vbc)
   ratio=dble(freeze_poles_delta_iter-1)/dble(freeze_poles_delta_niter)*freeze_pole_lambda
   if(freeze_poles_delta_iter==1)then
    FROZEN_POLES=eigenvalues
   else
    eigenvalues=FROZEN_POLES
    do i=1,BATH%Nb-1
     eigenvalues(i)=FROZEN_POLES(i)+ratio*(FROZEN_POLES(i+1)-FROZEN_POLES(i))
    enddo
    do i=BATH%Nb+1,2*BATH%Nb-1
     eigenvalues(i)=FROZEN_POLES(i)+ratio*(FROZEN_POLES(i+1)-FROZEN_POLES(i))
    enddo
   endif
!#ifndef OPENMP_MPI_SAFE
!$OMP PARALLEL PRIVATE(iw)
!$OMP DO
!#endif
    do iw=1,Nw
      hybrid(:,:,iw)=MATMUL(Vcb,MATMUL_x(aa=bande_mat(2*BATH%Nb,1.d0/(freq(iw)-eigenvalues)),bb=Vbc,IdL=.true.))
    enddo
!#ifndef OPENMP_MPI_SAFE
!$OMP END DO
!$OMP END PARALLEL
!#endif

!---------------------------------------------------------------------------!
!---------------------------------------------------------------------------!
else
 if(.not.fast_fit.or.(fit_green_func_and_not_hybrid.and.present(short)))then

   if(fit_green_func_and_not_hybrid.and.present(short))then
!#ifndef OPENMP_MPI_SAFE
!$OMP PARALLEL PRIVATE(iw,Ebm1,i) SHARED(Eb,freq)
!$OMP DO
!#endif
         do iw=1,Nw
              Ebm1=Eb ; do i=1,size(Eb,1) ; Ebm1(i,i) = Ebm1(i,i) + freq(iw) ; enddo
              CALL invmat(n=size(Ebm1,1),mat=Ebm1,block_matrix=block,diagmat=diagmat)
              if(.not.diagmat)then
                hybrid(:,:,iw)=MATMUL(Vcb,MATMUL_x(aa=Ebm1,bb=Vbc,a_by_block=block))
              else
                hybrid(:,:,iw)=MATMUL(Vcb,MATMUL_x(aa=Ebm1,bb=Vbc,IdL=.true.))
              endif
              hybrid(:,:,iw)=-hybrid(:,:,iw)
              do i=1,size(hybrid,1) ; hybrid(i,i,iw) = hybrid(i,i,iw) + freq(iw) ; enddo
              hybrid(:,:,iw) = hybrid(:,:,iw) - Eccc%rc%mat
              CALL invmat(n=size(hybrid,1),mat=hybrid(:,:,iw),block_matrix=block,diagmat=diagmat)
         enddo
!#ifndef OPENMP_MPI_SAFE
!$OMP END DO
!$OMP END PARALLEL
!#endif
   else
         mmstep=size(Eb,1)/size(hybrid,1)
!#ifndef OPENMP_MPI_SAFE
!$OMP PARALLEL PRIVATE(iw,Ebm1,i,mm,ll) SHARED(Eb,freq)
!$OMP DO
!#endif
         do iw=1,Nw
              if(.not.(diag_V.and.diagmat))then
                Ebm1=Eb ; do i=1,size(Eb,1) ; Ebm1(i,i) = Ebm1(i,i) + freq(iw) ; enddo
                CALL invmat(n=size(Ebm1,1),mat=Ebm1,block_matrix=block,diagmat=diagmat)
                if(.not.diagmat)then
                  hybrid(:,:,iw)=MATMUL(Vcb,MATMUL_x(aa=Ebm1,bb=Vbc,a_by_block=block))
                else
                  hybrid(:,:,iw)=MATMUL(Vcb,MATMUL_x(aa=Ebm1,bb=Vbc,IdL=.true.))
                endif
              else
                hybrid(:,:,iw)=0.d0
                do mm=1,size(hybrid,1)
                  hybrid(mm,mm,iw)=0.d0
                  if(fmos)then
                   do ll=(mm-1)*mmstep+1,mm*mmstep
                    hybrid(mm,mm,iw)=hybrid(mm,mm,iw)+conjg(Vcb(mm,ll))*Vcb(mm,ll)/(freq(iw)+Eb(ll,ll))
                   enddo
                  else
                   do ll=1,size(Eb,1)
                    hybrid(mm,mm,iw)=hybrid(mm,mm,iw)+conjg(Vcb(mm,ll))*Vcb(mm,ll)/Ebm1(ll,ll)
                   enddo
                  endif
                enddo
              endif
         enddo
!#ifndef OPENMP_MPI_SAFE
!$OMP END DO
!$OMP END PARALLEL
!#endif
   endif
 else
   Ebm1=-Eb; CALL eigenvector_matrix_c(lsize=size(Ebm1,1),mat=Ebm1,vaps=eigenvalues,eigenvec=Ebm1);
   Vcb=MATMUL(Vcb,Ebm1); Vbc=MATMUL(conjg(transpose(Ebm1)),Vbc)
!#ifndef OPENMP_MPI_SAFE
!$OMP PARALLEL PRIVATE(iw)
!$OMP DO
!#endif
    do iw=1,Nw
     hybrid(:,:,iw)=MATMUL(Vcb,MATMUL_x(aa=bande_mat(size(eigenvalues),1.d0/(freq(iw)-eigenvalues)),bb=Vbc,IdL=.true.))
    enddo
!#ifndef OPENMP_MPI_SAFE
!$OMP END DO
!$OMP END PARALLEL
!#endif
 endif
endif
!---------------------------------------------------------------------------!
!---------------------------------------------------------------------------!

    IF(write_.AND.iproc==1) CALL glimpse_correl(BATH%hybrid)

    CALL delete_masked_matrix(EbNambu); CALL delete_masked_matrix(VbcNambu)

  return
  END SUBROUTINE

!*********************************************
!*********************************************
!*********************************************
!*********************************************
!*********************************************
!*********************************************
!*********************************************
!*********************************************
!*********************************************
!*********************************************
!*********************************************
!*********************************************
!*********************************************

  SUBROUTINE hybrid2bath(bath)

    TYPE(bath_type), INTENT(INOUT) :: bath
    INTEGER                        :: spin,iparam,ii,j,Nw,i,iw
    INTEGER                        :: start_hybrid2bath,istep
    REAL(DBL)                      :: dist_min,dist_test
    REAL(DBL),ALLOCATABLE          :: test(:)

    IF(.NOT.ASSOCIATED(bath%Eb)) STOP "ERROR IN hybrid2bath : INPUT  ISNT ASSOCIATED!"

    CALL reset_timer(start_hybrid2bath)

    ! CREATE THE REFERENCE HYBRIDIZATION WE WANT TO FIT
    IF(.NOT.ASSOCIATED(hybrid2fit%fctn)) CALL new_correl(hybrid2fit,bath%hybrid)
    CALL copy_correl(hybrid2fit,bath%hybrid)
    hybrid2fit%title = 'hybrid2fit'

    if(abs(average_G)>=4)then
      call average_correlations(bath%hybrid,hybrid2fit%fctn,average_G>=0,MASK_AVERAGE)
      bath%hybrid%fctn=hybrid2fit%fctn
      call bath2vec(bath)
    endif

    if(fit_green_func_and_not_hybrid) then
      write(*,*) ' ... FITTING GREEN FUNCTION ... '
      call write_array( Eccc%rc%mat(:,:), 'Ec for Fit', unit=6, short=.true.)
      Nw=size(hybrid2fit%fctn,3)
      write(*,*) 'Nw = ', Nw
      do iw=1,Nw
        hybrid2fit%fctn(:,:,iw) = - hybrid2fit%fctn(:,:,iw)
        do i=1,size(hybrid2fit%fctn,1)
          hybrid2fit%fctn(i,i,iw) = hybrid2fit%fctn(i,i,iw) + hybrid2fit%freq%vec(iw)
        enddo
        hybrid2fit%fctn(:,:,iw) = hybrid2fit%fctn(:,:,iw) - Eccc%rc%mat(:,:)
        CALL invmat(n=size(hybrid2fit%fctn,1),mat=hybrid2fit%fctn(:,:,iw))
      enddo
      write(*,*) 'Weiss Field Function to fit defined'
      call write_array( Eccc%rc%mat(:,:), 'Ec for Fit', unit=6, short=.true.)
      call write_array( real(hybrid2fit%fctn(:,:,1)), 'Re Weiss to fit (iw=1)', unit=6, short=.true.)
      call write_array( aimag(hybrid2fit%fctn(:,:,1)), 'Re Weiss to fit (iw=1)', unit=6, short=.true.)
    endif

    ! CREATE THE RUNNING BATH

    IF(.NOT.ASSOCIATED(batht%Eb)) CALL new_bath(batht,bath)
    CALL copy_bath(batht,bath)
    CALL bath2vec(batht)
    CALL bath2vec(bath)

    CALL dump_message(TEXT="############################")
    CALL dump_message(TEXT="### BEGIN HYBRID => BATH ###")
    CALL dump_message(TEXT="############################")

    if(size2>1.and..not.no_mpi)then
     write(*,*) 'BEGIN HYBRIDIZATION FIT, RANK = ', rank
     call mpibarrier
    endif

    write(log_unit,*) "parameters for minimization = "
    write(log_unit,*) 'nparam,search_step,dist_max,Niter_search_max : '
    write(log_unit,*)  bath%nparam,bath%search_step,bath%dist_max,bath%Niter_search_max

  !---------------------------------------------------------------------------------------------!
     if(allocated(test)) deallocate(test); allocate(test(bath%nparam+ncpt_para*ncpt_tot))
                                     test                           =   0.d0
                                     test(1:bath%nparam)            =   bath%vec(1:bath%nparam)
     if(ncpt_tot>0)then
       do i=1,ncpt_tot
                                     test(bath%nparam+i)            = (-1.d0+2.d0*dran_tab(i))/2.d0/1000.d0
       if(ncpt_para==2)then
                                     test(bath%nparam+i+ncpt_tot)   = test(bath%nparam+i)
       endif
       enddo
     endif

     if(use_specific_set_parameters.and.(ncpt_tot==0.or..not.ncpt_flag_two_step_fit)) &
                         &  test(1:bath%nparam+ncpt_para*ncpt_tot) = param_input(1:bath%nparam+ncpt_para*ncpt_tot)

     if(.not.skip_fit_)then
      if(iterdmft==1)then
        istep=Niter_search_max_0
      else
        istep=bath%Niter_search_max
      endif

      write(*,*) 'minimizing with [x] total parameters - rank : ', bath%nparam+ncpt_para*ncpt_tot,rank
      write(*,*) 'size of array test (parameters)      - rank : ', size(test),rank

      if(size(test)==0)then
       write(*,*) 'ERROR - array test has zero dimension in bath_hybrid'
       write(*,*) '        rank = ', rank
       stop
      endif

      icount_=0

      if(size2>1.and..not.no_mpi)then
       write(*,*) 'CALLING WRAPPER, RANK = ', rank
       call mpibarrier
      endif

#ifdef OPENMP_MPI_SAFE___
      if(rank==0.or.no_mpi)then
          write(*,*) 'COMPUTING DISTANCE_FUNC'
          call distance_func(dist_test,size(test),test)
          write(*,*) 'INITIAL DISTANCE : ', dist_test
          write(*,*) 'CALLING minimize_func .....'
          call minimize_func_wrapper(distance_func,test,bath%nparam+ncpt_para*ncpt_tot,FIT_METH,istep, &
                             & dist_min,bath%dist_max,bath%search_step,use_mpi=.false.)
      endif
      write(*,*) 'RANK WAITING FOR MASTER : ', rank
      write(*,*) 'no_mpi flag             : ', no_mpi
      if(.not.no_mpi)then
       call mpibarrier
       call mpibcast(test)
      endif
#else
      write(*,*) 'COMPUTING DISTANCE_FUNC'
      call distance_func(dist_test,size(test),test)
      write(*,*) 'INITIAL DISTANCE : ', dist_test
      write(*,*) 'CALLING minimize_func .....'
      call minimize_func_wrapper(distance_func,test,bath%nparam+ncpt_para*ncpt_tot,FIT_METH,istep, &
                             &   dist_min,bath%dist_max,bath%search_step,use_mpi=.true.)
#endif
     else
      write(*,*) 'SKIPPING FIT'
      dist_min=0.d0
     endif

     if(size2>1.and..not.no_mpi)then
      write(*,*) 'COLLECTING OPTIMAL PARAMETERS, RANK = ', rank
      call mpibarrier
     endif

     bath%vec(1:bath%nparam)                        = test(1:bath%nparam)
     param_output = 0.d0
     param_output(1:bath%nparam+ncpt_para*ncpt_tot) = test(1:bath%nparam+ncpt_para*ncpt_tot)

     CALL vec2bath(bath)

     if(ncpt_tot==0)then
      CALL bath2hybrid(bath,FERMIONIC)
      CALL plot_some_results
      CALL bath2hybrid(bath,RETARDED)
     else
      !to store epsilon_cpt and T_cpt
      CALL bath2hybrid(bath,FERMIONIC,cptvec=test(bath%nparam+1:size(test)),cpt_build_matrix=.true.)
      CALL plot_some_results
      !we solve and obtain the GF of the disconnected problem
      CALL bath2hybrid(bath,FERMIONIC)
      CALL bath2hybrid(bath,RETARDED)
     endif

     deallocate(test)
  !---------------------------------------------------------------------------------------------!

    if(verbose_graph)then
      !!call plotarray(real(bath%hybridret%freq%vec),  real(bath%hybridret%fctn(1,1,:)), 'ED hybrid Bath re bath')
      !!call plotarray(real(bath%hybridret%freq%vec),  real(bath%hybridret%fctn(2,2,:)), 'ED hybrid Bath re bath2')
      !!call plotarray(real(bath%hybridret%freq%vec), aimag(bath%hybridret%fctn(1,1,:)), 'ED hybrid Bath im bath')
      !!call plotarray(real(bath%hybridret%freq%vec), aimag(bath%hybridret%fctn(2,2,:)), 'ED hybrid Bath im bath2')
    endif

    write(*,*) 'min bath parameters are : ', param_output
    WRITE(log_unit,'(2(a,f0.12),a)') "# END of conjugate gradient: dist_min = ",dist_min," (tolerance=",bath%dist_max,")"
    CALL timer_fortran(start_hybrid2bath,"### HYBRID => BATH TOOK ")

  contains

 !---------------------------!

  subroutine plot_some_results
  character(12) :: lab
  integer       :: kkk,i,j
   if(rank/=0) return
   !call PGSUBP(4,4)
   open(unit=1000,file='delta_fit1')
   do kkk=1,size(hybrid2fit%freq%vec)
      write(1000,'((x,f14.8))',advance='no') aimag(hybrid2fit%freq%vec(kkk))
      do i = 1,size(hybrid2fit%fctn(:,1,1))/2
         do j = 1, size(hybrid2fit%fctn(:,1,1))/2
            write(1000,'(2(x,f14.8))',advance='no') real(bath%hybrid%fctn(i,j,kkk)),aimag(bath%hybrid%fctn(i,j,kkk))
         enddo
      enddo
      write(1000,*)
   enddo
   close(1000)

   open(unit=1031,file='delta_skip_fit1')
   do kkk=1,size(hybrid2fit%freq%vec)
    write(1031,*) aimag(hybrid2fit%freq%vec(kkk)),real(bath%hybrid%fctn(1,1,kkk)),aimag(bath%hybrid%fctn(1,1,kkk))
   enddo
   close(1031)
   open(unit=1031,file='delta_skip_fit2')
   do kkk=1,size(hybrid2fit%freq%vec)
    write(1031,*) aimag(hybrid2fit%freq%vec(kkk)),real(bath%hybrid%fctn(2,2,kkk)),aimag(bath%hybrid%fctn(2,2,kkk))
   enddo
   close(1031)

   do j=1,size(bath%hybrid%fctn(:,1,1))
   do kkk=1,size(bath%hybrid%fctn(1,:,1))

    if(j==kkk.or.fit_all_elements_show_graphs)then
    lab=TRIM(ADJUSTL(toString(j)))//"_"//TRIM(ADJUSTL(toString(kkk)))//"_iter"//TRIM(ADJUSTL(toString(iterdmft)))//"_"
     if(.not.fit_green_func_and_not_hybrid)then
      !!call plotarray( aimag(hybrid2fit%freq%vec),real(bath%hybrid%fctn(j,kkk,:)), &
         !           & aimag(hybrid2fit%freq%vec),real(hybrid2fit%fctn(j,kkk,:)), 'FIT_ED_re_bath'//lab,inset=.true.,nn=100)
      !!call plotarray( aimag(hybrid2fit%freq%vec),aimag(bath%hybrid%fctn(j,kkk,:)), &
         !           & aimag(hybrid2fit%freq%vec),aimag(hybrid2fit%fctn(j,kkk,:)), 'FIT_ED_im_bath'//lab,inset=.true.,nn=100)
     else
      !!call plotarray( aimag(hybrid2fit%freq%vec),real(batht%hybrid%fctn(j,kkk,:)), &
          !          & aimag(hybrid2fit%freq%vec),real(hybrid2fit%fctn(j,kkk,:)), 'FIT_ED_re_bath_t'//lab,inset=.true.,nn=100)
      !!call plotarray( aimag(hybrid2fit%freq%vec),aimag(batht%hybrid%fctn(j,kkk,:)), &
          !          & aimag(hybrid2fit%freq%vec),aimag(hybrid2fit%fctn(j,kkk,:)), 'FIT_ED_im_bath_t'//lab,inset=.true.,nn=100)
     endif
    endif

   enddo
   enddo
   !call PGSUBP(1,1)

  end subroutine

 !---------------------------!

  END SUBROUTINE

!*********************************************
!*********************************************
!*********************************************
!*********************************************
!*********************************************
!*********************************************
!*********************************************
!*********************************************
!*********************************************
!*********************************************
!*********************************************
!*********************************************
!*********************************************
!*********************************************
!*********************************************

  SUBROUTINE distance_func(dist,n,vec)
    REAL(DBL), INTENT(OUT) :: dist
    INTEGER,   INTENT(IN)  :: n
    REAL(DBL), INTENT(IN)  :: vec(n)
    REAL(DBL)              :: Vweight

    !$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    !$$ EXTRACT THE NEW BATH PARAMETERS OUT OF VECTOR 'vec' $$
    !$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

    if(n<batht%nparam)then
       write(*,*) 'error in routine sent to conjg gradient'
       write(*,*) 'dimension given as input : ', n
       write(*,*) 'batht%nparam             : ', batht%nparam
       stop 'termine'
    endif

    batht%vec(1:batht%nparam)=vec(1:batht%nparam)
    CALL vec2bath(batht)

    !$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    !$$ COMPUTE THE NEW HYBRIZATION FUNCTION $$
    !$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

    if(ncpt_tot==0)then
       CALL bath2hybrid(batht,FERMIONIC,WRITE_HYBRID=F,short=.true.)
    else
     if(n==batht%nparam)then
       write(*,*) 'ERROR using CPT approximation, total parameters mismatch1'
       stop
     endif
     if(ncpt_para*ncpt_tot+batht%nparam/=n)then
       write(*,*) 'ERROR using CPT approximation, total parameters mismatch2'
       stop
     endif
     CALL bath2hybrid(batht,FERMIONIC,WRITE_HYBRID=F,short=.true.,cptvec=vec(batht%nparam+1:n),Vweight=Vweight)
    endif

    !$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    !$$ COMPUTE THE DISTANCE TO THE DESIRED HYBRIZATION FUNCTION $$
    !$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    CALL diff_correl(dist,batht%hybrid,hybrid2fit)

    if(ncpt_tot/=0)then
      dist=dist+Vweight*cpt_lagrange
    endif

    icount_=icount_+1
    if(mod(icount_,200) ==0)  write(log_unit,*) ' dist = ' , dist, icount_, rank
    if(mod(icount_,20)  ==0)  write(*,*)        ' dist = ' , dist, icount_, rank

    if(mod(icount_,100)==0.and.verbose_graph.and.size2==1) call plot_it_

  END SUBROUTINE

!*********************************************
!*********************************************
!*********************************************
!*********************************************
!*********************************************
!*********************************************
!*********************************************
!*********************************************
!*********************************************
!*********************************************
!*********************************************
!*********************************************

 subroutine plot_it_
     !call simplehist(dble(batht%vec),'vec',display=5)
     !!call plotarray( aimag(hybrid2fit%freq%vec),real(batht%hybrid%fctn(1,1,:)), &
            !       & aimag(hybrid2fit%freq%vec),real(hybrid2fit%fctn(1,1,:)), 're bath'  ,inset=.true.,nn=100,display=1)
     !!call plotarray( aimag(hybrid2fit%freq%vec),real(batht%hybrid%fctn(2,2,:)), &
            !       & aimag(hybrid2fit%freq%vec),real(hybrid2fit%fctn(2,2,:)), 're bath2' ,inset=.true.,nn=100,display=2)
     !!call plotarray( aimag(hybrid2fit%freq%vec),aimag(batht%hybrid%fctn(1,1,:)), &
            !       & aimag(hybrid2fit%freq%vec),aimag(hybrid2fit%fctn(1,1,:)), 'im bath',inset=.true.,nn=100,display=3)
     !!call plotarray( aimag(hybrid2fit%freq%vec),aimag(batht%hybrid%fctn(2,2,:)), &
            !       & aimag(hybrid2fit%freq%vec),aimag(hybrid2fit%fctn(2,2,:)), 'im bath2',inset=.true.,nn=100,display=4)
 end subroutine

!*********************************************
!*********************************************
!*********************************************
!*********************************************
!*********************************************
!*********************************************
!*********************************************
!*********************************************
!*********************************************
!*********************************************
!*********************************************
!*********************************************
!*********************************************
!*********************************************

END MODULE
