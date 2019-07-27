MODULE fermion_ket_class
  use genvar
  use mask_class, only: write_array
  !USE common_def 
  !use matrix
  !use linalg

  IMPLICIT NONE


  REAL(DBL),    PARAMETER, private                 :: zero=0.0_DBL,one=1.0_DBL,two=2.0_DBL,three=3.0_DBL,four=4.0_DBL
  LOGICAL,      PARAMETER, private                 :: F=.FALSE.,T=.TRUE.



  INTERFACE new_ket
    MODULE PROCEDURE new_ket_from_state
    MODULE PROCEDURE new_ket_from_old
  END INTERFACE



  TYPE fermion_ket_type
    !$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    !$$ SPINLESS FERMIONIC ORBITALS KET TYPE $$
    !$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    ! NUMBER OF ORBITALS (NEEDED FOR FERMIONIC SIGN!)
    INTEGER :: norbs
    ! STATE (INTEGER REP.)
    INTEGER :: state
    ! FERMIONIC SIGN FACTOR
    INTEGER :: fermion_sign
    ! is_nil = T IF NIL KET
    LOGICAL :: is_nil
  END TYPE 


  TYPE fermion_ket_vec
    integer             :: dim
    real(8)             :: energy,total_S,total_Sz,total_N
    real(8),allocatable :: vec(:)    
  END TYPE


CONTAINS 

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
!**************************************************************************

 integer function locate_fermion(basis,ket,Nimpurity)
 implicit none
 integer                :: Nimpurity
 TYPE(fermion_ket_type) :: basis(1:4**Nimpurity),ket
 integer                :: i
  do i=1,4**Nimpurity
   if(ket%state==basis(i)%state)then
     locate_fermion=i; return
   endif     
  enddo
 end function

!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************

subroutine eigenvector_matrix_r(lsize,mat,vaps,eigenvec)
implicit none
integer                   :: lsize,i
real(8)                   :: WORK(3*lsize),RWORK(3*lsize)
real(8)                   :: mat(lsize,lsize)
real(8)                   :: eigenvec(lsize,lsize)
real(8)                   :: rrr
integer                   :: INFO,order(lsize)
real(8)                   :: vaps(lsize),temp(1,lsize)

   if(lsize<1) stop 'error eigenvector_matrix_r, 0 dim'

   eigenvec=mat

   call DSYEV('V','U',lsize,eigenvec,lsize,vaps,WORK,3*lsize,INFO)

   if(INFO/=0)then
    write(*,*) 'BAD eigenvalue calculation , info = :', INFO
    write(*,*) 'stop calculations...'
    stop
   endif

end subroutine



