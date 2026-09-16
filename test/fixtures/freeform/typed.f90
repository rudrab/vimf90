module solver_mod
  implicit none
  integer, parameter :: dp = kind(1.0d0)
  type :: solver
    integer :: n
  end type solver
  interface generic_make
    module procedure make_solver
  end interface generic_make
contains
  real function square(x)
    real :: x
    square = x*x
  end function square

  integer(kind=8) pure function counter(n)
    integer, intent(in) :: n
    counter = n + 1
  end function counter

  character(len=*) function label()
    label = 'hi'
  end function label

  real(kind(1.0d0)) function precise(x)
    real(dp) :: x
    precise = x
  end function precise

  type(solver) function make_solver(n)
    integer :: n
    do i = 1, 10
      call noop()
    end do
  end function make_solver

  subroutine plain(a)
    integer :: a
  end subroutine plain
end module solver_mod
