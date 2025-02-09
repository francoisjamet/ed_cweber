!####################################################!
!####################################################!
!####################################################!
!####################################################!
!####################################################!
!####################################################!
!####################################################!
!####################################################!
!####################################################!
!####################################################!
!####################################################!
!####################################################!
!####################################################!
!####################################################!
!####################################################!

module cdagger
!use fortran_cuda
!use matrix, only : write_array,invmat
!use StringManip ,only : StrInt2,toString
use openmpmod
use init_and_close_my_sim
use mask_class
use StringManip
use mpirout

 INTERFACE ASSIGNMENT (=)
    MODULE PROCEDURE cdagger_copy
  END INTERFACE

  TYPE eigen
   real(8),allocatable :: val(:)
  END TYPE

  TYPE cdagger_mat
   integer    :: k_p,l_p
   integer    :: k_m,l_m
   real(8),   allocatable :: c_p(:,:) , c_m(:,:)
  END TYPE

contains

  subroutine swap_A_B(a,b)
  implicit none
  real(8) :: a(:,:),b(:,:)
  real(8), allocatable :: c(:,:)
  allocate(c(size(A,1),size(A,2)))
  c=a
  a=b
  b=c
  deallocate(c)
  end subroutine

  subroutine test_shapev(a,b)
  implicit none
  real(8) :: a(:),b(:)
  integer, save :: counter = 0

  counter = counter + 1

  if(any(shape(a)/=shape(b)))then
    write(*,*) 'error V , counter : ', counter
    write(*,*) 'A vector shape    : ', shape(a)
    write(*,*) 'B vector shpe     : ', shape(b)
    stop
  endif


  end subroutine

         !-------------------------!

  subroutine cdagger_copy(cout,cin)
  implicit none
  Type(cdagger_mat),intent(inout) :: cout
  Type(cdagger_mat),intent(in)    :: cin
   call kill_cdagger(cout)
   cout%k_p=cin%k_p
   cout%l_p=cin%l_p
   cout%k_m=cin%k_m
   cout%l_m=cin%l_m
   call allocate_dagger(cout)
   cout%c_p=cin%c_p
   cout%c_m=cin%c_m
  end subroutine

         !-------------------------!

  subroutine kill_cdagger(cdagger)
  implicit none
  Type(cdagger_mat) :: cdagger
      if(allocated(cdagger%c_p)) deallocate(cdagger%c_p)
      if(allocated(cdagger%c_m)) deallocate(cdagger%c_m)
  end subroutine

         !-------------------------!

  subroutine allocate_dagger(cdagger)
  implicit none
  Type(cdagger_mat) :: cdagger
   call allocate_dagger_p(cdagger)
   call allocate_dagger_m(cdagger)
  end subroutine

         !-------------------------!

  subroutine allocate_dagger_p(cdagger)
  implicit none
  Type(cdagger_mat) :: cdagger
    if(allocated(cdagger%c_p)) deallocate(cdagger%c_p)
    allocate(cdagger%c_p(cdagger%k_p,cdagger%l_p))
    cdagger%c_p=0.d0
  end subroutine

         !-------------------------!

  subroutine allocate_dagger_m(cdagger)
  implicit none
  Type(cdagger_mat) :: cdagger
    if(allocated(cdagger%c_m)) deallocate(cdagger%c_m)
    allocate(cdagger%c_m(cdagger%k_m,cdagger%l_m))
    cdagger%c_m=0.d0
  end subroutine

         !-------------------------!

end module

!####################################################!
!####################################################!
!####################################################!
!####################################################!
!####################################################!
!####################################################!
!####################################################!
!####################################################!
!####################################################!
!####################################################!
!####################################################!
!####################################################!
!####################################################!
!####################################################!
!####################################################!