!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************

 subroutine build_and_diag_hamiltonian_matrix(basis,kets,Nimpurity,hz,eps,U,hund,teta_mat)
 implicit none
 integer                :: Nimpurity
 TYPE(fermion_ket_type) :: basis(1:4**Nimpurity),ket_temp,ket_temp2
 TYPE(fermion_ket_vec)  :: kets(4**Nimpurity)
 integer                :: ii,jj,i,j,k
 integer                :: UU(Nimpurity),hop_up_dest,hop_dn_dest,hop_up_sign,hop_dn_sign
 real(8)                :: hz(Nimpurity)
 real(8)                :: eps(2*Nimpurity),U(Nimpurity),hund,teta_mat(Nimpurity,Nimpurity)
 real(8)                :: hamilt_(4**Nimpurity,4**Nimpurity),eigen_(4**Nimpurity)

   hamilt_=0.d0
   do i=1,4**Nimpurity


     hamilt_(i,i)=diag_energy_of_ket(basis(i),Nimpurity,hz,eps,U)
     write(*,*) 'diag energy = ', hamilt_(i,i)

     do ii=1,Nimpurity
      do jj=1,Nimpurity
       
       if(abs(teta_mat(ii,jj))>1.d-4)then
          !HOPPINGS
           write(*,*) 'compute hopping matrix element', ii,jj
           call hop(ket_temp,ii+Nimpurity,jj+Nimpurity,basis(i))
           hop_up_dest=locate_fermion(basis,ket_temp,Nimpurity)
           hop_up_sign=ket_temp%fermion_sign
           if(.not.ket_temp%is_nil) hamilt_(hop_up_dest,i)=hamilt_(hop_up_dest,i)+dble(hop_up_sign)*teta_mat(ii,jj)
           call hop(ket_temp,ii,jj,basis(i))
           hop_dn_dest=locate_fermion(basis,ket_temp,Nimpurity)
           hop_dn_sign=ket_temp%fermion_sign
           if(.not.ket_temp%is_nil) hamilt_(hop_dn_dest,i)=hamilt_(hop_dn_dest,i)+dble(hop_dn_sign)*teta_mat(ii,jj)
       endif

       !HUNDS COUPLING
       if(abs(teta_mat(ii,jj))>1.d-4.and.abs(hund)>1.d-4)then
           write(*,*) 'compute hund matrix element'
           call hop(ket_temp,ii+Nimpurity,jj+Nimpurity,basis(i))
           hop_up_dest=locate_fermion(basis,ket_temp,Nimpurity)
           hop_up_sign=ket_temp%fermion_sign
           if(.not.ket_temp%is_nil)then
             call hop(ket_temp2,jj,ii,ket_temp)
             hop_dn_dest=locate_fermion(basis,ket_temp2,Nimpurity)
             hop_dn_sign=-ket_temp%fermion_sign*ket_temp2%fermion_sign
             if(.not.ket_temp2%is_nil) hamilt_(hop_dn_dest,i)=hamilt_(hop_dn_dest,i)+dble(hop_dn_sign)*hund/2.d0
           endif
           call hop(ket_temp,ii,jj,basis(i))
           hop_up_dest=locate_fermion(basis,ket_temp,Nimpurity)
           hop_up_sign=ket_temp%fermion_sign
           if(.not.ket_temp%is_nil)then
             call hop(ket_temp2,jj+Nimpurity,ii+Nimpurity,ket_temp)
             hop_dn_dest=locate_fermion(basis,ket_temp2,Nimpurity)
             hop_dn_sign=-ket_temp%fermion_sign*ket_temp2%fermion_sign
             if(.not.ket_temp2%is_nil) hamilt_(hop_dn_dest,i)=hamilt_(hop_dn_dest,i)+dble(hop_dn_sign)*hund/2.d0
           endif
           hamilt_(i,i)=hamilt_(i,i)+hund*siz__(ii,basis(i),Nimpurity)*siz__(jj,basis(i),Nimpurity) 
       endif

      enddo
     enddo     

   enddo

   if(maxval(abs(hamilt_-transpose(hamilt_)))>1.d-5)then
     call write_array(hamilt_, ' IMP. HAMILTONIAN ', SHORT=.true., UNIT =6 )
     write(*,*) 'not hermitic!'
     stop 'critical'
   endif

   call eigenvector_matrix_r(size(eigen_),hamilt_,eigen_,hamilt_)  
    
   do i=1,size(eigen_)
     kets(i)%energy=eigen_(i)
     if(size(kets(i)%vec)/=size(eigen_)) then
       write(*,*) 'problem size to not match in build Himp'
       stop 'critical'
     endif 
     kets(i)%vec(:) = hamilt_(:,i)
   enddo
  
   do i=1,size(eigen_)
     kets(i)%total_N  =       total_N_(basis,kets(i),Nimpurity)
     kets(i)%total_Sz = total_spin_Sz_(basis,kets(i),Nimpurity)
     kets(i)%total_S  =  total_spin_S_(basis,kets(i),Nimpurity)
   enddo

 end subroutine

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
!**************************************************************************

 subroutine build_basis_of_hilbert_space(kets,Nimpurity)
 implicit none
 integer                :: ii,Nimpurity
 TYPE(fermion_ket_type) :: kets(4**Nimpurity)
     do ii=1,4**Nimpurity
        call new_ket_from_state(kets(ii),ii-1,2*Nimpurity)
     enddo
 end subroutine

!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************

 subroutine apply_cdagger_dn_and_cdagger_up_on_state(istate,basis,kets,Nimpurity,site,up_or_dn,nconnected,connection,m_element)
 implicit none
 integer                :: Nimpurity,istate
 TYPE(fermion_ket_type) :: basis(1:4**Nimpurity),ket_out
 TYPE(fermion_ket_vec)  :: kets(4**Nimpurity),ket_temp
 integer                :: ii,jj,i,j,k,ii1,up_or_dn,site,nconnected,connection(4**Nimpurity)
 real(8)                :: projection(4**Nimpurity),m_element(4**Nimpurity)
 
  call init_ket_vec(ket_temp,4**Nimpurity)
  
                  jj=   site
  if(up_or_dn==1) jj=jj+Nimpurity

  ket_temp%vec=0.d0
  do ii=1,4**Nimpurity
   call create(ket_out,jj,basis(ii))
   if(.not.ket_out%is_nil)then
    ii1= locate_fermion(basis,ket_out,Nimpurity)
    ket_temp%vec(ii1) = ket_temp%vec(ii1) + (-1)**(noccupied(ket_out,jj)-1)*kets(istate)%vec(ii)
   endif
  enddo
  nconnected=0
  do ii=1,4**Nimpurity
    projection(ii)=dot_product(kets(ii)%vec(:),ket_temp%vec(:))
    if(abs(projection(ii))>1.d-5)then
     nconnected=nconnected+1
     connection(nconnected)=ii
     m_element(nconnected)=projection(ii)
   endif
  enddo

 return
 end subroutine

