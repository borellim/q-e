!
! Copyright (C) 2001-2003 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!--------------------------------------------------------------------
subroutine efermig (et, nbnd, nks, nelec, wk, Degauss, Ngauss, Ef, is, isk)
  !--------------------------------------------------------------------
  !
  !     Finds the Fermi energy - Gaussian Broadening (Methfessel-Paxton)
  !
  USE io_global, ONLY : stdout
  USE kinds
  implicit none
  !  I/O variables
  integer, intent(in) :: nks, nbnd, Ngauss, is, isk(nks)
  real(DP), intent(in) :: wk (nks), et (nbnd, nks), Degauss, nelec
  real(DP), intent(out) :: Ef
  ! internal variables
  real(DP) :: Eup, Elw, sumkup, sumklw, sumkmid
  real(DP), external::  sumkg
  integer :: i, kpoint
  !
  !      find bounds for the Fermi energy. Very safe choice!
  !
  Elw = et (1, 1)
  Eup = et (nbnd, 1)
  do kpoint = 2, nks
     Elw = min (Elw, et (1, kpoint) )
     Eup = max (Eup, et (nbnd, kpoint) )
  enddo
  Eup = Eup + 2 * Degauss
  Elw = Elw - 2 * Degauss
#ifdef __PARA
  !
  ! find min and max across pools
  !
  call poolextreme (Eup, + 1)
  call poolextreme (Elw, - 1)
#endif
  !
  !      Bisection method
  !
  sumkup = sumkg (et, nbnd, nks, wk, Degauss, Ngauss, Eup, is, isk)
  sumklw = sumkg (et, nbnd, nks, wk, Degauss, Ngauss, Elw, is, isk)
  if ( (sumkup - nelec) .lt. - 1.0e-10 .or. &
       (sumklw - nelec) .gt.1.0e-10)  &
       call errore ('Efermi', 'unexpected error', 1)
  do i = 1, 50
     Ef = (Eup + Elw) / 2.0
     sumkmid = sumkg (et, nbnd, nks, wk, Degauss, Ngauss, Ef, is, isk)
     if (abs (sumkmid-nelec) .lt.1.0e-10) then
        return
     elseif ( (sumkmid-nelec) .lt. - 1.0e-10) then
        Elw = Ef
     else
        Eup = Ef
     endif
  enddo
  if (is /= 0) WRITE(stdout, '(5x,"Spin Component #",i3)') is
  WRITE( stdout, '(5x,"Warning: too many iterations in bisection"/ &
       &      5x,"Ef = ",f10.6," sumk = ",f10.6," electrons")' ) &
       Ef * 13.6058, sumkmid
  !
  return
end subroutine efermig