program read_chi_loc
use chitilde
use cdagger
!use mpirout
!use init_and_close_my_sim
implicit none
complex(8)                          :: w1,w2,w3
real(8)                             :: w1r,w2r,w3r
integer                             :: min_up,max_up,min_dn,max_dn,nsector
integer,allocatable                 :: nup(:),ndn(:)
integer                             :: neigen,k,l
TYPE(eigen),allocatable             :: eigenval(:,:)
TYPE(cdagger_mat),allocatable       :: cup_mat(:,:,:),cdn_mat(:,:,:)
integer                             :: i,j
real(8)                             :: temp
real(8)                             :: PHI_EPS,beta,ZZ
integer                             :: nsites,op
integer                             :: dim_E_i
integer                             :: dim_E_pup
integer                             :: dim_E_pdn
integer                             :: dim_E_mup
integer                             :: dim_E_mdn
integer                             :: dim_E_p2dn
integer                             :: dim_E_m2dn
integer                             :: dim_E_puppdn
integer                             :: dim_E_muppdn
integer                             :: dim_E_pupmdn
integer                             :: dim_E_mupmdn
real(8),allocatable                 ::      cp_i_E(:)
real(8),allocatable                 ::    cp_pup_E(:)
real(8),allocatable                 ::    cp_pdn_E(:)
real(8),allocatable                 ::    cp_mup_E(:)
real(8),allocatable                 ::    cp_mdn_E(:)
real(8),allocatable                 ::   cp_p2dn_E(:)
real(8),allocatable                 ::   cp_m2dn_E(:)
real(8),allocatable                 :: cp_puppdn_E(:)
real(8),allocatable                 :: cp_muppdn_E(:)
real(8),allocatable                 :: cp_pupmdn_E(:)
real(8),allocatable                 :: cp_mupmdn_E(:)
integer                             :: n1,n2,n3,n4,n5,n6,n7,n8,n9,n10,n11,n12,n13,n14,n15,n16
integer                             :: n17,n18,n19,n20,n21,n22,n23,n24,n25,n26,n27,n28
real(8),allocatable                 ::      cp_i_cdup(:,:,:)
real(8),allocatable                 ::      cp_i_cddn(:,:,:)
real(8),allocatable                 ::    cp_pup_cddn(:,:,:)
real(8),allocatable                 ::    cp_pdn_cdup(:,:,:)
real(8),allocatable                 ::    cp_pdn_cddn(:,:,:)
real(8),allocatable                 ::    cp_mup_cdup(:,:,:)
real(8),allocatable                 ::    cp_mup_cddn(:,:,:)
real(8),allocatable                 ::    cp_mdn_cddn(:,:,:)
real(8),allocatable                 ::    cp_mdn_cdup(:,:,:)
real(8),allocatable                 :: cp_muppdn_cdup(:,:,:)
real(8),allocatable                 :: cp_pupmdn_cddn(:,:,:)
real(8),allocatable                 :: cp_mupmdn_cdup(:,:,:)
real(8),allocatable                 :: cp_mupmdn_cddn(:,:,:)
real(8),allocatable                 ::   cp_m2dn_cddn(:,:,:)
integer,allocatable                 :: neigentab(:,:)
complex(8)                          :: pDNDN,pUPDN

real(8)                             :: gs_E
real(8),allocatable                 :: minE_list(:)
real(8)                             :: Z_test
real(8)                             :: omega,nu,mu,rtmp,frequsum
integer :: ifrequsum,itmp
integer                             :: i_,j_
complex(8),allocatable              :: chi_loc(:,:,:,:,:,:),Chi0_loc(:,:,:,:,:,:),Chi0_spin_inv(:,:),Chi_spin_inv(:,:),Chi0_charge_inv(:,:),Chi_charge_inv(:,:)
complex(8),allocatable              :: Chi_charge(:,:,:,:,:),Chi_spin(:,:,:,:,:),Chi0_charge(:,:,:,:,:),Chi0_spin(:,:,:,:,:),Chi_vertex_spin(:,:,:,:,:),Chi_vertex_charge(:,:,:,:,:)
complex(8),allocatable              :: frequ_(:,:) ,frequ__(:,:)
real(8),allocatable                 :: mu_(:),nu_(:)
integer,allocatable                 :: frequ_ind(:,:),frequ_ind_orig(:,:)
logical,parameter                   :: verbose=.false.
integer                             :: norb
integer                             :: nmatsu
complex(8)                          :: tmpc
complex(8),allocatable              :: green(:,:,:)
real(8) :: t1,t2,t3,t4,t5,fac
integer :: omegai,nui,mui
real(8),allocatable :: omega_array(:)
integer :: nomega,start_omega
integer :: kkk_,kkk,lll_,Nc,k_,l_,k__,l__
real(8) :: spindeg,chargedeg,cutoff,cccc_cutoff,def,diff
logical :: path,swap_up_dn,roaming,vertex_gpu,impose_sym

   call init()

   call read_vertex()

   call swapupdn()

   call check_partition_function


   call read_frequ()

   call allocate_arrays()

   nu_ = 0.d0 ; mu_ = 0.d0 ; frequ_ = 0.d0 ; frequ__ = 0.d0 ; frequ_ind = 0 ; frequ_ind_orig=0

   do kkk_=1,nomega ! bosonic frequ


   call open_path_area_file ; call fix_frequency_table
   if(kkk_ < start_omega) cycle
   chargedeg = 1.d0 ;  spindeg = 1.d0

   chi_loc = 0.d0
   !$OMP PARALLEL
   ! if((rank == 0).and.(omp_get_thread_num()==0)) then
   !    print*,'nomega=',nomega
   !    print*,'cutoff=',cutoff
   !    print*,'cccc_cutoff=',cccc_cutoff
   !    print*,'nb of process=',size2
   !    print*,'nb of threads=',omp_get_num_threads()

   ! endif
   !$OMP END PARALLEL

   do op=1,2 ! dndn and updn terms
     if(rank==0) write(*,*) 'OMEGA / FREQ / TOT  = ', kkk_,i_,j_

     do i=1,nsector

       call loop_index_verbose
       call fix_dim
       call fix_bounds
       call allocate_cp
       call assign_cp_eigen
       call assign_cp_matrices


        call chi_tilde_loc( &
     &    cutoff, cccc_cutoff, op, PHI_EPS, beta, ZZ, gs_E, nsites, nup(i), ndn(i),  &
     &    cp_i_E,            dim_E_i,           cp_pup_E,          dim_E_pup,        &
     &    cp_pdn_E,          dim_E_pdn,         cp_mup_E,          dim_E_mup,        &
     &    cp_mdn_E,          dim_E_mdn,         cp_p2dn_E,         dim_E_p2dn,       &
     &    cp_m2dn_E,         dim_E_m2dn,        cp_puppdn_E,       dim_E_puppdn,     &
     &    cp_muppdn_E,       dim_E_muppdn,      cp_pupmdn_E,       dim_E_pupmdn,     &
     &    cp_mupmdn_E,       dim_E_mupmdn,      cp_i_cdup,         cp_i_cddn,        &
     &    cp_pup_cddn,       cp_pdn_cdup,       cp_pdn_cddn,       cp_mup_cdup,      &
     &    cp_mup_cddn,       cp_mdn_cddn,       cp_mdn_cdup,       cp_muppdn_cdup,   &
     &    cp_pupmdn_cddn,    cp_mupmdn_cdup,    cp_mupmdn_cddn,    cp_m2dn_cddn,     &
     &    j_,frequ_,rank,size2,chi_loc )

          if(verbose)then
           if(op==1) write(*,*) 'pDNDN = ', pDNDN
           if(op==2) write(*,*) 'pUPDN = ', pUPDN
        endif

     enddo !sector
  enddo ! dndn or updn

    do k_=1,norb
     do l_=1,norb
      call mpisum(chi_loc(k_,l_,:,:,:,:))
     enddo
    enddo

    Chi_charge = ( chi_loc(:,:,:,:,:,1)+chi_loc (:,:,:,:,:,2) )/chargedeg
    Chi_spin   = ( chi_loc(:,:,:,:,:,1)-chi_loc (:,:,:,:,:,2) )/spindeg
    if(rank == 0) call write_chiloc


   if(rank==0) write(*,*)'NEXT OMEGA , RANK : ', rank

  enddo ! omega

  if(rank==0)then
      close(880)
      close(881)
  endif

  call finalize_my_simulation