!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************

 real(8) function total_spin_S_(basis,ket,Nimpurity)
 implicit none
 integer                :: Nimpurity,i
 TYPE(fermion_ket_type) :: basis(4**Nimpurity)  
 TYPE(fermion_ket_vec)  :: ket
    do i=1,size(ket%vec)
     if(abs(ket%vec(i))>1.d-3)then
      total_spin_S_=total_spin_S_of_ket(basis(i),Nimpurity)
      return
     endif
    enddo
  stop 'error total S'
 end function

 real(8) function total_N_(basis,ket,Nimpurity)
 implicit none
 integer                :: Nimpurity,i
 TYPE(fermion_ket_type) :: basis(4**Nimpurity)
 TYPE(fermion_ket_vec)  :: ket
  do i=1,size(ket%vec)
     if(abs(ket%vec(i))>1.d-3)then
      total_N_=total_N_of_ket(basis(i),Nimpurity)
      return
     endif
  enddo
  stop 'error total N'
 end function

 real(8) function total_spin_Sz_(basis,ket,Nimpurity)
 implicit none
 integer                :: Nimpurity,i
 TYPE(fermion_ket_type) :: basis(4**Nimpurity)
 TYPE(fermion_ket_vec)  :: ket
  do i=1,size(ket%vec)
     if(abs(ket%vec(i))>1.d-3)then
      total_spin_Sz_=total_spin_Sz_of_ket(basis(i),Nimpurity)
      return
     endif
  enddo
  stop 'error total Sz'
 end function

!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************

 real(8) function total_spin_S_of_ket(ket,Nimpurity)
 implicit none
 TYPE(fermion_ket_type) :: ket
 integer                :: Nimpurity,ii,jj,i,j,k
 integer                :: v1(Nimpurity),v2(Nimpurity)
   v1=(/( ni__(jj,ket), jj =           1,  Nimpurity  )/) 
   v2=(/( ni__(jj,ket), jj = Nimpurity+1,2*Nimpurity  )/) 
   total_spin_S_of_ket = sum((/(abs(v2(jj)-v1(jj))*0.5,jj=1,Nimpurity)/))
 end function

 real(8) function total_N_of_ket(ket,Nimpurity)
 implicit none
 TYPE(fermion_ket_type) :: ket
 integer                :: Nimpurity,ii,jj,i,j,k
 integer                :: v1(Nimpurity),v2(Nimpurity)
   v1=(/( ni__(jj,ket), jj =           1,  Nimpurity  )/)
   v2=(/( ni__(jj,ket), jj = Nimpurity+1,2*Nimpurity  )/)
   total_N_of_ket = sum((/(  v2(jj)+v1(jj),jj=1,Nimpurity )/))
 end function

 real(8) function total_spin_Sz_of_ket(ket,Nimpurity)
 implicit none
 TYPE(fermion_ket_type) :: ket
 integer                :: Nimpurity,ii,jj,i,j,k
 integer                :: v1(Nimpurity),v2(Nimpurity)
   v1=(/( ni__(jj,ket), jj =           1,  Nimpurity  )/)
   v2=(/( ni__(jj,ket), jj = Nimpurity+1,2*Nimpurity  )/)
   total_spin_Sz_of_ket = sum( (/(  (v2(jj)-v1(jj))*0.5 ,jj=1,Nimpurity )/) )
 end function


