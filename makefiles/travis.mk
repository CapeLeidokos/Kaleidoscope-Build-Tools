# Copyright (C) 2018  Keyboard.io, Inc.
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, version 3.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program. If not, see <http://www.gnu.org/licenses/>.

## Note: This file is meant to be included by Kaleidoscope, or a bundle, not by
## individual examples or sketches!

MAKEFILE_RULES_DIR          := $(dir $(lastword ${MAKEFILE_LIST}))
BOARD_HARDWARE_PATH         ?= $(abspath $(dir $(lastword ${MAKEFILE_LIST}))../../../)

include ${MAKEFILE_RULES_DIR}/verbose.mk

TRAVIS_ARDUINO              ?= arduino-1.8.2
TRAVIS_ARDUINO_FILE         ?= ${TRAVIS_ARDUINO}-linux64.tar.xz
TRAVIS_ARDUINO_PATH         ?= ${CURDIR}/${TRAVIS_ARDUINO}
TRAVIS_ARDUINO_DOWNLOAD_URL ?= http://downloads.arduino.cc/${TRAVIS_ARDUINO_FILE}

.DEFAULT_GOAL := build

travis-test: travis-build travis-check-astyle
test: build check-astyle cpplint-noisy

.PHONY: travis-test travis-smoke-examples travis-check-astyle
.PHONY: test smoke-examples cpplint cpplint-noisy
.PHONY: travis-install-arduino

%:
	for e in $(shell echo ${EXAMPLES} | sort); do \
		${MAKE} -C $$e $@; \
	done

## NOTE: HERE BE DRAGONS, DO NOT CLEAN THIS UP!
# When building outside of the bundle, we want to use the current library, not
# whatever version is in the bundle at the time. To do so, we must tell
# arduino-builder about the library, because the current directory is not
# considered by default.
#
# Now, we can't use -libraries ., because arduino-builder will search for a
# directory named like the library, and we don't have that. We are already in
# the library directory at this point.
#
# So, we need a library outside of the current dir. We could use .., but we want
# to be safe, to only have the current library there. For this reason, the
# travis-build target will create a current-libraries directory one level up,
# symlink the current directory there, under the library name, and add
# -libraries $(pwd)/../current-libraries to the arduino-builder arguments.
#
# All of this makes the builder consider the current library the best to use.
travis-build: travis-install-arduino
travis-%:
	install -d ../current-libraries
	rm ../current-libraries/* && ln -s $$(pwd) ../current-libraries/
	ARDUINO_PATH="$(TRAVIS_ARDUINO_PATH)" BOARD_HARDWARE_PATH="$(BOARD_HARDWARE_PATH)" ARDUINO_BUILDER_ARGS="-libraries $$(pwd)/../current-libraries" ${MAKE} $*
	rm -rf ../current-libraries

travis-install-arduino:
	@if [ ! -d "$(TRAVIS_ARDUINO_PATH)" ]; then \
		echo "Installing Arduino..."; \
		wget -O "$(TRAVIS_ARDUINO_FILE)" -c $(TRAVIS_ARDUINO_DOWNLOAD_URL); \
		tar xf $(TRAVIS_ARDUINO_FILE); \
	fi

travis-smoke-examples:
	${MAKE} travis-build

.PHONY: travis-install-arduino travis-%