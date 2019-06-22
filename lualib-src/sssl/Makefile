# Quick instruction:
# To build against an OpenSSL built in the source tree, do this:
#
#    make OPENSSL_INCS_LOCATION=-I../../include OPENSSL_LIBS_LOCATION=-L../..
#
# To run the demos when linked with a shared library (default):
#
#    LD_LIBRARY_PATH=../.. ./aesccm
#    LD_LIBRARY_PATH=../.. ./aesgcm

CFLAGS = $(OPENSSL_INCS_LOCATION)
LDFLAGS = $(OPENSSL_LIBS_LOCATION) -lssl -lcrypto -lpthread -lm -ldl

all: ./../../ssock

./../../ssock: ssock_test.c ssock.c sssl.c write_buffer.c
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)	

clean:
	$(RM) aesccm aesgcm *.o