contains




subroutine fix_frequency_table
      do i_=1,j_  ! number of fermionic frequ
         if(kkk_==1) then
              read(4848, *) mu,nu
              mu=mu*pi/beta
              nu=nu*pi/beta
              mu_(i_)=mu
              nu_(i_)=nu
              if(abs(mu)<1.d-5.or.abs(nu)<1.d-5)then
               write(*,*) 'ERROR ZERO FERMIONIC FREQU'
               write(*,*) 'mu , nu : ', mu,nu
               stop
              endif
           else
              mu=mu_(i_)
              nu=nu_(i_)
           endif

           omega=omega_array(kkk_)


           if(roaming)then
              if( modulo(kkk_,2) == 1) then
                 mu=mu- (dble(kkk_-1) * pi / beta )
                 nu=nu -(dble(kkk_-1) * pi / beta )
              else
                 mu=mu- (dble(kkk_-2) * pi / beta )
                 nu=nu - (dble(kkk_-2) * pi / beta )
              endif
           endif

          if(path)then
           w1r=  mu+omega
           w2r= -mu
           w3r=  nu
          else
           w1r=  mu+omega
           w2r= -mu !BUGGGGGGGGGGG
           w3r=  nu
          endif

           if(verbose) write(*,*) "w1r, w2r, w3r = ", w1r, w2r, w3r

           frequ_(i_,1)    = CMPLX(0.0, w1r)
           frequ_(i_,2)    = CMPLX(0.0, w2r)
           frequ_(i_,3)    = CMPLX(0.0, w3r)
           frequ__(i_,1)   = CMPLX(0.0, omega)
           frequ__(i_,2)   = CMPLX(0.0, mu)
           frequ__(i_,3)   = CMPLX(0.0, nu)
           frequ_ind(i_,1) = NINT( omega * beta/pi /2.0 )

           if(abs(mu)<1.d-6.or.abs(nu)<1.d-6)then
             write(*,*) 'error, not fermionic frequ';stop
           endif

           if(mu>0)then
             frequ_ind(i_,2)= NINT( (mu    * beta/pi +1.0 ) /2.0 )
           else
             frequ_ind(i_,2)= NINT( (mu    * beta/pi -1.0 ) /2.0 )
           endif
           if(nu>0)then
             frequ_ind(i_,3)= NINT( (nu    * beta/pi +1.0 ) /2.0 )
           else
             frequ_ind(i_,3)= NINT( (nu    * beta/pi -1.0 ) /2.0 )
           endif

           if(verbose) write(*,*) "int indices : ", (frequ_ind(i_,j),j=1,3)
      enddo
      if(kkk_==1) frequ_ind_orig=frequ_ind
      if(kkk_==1) close(4848)

end subroutine


