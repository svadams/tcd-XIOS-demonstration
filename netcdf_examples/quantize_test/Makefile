# Makefile intital

CC = cc

all: quantize

# added CFFLAGS, LDFLAGS and package lm to both
quantize: quantize.c quantize.h quantize_params.c
	$(CC) $(CFLAGS) quantize.c $(LDFLAGS) -lnetcdf -lm -o quantize.exe

quantize_github: quantize.c quantize.h quantize_params.c
	$(CC) $(CFLAGS) quantize.c $(LDFLAGS) -lnetcdf -lm -o quantize.exe

clean:
	rm -rf *exe core *nc
