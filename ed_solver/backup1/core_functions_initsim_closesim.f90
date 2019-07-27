module init_and_close_my_sim

 use genvar
! use linalg
 use common_def
 use namelistmod
#ifdef _GPU
 use fortran_cuda
#endif
 use random

 REAL(DBL),PARAMETER,private :: zero=0.0_DBL,one=1.0_DBL,two=2.0_DBL,three=3.0_DBL

 PRIVATE
 PUBLIC :: initialize_my_simulation,finalize_my_simulation,initialize_random_numbers

  real(8),parameter,    private :: rerror=1.d-3
  INTEGER,              PRIVATE :: seedsize
  CHARACTER(LEN=5),     private :: csize
  INTEGER, ALLOCATABLE, PRIVATE :: seed(:)
  CHARACTER(LEN=100),   PRIVATE :: SEEDFILEOUT
  CHARACTER(LEN=100),   PRIVATE :: fmtseed

contains


!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************

  SUBROUTINE init_common
    CHARACTER(LEN=100) :: fmt_ciwprint
    INTEGER            :: length_ciwprint,intg,clock_rate
    write(*,*) 'start to init common quantities'
    ! INITIALIZE CONSTANTS !
    pi2       =  two * pi
    oneoverpi =  one / pi
    s2        =  SQRT(two)
    s3        =  SQRT(three)
    s6        =  s2 * s3
    CALL SYSTEM_CLOCK(COUNT_RATE=clock_rate)
    call initialize_random_numbers(iseed,rank)
    write(*,*) 'system clock rate is : ', clock_rate
    one_over_clock_rate  = one / DBLE(clock_rate)
    write(*,*) 'one over clock rate : ', one_over_clock_rate
    LOGfile = 'logfile'
    LOGfile = TRIM(LOGfile)//"-p"//c2s(i2c(iproc))
    CALL open_safe(log_unit,LOGfile,"UNKNOWN","WRITE")
    write(*,*) 'log unit file opened',log_unit
    write(*,*) 'common quantities done'
  END SUBROUTINE 

   !-------------------------------------------------!

  subroutine finalize_common
    CALL close_safe(log_unit)
  end subroutine

!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************

  !-------------------!

  SUBROUTINE finalize_MPI
    write(*,*) ' --- MPI TERMINATED --- '
    if(allocated(all_log_unit)) DEALLOCATE(all_log_unit)
    if(allocated(ramp_proc))    DEALLOCATE(ramp_proc)
    if(.not.no_mpi) call MPI_FINALIZE(ierr)
  END SUBROUTINE

  !-------------------!

  SUBROUTINE initialize_MPI
    INTEGER :: jproc,provided
    write(*,*) 'start to init MPI'
    if(.not.no_mpi)then
     call MPI_INIT(ierr)
    !call MPI_INIT_THREAD(MPI_THREAD_FUNNELED,provided,ierr)
     call MPI_COMM_SIZE(MPI_COMM_WORLD,size2,ierr)
     call MPI_COMM_RANK(MPI_COMM_WORLD,rank,ierr)
    else
     ierr=0
     size2=1
     rank=0
    endif
    myid     = rank
    numprocs = size2
    nproc    = size2
    iproc    = rank  + 1
    ALLOCATE(all_log_unit(nproc))
    all_log_unit = (/(9876+jproc,jproc=1,nproc)/)
    log_unit     = all_log_unit(iproc)
    ALLOCATE(ramp_proc(nproc))
    CALL ramp(ramp_proc)
    if(.not.no_mpi) CALL MPI_GET_PROCESSOR_NAME(procname,nname,ierr)
    write(*,*) ' RANK / SIZE : ', rank, size2
    CALL init_common
    write(*,*) 'mpi init done'
  END SUBROUTINE

  !-------------------!

  SUBROUTINE finalize_my_simulation
    call finalize_common
    call finalize_MPI
  END SUBROUTINE

  !-------------------!

  SUBROUTINE initialize_my_simulation
   write(*,*) '...set common variables....'
   call init_common
   write(*,*) 'init MPI : '
   call initialize_MPI
   write(*,*) 'INIT OPENMP : '
   call init_openmp

#ifdef GPU
   write(*,*) 'INIT GPU : '
   if(use_cuda_routines) call init_gpu_device
#endif

   messages                = .true.
   messages2               = .true.
   messages3               = .false.
   messages4               = .false.
   MPIseparate             = .false.
   testing                 = .false.
   strongstop              = .false.
   enable_mpi_dot          = .false.
  END SUBROUTINE

!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************

end module