subroutine read_vertex()
     open(unit=1414,file='c_transition',form='unformatted')
     read(1414)  !header

     do lll_=1,Nc
     do i=1,nsector
       if(verbose) write(*,*) '!########################################'
       if(verbose) write(*,*) 'reading sector / nsector: ', i,nsector
       read(1414) kkk,nup(i),ndn(i)
       read(1414) neigen
       neigentab(nup(i),ndn(i))=neigen
       if(neigen==0)then
         write(*,*) 'zero eigenstates in sector'
         stop
       endif
       if(verbose) write(*,*) 'reading : i,nsector,neigen: ', i,nsector,neigen
       if(neigen<0)then
        write(*,*) 'negative neigen, error : ' , neigen
        stop
       endif

       if(lll_==1) allocate(eigenval(nup(i),ndn(i))%val(neigen))
       read(1414) eigenval(nup(i),ndn(i))%val
       minE_list(i)=minval(eigenval(nup(i),ndn(i))%val)

       if(verbose)then
        write(*,*) 'nup,ndn,Nc                    : ',nup(i),ndn(i),norb
        write(*,'(a,200f9.3)') 'eigenvals         : ',eigenval(nup(i),ndn(i))%val
        write(*,'(a,f9.3)') 'the lowest energy is : ', minE_list(i)
       endif
       if(kkk/=lll_)then
         write(*,*) 'error mismatch orbital argument in vertex file and post-processing'
         write(*,*) 'kkk,lll_ : ', kkk,lll_
         stop
       endif
       read(1414) k,l
       cup_mat(kkk,nup(i),ndn(i))%k_p=k
       cup_mat(kkk,nup(i),ndn(i))%l_p=l
       call allocate_dagger_p(cup_mat(kkk,nup(i),ndn(i)))
       read(1414) cup_mat(kkk,nup(i),ndn(i))%c_p

       cup_mat(kkk,nup(i),ndn(i))%c_p=cup_mat(kkk,nup(i),ndn(i))%c_p*( (-1)**( ndn(i)  )  )

       read(1414) k,l
       cup_mat(kkk,nup(i),ndn(i))%k_m=k
       cup_mat(kkk,nup(i),ndn(i))%l_m=l
       call allocate_dagger_m(cup_mat(kkk,nup(i),ndn(i)))
       read(1414) cup_mat(kkk,nup(i),ndn(i))%c_m

       cup_mat(kkk,nup(i),ndn(i))%c_m=cup_mat(kkk,nup(i),ndn(i))%c_m*( (-1)**( ndn(i)  )  )

       read(1414) k,l
       cdn_mat(kkk,nup(i),ndn(i))%k_p=k
       cdn_mat(kkk,nup(i),ndn(i))%l_p=l
       call allocate_dagger_p(cdn_mat(kkk,nup(i),ndn(i)))
       read(1414) cdn_mat(kkk,nup(i),ndn(i))%c_p

       read(1414) k,l
       cdn_mat(kkk,nup(i),ndn(i))%k_m=k
       cdn_mat(kkk,nup(i),ndn(i))%l_m=l
       call allocate_dagger_m(cdn_mat(kkk,nup(i),ndn(i)))
       read(1414) cdn_mat(kkk,nup(i),ndn(i))%c_m

     enddo
     enddo
     close(1414)

    if(minval(neigentab)<0)then
      if(rank==0) write(*,*) 'WARNING SOME UP-DO SECTORS NOT TAKEN INTO ACCOUNT'
      write(*,*) minloc(neigentab)
    endif
    if(rank==0) write(*,*) 'minval maxval nup,ndn', minval(nup),maxval(nup)

end subroutine

subroutine init
     call initialize_my_simulation
     open(unit=10001,file='cutoff')
     read(10001,*) start_omega
     read(10001,*) nomega
     read(10001,*) cutoff
     read(10001,*) cccc_cutoff

     !call init_gpu_device
     !call test_cuda_c !BUGGGGG
     !stop

     PHI_EPS=0.00001
     def=0.d0
     path=.true.

     if(path) then
       roaming=.true.
       vertex_gpu=.false.
     else
       roaming=.true.
       vertex_gpu=.true.
     endif

     impose_sym=.false.
     swap_up_dn=.false.

     open(unit=1414,file='c_transition',form='unformatted')
     read(1414) Nc,ZZ,beta,nsites,min_up,max_up,min_dn,max_dn,nsector
     close(1414)
     norb=Nc

     write(*,*) 'partition function : ', ZZ
     write(*,*) 'beta               : ', beta
     write(*,*) 'nsites             : ', nsites
     write(*,*) 'nsector            : ', nsector
     write(*,*) 'up dn min max      : ', min_up,max_up,min_dn,max_dn
     allocate(omega_array(nomega))
     open(unit=880,file='vertex_charge_sum')
     open(unit=881,file='vertex_spin_sum')

     ! if(roaming)then
     !  do i=1,nomega
     !   omega_array(i)= 2.d0 * ( 2.d0*dble(i-1) * pi / beta )
     !  enddo
     ! else
        do i=1,nomega
           omega_array(i)= 1.d0 * ( 2.d0*dble(i-1) * pi / beta )
      enddo
!     endif

     allocate(nup(nsector),ndn(nsector))
     if(allocated(cup_mat)) deallocate(cup_mat)
     if(allocated(cdn_mat)) deallocate(cdn_mat)
     allocate(cup_mat(Nc,min_up:max_up,min_dn:max_dn))
     allocate(cdn_mat(Nc,min_up:max_up,min_dn:max_dn))
     allocate(eigenval(min_up:max_up,min_dn:max_dn))
     allocate(neigentab(min_up:max_up,min_dn:max_dn))

     if(verbose) write(*,*) 'start reading'
     allocate(minE_list(nsector))
     neigentab=-1
     nup=0
     ndn=0
