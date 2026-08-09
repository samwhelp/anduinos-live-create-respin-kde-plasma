
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
	@echo '	$$ make prepare'
	@echo '	$$ make build'
	@echo '	$$ make clean'
	@echo
.PHONY: help




prepare:
	make prepare -C template/engine
.PHONY: prepare


build:
	make build -C template/engine
.PHONY: build


clean:
	make clean -C template/engine
.PHONY: clean