!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************

 real(8) function diag_energy_of_ket(ket,Nimpurity,hz,eps,U)
 implicit none
 TYPE(fermion_ket_type) ::  ket
 integer                ::  Nimpurity,ii,jj,i,j,k
 integer                ::  v1(Nimpurity),v2(Nimpurity),UU(Nimpurity)
 real(8)                ::  hz(Nimpurity)
 real(8)                ::  eps(2*Nimpurity),U(Nimpurity)

   v1=(/( ni__(jj,ket), jj =           1,  Nimpurity  )/)
   v2=(/( ni__(jj,ket), jj = Nimpurity+1,2*Nimpurity  )/)
   UU=0; where(v1==1.and.v2==1) UU=1
   diag_energy_of_ket=     sum((/(U(jj)*UU(jj),jj=1,Nimpurity)/))+ &
                        &  sum((/(v2(jj)*eps(jj),jj=1,Nimpurity)/))+ &
                        &  sum((/(v1(jj)*eps(jj+Nimpurity),jj=1,Nimpurity)/)) + &
                        &  sum((/(hz(jj)*(v2(jj)-v1(jj))/2.d0,jj=1,Nimpurity)/))
 end function

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
!**************************************************************************
!**************************************************************************

 subroutine init_ket_vec(ket_vec,dim)
 integer               :: dim
 TYPE(fermion_ket_vec) :: ket_vec
   if(allocated(ket_vec%vec)) deallocate(ket_vec%vec)
   allocate(ket_vec%vec(dim))
   ket_vec%vec=0.d0
 end subroutine

!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************

  SUBROUTINE new_ket_from_state(ket,state,norbs)
    !$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    !$$ CREATE NEW KET FROM STATE + NORBITALS $$ 
    !$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    TYPE(fermion_ket_type), INTENT(INOUT) :: ket
    INTEGER,                INTENT(IN)    :: state
    INTEGER,                INTENT(IN)    :: norbs
    ket%norbs        = norbs
    ket%state        = state
    ket%fermion_sign = 1
    ket%is_nil       = F
  END SUBROUTINE 

!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************

  SUBROUTINE new_ket_from_old(ket_out,ket_in) 
    !$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    !$$ CREATE NEW KET FROM STATE + NORBITALS $$ 
    !$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    TYPE(fermion_ket_type), INTENT(INOUT) :: ket_out
    TYPE(fermion_ket_type), INTENT(IN)    :: ket_in
    CALL copy_ket(ket_out,ket_in) 
  END SUBROUTINE 

!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************

  SUBROUTINE copy_ket(ket_out,ket_in)
    !$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    !$$ CREATE NEW KET FROM EXISTING ONE $$
    !$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    TYPE(fermion_ket_type), INTENT(INOUT) :: ket_out
    TYPE(fermion_ket_type), INTENT(IN)    :: ket_in
    ket_out%norbs        = ket_in%norbs
    ket_out%state        = ket_in%state
    ket_out%fermion_sign = ket_in%fermion_sign
    ket_out%is_nil       = ket_in%is_nil
  END SUBROUTINE 

!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************

  SUBROUTINE hop(ket_out,jorb,iorb,ket_in)
    !$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    !$$ HOP PARTICULE FROM iorb to jorb $$
    !$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    TYPE(fermion_ket_type), INTENT(INOUT) :: ket_out
    TYPE(fermion_ket_type), INTENT(IN)    :: ket_in
    INTEGER,                INTENT(IN)    :: iorb,jorb
    CALL destroy(ket_out,iorb,ket_in)
    CALL create (ket_out,jorb,ket_out)
  END SUBROUTINE 

!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************

  SUBROUTINE create_pair(ket_out,jorb,iorb,ket_in) 
    !$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    !$$ CREATE PARTICLES ON iorb AND jorb $$
    !$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    TYPE(fermion_ket_type), INTENT(INOUT) :: ket_out
    TYPE(fermion_ket_type), INTENT(IN)    :: ket_in
    INTEGER,                INTENT(IN)    :: iorb,jorb
    CALL create(ket_out,iorb,ket_in)
    CALL create(ket_out,jorb,ket_out)
  END SUBROUTINE 

!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
  
  SUBROUTINE destroy_pair(ket_out,jorb,iorb,ket_in) 
    !$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    !$$ DESTROY PARTICULE ON iorb AND jorb $$
    !$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    TYPE(fermion_ket_type), INTENT(INOUT) :: ket_out
    TYPE(fermion_ket_type), INTENT(IN)    :: ket_in
    INTEGER,                INTENT(IN)    :: iorb,jorb
    CALL destroy(ket_out,iorb,ket_in)
    CALL destroy(ket_out,jorb,ket_out)
  END SUBROUTINE 
  
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************

  SUBROUTINE create(ket_out,iorb,ket_in) 
    !$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    !$$ CREATE PARTICULE ON ORBITAL iorb $$
    !$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    TYPE(fermion_ket_type), INTENT(INOUT) :: ket_out
    INTEGER,                INTENT(IN)    :: iorb
    TYPE(fermion_ket_type), INTENT(IN)    :: ket_in

    CALL copy_ket(ket_out,ket_in)
    IF(.NOT.ket_in%is_nil)THEN
      IF(.NOT.is_occupied(iorb,ket_in))THEN
         ket_out%state  = IBSET(ket_in%state,iorb-1) 
         CALL Fermion_sign(ket_out%fermion_sign,ket_out,iorb)
         ket_out%is_nil = F
      ELSE
         ket_out%is_nil = T
      ENDIF
    ENDIF

  END SUBROUTINE 