end subroutine

subroutine swapupdn
     if(swap_up_dn)then
     do kkk=1,Nc
      do i=1,nsector
       call swap_A_B(cdn_mat(kkk,nup(i),ndn(i))%c_p,cup_mat(kkk,ndn(i),nup(i))%c_p)
       call swap_A_B(cdn_mat(kkk,nup(i),ndn(i))%c_m,cup_mat(kkk,ndn(i),nup(i))%c_m)
      enddo
     enddo
     endif
end subroutine


subroutine read_frequ
     if(path)then
     open(unit=4848, file="omega_list_path", form="formatted")
     else
     open(unit=4848, file="omega_list_area", form="formatted")
     endif
     j_=0
     do
      read(4848, *,end=871) mu,nu
      j_=j_+1
     enddo
   871 continue
     close(4848)

     if(rank==0) write(*,*) 'THERE ARE [x] FREQUENCIES IN FILE : ', j_
end subroutine


subroutine allocate_arrays
     if(rank==0) write(*,*) 'allocating chi_loc array'
     if(allocated(chi_loc))           deallocate(chi_loc)
     if(allocated(Chi0_loc))          deallocate(Chi0_loc)
     if(allocated(mu_))               deallocate(mu_)
     if(allocated(nu_))               deallocate(nu_)
     if(allocated(Chi_vertex_spin))   deallocate(Chi_vertex_spin)
     if(allocated(Chi_vertex_charge)) deallocate(Chi_vertex_charge)
     if(allocated(Chi0_charge))       deallocate(Chi0_charge)
     if(allocated(Chi_charge))        deallocate(Chi_charge)
     if(allocated(Chi_spin))          deallocate(Chi_spin)
     if(allocated(Chi0_spin))         deallocate(Chi0_spin)
     allocate(Chi0_charge(j_,norb,norb,norb,norb),Chi_charge(norb,norb,norb,norb,j_),Chi_spin(norb,norb,norb,norb,j_),Chi0_spin(j_,norb,norb,norb,norb))
     allocate(Chi_vertex_spin(norb,norb,norb,norb,j_),Chi_vertex_charge(norb,norb,norb,norb,j_))
     allocate(mu_(j_),nu_(j_),frequ_(j_,3),frequ__(j_,3))
     allocate(chi_loc(norb,norb,norb,norb,j_,2))
     allocate(frequ_ind_orig(j_,3),frequ_ind(j_,3),Chi0_loc(norb,norb,norb,norb,j_,2))
end subroutine


subroutine fix_dim
        dim_E_i= neigentab(nup(i), ndn(i))

    if (nup(i)+1 > max_up ) then
        dim_E_pup= -1
    else
        dim_E_pup= neigentab(nup(i)+1, ndn(i))
    end if
! dim_E_pdn
    if (ndn(i)+1 > max_dn) then
        dim_E_pdn= -1
    else
        dim_E_pdn= neigentab(nup(i), ndn(i)+1)
    end if
! dim_E_mup
    if (nup(i)-1 < min_up) then
        dim_E_mup= -1
    else
        dim_E_mup= neigentab(nup(i)-1, ndn(i))
    end if
! dim_E_mdn
    if (ndn(i)-1 < min_dn) then
        dim_E_mdn= -1
    else
        dim_E_mdn= neigentab(nup(i), ndn(i)-1)
    end if
! dim_E_p2dn
    if (ndn(i)+2 > max_dn) then
        dim_E_p2dn= -1
    else
        dim_E_p2dn= neigentab(nup(i), ndn(i)+2)
    end if
! dim_E_m2dn
    if (ndn(i)-2 < min_dn) then
        dim_E_m2dn= -1
    else
        dim_E_m2dn= neigentab(nup(i), ndn(i)-2)
    end if
! dim_E_puppdn
    if (nup(i)+1 > max_up .or. ndn(i)+1 > max_dn) then
        dim_E_puppdn= -1
    else
        dim_E_puppdn= neigentab(nup(i)+1, ndn(i)+1)
    end if
! dim_E_muppdn
    if (nup(i)-1 < min_up .or. ndn(i)+1 > max_dn) then
        dim_E_muppdn= -1
    else
        dim_E_muppdn= neigentab(nup(i)-1, ndn(i)+1)
    end if
! dim_E_pupmdn
    if (nup(i)+1 > max_up .or. ndn(i)-1 < min_dn) then
        dim_E_pupmdn= -1
    else
        dim_E_pupmdn= neigentab(nup(i)+1, ndn(i)-1)
    end if
! dim_E_mupmdn
    if (nup(i)-1 < min_up .or. ndn(i)-1 < min_dn) then
        dim_E_mupmdn= -1
    else
        dim_E_mupmdn= neigentab(nup(i)-1, ndn(i)-1)
    end if
end subroutine

subroutine fix_bounds
! dim_E_i
   if(dim_E_i == - 1)then
      n2=1; n4=1; n11=1; n15=1
   else
      n2=dim_E_i; n4=dim_E_i; n11=dim_E_i; n15=dim_E_i
   endif
