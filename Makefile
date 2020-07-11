# Makefile to create lws.c and lwsOne.c
# TODO: create miniz.c
LWS_VER=2.0202
LWS_SSL=0
LWS_MINIZ=0   # 1=external provide, 2=internally provided
LWS_CFLAGS=

TARGET=unix
LWSBASE=src
CFLAGS=-g -Wall -I$(SOURCEDIR) $(LWS_CFLAGS)

SOURCEDIR=$(LWSBASE)
LWSINT=$(LWSBASE)
LWSLIBNAME=liblws_$(TARGET)-$(LWS_VER).a

SOURCES = $(SOURCEDIR)/base64-decode.c $(SOURCEDIR)/handshake.c $(SOURCEDIR)/lws.c \
	$(SOURCEDIR)/service.c $(SOURCEDIR)/pollfd.c $(SOURCEDIR)/output.c $(SOURCEDIR)/parsers.c \
	$(SOURCEDIR)/context.c $(SOURCEDIR)/alloc.c $(SOURCEDIR)/header.c $(SOURCEDIR)/client.c \
	$(SOURCEDIR)/client-handshake.c $(SOURCEDIR)/client-parser.c $(SOURCEDIR)/sha-1.c \
	$(SOURCEDIR)/server.c $(SOURCEDIR)/server-handshake.c \
	$(SOURCEDIR)/extension.c $(SOURCEDIR)/extension-permessage-deflate.c $(SOURCEDIR)/ranges.c



ifeq ($(LWS_MINIZ),1)
CFLAGS += -Iminiz
endif
ifeq ($(LWS_MINIZ),2)
CFLAGS += -DLWS_MINIZ=1
endif

SSLSOURCES += $(SOURCEDIR)/ssl.c $(SOURCEDIR)/ssl-client.c $(SOURCEDIR)/ssl-server.c
#$(SOURCEDIR)/ssl-http2.c $(SOURCEDIR)/http2.c

ifeq ($(LWS_SSL),1)
CFLAGS += -DLWS_OPENSSL_SUPPORT=1 -DLWS_WITH_SSL=1 
#-DLWS_USE_HTTP2=1
CFLAGS += -I$(HOME)/usr/openssl/include
endif


WFILES = $(SOURCEDIR)/lws-plat-win.c 
UFILES = $(SOURCEDIR)/lws-plat-unix.c 

ifeq ($(WIN),1)
CFLAGS +=  -D__USE_MINGW_ANSI_STDIO -I$(SOURCEDIR)/../win32port/win32helpers
endif

all: lws.c lwsOne.c liblws

# Create the single amalgamation file lws.c
lws.c: $(SOURCEDIR)/lws.h $(SOURCES) $(SSLSOURCES) $(MAKEFILE)
	cat $(SOURCEDIR)/lws.h > $@
	echo "#ifndef LWS_IN_AMALGAMATION" >> $@
	echo "#define LWS_IN_AMALGAMATION" >> $@
	echo "#define _GNU_SOURCE"  >> $@
	echo "#define LWS_AMALGAMATION" >> $@
	echo "#if LWS_MINIZ==1" >> $@
	cat miniz/miniz.c >> $@
	echo "#endif //LWS_MINIZ==1 " >> $@
	cat $(SOURCES) | grep -v '^#line' >> $@
	echo "#if LWS_WITH_SSL==1" >> $@
	cat $(SSLSOURCES) | grep -v '^#line' >> $@
	echo "#endif //LWS_WITH_SSL==1 " >> $@
	echo "#ifndef WIN32" >> $@
	cat $(WFILES)  >> $@
	echo "#else // WIN32" >> $@
	cat $(UFILES)  >> $@
	echo "#endif //WIN32" >> $@
	echo "#endif //LWS_IN_AMALGAMATION" >> $@

# Create the single compile file lwsOne.c
lwsOne.c: $(SOURCEDIR)/lws.h   $(SOURCES) $(SSLSOURCES) $(MAKEFILE)
	echo '#include "$(SOURCEDIR)/lws.h"' > $@
	echo "#define LWS_AMALGAMATION" >> $@
	echo "#if LWS_MINIZ==1" >> $@
	echo '#include "'miniz/miniz.c'"' >> $@
	echo "#endif //LWS_MINIZ==1" >> $@
	for ii in  $(SOURCES); do echo '#include "'$$ii'"' >> $@; done
	echo "#if LWS_WITH_SSL==1" >> $@
	for ii in  $(SSLSOURCES); do echo '#include "'$$ii'"' >> $@; done
	echo "#endif //LWS_WITH_SSL==1" >> $@
	echo "#ifdef WIN32" >> $@
	for ii in $(WFILES); do echo '#include "'$$ii'"' >> $@; done
	echo "#else // WIN32" >> $@
	for ii in $(UFILES); do echo '#include "'$$ii'"' >> $@; done
	echo "#endif //WIN32" >> $@


liblws: $(LWSLIBNAME)

$(LWSLIBNAME): lwsOne.c
	$(CC) -c -o $@ lwsOne.c $(CFLAGS)


clean:
	rm -f liblws_*.a

cleanall: clean
	
.PHONY: all depend remake clean cleanall
