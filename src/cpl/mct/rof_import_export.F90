module rof_import_export

  use shr_kind_mod     , only : r8 => shr_kind_r8
  use shr_file_mod     , only : shr_file_setLogUnit, shr_file_setLogLevel, &
                                shr_file_getLogUnit, shr_file_getLogLevel, &
                                shr_file_getUnit, shr_file_setIO
  use shr_sys_mod      , only : shr_sys_abort
  use shr_const_mod    , only : SHR_CONST_REARTH
  use RunoffMod        , only : runoff
  use RtmVar           , only : ice_runoff, iulog, nt_hydros, hydros_tracers, rtmlon, rtmlat 
  use RtmSpmd          , only : masterproc
  use RtmTimeManager   , only : get_nstep
  use perf_mod         , only : t_startf, t_stopf, t_barrierf
  use rtm_cpl_indices  , only : index_x2r_Flrl_rofsur,index_x2r_Flrl_rofi 
  use rtm_cpl_indices  , only : index_x2r_Flrl_rofgwl,index_x2r_Flrl_rofsub 
  use rtm_cpl_indices  , only : index_x2r_Flrl_irrig
  use rtm_cpl_indices  , only : index_r2x_Forr_rofl, index_r2x_Forr_rofi
  use rtm_cpl_indices  , only : index_r2x_Flrr_flood, index_r2x_Flrr_volr
  use rtm_cpl_indices  , only : index_r2x_Flrr_volrmch

  implicit none
  public

  integer     ,parameter :: debug = 0  ! internal debug level
  integer     ,parameter :: nmax  = 48 ! number of time steps to write debug output
  character(*),parameter :: F01 = "('(rof_import_export) ',a,i5,2x,3(i8,2x),d21.9)"