! dim_E_pup
    if (dim_E_pup == -1) then
        n1=1; n6=1; n21=1
    else
        n1=dim_E_pup; n6=dim_E_pup; n21=dim_E_pup
    end if
! dim_E_pdn
    if (dim_E_pdn == -1) then
        n3=1; n8=1; n10=1; n19=1
    else
        n3=dim_E_pdn; n8=dim_E_pdn; n10=dim_E_pdn; n19=dim_E_pdn
    end if
! dim_E_mup
    if (dim_E_mup == -1) then
        n12=1; n14=1; n25=1
    else
        n12=dim_E_mup; n14=dim_E_mup; n25=dim_E_mup
    end if
! dim_E_mdn
    if (dim_E_mdn == -1) then
        n16=1; n18=1; n23=1; n27=1
    else
        n16=dim_E_mdn; n18=dim_E_mdn; n23=dim_E_mdn; n27=dim_E_mdn
    end if
! dim_E_p2dn
    if (dim_E_p2dn == -1) then
        n9=1
    else
        n9=dim_E_p2dn
    end if
! dim_E_m2dn
    if (dim_E_m2dn == -1) then
        n28=1
    else
        n28=dim_E_m2dn
    end if
! dim_E_puppdn
    if (dim_E_puppdn == -1) then
        n5=1; n7=1
    else
        n5=dim_E_puppdn; n7=dim_E_puppdn
    end if
! dim_E_muppdn
    if (dim_E_muppdn == -1) then
        n13=1; n20=1
    else
        n13=dim_E_muppdn; n20=dim_E_muppdn
    end if
! dim_E_pupmdn
    if (dim_E_pupmdn == -1) then
        n17=1; n22=1
    else
        n17=dim_E_pupmdn; n22=dim_E_pupmdn
    end if
! dim_E_mupmdn
    if (dim_E_mupmdn == -1) then
        n24=1; n26=1
    else
        n24=dim_E_mupmdn; n26=dim_E_mupmdn
    end if

end subroutine

subroutine allocate_cp()

     if(allocated(cp_i_E)) deallocate( &
& cp_i_E, cp_pup_E, cp_pdn_E, cp_mup_E, cp_mdn_E, cp_p2dn_E, cp_m2dn_E, cp_puppdn_E, &
& cp_muppdn_E, cp_pupmdn_E, cp_mupmdn_E, cp_i_cdup,cp_i_cddn,                        &
& cp_pup_cddn, cp_pdn_cdup, cp_pdn_cddn, cp_mup_cdup, cp_mup_cddn, cp_mdn_cddn,      &
& cp_mdn_cdup, cp_muppdn_cdup, cp_pupmdn_cddn, cp_mupmdn_cdup, cp_mupmdn_cddn, cp_m2dn_cddn)

!################################################
! allocate arrays of eigenvalues ################
     ! ###############################################
     allocate(      cp_i_E(max( dim_E_i     ,1 )  ) )
     allocate(    cp_pup_E(max( dim_E_pup   ,1 )  ) )
     allocate(    cp_pdn_E(max( dim_E_pdn   ,1 )  ) )
     allocate(    cp_mup_E(max( dim_E_mup   ,1 )  ) )
     allocate(    cp_mdn_E(max( dim_E_mdn   ,1 )  ) )
     allocate(   cp_p2dn_E(max( dim_E_p2dn  ,1 )  ) )
     allocate(   cp_m2dn_E(max( dim_E_m2dn  ,1 )  ) )
     allocate( cp_puppdn_E(max( dim_E_puppdn,1 )  ) )
     allocate( cp_muppdn_E(max( dim_E_muppdn,1 )  ) )
     allocate( cp_pupmdn_E(max( dim_E_pupmdn,1 )  ) )
     allocate( cp_mupmdn_E(max( dim_E_mupmdn,1 )  ) )
!#######################################
! allocate of c^dagger matrices ########
!#######################################
     allocate( cp_i_cdup     (norb, n1, n2) )
     allocate( cp_i_cddn     (norb, n3, n4) )
     allocate( cp_pup_cddn   (norb, n5, n6) )
     allocate( cp_pdn_cdup   (norb, n7, n8) )
     allocate( cp_pdn_cddn   (norb, n9,n10) )
     allocate( cp_mup_cdup   (norb,n11,n12) )
     allocate( cp_mup_cddn   (norb,n13,n14) )
     allocate( cp_mdn_cddn   (norb,n15,n16) )
     allocate( cp_mdn_cdup   (norb,n17,n18) )
     allocate( cp_muppdn_cdup(norb,n19,n20) )
     allocate( cp_pupmdn_cddn(norb,n21,n22) )
     allocate( cp_mupmdn_cdup(norb,n23,n24) )
     allocate( cp_mupmdn_cddn(norb,n25,n26) )
     allocate( cp_m2dn_cddn  (norb,n27,n28) )
end subroutine

