
MODULE readable_vec_class

  USE fermion_ket_class
  use common_def

  IMPLICIT NONE


  REAL(DBL),    PARAMETER, private                 :: zero=0.0_DBL,one=1.0_DBL,two=2.0_DBL,three=3.0_DBL,four=4.0_DBL
  LOGICAL,      PARAMETER, private                 :: F=.FALSE.,T=.TRUE.


  !-----------------------!
  ! KETS IN READABLE FORM !
  !-----------------------!


  TYPE readable_vec_type
    INTEGER                    :: nket   = 0 ! number of components
    CHARACTER(LEN=100)         :: title  = '\0'
    REAL(DBL)                  :: weight = zero
    COMPLEX(DBL),      POINTER :: coeff(:) => NULL()
    CHARACTER(LEN=10), POINTER :: cket(:)  => NULL()
    INTEGER,           POINTER :: state(:) => NULL()
  END TYPE


  INTERFACE new_readable_vec
    MODULE PROCEDURE new_readable_vec_from_scratch
    MODULE PROCEDURE new_readable_vec_from_old
  END INTERFACE



CONTAINS


!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************


  SUBROUTINE new_readable_veclist_from_file(list,UNIT,iorb,NAMBU,nvecout) 

    TYPE(readable_vec_type), POINTER    :: list(:) 
    INTEGER,                 INTENT(IN) :: UNIT
    INTEGER,                 INTENT(IN) :: iorb(:,:)
    LOGICAL, OPTIONAL,       INTENT(IN) :: NAMBU
    INTEGER                             :: ivec,nvec,shift_,iket,nket,imin,imax,jmax
    CHARACTER(LEN=600)                  :: cket_list,prefactor
    COMPLEX(DBL), ALLOCATABLE           :: fac(:)
    LOGICAL                             :: nambu_
    integer                             :: ff,nvecout


    IF(ASSOCIATED(list)) DEALLOCATE(list)

    !------------------------------------------------------!    
    ! READ IMPURITY STATES WHOSE WEIGHT WE WANT TO COMPUTE !
    !------------------------------------------------------!

    CALL skip_line(UNIT,3)
    NULLIFY(list)
    READ(UNIT,*) nvec
    nvecout=nvec

  if(nvec>0)then

    ALLOCATE(list(nvec))
    DO ivec=1,nvec
      READ(UNIT,*) cket_list
      write(*,*) 'reading quantum vector input : ', TRIM(ADJUSTL(cket_list))
      nket   = -1   
      shift_ =  1
      cket_list = TRIM(ADJUSTL(cket_list))
      ! COUNT THE NUMBER OF BASIS STATES
      DO WHILE(SCAN(cket_list(shift_:),'|')/=0)
        nket    = nket + 1
        shift_  = shift_ + SCAN(cket_list(shift_:),'>') + 1 
      END DO
      ! ALLOCATE ARRAY OF IRRATIONAL PREFACTORS
      IF(ALLOCATED(fac)) DEALLOCATE(fac)
      ALLOCATE(fac(0:nket))
      fac    = one
      shift_ = 1
      DO iket=0,nket
        ! FIRST WE READ THE BASIS STATE (ENCLOSED IN |...>)
        imin = SCAN(cket_list(shift_:),'|')
        imax = SCAN(cket_list(shift_:),'>')
        IF(iket==0)THEN ! THE FIRST STATE IS THE NAME OF THE REFERENCE VECTOR
          CALL new_readable_vec(list(ivec),cket_list(shift_+imin-1:shift_+imax-1),nket)
        ELSE
          list(ivec)%cket (iket) = cket_list(shift_+imin-1:shift_+imax-1) 
          list(ivec)%state(iket) = state_from_cket(list(ivec)%cket(iket),iorb,NAMBU=NAMBU)
          IF(list(ivec)%state(iket)<0)THEN
            list(ivec)%state(iket) = - list(ivec)%state(iket)
            fac(iket)              = - one
          END IF
          write(*,*) 'quantum vector : ', TRIM(ADJUSTL(list(ivec)%cket(iket))),list(ivec)%state(iket),fac(iket)
        END IF
        ! THEN WE READ THE EVENTUAL IRRATIONAL PREFACTORS
        jmax = SCAN(cket_list(shift_:shift_+imin-1),'*')
        IF(jmax>2)THEN
          prefactor = cket_list(shift_:shift_+jmax-2)
          SELECT CASE(TRIM(ADJUSTL(prefactor)))
            CASE('s2')
              fac(iket) = fac(iket) * s2
            CASE('s3')
              fac(iket) = fac(iket) * s3
            CASE('s6')
              fac(iket) = fac(iket) * s6
            CASE('i')
              fac(iket) = fac(iket) * imi
            CASE('j')
              fac(iket) = fac(iket) * jimi
            CASE('j2')
              fac(iket) = fac(iket) * jimi**2
          END SELECT
        END IF
        shift_ = shift_ + imax + 1
      END DO
      READ(UNIT,*) list(ivec)%coeff
      list(ivec)%coeff = list(ivec)%coeff * fac(1:nket) / fac(0)
    END DO
    DEALLOCATE(fac)

  endif

  END SUBROUTINE

