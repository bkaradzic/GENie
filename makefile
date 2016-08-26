#
# Copyright 2011-2014 Branimir Karadzic. All rights reserved.
# License: http://www.opensource.org/licenses/BSD-2-Clause
#

UNAME := $(shell uname)
ifeq ($(UNAME),$(filter $(UNAME),Linux Darwin SunOS FreeBSD GNU/kFreeBSD NetBSD OpenBSD GNU))
ifeq ($(UNAME),$(filter $(UNAME),Darwin))
OS=darwin
else
ifeq ($(UNAME),$(filter $(UNAME),SunOS))
OS=solaris
else
ifeq ($(UNAME),$(filter $(UNAME),FreeBSD GNU/kFreeBSD NetBSD OpenBSD))
OS=bsd
else
OS=linux
endif
endif
endif
else
OS=windows
endif

.PHONY: release

GENIE=bin/$(OS)/genie

SILENT?=@

$(GENIE):
	$(SILENT) $(MAKE) -C build/gmake.$(OS)

all: $(SILENT) $(GENIE)

clean:
	$(SILENT) $(MAKE) -C build/gmake.$(OS) clean
	$(SILENT) -rm -rf bin

projgen:
	$(SILENT) $(GENIE) --to=../build/gmake.windows --os=windows gmake
	$(SILENT) $(GENIE) --to=../build/gmake.linux --os=linux gmake
	$(SILENT) $(GENIE) --to=../build/gmake.darwin --os=macosx --platform=universal32 gmake
	$(SILENT) $(GENIE) --to=../build/gmake.freebsd --os=bsd gmake

rebuild:
	$(SILENT) $(MAKE) -C build/gmake.$(OS) clean all

release-windows release-darwin: $(GENIE)
	$(GENIE) release
	$(SILENT) $(MAKE) -C build/gmake.$(OS) clean all
	$(SILENT) git checkout src/host/version.h

release-linux: $(GENIE)
	$(SILENT) $(GENIE) release
	$(SILENT) $(MAKE) -C build/gmake.darwin  clean all CC=x86_64-apple-darwin15-clang
	$(SILENT) $(MAKE) -C build/gmake.linux   clean all
	$(SILENT) $(MAKE) -C build/gmake.windows clean all CC=i686-w64-mingw32-gcc
	$(SILENT) git checkout src/host/version.h

release: release-$(OS)

dist: release
	cp bin/linux/genie       ../bx/tools/bin/linux/
	cp bin/windows/genie.exe ../bx/tools/bin/windows/
	cp bin/darwin/genie      ../bx/tools/bin/darwin/
