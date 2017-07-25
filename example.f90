module example

  use types, only: dp
  implicit none
  private
  public foo, UserDefined

  type UserDefined
     real(dp) :: buzz
     real(dp) :: broken
     integer :: how_many
  end type UserDefined

contains

  subroutine foo(bar, baz, quux)
    real(dp), intent(in) :: bar, baz
    real(dp), intent(out) :: quux

    quux = bar + 3.75_dp * baz

  end subroutine foo

end module example