!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************



  SUBROUTINE write_readable_veclist(list,UNIT)
    TYPE(readable_vec_type),     POINTER    :: list(:) 
    INTEGER,  OPTIONAL,          INTENT(IN) :: UNIT
    INTEGER :: unit_,ivec
    unit_ = log_unit
    IF(PRESENT(UNIT)) unit_ = UNIT
    DO ivec=1,SIZE(list)
      WRITE(unit_,'(a,f0.12)') "# "//TRIM(ADJUSTL(list(ivec)%title))//"   ",list(ivec)%weight
    END DO
  END SUBROUTINE


!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************



  SUBROUTINE new_readable_vec_from_scratch(vec,title,nket) 
    TYPE(readable_vec_type), INTENT(INOUT) :: vec
    INTEGER,                 INTENT(IN)    :: nket
    CHARACTER(LEN=*),        INTENT(IN)    :: title
    vec%title  = TRIM(ADJUSTL(title))
    vec%weight = zero
    vec%nket   = nket
    ALLOCATE(vec%coeff(nket))
    vec%coeff  = zero
    ALLOCATE(vec%cket(nket))
    ALLOCATE(vec%state(nket))
    vec%state  = -1
  END SUBROUTINE 


!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************


  SUBROUTINE new_readable_vec_from_old(VECOUT,VECIN) 
    TYPE(readable_vec_type), INTENT(INOUT) :: VECOUT
    TYPE(readable_vec_type), INTENT(IN)    :: VECIN
    INTEGER :: iket
    CALL new_readable_vec_from_scratch(VECOUT,VECIN%title,VECIN%nket)
    VECOUT%weight = VECIN%weight
    VECOUT%coeff  = VECIN%coeff
    DO iket=1,VECOUT%nket
      VECOUT%cket(iket) = TRIM(ADJUSTL(VECIN%cket(iket)))
    END DO
    VECOUT%state = VECIN%state
  END SUBROUTINE 

!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************



  SUBROUTINE delete_readable_vec(vec)
    TYPE(readable_vec_type), INTENT(INOUT) :: vec
    IF(ASSOCIATED(vec%coeff)) DEALLOCATE(vec%coeff)
    IF(ASSOCIATED(vec%cket))  DEALLOCATE(vec%cket)
    IF(ASSOCIATED(vec%state)) DEALLOCATE(vec%state)
  END SUBROUTINE

!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************


  SUBROUTINE delete_readable_veclist(list)
    TYPE(readable_vec_type), POINTER :: list(:) 
    INTEGER :: ivec
    DO ivec=1,SIZE(list)
      CALL delete_readable_vec(list(ivec))
    END DO
    IF(ASSOCIATED(list)) DEALLOCATE(list)
  END SUBROUTINE


