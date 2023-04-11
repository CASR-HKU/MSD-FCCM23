ifeq ($(BOARD_PART_REPO),)
$(error BOARD_PART_REPO is not set)
endif

all: clean
	$(MAKE) prj
	$(MAKE) gen

prj:
	vivado -mode batch -source project.tcl > /dev/null 
	@echo "Project created"

gen:
	vivado -mode batch -source output_gen.tcl > /dev/null
	@echo "Vivado design flow finished"

clean:
	rm -rf msd_hw_zcu102* vivado* .Xil