subroutine assign_cp_eigen
!########################################
! assignment of lists of eigenvalues ####
!########################################
     if( dim_E_i  == -1)then
         cp_i_E   = def
     else
         call test_shapev(cp_i_E, eigenval(nup(i), ndn(i))%val)
         cp_i_E   = eigenval(nup(i), ndn(i))%val
     endif
     if (dim_E_pup == -1) then
         cp_pup_E = def
     else
         call test_shapev( cp_pup_E , eigenval(nup(i)+1, ndn(i))%val)
         cp_pup_E = eigenval(nup(i)+1, ndn(i))%val
     end if
     if (dim_E_pdn == -1) then
         cp_pdn_E = def
     else
         call test_shapev(cp_pdn_E , eigenval(nup(i), ndn(i)+1)%val)
         cp_pdn_E = eigenval(nup(i), ndn(i)+1)%val
     end if
     if (dim_E_mup == -1) then
         cp_mup_E = def
     else
         call test_shapev( cp_mup_E , eigenval(nup(i)-1, ndn(i))%val)
         cp_mup_E = eigenval(nup(i)-1, ndn(i))%val
     end if
     if (dim_E_mdn == -1) then
         cp_mdn_E = def
     else
         call test_shapev(cp_mdn_E , eigenval(nup(i), ndn(i)-1)%val)
         cp_mdn_E = eigenval(nup(i), ndn(i)-1)%val
     end if
     if (dim_E_p2dn == -1) then
         cp_p2dn_E = def
     else
         call test_shapev( cp_p2dn_E , eigenval(nup(i), ndn(i)+2)%val)
         cp_p2dn_E = eigenval(nup(i), ndn(i)+2)%val
     end if
     if (dim_E_m2dn == -1) then
         cp_m2dn_E = def
     else
         call test_shapev(cp_m2dn_E , eigenval(nup(i), ndn(i)-2)%val)
         cp_m2dn_E = eigenval(nup(i), ndn(i)-2)%val
     end if
     if (dim_E_puppdn == -1) then
         cp_puppdn_E = def
     else
         call test_shapev(cp_puppdn_E , eigenval(nup(i)+1, ndn(i)+1)%val)
         cp_puppdn_E = eigenval(nup(i)+1, ndn(i)+1)%val
     end if
     if (dim_E_muppdn == -1) then
         cp_muppdn_E = def
     else
         call test_shapev(cp_muppdn_E , eigenval(nup(i)-1, ndn(i)+1)%val)
         cp_muppdn_E = eigenval(nup(i)-1, ndn(i)+1)%val
     end if
     if (dim_E_pupmdn == -1) then
         cp_pupmdn_E = def
     else
         call test_shapev(cp_pupmdn_E , eigenval(nup(i)+1, ndn(i)-1)%val)
         cp_pupmdn_E = eigenval(nup(i)+1, ndn(i)-1)%val
     end if
     if (dim_E_mupmdn == -1) then
         cp_mupmdn_E = def
     else
         call test_shapev(cp_mupmdn_E,eigenval(nup(i)-1, ndn(i)-1)%val)
         cp_mupmdn_E = eigenval(nup(i)-1, ndn(i)-1)%val
     end if
end subroutine

subroutine assign_cp_matrices
implicit none
integer :: llll_
!########################################
! assignment of c^dagger matrices #######
!########################################
do llll_=1,norb
! cp_i_cdup
     if (dim_E_pup == -1) then
         cp_i_cdup = def
     else
         cp_i_cdup(llll_,:,:) = cup_mat(llll_,nup(i),ndn(i))%c_p
     end if
! cp_i_cddn
     if (dim_E_pdn == -1) then
         cp_i_cddn = def
     else
         cp_i_cddn(llll_,:,:) = cdn_mat(llll_,nup(i),ndn(i))%c_p
     end if
! cp_pup_cddn
     if (dim_E_puppdn == -1 .or. dim_E_pup == -1) then
         cp_pup_cddn = def
     else
         cp_pup_cddn(llll_,:,:) = cdn_mat(llll_,nup(i)+1,ndn(i))%c_p
     end if
! cp_pdn_cdup
     if (dim_E_puppdn==-1 .or. dim_E_pdn==-1) then
         cp_pdn_cdup = def
     else
         cp_pdn_cdup(llll_,:,:) = cup_mat(llll_,nup(i),ndn(i)+1)%c_p
     end if
! cp_pdn_cddn
     if (dim_E_p2dn==-1 .or. dim_E_pdn==-1) then
         cp_pdn_cddn = def
     else
         cp_pdn_cddn(llll_,:,:) = cdn_mat(llll_,nup(i),ndn(i)+1)%c_p
     end if
! cp_mup_cdup
     if (dim_E_mup==-1 ) then
         cp_mup_cdup = def
     else
         cp_mup_cdup(llll_,:,:) = cup_mat(llll_,nup(i)-1,ndn(i))%c_p
     end if
! cp_mup_cddn
     if (dim_E_muppdn==-1 .or. dim_E_mup==-1) then
         cp_mup_cddn = def
     else
         cp_mup_cddn(llll_,:,:) = cdn_mat(llll_,nup(i)-1,ndn(i))%c_p
     end if
! cp_mdn_cddn
     if (dim_E_mdn==-1) then
         cp_mdn_cddn = def
     else
         cp_mdn_cddn(llll_,:,:) = cdn_mat(llll_,nup(i),ndn(i)-1)%c_p
     end if
