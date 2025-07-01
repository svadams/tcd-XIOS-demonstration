!-----------------------------------------------------------------------------
! (C) Crown copyright 2025 Met Office. All rights reserved.
! The file LICENCE, distributed with this code, contains details of the terms
! under which the code may be used.
!-----------------------------------------------------------------------------
!> Multiple file read using multiple contexts
!>
program multiple_file_read
  use xios
  use mpi

  implicit none

  integer :: comm = -1
  integer :: rank = -1
  integer :: npar = 0

  call initialise()
  call simulate()
  call finalise()
contains

  subroutine initialise()

    type(xios_date) :: origin
    type(xios_date) :: start
    type(xios_duration) :: tstep
    integer :: mpi_error
    integer :: lenx
    integer :: leny


    ! Arbitrary datetime setup, required for XIOS but unused
    origin = xios_date(2022, 2, 2, 12, 0, 0)
    start = xios_date(2022, 12, 13, 12, 0, 0)
    tstep = xios_hour

    ! Initialise MPI and XIOS
    call MPI_INIT(mpi_error)

    call xios_initialize('client', return_comm=comm)

    call MPI_Comm_rank(comm, rank, mpi_error)
    call MPI_Comm_size(comm, npar, mpi_error)

    ! use the axis_check context to obtain sizing information on all arrays
    ! for use in defining the main context interpretation
    call xios_context_initialize('domain_check', comm)
    call xios_set_time_origin(origin)
    call xios_set_start_date(start)
    call xios_set_timestep(tstep)

    call xios_close_context_definition()

    call xios_get_axis_attr('x', n_glo=lenx)
    call xios_get_axis_attr('y', n_glo=leny)
    
    
    print *, 'domain x, domain y', lenx, ', ', leny

    ! initialize the main context for reading in input data
    call xios_context_initialize('input_1', comm)

    call xios_set_time_origin(origin)
    call xios_set_start_date(start)
    call xios_set_timestep(tstep)

    call xios_set_domain_attr("input_domain", ni=lenx, nj=leny, ibegin=0, jbegin=0)
    
    call xios_close_context_definition()
       


  end subroutine initialise

  subroutine finalise()

    integer :: mpi_error

    ! Finalise all XIOS contexts and MPI
    call xios_set_current_context('domain_check')
    call xios_context_finalize()
    call xios_set_current_context('input_1')
    call xios_context_finalize()
    call MPI_Comm_free(comm, mpi_error)
    call xios_finalize()
    call MPI_Finalize(mpi_error)

  end subroutine finalise
  
  subroutine simulate()

    type(xios_date) :: current
    integer :: ts
    integer :: lenx
    integer :: leny

    ! Allocatable arrays, size is taken from input file
    double precision, dimension (:,:), allocatable :: field_A

    call xios_get_domain_attr('input_domain', ni_glo=lenx)
    call xios_get_domain_attr('input_domain', nj_glo=leny)

    allocate ( field_A(leny, lenx) )

    ! Load data from the input file
    call xios_recv_field('field_A', field_A)

    do ts=1, 1
      call xios_update_calendar(ts)
      call xios_get_current_date(current)
      ! Send (copy) the original data to the output file.
      !call xios_send_field('odata', inodata)
      ! Send (copy) the expected data to the output file.
      !call xios_send_field('edata', inedata)
    enddo

    deallocate (field_A)

  end subroutine simulate


end program multiple_file_read
