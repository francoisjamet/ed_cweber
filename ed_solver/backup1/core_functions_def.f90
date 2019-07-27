MODULE common_def

  use genvar

  IMPLICIT NONE


  INTERFACE readfmt
   MODULE PROCEDURE readfmt_,readfmt__,readfmt___
  END INTERFACE

  INTERFACE get_address
   MODULE PROCEDURE   get_addressr,get_addressi,get_address_d,get_address_c, &
                    & get_addressl,get_address_dvec,get_addresschar,get_address_cvec,get_address_ivec
  END INTERFACE

  INTERFACE put_address
   MODULE PROCEDURE   put_addressr,put_addressi,put_addressd,put_addressl, &
                    & put_addressc,put_addressdvec,put_addresschar,put_addresscvec,put_addressivec 
  END INTERFACE

 INTERFACE ramp
   MODULE PROCEDURE ramp_vec
   MODULE PROCEDURE ramp_mat
 END INTERFACE
 
   contains

  SUBROUTINE ramp_vec(zeramp,n)
    INTEGER, INTENT(INOUT)        :: zeramp(:)
    INTEGER, INTENT(IN), OPTIONAL :: n
    INTEGER                       :: i,nn
    nn = SIZE(zeramp)
    IF(PRESENT(n)) nn = n
    zeramp(1:nn) = (/(i,i=1,nn)/)
  END SUBROUTINE


  SUBROUTINE ramp_mat(zeramp,n1,n2)
    INTEGER, INTENT(INOUT)        :: zeramp(:,:)
    INTEGER, INTENT(IN), OPTIONAL :: n1,n2
    INTEGER                       :: i,nn1,nn2
    nn1 = SIZE(zeramp,1)
    IF(PRESENT(n1)) nn1 = n1
    nn2 = SIZE(zeramp,2)
    IF(PRESENT(n2)) nn2 = n2
    zeramp(1:nn1,1:nn2) = RESHAPE((/(i,i=1,nn1*nn2)/),(/nn1,nn2/))
  END SUBROUTINE


!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************

 subroutine create_seg_fault
 implicit none
 integer :: ii
 real(8) :: x(2)
  ii=2
  write(*,*) x(ii+3)
 end subroutine

!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************

   subroutine put_addressr(j,d1)
    interface
     integer function putaddress_r(j,d1)
      real(4)    :: d1
      integer(8) :: j
     end function
    end interface
    real(4)    :: d1
    integer(8) :: j
    integer    :: i
    i=putaddress_r(j,d1)
   end subroutine

   subroutine put_addressi(j,d1)
    interface
     integer function putaddress_i(j,d1)
      integer(4) :: d1
      integer(8) :: j
     end function
    end interface
    integer(4) :: d1,i
    integer(8) :: j
    i=putaddress_i(j,d1)
   end subroutine

   subroutine put_addressdvec(j,d1)
    real(8)    :: d1(:)
    integer    :: i,ii
    integer(8) :: j,iii
    iii=j
    do ii=1,size(d1)
      call put_address(iii,d1(ii))
      iii=iii+8
    enddo
   end subroutine

   subroutine put_addresscvec(j,d1)
    complex(8) :: d1(:)
    integer    :: i,ii
    integer(8) :: j,iii
    iii=j
    do ii=1,size(d1)
      call put_address(iii,d1(ii))
      iii=iii+16
    enddo
   end subroutine

   subroutine put_addressivec(j,d1)
    integer(4)    :: d1(:)
    integer       :: i,ii
    integer(8)    :: iii,j
    iii=j
    do ii=1,size(d1)
      call put_address(iii,d1(ii))
      iii=iii+4
    enddo
   end subroutine

   subroutine put_addresschar(j,d1)
    interface
     integer function putaddress_char(j,d1)
      character(1) :: d1
      integer(8)   :: j
     end function
    end interface
    character(LEN=*) :: d1
    integer          :: i,iii
    integer(8)       :: jjj,j
    jjj=j
    do iii=1,LEN(d1)
     i=putaddress_char(jjj,d1(iii:iii))
     jjj=jjj+1
    enddo
   end subroutine

   subroutine put_addressd(j,d1)
    interface
     integer function putaddress(j,d1)
      real(8)    :: d1
      integer(8) :: j
     end function
    end interface
    real(8)    :: d1
    integer    :: i
    integer(8) :: j
    i=putaddress(j,d1)
   end subroutine

   subroutine put_addressc(j,d1)
    interface
     integer function putaddress(j,d1)
      real(8)    :: d1
      integer(8) :: j
     end function
    end interface
    complex(8) :: d1
    integer    :: i
    integer(8) :: j
    i=putaddress(j,real(d1))
    i=putaddress(j+8,aimag(d1))
   end subroutine

   subroutine put_addressl(j,d1)
    interface
     integer function putaddress_l(j,d1)
      logical    :: d1
      integer(8) :: j
     end function
    end interface
    logical    :: d1
    integer    :: i
    integer(8) :: j
    i=putaddress_l(j,d1)
   end subroutine

