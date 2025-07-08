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
    ! TODO - should this be in the file or in the model code?
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
    
    
    print *, 'setup domain x, setup domain y', lenx, ', ', leny
    
    ! We don't need the domain_check context so we can finalize it
    call xios_context_finalize()

    ! initialize first context for reading in input data
    call xios_context_initialize('input_1', comm)

    call xios_set_time_origin(origin)
    call xios_set_start_date(start)
    call xios_set_timestep(tstep)

    call xios_set_domain_attr("input_domain_1", ni=lenx, nj=leny, ni_glo=lenx, nj_glo=leny, ibegin=0, jbegin=0)
    
    call xios_close_context_definition()
    
    ! initialize second context for reading in input data
    call xios_context_initialize('input_2', comm)

    call xios_set_time_origin(origin)
    call xios_set_start_date(start)
    call xios_set_timestep(tstep)

    call xios_set_domain_attr("input_domain_2", ni=lenx, nj=leny, ni_glo=lenx, nj_glo=leny, ibegin=0, jbegin=0)
    
    call xios_close_context_definition()
    
    ! initialize context for writing output data
    call xios_context_initialize('output', comm)

    call xios_set_time_origin(origin)
    call xios_set_start_date(start)
    call xios_set_timestep(tstep)

    call xios_set_domain_attr("output_domain", ni=lenx, nj=leny, ni_glo=lenx, nj_glo=leny, ibegin=0, jbegin=0)
    
    call xios_close_context_definition()
       

  end subroutine initialise

  subroutine finalise()

    integer :: mpi_error
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
    double precision, dimension (:,:), allocatable :: field_B
    double precision, dimension (:,:), allocatable :: field_C
    
    ! Switch to context for first read
    
    call xios_set_current_context('input_1')

    call xios_get_domain_attr('input_domain_1', ni_glo=lenx)
    call xios_get_domain_attr('input_domain_1', nj_glo=leny)
    
        
    print *, 'input domain 1 x, input domain 1 y', lenx, ', ', leny

    allocate ( field_A(leny, lenx) )

    ! Load data from the input file
    call xios_recv_field('field_A', field_A)
    
    ! We don't need this read context now so finalize
    call xios_context_finalize()
    
    ! Switch to context for second read
    
    call xios_set_current_context('input_2')

    call xios_get_domain_attr('input_domain_2', ni_glo=lenx)
    call xios_get_domain_attr('input_domain_2', nj_glo=leny)
    
    print *, 'input domain 2 x, input domain 2 y', lenx, ', ', leny
    
    allocate ( field_B(leny, lenx) )
    
    ! Load data from the input file
    call xios_recv_field('field_B', field_B)
    
    ! We don't need this read context now so finalize
    call xios_context_finalize()
    
    ! Switch to context for write
    
    call xios_set_current_context('output')

    call xios_get_domain_attr('output_domain', ni_glo=lenx)
    call xios_get_domain_attr('output_domain', nj_glo=leny)
    
    print *, 'output domain x, output domain y', lenx, ', ', leny
    
    allocate ( field_C(leny, lenx) )
    
    ! initialise field_C
    
    field_C = field_A + field_B

    do ts=1, 5
      call xios_update_calendar(ts)
      call xios_get_current_date(current)
      ! Change our data so we can see clearly what is happening
      field_C(:,:) = field_C(:,:) + 1.0d0
      ! Send data to the output file.
      call xios_send_field('field_C', field_C)
    enddo
    
    ! We don't need this write context now so finalize
    call xios_context_finalize()

    deallocate (field_A)
    deallocate (field_B)
    deallocate (field_C)

  end subroutine simulate


end program multiple_file_read
