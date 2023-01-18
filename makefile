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
uname_p := $(shell uname -p)
ifeq ($(uname_p),x86_64)
OS=linux
else
OS=linux-arm
endif
endif
endif
endif
else
OS=windows
endif

.PHONY: release

GENIE=bin/$(OS)/genie
PROJECT_TYPE?=gmake

SILENT?=@

$(GENIE):
	$(SILENT) $(MAKE) -C build/$(PROJECT_TYPE).$(OS)
	./bin/$(OS)/genie vs2022

all: $(SILENT) $(GENIE)

clean:
	$(SILENT) $(MAKE) -C build/$(PROJECT_TYPE).$(OS) clean
	$(SILENT) -rm -rf bin

projgen:
	$(SILENT) $(GENIE) --to=../build/$(PROJECT_TYPE).windows   --os=windows $(PROJECT_TYPE)
	$(SILENT) $(GENIE) --to=../build/$(PROJECT_TYPE).linux     --os=linux --platform=x64 $(PROJECT_TYPE)
	$(SILENT) $(GENIE) --to=../build/$(PROJECT_TYPE).linux-arm --os=linux --platform=ARM64 $(PROJECT_TYPE)
	$(SILENT) $(GENIE) --to=../build/$(PROJECT_TYPE).darwin    --os=macosx --platform=universal32 $(PROJECT_TYPE)
	$(SILENT) $(GENIE) --to=../build/$(PROJECT_TYPE).freebsd   --os=bsd $(PROJECT_TYPE)

rebuild:
	$(SILENT) $(MAKE) -C build/$(PROJECT_TYPE).$(OS) clean all

release-windows release-darwin: $(GENIE)
	$(GENIE) release
	$(SILENT) $(MAKE) -C build/$(PROJECT_TYPE).$(OS) clean all
	$(SILENT) git checkout src/host/version.h

release-linux release-linux-arm: $(GENIE)
	$(SILENT) $(GENIE) release
	$(SILENT) $(MAKE) -C build/$(PROJECT_TYPE).darwin    clean all CC=x86_64-apple-darwin20.2-clang
	$(SILENT) $(MAKE) -C build/$(PROJECT_TYPE).linux     clean all
	$(SILENT) $(MAKE) -C build/$(PROJECT_TYPE).linux-arm clean all
	$(SILENT) $(MAKE) -C build/$(PROJECT_TYPE).windows   clean all CC=x86_64-w64-mingw32-gcc
	$(SILENT) git checkout src/host/version.h
	cp bin/linux-arm/genie   ../bx/tools/bin/linux-arm/

release: release-$(OS)

dist: release
	cp bin/linux/genie       ../bx/tools/bin/linux/
	cp bin/linux-arm/genie   ../bx/tools/bin/linux-arm/
	cp bin/windows/genie.exe ../bx/tools/bin/windows/
	cp bin/darwin/genie      ../bx/tools/bin/darwin/