!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************

   integer(8) function get_addressr(d1)
    interface
     integer(8) function getaddress_r(d1)
      real(4) :: d1
     end function
    end interface
    real(4) :: d1
    get_addressr=getaddress_r(d1)
   end function

   integer(8) function get_addressi(d1)
    interface
     integer(8) function getaddress_i(d1)
      integer(4) :: d1
     end function
    end interface
    integer(4) :: d1
    get_addressi=getaddress_i(d1)
   end function

   integer(8) function get_addressl(d1)
    interface
     integer(8) function getaddress_l(d1)
      logical :: d1
     end function
    end interface
    logical    :: d1
    get_addressl=getaddress_l(d1)
   end function

   integer(8) function get_addresschar(d1)
    interface
     integer(8) function getaddress_char(d1)
      character(1) :: d1
     end function
    end interface
    character(LEN=*) :: d1
    get_addresschar=getaddress_char(d1(1:1))
   end function

   integer(8) function get_address_d(d1)
    interface
     integer(8) function getaddress(d1)
      real(8) :: d1
     end function
    end interface
    real(8) :: d1
    get_address_d=getaddress(d1)
   end function

   integer(8) function get_address_dvec(d1)
    interface
     integer(8) function getaddress(d1)
      real(8) :: d1
     end function
    end interface
    real(8) :: d1(:)
    get_address_dvec=getaddress(d1(1))
   end function

   integer(8) function get_address_c(d1)
    interface
     integer(8) function getaddress_vec(d1)
      complex(8) :: d1
     end function
    end interface
    complex(8) :: d1
    get_address_c=getaddress_vec(d1)
   end function

   integer(8) function get_address_cvec(d1)
    interface
     integer(8) function getaddress_vec(d1)
      complex(8) :: d1
     end function
    end interface
    complex(8) :: d1(:)
    get_address_cvec=getaddress_vec(d1(1))
   end function

   integer(8) function get_address_ivec(d1)
    interface
     integer(8) function getaddress_i(d1)
      integer(4) :: d1
     end function
    end interface
    integer(4) :: d1(:)
    get_address_ivec=getaddress_i(d1(1))
   end function

!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************

   character(80) function readfmt_(ii,ch)
   implicit none
    integer :: ii
    character*(*) :: ch
     write(readfmt_,'(A,I4,A,A)') "(",ii,ch,")"
   end function

    
   character(80) function readfmt__(ii,ch,ii2,ch2)
   implicit none
    integer :: ii,ii2
    character*(*) :: ch,ch2
     write(readfmt__,'(A,I4,A,A,I4,A,A)') "(",ii,ch,',',ii2,ch2,")"
   end function

    
   character(80) function readfmt___(ii,ch,ii2,ch2,ii3,ch3)
   implicit none
    integer :: ii,ii2,ii3
    character*(*) :: ch,ch2,ch3
     write(readfmt___,'(A,I4,A,A,I4,A,A,I4,A,A)') "(",ii,ch,',',ii2,ch2,',',ii3,ch3,")"
   end function

!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************

 subroutine get_free_unit(unit_)
 implicit none
 integer :: unit_,ios
 logical :: is_it_opened
  unit_=20
  do 
   unit_=unit_+1
   INQUIRE(unit=unit_,OPENED=is_it_opened,iostat=ios)
   if(.not.is_it_opened.and.ios==0)return 
   if(unit_>900) stop 'get_free_unit error : no unit free smaller than 900, can be a bug, so now stop'
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

  SUBROUTINE dump_message(UNIT,TEXT)
    INTEGER,          INTENT(IN), OPTIONAL :: UNIT
    CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: TEXT
    INTEGER, SAVE :: counter=0
    INTEGER       :: unit_
    unit_ = log_unit ! STANDARD OUTPUT
    IF(PRESENT(UNIT)) unit_ = UNIT
    IF(PRESENT(TEXT))THEN
      WRITE(unit_,'(a)') TEXT
    ELSE
      counter = counter + 1
      WRITE(unit_,'(a)') "... called dump_message() for the "//c2s(i2c(counter))//"th time" 
    ENDIF
    CALL flush(unit_)
  END SUBROUTINE 