!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************


  FUNCTION cket_from_state(state,iorb,NAMBU) RESULT(cket) 
    INTEGER,           INTENT(IN) :: iorb(:,:)
    CHARACTER(LEN=SIZE(iorb,1)+2) :: cket    ! OUTPUT KET IN WRITEABLE FORM
    INTEGER,           INTENT(IN) :: state   ! OCCUPATION NUMBER OF THE IMPURITY ORBITALS (site,spin)
    LOGICAL, OPTIONAL, INTENT(IN) :: NAMBU
    TYPE(fermion_ket_type) :: ket
    LOGICAL :: nambu_,bn(2)
    INTEGER :: site,Nc,npart
    Nc      = SIZE(iorb,1)
    cket    = '|'
    nambu_ = F
    IF(PRESENT(NAMBU)) nambu_ = NAMBU
    CALL new_ket_from_state(ket,state,SIZE(iorb))
    DO site=1,Nc
      IF(nambu_)THEN
        bn = (/is_occupied(iorb(site,1),ket),.NOT.is_occupied(iorb(site,2),ket)/)
        npart = COUNT(bn)
        SELECT CASE(npart)
          CASE(0) 
            cket = cket(1:site)//'.'
          CASE(1)
            IF(     is_occupied(iorb(site,1),ket)) cket = cket(1:site)//'u'
            IF(.NOT.is_occupied(iorb(site,2),ket)) cket = cket(1:site)//'d'
          CASE(2)
            cket = cket(1:site)//'2'
        END SELECT
      ELSE
        bn = (/is_occupied(iorb(site,1),ket),     is_occupied(iorb(site,2),ket)/)
        npart = COUNT(bn)
        SELECT CASE(npart)
          CASE(0) 
            cket = cket(1:site)//'.'
          CASE(1)
            IF(is_occupied(iorb(site,1),ket)) cket = cket(1:site)//'u'
            IF(is_occupied(iorb(site,2),ket)) cket = cket(1:site)//'d'
          CASE(2)
            cket = cket(1:site)//'2'
        END SELECT
      END IF
    END DO
    cket = cket(1:Nc+1)//'>'
  END FUNCTION 

!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************



  FUNCTION state_from_cket(cket,iorb,NAMBU) RESULT(state) 
    INTEGER                       :: state
    CHARACTER(LEN=10), INTENT(IN) :: cket     ! INPUT KET IN READABLE FORM
    INTEGER,           INTENT(IN) :: iorb(:,:)
    LOGICAL, OPTIONAL, INTENT(IN) :: NAMBU
    TYPE(fermion_ket_type)        :: ket 
    LOGICAL :: nambu_
    INTEGER :: site,Nc
    nambu_ = F
    IF(PRESENT(NAMBU)) nambu_ = NAMBU

    Nc = SIZE(iorb,1)
    CALL new_ket(ket,0,SIZE(iorb))
    IF(nambu_)THEN 
      DO site=1,Nc
        CALL create(ket,iorb(site,2),ket)
      END DO
    END IF

    IF(nambu_)THEN 
      DO site=1,Nc
        SELECT CASE(cket(site+1:site+1))
          CASE('u')
            CALL  create(ket,iorb(site,1),ket)
          CASE('d')
            CALL destroy(ket,iorb(site,2),ket)
          CASE('2')
            CALL  create(ket,iorb(site,1),ket)
            CALL destroy(ket,iorb(site,2),ket)
        END SELECT
      END DO
    ELSE
      DO site=1,Nc
        SELECT CASE(cket(site+1:site+1))
          CASE('u')
            CALL create(ket,iorb(site,1),ket)
          CASE('d') 
            CALL create(ket,iorb(site,2),ket) 
          CASE('2')
            CALL create(ket,iorb(site,1),ket)
            CALL create(ket,iorb(site,2),ket)
        END SELECT
      END DO
    END IF
    state = ket%fermion_sign * ket%state
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
