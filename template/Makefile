
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
	make prepare -C engine
.PHONY: prepare


build:
	make build -C engine
.PHONY: build


clean:
	make clean -C engine
.PHONY: clean