!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************

  SUBROUTINE skip_line(unit_,NLINES)
    INTEGER, INTENT(IN) :: unit_
    INTEGER, INTENT(IN), OPTIONAL :: NLINES
    INTEGER :: nlines_,i
    CHARACTER(LEN=100)  :: fmtnlines
    nlines_ = 1
    IF(PRESENT(NLINES)) nlines_ = NLINES
    do i=1,nlines_
     read(unit_,*,end=10)
    enddo
    10 continue
  END SUBROUTINE 

!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************

  FUNCTION i2c(i)
    ! INTEGER => ARRAY OF CHARACTERS
    CHARACTER, POINTER    :: i2c(:) 
    INTEGER,   INTENT(IN) :: i
    CHARACTER(LEN=100) :: ctemp1,ctemp2
    INTEGER :: ic,lgth
    WRITE(ctemp1,*) i 
    ctemp2 = ADJUSTL(ctemp1)
    lgth   = LEN_TRIM(ctemp2)
    ALLOCATE(i2c(lgth)) 
    DO ic=1,lgth
      i2c(ic) = ctemp2(ic:ic)
    END DO
  END FUNCTION 

   !--------------------!

  FUNCTION c2s(c)
    ! ARRAY OF CHARACTERS => STRING
    CHARACTER, INTENT(IN)  :: c(:)  
    CHARACTER(LEN=SIZE(c)) :: c2s
    INTEGER :: ic 
    DO ic=1,SIZE(c)
      c2s(ic:ic) = c(ic)
    END DO
  END FUNCTION 

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

