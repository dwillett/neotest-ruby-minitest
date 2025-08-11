PLENARY_DIR = misc/plenary

.PHONY: deps test clean

deps:
	@test -d $(PLENARY_DIR) || git clone --depth=1 https://github.com/nvim-lua/plenary.nvim $(PLENARY_DIR)

test: deps
	nvim --headless --clean \
	  -u minimal_init.lua \
	  -c "PlenaryBustedDirectory tests"

clean:
	rm -rf $(PLENARY_DIR)

