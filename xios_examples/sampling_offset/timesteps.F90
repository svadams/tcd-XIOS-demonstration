program timesteps
    use xios
    use mpi
    implicit none

    integer :: ierr = 0
    integer :: rank, size
    
    ! Initialise MPI
    call MPI_INIT(ierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    call MPI_Comm_size(MPI_COMM_WORLD, size, ierr)

    call initialise()
    call simulate()
    call finalise()
    
    call MPI_Finalize(ierr)

contains

    subroutine initialise()
        integer :: comm = -1
        type(xios_date) :: origin
        type(xios_date) :: start
        type(xios_duration) :: tstep

        ! XIOS initialization
        call xios_initialize("client", return_comm=comm)
        call xios_context_initialize("main", comm)

        ! Arbitrary datetime setup, required for XIOS but unused
        ! in this example
        origin = xios_date(2024, 1, 1, 0, 0, 0)
        start = xios_date(2024, 1, 1, 0, 0, 0)
        tstep = xios_hour

        call xios_set_time_origin(origin)
        call xios_set_start_date(start)
        call xios_set_timestep(tstep)

        ! Closing definition
        call xios_close_context_definition()

    end subroutine initialise


    subroutine finalise()
        ! Finalise XIOS and MPI
        call xios_context_finalize()

        call xios_finalize()

    end subroutine finalise


    subroutine simulate()
        integer :: ts, i
        double precision, allocatable :: a_field (:)

        ALLOCATE ( a_field(10) )

        ! Entering time loop
        ! Send 96 timesteps (4 days)
        do ts=1,96
            ! do i=1,10
            !     a_field(i) = 10 * ts + i
            ! enddo
            a_field(:) = ts
            call xios_update_calendar(ts)
            call xios_send_field("a_field", a_field)
        enddo

    end subroutine simulate

end program timesteps