! cp_mdn_cdup
     if (dim_E_pupmdn==-1 .or. dim_E_mdn==-1) then
         cp_mdn_cdup = def
     else
         cp_mdn_cdup(llll_,:,:) = cup_mat(llll_,nup(i),ndn(i)-1)%c_p
     end if
! cp_muppdn_cdup
     if (dim_E_pdn==-1 .or. dim_E_muppdn==-1) then
         cp_muppdn_cdup = def
     else
         cp_muppdn_cdup(llll_,:,:) = cup_mat(llll_,nup(i)-1,ndn(i)+1)%c_p
     end if
! cp_pupmdn_cddn
     if (dim_E_pup==-1 .or. dim_E_pupmdn==-1) then
         cp_pupmdn_cddn = def
     else
         cp_pupmdn_cddn(llll_,:,:) = cdn_mat(llll_,nup(i)+1,ndn(i)-1)%c_p
     end if
! cp_mupmdn_cdup
     if (dim_E_mdn==-1 .or. dim_E_mupmdn==-1) then
         cp_mupmdn_cdup = def
     else
         cp_mupmdn_cdup(llll_,:,:) = cup_mat(llll_,nup(i)-1,ndn(i)-1)%c_p
     end if
! cp_mupmdn_cddn
     if (dim_E_mup==-1 .or. dim_E_mupmdn==-1) then
         cp_mupmdn_cddn = def
     else
         cp_mupmdn_cddn(llll_,:,:) = cdn_mat(llll_,nup(i)-1,ndn(i)-1)%c_p
     end if
! cp_m2dn_cddn
     if (dim_E_mdn==-1 .or. dim_E_m2dn==-1) then
         cp_m2dn_cddn = def
     else
         cp_m2dn_cddn(llll_,:,:) = cdn_mat(llll_,nup(i),ndn(i)-2)%c_p
     end if
  end do
end subroutine

subroutine check_partition_function
    gs_E = minval(minE_list)
    if(verbose) write(*,*) 'Ground state energy=', gs_E
    Z_test = 0.0
    do i=1,nsector
        neigen=neigentab(nup(i),ndn(i))
        do j=1,neigen
           Z_test=Z_test+exp(-beta*(eigenval(nup(i),ndn(i))%val(j)-gs_E))
        enddo
    enddo
    if(rank==0) write(*,*) 'partition function gsE =', Z_test
    if(rank==0) write(*,*) 'partition function ZZ  =', ZZ
    if(rank==0) write(*,*) 'ratio ZZ               =', ZZ/Z_test
    if(rank==0) write(*,*) 'ratio ZZ               =', Z_test/ZZ
    if(rank==0) write(*,*) 'e^-B_G0                =', exp(beta*gs_E)
    if(rank==0) write(*,*) 'nsector                =', nsector
end subroutine

subroutine open_path_area_file
   if(kkk_==1) then  ! first omega we read the fermionic frequ from file
     if(path)then
       open(unit=4848, file="omega_list_path", form="formatted")
     else
       open(unit=4848, file="omega_list_area", form="formatted")
     endif
    endif

  end subroutine open_path_area_file

subroutine write_chiloc
  integer :: om,i1,i2,i3,i4,u1,u2
  do  i1 = 1, norb
     do  i2 = 1, norb
        do  i3 = 1, norb
           do  i4 = 1, norb
              ! open(unit=8080,file='chiloc_spin_'//adjustl(trim(toString(kkk_)))//'_'//adjustl(trim(toString(i1)))//adjustl(trim(toString(i2)))//adjustl(trim(toString(i3)))//adjustl(trim(toString(i4))))
              ! open(unit=8081,file='chiloc_charge_'//adjustl(trim(toString(kkk_)))//'_'//adjustl(trim(toString(i1)))//adjustl(trim(toString(i2)))//adjustl(trim(toString(i3)))//adjustl(trim(toString(i4))))
              open(unit=8080,file='G2_uuuu_'//adjustl(trim(toString(kkk_)))//'_'//adjustl(trim(toString(i1)))//adjustl(trim(toString(i2)))//adjustl(trim(toString(i3)))//adjustl(trim(toString(i4))))
              open(unit=8081,file='G2_uudd_'//adjustl(trim(toString(kkk_)))//'_'//adjustl(trim(toString(i1)))//adjustl(trim(toString(i2)))//adjustl(trim(toString(i3)))//adjustl(trim(toString(i4))))
              do om = 1, j_
                 write(8080,*) real(chi_loc(i1,i2,i3,i4,om,1)),aimag(chi_loc(i1,i2,i3,i4,om,1))
                 write(8081,*) real(chi_loc(i1,i2,i3,i4,om,2)),aimag(chi_loc(i1,i2,i3,i4,om,2))
              enddo
              close(8080)
              close(8081)
           enddo
        enddo
     enddo
  enddo
end subroutine write_chiloc

subroutine loop_index_verbose
         if(verbose.or.mod(i,30)==0)then
          if(rank==0) write(*,*) 'sector    : ', i, nsector
          if(verbose) write(*,*) 'neigentab : ', neigentab
         endif
end subroutine

end program
