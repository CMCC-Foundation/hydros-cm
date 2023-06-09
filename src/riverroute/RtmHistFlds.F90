module RtmHistFlds

!-----------------------------------------------------------------------
! !DESCRIPTION:
! Module containing initialization of RTM history fields and files
! This is the module that the user must modify in order to add new
! history fields or modify defaults associated with existing history
! fields.
!
! !USES:
  use shr_kind_mod   , only: r8 => shr_kind_r8
  use RunoffMod      , only : runoff
  use RtmHistFile    , only : RtmHistAddfld, RtmHistPrintflds
  use RtmVar         , only : nt_hydros, hydros_tracers  

  implicit none
!
! !PUBLIC MEMBER FUNCTIONS:
  public :: RtmHistFldsInit 
  public :: RtmHistFldsSet
!
!------------------------------------------------------------------------

contains

!-----------------------------------------------------------------------

  subroutine RtmHistFldsInit()

    !-------------------------------------------------------
    ! DESCRIPTION:
    ! Build master field list of all possible fields in a history file.
    ! Each field has associated with it a ``long\_name'' netcdf attribute that
    ! describes what the field is, and a ``units'' attribute. A subroutine is
    ! called to add each field to the masterlist.
    !
    ! !USES:
    ! ARGUMENTS:
    implicit none
    !-------------------------------------------------------

    call RtmHistAddfld (fname='QCHANR', units='m3/s',  &
         avgflag='A', long_name='RTM river flow: '//trim(hydros_tracers(1)), &
         ptr_rof=runoff%runofflnd_nt1)

    call RtmHistAddfld (fname='QCHANR'//'_'//trim(hydros_tracers(2)), units='m3/s',  &
         avgflag='A', long_name='RTM river flow: '//trim(hydros_tracers(2)), &
         ptr_rof=runoff%runofflnd_nt2)

    call RtmHistAddfld (fname='QCHOCNR', units='m3/s', &
         avgflag='A', long_name='RTM river discharge into ocean: '//trim(hydros_tracers(1)), &
         ptr_rof=runoff%runoffocn_nt1)

    call RtmHistAddfld (fname='QCHOCNR'//'_'//trim(hydros_tracers(2)), units='m3/s', &
         avgflag='A', long_name='RTM river discharge into ocean: '//trim(hydros_tracers(2)), &
         ptr_rof=runoff%runoffocn_nt2)

    call RtmHistAddfld (fname='VOLR'//'_'//trim(hydros_tracers(1)), units='m3',  &
         avgflag='A', long_name='RTM storage: '//trim(hydros_tracers(1)), &
         ptr_rof=runoff%volr_nt1, default='inactive')

    call RtmHistAddfld (fname='VOLR'//'_'//trim(hydros_tracers(2)), units='m3',  &
         avgflag='A', long_name='RTM storage: '//trim(hydros_tracers(2)), &
         ptr_rof=runoff%volr_nt2, default='inactive')

    call RtmHistAddfld (fname='DVOLRDT_LND', units='mm/s',  &
         avgflag='A', long_name='RTM land change in storage: '//trim(hydros_tracers(1)), &
         ptr_rof=runoff%dvolrdtlnd_nt1, default='inactive')

    call RtmHistAddfld (fname='DVOLRDT_LND'//'_'//trim(hydros_tracers(2)), units='mm/s',  &
         avgflag='A', long_name='RTM land change in storage: '//trim(hydros_tracers(2)), &
         ptr_rof=runoff%dvolrdtlnd_nt2, default='inactive')

    call RtmHistAddfld (fname='DVOLRDT_OCN', units='mm/s',  &
         avgflag='A', long_name='RTM ocean change of storage: '//trim(hydros_tracers(1)), &
         ptr_rof=runoff%dvolrdtocn_nt1, default='inactive')

    call RtmHistAddfld (fname='DVOLRDT_OCN'//'_'//trim(hydros_tracers(2)), units='mm/s',  &
         avgflag='A', long_name='RTM ocean change of storage: '//trim(hydros_tracers(2)), &
         ptr_rof=runoff%dvolrdtocn_nt2, default='inactive')

    call RtmHistAddfld (fname='RTMFLOOD', units='m3/s',  &
         avgflag='A', long_name='RTM flooding flux', &
         ptr_rof=runoff%flood, default='inactive')

    call RtmHistAddfld (fname='QIRRIG', units='mm/s',  &
         avgflag='A', long_name='Irrigation flux from land', &
         ptr_rof=runoff%qirrig, default='inactive')

    ! Print masterlist of history fields

    call RtmHistPrintflds()

  end subroutine RtmHistFldsInit

!-----------------------------------------------------------------------

  subroutine RtmHistFldsSet()

    !-----------------------------------------------------------------------
    ! !DESCRIPTION:
    ! Set hydros history fields as 1d pointer arrays
    !
    implicit none
    !-----------------------------------------------------------------------

    ! Currently only have two tracers

    runoff%runofflnd_nt1(:)  = runoff%runofflnd(:,1)
    runoff%runofflnd_nt2(:)  = runoff%runofflnd(:,2)

    runoff%runoffocn_nt1(:)  = runoff%runoffocn(:,1)
    runoff%runoffocn_nt2(:)  = runoff%runoffocn(:,2)

    runoff%dvolrdtlnd_nt1(:) = runoff%dvolrdtlnd(:,1)
    runoff%dvolrdtlnd_nt2(:) = runoff%dvolrdtlnd(:,2)

    runoff%dvolrdtocn_nt1(:) = runoff%dvolrdtocn(:,1)
    runoff%dvolrdtocn_nt2(:) = runoff%dvolrdtocn(:,2)

    runoff%volr_nt1(:)       = runoff%volrlnd(:,1)
    runoff%volr_nt2(:)       = runoff%volrlnd(:,2)

  end subroutine RtmHistFldsSet


end module RtmHistFlds
