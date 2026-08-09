
default: help
.PHONY: default

help:
	@echo 'Usage:'
	@echo '	$$ make [action]'
	@echo
	@echo 'Example:'
	@echo '	$$ make'
	@echo '	$$ make help'
	@echo
	@echo '	$$ make clean'
	@echo
	@echo '	$$ make create-core-system'
	@echo '	$$ make create-base-system'
	@echo '	$$ make create-basic-system'
	@echo '	$$ make create-full-system'
	@echo
	@echo '	$$ make mount'
	@echo '	$$ make unmount'
	@echo
	@echo '	$$ make chroot'
	@echo
	@echo '	$$ make archive-system-to-iso'
	@echo
	@echo '	$$ make prepare'
	@echo '	$$ make build'
	@echo
.PHONY: help




clean:
	@./to-clean.sh
.PHONY: clean




create-core-system:
	@./to-create-core-system.sh
.PHONY: create-core-system


create-base-system:
	@./to-create-base-system.sh
.PHONY: create-base-system


create-basic-system:
	@./to-create-basic-system.sh
.PHONY: create-basic-system


create-full-system:
	@./to-create-full-system.sh
.PHONY: create-full-system




mount:
	@./to-mount.sh
.PHONY: mount


unmount:
	@./to-unmount.sh
.PHONY: unmount




chroot:
	@./to-chroot.sh
.PHONY: chroot




archive-system-to-iso:
	@./to-archive-system-to-iso.sh
.PHONY: archive-system-to-iso




prepare:
	@./to-prepare.sh
.PHONY: prepare


build:
	@./build.sh
.PHONY: build
