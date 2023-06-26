init:
	@../../makefile.sh init

prep_vars: check_uuid
	@if [ -d files ] && [ ! -f files/config/init-cfg.txt ]; then cp files/config/init-cfg.sample.txt files/config/init-cfg.txt; fi

validate:
	@../../makefile.sh validate

test:
	@../../makefile.sh test

destroy:
	@../../makefile.sh destroy

check_uuid:
ifndef UUID
	$(info Missing UUID, generate one for yourself using command:)
	$(info export UUID=$$(uuidgen | tr '[:upper:]' '[:lower:]'))
	$(error )
else
RG := $(shell echo ${UUID} | cut -d '-' -f 1,5)
PREFIX := ghci$(shell echo ${UUID} | cut -d '-' -f 2)-
STORAGE := $(shell echo ${UUID} | cut -d '-' -f 2,3,4 | tr -d '-')
endif