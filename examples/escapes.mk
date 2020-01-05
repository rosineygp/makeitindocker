.EXPORT_ALL_VARIABLES:
.ONESHELL:
SHELL = /bin/bash

define . =
	source .mkdkr
	$(eval MKDKR_JOB_NAME=$(shell bash -c 'source .mkdkr; .... $(@)'))
	trap '.' EXIT
endef

# nothing special here, just add backslashes
multiline:
	@$(.)
	... alpine
	.. apk add htop \
		vim \
		bash

# add quote in && to not back to local terminal
logical_and:
	@$(.)
	... ubuntu:18.04
	.. 'apt-get update && \
			apt-get install -y \
			htop \
			vim \
			csh'

# add quote to pipes also
pipes:
	@$(.)
	... ubuntu:18.04
	.. "find . -iname '*.mk' -type f -exec cat {} \; | grep -c escapes"

# you can redirect a output to outside container
redirect_to_outside:
	@$(.)
	... ubuntu:18.04
	.. dpkg -l > dpkg_report.txt
	cat dpkg_report.txt            # outside container

all: multiline logical_and pipes redirect_to_outside