#
# Copyright 2011-2014 Branimir Karadzic. All rights reserved.
# License: http://www.opensource.org/licenses/BSD-2-Clause
#

UNAME := $(shell uname)
ifeq ($(UNAME),$(filter $(UNAME),Linux Darwin))
ifeq ($(UNAME),$(filter $(UNAME),Darwin))
OS=darwin
else
OS=linux
endif
else
OS=windows
endif

.PHONY: release

GENIE=../bx/tools/bin/$(OS)/genie

all:
	make -C build/gmake.$(OS)

rebuild:
	make -C build/gmake.$(OS) clean all

release:
	bin/release/genie release
	make -C build/gmake.$(OS) clean all
	git checkout src/host/version.h
