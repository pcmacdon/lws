# Makefile to create lws.c and lwsOne.c
# TODO: create miniz.c
LWSVER=2.2

TARGET=unix
LWSBASE=src
CFLAGS  = -g -Wall -I$(SOURCEDIR)

ifeq ($(MINIZ),1)
CFLAGS += -I../miniz
endif

SOURCEDIR=$(LWSBASE)
LWSINT=$(LWSBASE)
LWSLIBNAME=liblws_$(TARGET).a

SOURCES = $(SOURCEDIR)/base64-decode.c $(SOURCEDIR)/handshake.c $(SOURCEDIR)/liblws.c \
	$(SOURCEDIR)/service.c $(SOURCEDIR)/pollfd.c $(SOURCEDIR)/output.c $(SOURCEDIR)/parsers.c \
	$(SOURCEDIR)/context.c $(SOURCEDIR)/alloc.c $(SOURCEDIR)/header.c $(SOURCEDIR)/client.c \
	$(SOURCEDIR)/client-handshake.c $(SOURCEDIR)/client-parser.c $(SOURCEDIR)/sha-1.c \
	$(SOURCEDIR)/server.c $(SOURCEDIR)/server-handshake.c \
	$(SOURCEDIR)/extension.c $(SOURCEDIR)/extension-permessage-deflate.c $(SOURCEDIR)/ranges.c

ifeq ($(LWSSSL),1)
SSLSOURCES += $(SOURCEDIR)/ssl.c $(SOURCEDIR)/ssl-client.c $(SOURCEDIR)/ssl-server.c $(SOURCEDIR)/ssl-http2.c
endif


WFILES = $(SOURCEDIR)/lws-plat-win.c 
UFILES = $(SOURCEDIR)/lws-plat-unix.c 

ifeq ($(WIN),1)
CFLAGS +=  -D__USE_MINGW_ANSI_STDIO -I$(SOURCEDIR)/../win32port/win32helpers
endif

LWSFLAGS = -DLWS_WITHOUT_TESTAPPS=1 -DWITH_SSL=0  \
	-DLWS_WITH_SSL=0 -DLWS_WITH_ZLIB=0 -DLWS_USE_BUNDLED_ZLIB=0 -DLWS_WITHOUT_EXTENSIONS=1

ifeq ($(WIN),1)
LWSFLAGS += -DLWS_USE_BUNDLED_ZLIB=1 -DLWS_WITH_STATIC=1 -DLWS_WITH_SHARED=0
endif

all: lws.c lwsOne.c

checkver:
	rm -f src && ln -sf liblws-$(LWSVER) src

# Create the single amalgamation file lws.c
lws.c: $(SOURCEDIR)/liblws.h $(SOURCES) $(SSLSOURCES) $(MAKEFILE)
	cat $(SOURCEDIR)/liblws.h > $@
	echo "#ifndef LWS_IN_AMALGAMATION" >> $@
	echo "#define LWS_IN_AMALGAMATION" >> $@
	echo "#define _GNU_SOURCE"  >> $@
	echo "#define LWS_AMALGAMATION" >> $@
	#echo "#if LWS__MINIZ==1" >> $@
	#cat $(MINIZDIR)/miniz.c >> $@
	#echo "#endif //LWS__MINIZ==1 " >> $@
	cat $(SOURCES) $(SSLSOURCES) | grep -v '^#line' >> $@
	echo "#ifndef WIN32" >> $@
	cat $(WFILES)  >> $@
	echo "#else // WIN32" >> $@
	cat $(UFILES)  >> $@
	echo "#endif //WIN32" >> $@
	echo "#endif //LWS_IN_AMALGAMATION" >> $@

# Create the single compile file lwsOne.c
lwsOne.c: $(SOURCEDIR)/liblws.h   $(SOURCES) $(SSLSOURCES) $(MAKEFILE)
	echo '#include "$(SOURCEDIR)/liblws.h"' > $@
	echo "#define LWS_AMALGAMATION" >> $@
	echo "#if LWS__MINIZ==1" >> $@
	echo '#include "'$(MINIZDIR)/miniz.c'"' >> $@
	echo "#endif //LWS__MINIZ==1" >> $@
	for ii in  $(SOURCES) $(SSLSOURCES) $(PCFILES); do echo '#include "'$$ii'"' >> $@; done
	echo "#ifdef WIN32" >> $@
	for ii in $(WFILES); do echo '#include "'$$ii'"' >> $@; done
	echo "#else // WIN32" >> $@
	for ii in $(UFILES); do echo '#include "'$$ii'"' >> $@; done
	echo "#endif //WIN32" >> $@


liblws: $(LWSLIBNAME)

$(LWSLIBNAME): lwsOne.c
	$(CC) -c -o $@ lwsOne.c $(CFLAGS) -Isrc/$(TARGET)


clean:
	rm -f liblws_*.a

cleanall: clean
	
.PHONY: all depend remake clean cleanall