!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************

  SUBROUTINE destroy(ket_out,iorb,ket_in)

    !$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    !$$ ANNIHILATE PARTICULE ON ORBITAL iorb $$
    !$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

    TYPE(fermion_ket_type), INTENT(INOUT) :: ket_out
    INTEGER,                INTENT(IN)    :: iorb
    TYPE(fermion_ket_type), INTENT(IN)    :: ket_in

    CALL copy_ket(ket_out,ket_in)
    IF(.NOT.ket_in%is_nil)THEN
     IF(is_occupied(iorb,ket_in))THEN
       ket_out%state        = IBCLR(ket_in%state,iorb-1) 
       CALL Fermion_sign(ket_out%fermion_sign,ket_out,iorb)
       ket_out%is_nil       = F
     ELSE
       ket_out%is_nil       = T
     ENDIF
    ENDIF

  END SUBROUTINE 

!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************

  SUBROUTINE Fermion_sign(jsign,ket,iorb) 
    !$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    !$$ COMPUTE FERMION SIGN OF KET 'ket' FROM ORBITAL 'iorb' $$
    !$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    INTEGER,                INTENT(INOUT) :: jsign 
    TYPE(fermion_ket_type), INTENT(IN)    :: ket
    INTEGER,                INTENT(IN)    :: iorb
    INTEGER                               :: jorb
    ! Fermion_sign=(-1)^{Sum_(jorb>iorb) n(jorb)} 
    jsign = ket%fermion_sign
    DO jorb=iorb+1,ket%norbs  
      IF(is_occupied(jorb,ket)) jsign = - jsign
    ENDDO
  END SUBROUTINE 

!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************

  FUNCTION is_occupied(iorb,ket) 
    LOGICAL :: is_occupied
    TYPE(fermion_ket_type), INTENT(IN)  :: ket
    INTEGER,                INTENT(IN)  :: iorb
    is_occupied = BTEST(ket%state,iorb-1)
  END FUNCTION 

!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************

  FUNCTION siz__(iorb,ket,Nimpurity)
    INTEGER                             :: nup,ndn,Nimpurity
    REAL(8)                             :: siz__
    TYPE(fermion_ket_type), INTENT(IN)  :: ket
    INTEGER,                INTENT(IN)  :: iorb
                                        nup = 0
    IF(is_occupied(iorb+Nimpurity,ket)) nup = 1
                              ndn = 0
    IF(is_occupied(iorb,ket)) ndn = 1
    siz__=0.5*(nup-ndn)
  END FUNCTION

!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************

  FUNCTION ni__(iorb,ket) 
    INTEGER                             :: ni__
    TYPE(fermion_ket_type), INTENT(IN)  :: ket
    INTEGER,                INTENT(IN)  :: iorb
                              ni__ = 0
    IF(is_occupied(iorb,ket)) ni__ = 1
  END FUNCTION 

!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************

  FUNCTION mz__(ket)
    INTEGER                             :: mz__
    TYPE(fermion_ket_type), INTENT(IN)  :: ket
    INTEGER                             :: iorb
    mz__ =        SUM((/(ni__(iorb,ket),iorb=            1, ket%norbs/2 )/))
    mz__ = mz__ - SUM((/(ni__(iorb,ket),iorb=ket%norbs/2+1, ket%norbs   )/))
  END FUNCTION

  FUNCTION noccupied(ket,nnn) 
    INTEGER                             :: noccupied
    TYPE(fermion_ket_type), INTENT(IN)  :: ket
    INTEGER                             :: iorb,nnmax
    INTEGER,optional                    :: nnn
    nnmax=ket%norbs
    if(present(nnn)) nnmax=nnn
    noccupied = SUM((/(ni__(iorb,ket),iorb=1,nnmax)/))
  END FUNCTION 

!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************

END MODULE 