contains

  subroutine rof_import( x2r, totrunin)

    !---------------------------------------------------------------------------
    ! DESCRIPTION:
    ! Obtain the runoff input from the coupler
    !
    ! ARGUMENTS:
    real(r8), intent(inout) :: x2r(:,:)         
    real(r8), intent(out)   :: totrunin( runoff%begr: ,: ) 
    !
    ! LOCAL VARIABLES
    integer :: n2, n, nt, ix, iy
    integer :: begr, endr
    integer :: nliq, nfrz
    character(len=32), parameter :: sub = 'rof_import'
    !---------------------------------------------------------------------------
    
    ! Note that totrunin is a flux

    nliq = 0
    nfrz = 0
    do nt = 1,nt_hydros
       if (trim(hydros_tracers(nt)) == 'LIQ') then
          nliq = nt
       endif
       if (trim(hydros_tracers(nt)) == 'ICE') then
          nfrz = nt
       endif
    enddo
    if (nliq == 0 .or. nfrz == 0) then
       write(iulog,*) trim(sub),': ERROR in hydros_tracers LIQ ICE ',nliq,nfrz,hydros_tracers
       call shr_sys_abort()
    endif

    begr = runoff%begr
    endr = runoff%endr

    do n = begr,endr
       n2 = n - begr + 1
       totrunin(n,nliq) = x2r(index_x2r_Flrl_rofsur,n2) + &
                          x2r(index_x2r_Flrl_rofsub,n2) + &
                          x2r(index_x2r_Flrl_rofgwl,n2) + &
                          x2r(index_x2r_Flrl_irrig,n2)

       runoff%qirrig(n) = x2r(index_x2r_Flrl_irrig,n2)

       totrunin(n,nfrz) = x2r(index_x2r_Flrl_rofi,n2)

    enddo

    if (debug > 0 .and. masterproc .and. get_nstep() < nmax) then
       do n = begr,endr
          n2 = n - begr + 1
          iy = (n-1)/rtmlon + 1
          ix = n - (iy-1)*rtmlon
          write(iulog,F01)'import: nstep, n, ix, iy, Flrl_rofsur   = ',get_nstep(),n,ix,iy,x2r(index_x2r_Flrl_rofsur,n2)
          write(iulog,F01)'import: nstep, n, ix, iy, Flrl_rofsub   = ',get_nstep(),n,ix,iy,x2r(index_x2r_Flrl_rofsub,n2)
          write(iulog,F01)'import: nstep, n, ix, iy, Flrl_rofgwl   = ',get_nstep(),n,ix,iy,x2r(index_x2r_Flrl_rofgwl,n2)
          write(iulog,F01)'import: nstep, n, ix, iy, qirrig        = ',get_nstep(),n,ix,iy,runoff%qirrig(n)
          write(iulog,F01)'import: nstep, n, ix, iy, totrunin(liq) = ',get_nstep(),n,ix,iy,totrunin(n,nliq)
          write(iulog,F01)'import: nstep, n, ix, iy, totrunin(frz) = ',get_nstep(),n,ix,iy,totrunin(n,nfrz)
       end do
    end if

  end subroutine rof_import

  !====================================================================================

  subroutine rof_export(r2x)

    !---------------------------------------------------------------------------
    ! DESCRIPTION:
    ! Send the runoff model export state to the coupler
    !
    ! ARGUMENTS:
    real(r8), intent(inout) :: r2x(:,:)  ! Runoff to coupler export state
    !
    ! LOCAL VARIABLES
    integer :: ni, n, nt, ix, iy
    integer :: nliq, nfrz
    logical :: first_time = .true.
    character(len=32), parameter :: sub = 'rof_export'
    !---------------------------------------------------------------------------
    
    nliq = 0
    nfrz = 0
    do nt = 1,nt_hydros
       if (trim(hydros_tracers(nt)) == 'LIQ') then
          nliq = nt
       endif
       if (trim(hydros_tracers(nt)) == 'ICE') then
          nfrz = nt
       endif
    enddo
    if (nliq == 0 .or. nfrz == 0) then
       write(iulog,*) trim(sub),': ERROR in hydros_tracers LIQ ICE ',nliq,nfrz,hydros_tracers
       call shr_sys_abort()
    endif

    r2x(:,:) = 0._r8

    if (first_time) then
       if (masterproc) then
          if ( ice_runoff )then
             write(iulog,*)'Snow capping will flow out in frozen river runoff'
          else
             write(iulog,*)'Snow capping will flow out in liquid river runoff'
          endif
       endif
       first_time = .false.
    end if

    ni = 0
    if ( ice_runoff )then
       do n = runoff%begr,runoff%endr
          ni = ni + 1
          if (runoff%mask(n) == 2) then
             ! liquid and ice runoff are treated separately - this is what goes to the ocean
             r2x(index_r2x_Forr_rofl,ni) = &
                  runoff%runoff(n,nliq)/(runoff%area(n)*1.0e-6_r8*1000._r8)
             r2x(index_r2x_Forr_rofi,ni) = &
                  runoff%runoff(n,nfrz)/(runoff%area(n)*1.0e-6_r8*1000._r8)
             if (ni > runoff%lnumr) then
                write(iulog,*) sub, ' : ERROR runoff count',n,ni
                call shr_sys_abort( sub//' : ERROR runoff > expected' )
             endif
          endif
       end do
    else
       do n = runoff%begr,runoff%endr
          ni = ni + 1
          if (runoff%mask(n) == 2) then
             ! liquid and ice runoff are bundled together to liquid runoff
             ! and then ice runoff set to zero
             r2x(index_r2x_Forr_rofl,ni) =   &
                  (runoff%runoff(n,nfrz)+runoff%runoff(n,nliq))&
                 /(runoff%area(n)*1.0e-6_r8*1000._r8)
             r2x(index_r2x_Forr_rofi,ni) = 0._r8
             if (ni > runoff%lnumr) then
                write(iulog,*) sub, ' : ERROR runoff count',n,ni
                call shr_sys_abort( sub//' : ERROR runoff > expected' )
             endif
          endif
       end do
    end if

    ! Flooding back to land, sign convention is positive in land->rof direction
    ! so if water is sent from rof to land, the flux must be negative.
    ni = 0
    do n = runoff%begr, runoff%endr
       ni = ni + 1
       r2x(index_r2x_Flrr_flood,ni) = -runoff%flood(n)
    end do

    ! Want volr on land side to do a correct water balance
    ni = 0
    do n = runoff%begr, runoff%endr
      ni = ni + 1
      r2x(index_r2x_Flrr_volr,ni) = runoff%volr(n,1) / (runoff%area(n))
      r2x(index_r2x_Flrr_volrmch,ni) = r2x(index_r2x_Flrr_volr,ni)  ! main channel not defined in rtm so use total
    end do

    if (debug > 0 .and. masterproc .and. get_nstep() <  nmax) then
       ni = 0
       do n = runoff%begr,runoff%endr
          ni = ni + 1
          iy = (n-1)/rtmlon + 1
          ix = n - (iy-1)*rtmlon
          write(iulog,F01)'export: nstep, n, ix, iy, Flrr_flood   = ',get_nstep(),n,ix,iy,r2x(index_r2x_Flrr_flood,ni)
          write(iulog,F01)'export: nstep, n, ix, iy, Flrr_volr    = ',get_nstep(),n,ix,iy,r2x(index_r2x_Flrr_volr,ni)
          write(iulog,F01)'export: nstep, n, ix, iy, Flrr_volrmch = ',get_nstep(),n,ix,iy,r2x(index_r2x_Flrr_volrmch,ni)
          write(iulog,F01)'export: nstep, n, ix, iy, Forr_rofl    = ',get_nstep(),n,ix,iy,r2x(index_r2x_Forr_rofl,n)
          write(iulog,F01)'export: nstep, n, ix, iy, Forr_rofi    = ',get_nstep(),n,ix,iy,r2x(index_r2x_Forr_rofi,ni)
       end do
    end if

  end subroutine rof_export

end module rof_import_export
