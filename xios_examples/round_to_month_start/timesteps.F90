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
        type(xios_date) :: start
        type(xios_date) :: month_start
        type(xios_duration) :: offset
        type(xios_duration) :: tstep

        ! XIOS initialization
        call xios_initialize("client", return_comm=comm)
        call xios_context_initialize("main", comm)

        ! Set timestep
        tstep = xios_day
        call xios_set_timestep(tstep)

        ! Get start date from XML config
        call xios_get_start_date(start)
        month_start = start

        ! Increment month if not already at the start of a month
        if (month_start%day > 1) then
            month_start%month = month_start%month + 1
        endif

        ! Set day to the first of the month.
        ! Don't zero hours, minutes, or seconds as this would cause the offset
        ! freqency to contain non zero hours, minutes and seconds. This would
        ! cause a segmentation fault as the offset frequency must be a multiple
        ! of the timestep.
        month_start%day = 1

        offset = month_start - start

        call xios_set_field_attr("a_field", freq_offset=offset)

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
        type(xios_date) :: current_date
        double precision, allocatable :: a_field (:)

        allocate ( a_field(10) )

        ! Entering time loop
        ! Send 96 timesteps
        do ts=1,96
            call xios_get_current_date(current_date)
            call xios_update_calendar(ts)
            a_field(:) = 100 * current_date%month + current_date%day
            call xios_send_field("a_field", a_field)
        enddo

        deallocate ( a_field )

    end subroutine simulate

end program timesteps
