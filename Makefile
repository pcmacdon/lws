# Makefile to create lws.c and lwsOne.c
# TODO: create lws.h, add miniz.c
LWSVER=2.2

TARGET=unix
LWSBASE=src
CFLAGS  = -g -Wall -I$(SOURCEDIR) -I$(TARGET)/

ifeq ($(MINIZ),1)
CFLAGS += -I../miniz
endif

SOURCEDIR=$(LWSBASE)/lib
LWSINT=$(LWSBASE)
BUILDDIR=build/$(TARGET)
LWSLIBNAME=libwebsockets.a
LWSLIBBUILD=$(LWSLIBNAME)
CMAKE=cmake
DOCMAKE=0

LWSLIB=build/$(TARGET)/$(LWSLIBNAME)

SOURCES = $(SOURCEDIR)/base64-decode.c $(SOURCEDIR)/handshake.c $(SOURCEDIR)/libwebsockets.c \
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
SOURCES += $(WFILES)
else
SOURCES += $(UFILES)
endif

OBJLST  = $(SOURCES:.c=.o)
OBJECTS	= $(patsubst $(SOURCEDIR)/%,$(BUILDDIR)/%,$(OBJLST))

USECMAKE=
# Detect cmake and use it if not disabled.
ifeq ($(USECMAKE),)
CMAKEPATH := $(shell which $(CMAKE) )
ifneq ($(CMAKEPATH),)
DOCMAKE=1
endif
endif

LWSFLAGS = -DLWS_WITHOUT_TESTAPPS=1 -DCMAKE_C_FLAGS=-Wno-error -DWITH_SSL=0  \
	-DLWS_WITH_SSL=0 -DLWS_WITH_ZLIB=0 -DLWS_USE_BUNDLED_ZLIB=0 -DLWS_WITHOUT_EXTENSIONS=1

ifeq ($(WIN),1)
LWSFLAGS += -DLWS_USE_BUNDLED_ZLIB=1 -DCMAKE_TOOLCHAIN_FILE=../../$(LWSBASE)/cross-ming.cmake \
	-DCMAKE_INSTALL_PREFIX:PATH=/usr -DLWS_WITH_STATIC=1 -DLWS_WITH_SHARED=0
LWSLIBBUILD=libwebsockets_static.a
endif

all: lws.c lwsOne.c

mkdirs:
	mkdir -p $(BUILDDIR)

checkver:
	rm -f src && ln -sf libwebsockets-$(LWSVER) src

# Create the single amalgamation file lws.c
lws.c: $(SOURCEDIR)/libwebsockets.h $(SOURCES) $(SSLSOURCES) $(MAKEFILE)
	cat $(SOURCEDIR)/libwebsockets.h > $@
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
lwsOne.c: $(SOURCEDIR)/libwebsockets.h   $(SOURCES) $(SSLSOURCES) $(MAKEFILE)
	echo '#include "$(SOURCEDIR)/libwebsockets.h"' > $@
	echo "#define LWS_AMALGAMATION" >> $@
	echo "#if LWS__MINIZ==1" >> $@
	echo '#include "'$(MINIZDIR)/miniz.c'"' >> $@
	echo "#endif //LWS__MINIZ==1" >> $@
	for ii in  $(SOURCES) $(SSLSOURCES) src/lwsCode.c $(PCFILES); do echo '#include "'$$ii'"' >> $@; done
	echo "#ifndef WIN32" >> $@
	for ii in $(WFILES); do echo '#include "'$$ii'"' >> $@; done
	echo "#else // WIN32" >> $@
	for ii in $(UFILES); do echo '#include "'$$ii'"' >> $@; done
	echo "#endif //WIN32" >> $@


ifeq ($(DOCMAKE),1)
$(BUILDDIR)/libwebsockets.a:
	( mkdir -p $(BUILDDIR) && cd $(BUILDDIR) && CC=$(CC) AR=$(AR) $(CMAKE) ../../$(LWSBASE) $(LWSFLAGS)   && $(MAKE) CC=$(CC) AR=$(AR) && cp lib/$(LWSLIBBUILD) libwebsockets.a)
else

$(BUILDDIR)/%.o: $(SOURCEDIR)/%.c
	$(CC) -c -o $@ $< $(CFLAGS) 

$(BUILDDIR)/libwebsockets.a: $(OBJECTS)
	$(AR) rv $@ $(OBJECTS)

endif

clean:
	rm -f $(OBJECTS) $(BUILDDIR)/libwebsockets.a

cleanall: clean
	rm -rf build
	
.PHONY: all depend remake clean cleanall
