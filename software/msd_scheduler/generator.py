import configparser
from utils import floor_func, ceil_func, sqrt_func


class Generator(object):
    def __init__(self, device_file=""):
        """ Initialize hardware generator
            bs: bit-serial
            bp: bit-parallel

        Args:
            device_file (str, optional): FPGA device configuration file.
        """
        self.hw_device = configparser.ConfigParser()
        self.hw_device.read(device_file)
        self.mem_bandwidth = self.hw_device.getint(
            "system", "memory_bandwidth")
        self.frequency = self.hw_device.getint("system", "frequency")

        self.max_lut = self.hw_device.getint(
            "resource", "device_LUTs")
        self.max_ff = self.hw_device.getint("resource", "device_FFs")
        self.max_bram36 = self.hw_device.getint(
            "resource", "device_BRAM36")
        self.max_dsp = self.hw_device.getint("resource", "device_DSP48E2")

        self.bs_pe_lut = self.hw_device.getint("cost", "BS_PE_LUTs")
        self.bs_pe_ff = self.hw_device.getint(
            "cost", "BS_PE_FFs")
        self.bp_pe_lut = self.hw_device.getint(
            "cost", "BP_PE_LUTs")
        self.bp_pe_ff = self.hw_device.getint(
            "cost", "BP_PE_FFs")
        self.bp_pe_dsp = self.hw_device.getint("cost", "BP_PE_DSPs")
        self.other_lut = self.hw_device.getint("cost", "other_module_LUTs")
        self.other_ff = self.hw_device.getint("cost", "other_module_FFs")

    def bram_depth_calculator(self, bram18_utl, data_width=8):
        bram_bit_utl = bram18_utl * 16384
        bram_depth = ceil_func(bram_bit_utl, data_width)
        return bram_depth

    def gen_maximum_arch(self, hw_arch_ini=""):
        """ Generate maximum systolic array for both BS core and BP core
            TODO: add memory generation
        Args:
            hw_arch_ini (str, optional): hardware architecture file (target location).
        """
        ff = open(hw_arch_ini, "w")

        # stage I: generate all the possible bp archs (based on DSP)
        bp_comb = []
        for bp_r in range(9, floor_func(self.max_dsp, (9*self.bp_pe_dsp))):
            bp_c = floor_func(self.max_dsp, (bp_r*self.bp_pe_dsp))
            bp_lut_cost = bp_r * bp_c * self.bp_pe_lut
            bp_ff_cost = bp_r * bp_c * self.bp_pe_ff
            bp_comb.append([bp_r, bp_c, bp_lut_cost, bp_ff_cost])

        # stage II: generate the optimal bs archs with each bp arch
        # TODO: build an optimizer to generate better arch (with different rows and cols)
        bs_opt_rc = 0
        opt_arch = []
        for bp_arch in bp_comb:
            bs_max_lut = self.max_lut - bp_arch[2] - self.other_lut
            bs_max_ff = self.max_ff - bp_arch[3] - self.other_ff
            bs_max_arch = min(sqrt_func(floor_func(bs_max_lut, self.bs_pe_lut)), sqrt_func(
                floor_func(bs_max_ff, self.bs_pe_ff)))
            if bs_max_arch > bs_opt_rc:
                bs_opt_rc = bs_max_arch
                opt_arch = [bs_opt_rc, bp_arch[0], bp_arch[1]]

        # check if the optimal architecture is under constraint
        util_lut = opt_arch[0] * opt_arch[0] * self.bs_pe_lut + \
            opt_arch[1] * opt_arch[2] * self.bp_pe_lut + self.other_lut
        util_ff = opt_arch[0] * opt_arch[0] * self.bs_pe_ff + \
            opt_arch[1] * opt_arch[2] * self.bp_pe_ff + self.other_ff
        util_dsp = opt_arch[1] * opt_arch[2] * self.bp_pe_dsp

        assert util_lut <= self.max_lut, "LUT overflow"
        assert util_ff <= self.max_ff, "FF overflow"
        assert util_dsp <= self.max_dsp, "DSP overflow"

        # generate memory
        bram_18 = self.max_bram36 * 2
        bs_wgt_banks = opt_arch[0]
        bs_ifm_banks = opt_arch[0]
        bp_wgt_banks = opt_arch[1]
        bp_wgt_banks = opt_arch[2]

        # considering double buffer here

        ff.write("[system]\n")
        ff.write("hardware_bandwidth = " + str(self.mem_bandwidth) + '\n')
        ff.write("hardware_frequency = " + str(self.frequency) + '\n')
        ff.write('\n')
        ff.write("[array]\n")
        ff.write("bs_rows = " + str(opt_arch[0]) + '\n')
        ff.write("bs_cols = " + str(opt_arch[0]) + '\n')
        ff.write("bp_rows = " + str(opt_arch[1]) + '\n')
        ff.write("bp_cols = " + str(opt_arch[2]) + '\n')
        ff.close()

    def get_maximum_arch_simp(self, hw_arch_ini=""):
        """ Generate maximum systolic array for both BS core and BP core
            TODO: add memory generation
        Args:
            hw_arch_ini (str, optional): hardware architecture file (target location).
        """
        ff = open(hw_arch_ini, "w")

        # stage I: generate all the possible bp archs (based on DSP)
        bp_rows = sqrt_func(self.max_dsp*0.9)
        bp_cols = bp_rows
        bp_lut_cost = bp_rows * bp_cols * self.bp_pe_lut
        bp_ff_cost = bp_rows * bp_cols * self.bp_pe_ff

        # stage II: generate the optimal bs archs with each bp arch
        # TODO: build an optimizer to generate better arch (with different rows and cols)
        bs_opt_rc = 0
        opt_arch = []
        bs_max_lut = self.max_lut - bp_lut_cost - self.other_lut
        bs_max_ff = self.max_ff - bp_ff_cost - self.other_ff
        bs_max_arch = min(sqrt_func(floor_func(bs_max_lut*0.7, self.bs_pe_lut)), sqrt_func(
            floor_func(bs_max_ff*0.7, self.bs_pe_ff)))
        bs_opt_rc = bs_max_arch
        opt_arch = [bs_opt_rc, bp_rows, bp_cols]

        # check if the optimal architecture is under constraint
        util_lut = opt_arch[0] * opt_arch[0] * self.bs_pe_lut + \
            opt_arch[1] * opt_arch[2] * self.bp_pe_lut + self.other_lut
        util_ff = opt_arch[0] * opt_arch[0] * self.bs_pe_ff + \
            opt_arch[1] * opt_arch[2] * self.bp_pe_ff + self.other_ff
        util_dsp = opt_arch[1] * opt_arch[2] * self.bp_pe_dsp

        assert util_lut <= self.max_lut, "LUT overflow"
        assert util_ff <= self.max_ff, "FF overflow"
        assert util_dsp <= self.max_dsp, "DSP overflow"

        # generate memory
        bram_18 = self.max_bram36 * 2
        bs_wgt_banks = opt_arch[0]
        bs_ifm_banks = opt_arch[0]
        bp_wgt_banks = opt_arch[1]
        bp_wgt_banks = opt_arch[2]

        # considering double buffer here

        ff.write("[system]\n")
        ff.write("hardware_bandwidth = " + str(self.mem_bandwidth) + '\n')
        ff.write("hardware_frequency = " + str(self.frequency) + '\n')
        ff.write('\n')
        ff.write("[array]\n")
        ff.write("bs_rows = " + str(opt_arch[0]) + '\n')
        ff.write("bs_cols = " + str(opt_arch[0]) + '\n')
        ff.write("bp_rows = " + str(opt_arch[1]) + '\n')
        ff.write("bp_cols = " + str(opt_arch[2]) + '\n')
        ff.close()