subroutine erase(filename)
character*(*) filename
logical :: check
integer :: unit_
 INQUIRE(file=filename,OPENED=check)
 if(check)then
 write(*,*) 'danger erase unit already opened...'
 endif
 call get_free_unit(unit_)
 INQUIRE(unit=unit_,OPENED=check)
 if(check)then
  write(*,*) 'bug in erase filename routine...unit is already opened'
  stop 'error in erase filename'
 endif
 INQUIRE(file=filename,EXIST=check)
 if(.not.check) then
  write(*,*) 'file doesn t exist'
  return
 endif
 open(unit=unit_,file=filename)
 close(unit_,status='delete')
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

  SUBROUTINE open_safe(unit_,filename_,status_,action_,get_unit)
   !$$$$$$$$$$$$$$$$$$$$$
   !$$ OPEN-CHECK FILE $$
   !$$$$$$$$$$$$$$$$$$$$$
    INTEGER,         INTENT(INOUT) :: unit_
    CHARACTER(LEN=*),INTENT(IN)    :: filename_,status_
    CHARACTER(LEN=*),OPTIONAL      :: action_
    LOGICAL                        :: opened_
    INTEGER                        :: iostat_
    REAL(8)                        :: force_error
    LOGICAL,OPTIONAL               :: get_unit

    write(*,*) 'open_safe routine, filename :', filename_

    IF(LEN_TRIM(filename_)==0)THEN
      CALL dump_message(UNIT=6,TEXT="ERROR IN 'open_safe' : FILENAME NOT SPECIFIED")
      RETURN
    ENDIF

    write(*,*) 'inquire if file is opened'
    INQUIRE(FILE=filename_,OPENED=opened_)

    IF(opened_)THEN
      write(*,*) 'file was opened'
      CALL dump_message(UNIT=6,TEXT="ERROR IN 'open_safe' : FILE = "//TRIM(filename_)//" ALREADY OPENED")
      write(*,*) 'return...'
      RETURN
    ENDIF

    if(present(get_unit)) then
            write(*,*) 'getting free unit for file'
            call get_free_unit(unit_)
            write(*,*) 'unit is : ', unit_
    endif

    if(present(action_))then
       OPEN(UNIT=unit_,FILE=filename_,STATUS=status_,IOSTAT=iostat_,ACTION=action_)   
    else
       OPEN(UNIT=unit_,FILE=filename_,STATUS=status_,IOSTAT=iostat_)
    endif

    IF(iostat_>0)THEN 
     if(present(action_))then
       CALL dump_message(UNIT=6,TEXT=" filename: "//filename_//" actions: "//action_)
     else
       CALL dump_message(UNIT=6,TEXT=" filename: "//filename_)
     endif
    CALL dump_message(UNIT=6,TEXT="ERROR OPENING "//TRIM(filename_)//" : IOSTAT="//c2s(i2c(iostat_)))
    RETURN
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

  SUBROUTINE close_safe(unit_)
    !$$$$$$$$$$$$$$$$$$$$$$
    !$$ CLOSE-CHECK FILE $$
    !$$$$$$$$$$$$$$$$$$$$$$
    INTEGER, INTENT(IN) :: unit_
    LOGICAL             :: opened_
    INTEGER             :: iostat_
    CHARACTER(LEN=100)  :: filename_
    INQUIRE(UNIT=unit_,NAME=filename_,OPENED=opened_)
    IF(.NOT.opened_)THEN
      CALL dump_message(TEXT="ERROR IN 'close_safe' : FILE = "//TRIM(filename_)//" NOT OPENED")
      RETURN
    ENDIF
     CLOSE(unit_,err=11)
  11 continue
  END SUBROUTINE 

!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************

  SUBROUTINE reset_timer(clock_ref)
    INTEGER, INTENT(OUT) :: clock_ref
    CALL SYSTEM_CLOCK(COUNT=clock_ref)
  END SUBROUTINE

!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************

  SUBROUTINE timer_fortran(clock_ref,TEXT,unit_)
    !$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    !$$ WRITE ELAPSED TIME SINCE LAST CALL $$
    !$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    INTEGER,          INTENT(IN)           :: clock_ref
    CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: TEXT
    INTEGER                                :: clock,TEXT_length
    CHARACTER(LEN=100)                     :: fmt_TEXT
    REAL(DBL)                              :: elapsed_time
    integer,optional                       :: unit_
    integer                                :: log_unit_

                       log_unit_ = log_unit
    if(present(unit_)) log_unit_ =     unit_

    CALL SYSTEM_CLOCK(COUNT=clock)
    elapsed_time = DBLE(clock-clock_ref) * one_over_clock_rate

    IF(PRESENT(TEXT))THEN
      WRITE(fmt_TEXT,*) '(a',LEN(TRIM(ADJUSTL(TEXT))),',4X,f0.6,a)'
      WRITE(log_unit_,fmt_TEXT) TRIM(ADJUSTL(TEXT)),elapsed_time," seconds"
    ELSE
      WRITE(fmt_TEXT,*) '(a,f0.6,a)'
      WRITE(log_unit_,fmt_TEXT) "### TIMING: TIME ELAPSED SINCE LAST RESET =",elapsed_time," seconds"
    ENDIF
    CALL flush(log_unit_)

  END SUBROUTINE

!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************
!**************************************************************************

  SUBROUTINE system_call(cmd)
    CHARACTER(LEN=*), INTENT(IN) :: cmd
    CHARACTER(LEN=1000) :: mycmd,filename,tmp
#ifndef NO_SYS_CALL
    ! UGLY BUT WORKS SOLUTION
    tmp   = "syscall-p"//c2s(i2c(iproc))
    mycmd = TRIM(cmd)//" > "//TRIM(tmp)  ! REDIRECT OUTPUT TO TMP FILE
    CALL system(TRIM(mycmd))
    INQUIRE(UNIT=log_unit,NAME=filename) ! FIND NAME OF LOG FILE
    CALL system("cat "//TRIM(tmp)//" >> "//TRIM(filename)) ! APPEND TMP FILE TO LOG FILE
    CALL fseek(log_unit,0,2) ! REPOSITION TO THE END OF LOG FILE
    CALL system("rm -f "//TRIM(tmp)) ! REMOVE TMP FILE
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
 
  SUBROUTINE stats_func(TEXT)
    !$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    !$$ WRITE ELAPSED TIME SINCE LAST CALL $$
    !$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: TEXT
#ifndef NO_SYS_CALL
    CALL system_call("vmstat -S M -s | grep used")
#endif
    CALL dump_message(TEXT="---------------------")
    IF(PRESENT(TEXT)) CALL dump_message(TEXT=TEXT)
    CALL dump_message(TEXT="---------------------")
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

  FUNCTION find_rank(intg,tabintg)
    INTEGER             :: find_rank
    INTEGER, INTENT(IN) :: intg
    INTEGER, INTENT(IN) :: tabintg(:)
    INTEGER :: ntab
    find_rank = 0
    ntab = SIZE(tabintg)
    IF(ntab==0) RETURN 
    IF(ALL(tabintg(1:ntab)/=intg)) RETURN
    DO find_rank=1,ntab
      IF(tabintg(find_rank)==intg) RETURN
    END DO
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
