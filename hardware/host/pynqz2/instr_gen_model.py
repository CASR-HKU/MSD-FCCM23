import numpy as np
import math
import pickle


class InstrGen:

    def set_act_out_addr(self, addr):
        self.act_out_addr = addr

    def set_weight_addr(self, addr):
        self.weight_addr = addr

    def set_act_in_addr(self, addr):
        self.act_in_addr = addr

    def load_model_csv(self, modelfile=""):
        f = open(modelfile, 'r')
        self.model_arrays = []
        for row in f:
            row = row.strip()
            elems = row.split(',')[:-1]
            layer_name = elems[0].strip()
            self.append_model_arrays(layer_name, elems)

    def append_model_arrays(self, layer_name, elems):
        entry = [layer_name]
        for i in range(1, len(elems)):
            if i == 10:
                val = float(str(elems[i]).strip())
            else:
                val = int(str(elems[i]).strip())
            entry.append(val)
        self.model_arrays.append(entry)
            
    def gen_instr(self, hw_arch, modelfile, layer_num, instr_array):
        self.load_model_csv(modelfile)
        model_arrays = self.model_arrays
        for layer in range(layer_num):
            k = model_arrays[layer][2]
            k_t = model_arrays[layer][3]
            c = model_arrays[layer][4]
            c_t = model_arrays[layer][5]
            o = model_arrays[layer][6]
            o_t = model_arrays[layer][7]
            i = model_arrays[layer][8]
            j = model_arrays[layer][8]
            strd = model_arrays[layer][9]
            ratio = model_arrays[layer][10]
            tile_bs_eb = model_arrays[layer][11]
            mem_bw = 8
            
            och_lut = math.ceil(k * ratio)
            och_dsp = k - och_lut
            if och_lut == 0:
                och_lut = 1
            if och_dsp == 0:
                och_dsp = 1
            t_ih = (o - 1) * strd + i
            t_iw = (o - 1) * strd + j
            
            tile_act_size = t_ih * t_iw * c
            tile_wgt_size_bs = 0.5 * c * i * j * och_lut
            tile_wgt_size_bp = c * i * j * och_dsp
            tile_out_size_bs = och_lut * o * o
            tile_out_size_bp = och_dsp * o * o

            param_bw_tile_times_act = math.ceil(tile_act_size/mem_bw)
            param_bw_tile_times_bs_wgt = math.ceil(tile_wgt_size_bs/mem_bw)
            param_bw_tile_times_bp_wgt = math.ceil(tile_wgt_size_bp/mem_bw)
            bs_ceil_k_rows = math.ceil(och_lut/hw_arch[0])
            bp_ceil_k_rows = math.ceil(och_dsp/hw_arch[1])
            bs_ceil_hw_cols = math.ceil((o*o)/hw_arch[0])
            bp_ceil_hw_cols = math.ceil((o*o)/(hw_arch[1]*2))
            param_tile_cij = c * i * j
            param_tile_cij_ceilhw_bs = param_tile_cij * bs_ceil_hw_cols
            param_tile_cij_ceilhw_bp = param_tile_cij * bp_ceil_hw_cols
            param_tile_cij_eb = tile_bs_eb * param_tile_cij
            param_bs_bw_out_times = math.ceil(tile_out_size_bs/mem_bw)
            param_bp_bw_out_times = math.ceil(tile_out_size_bp/mem_bw)
            param_tile_number = k_t * c_t * o_t * o_t
            param_btt_tile_act = param_bw_tile_times_act * mem_bw
            param_btt_tile_wgt = (param_bw_tile_times_bs_wgt +
                                  param_bw_tile_times_bp_wgt) * mem_bw
            param_btt_tile_out = (param_bs_bw_out_times +
                                  param_bp_bw_out_times) * mem_bw
            ext_addr_act_tile = self.act_in_addr
            ext_addr_wgt_tile = self.weight_addr
            ext_addr_out_tile = self.act_out_addr

            assert param_bw_tile_times_act < 65535, "param_bw_tile_times_act overflows! Layer " + str(layer)
            assert param_bw_tile_times_bs_wgt < 65535, "param_bw_tile_times_bs_wgt overflows! Layer " + str(layer)
            assert param_bw_tile_times_bp_wgt < 65535, "param_bw_tile_times_bp_wgt overflows! Layer " + str(layer)
            assert bs_ceil_k_rows < 255, "bs_ceil_k_rows overflows! Layer " + str(layer)
            assert bp_ceil_k_rows < 255, "bp_ceil_k_rows overflows! Layer " + str(layer)
            assert bs_ceil_hw_cols < 255, "bs_ceil_hw_cols overflows! Layer " + str(layer)
            assert bp_ceil_hw_cols < 255, "bp_ceil_hw_cols overflows! Layer " + str(layer)
            assert param_tile_cij < 65535, "param_tile_cij overflows! Layer " + str(layer)
            assert param_tile_cij_ceilhw_bs < 16777215, "param_tile_cij_ceilhw_bs overflows! Layer " + str(layer)
            assert param_tile_cij_ceilhw_bp < 16777215, "param_tile_cij_ceilhw_bp overflows! Layer " + str(layer)
            assert param_tile_cij_eb < 16777215, "param_tile_cij_eb overflows! Layer " + str(layer)
            assert param_bs_bw_out_times < 65535, "param_bs_bw_out_times overflows! Layer " + str(layer)
            assert param_bp_bw_out_times < 65535, "param_bp_bw_out_times overflows! Layer " + str(layer)
            assert param_tile_number < 65535, "param_tile_number overflows! Layer " + str(layer)
            assert param_btt_tile_act < 16777215, "param_btt_tile_act overflows! Layer " + str(layer)
            assert param_btt_tile_wgt < 16777215, "param_btt_tile_wgt overflows! Layer " + str(layer)
            assert param_btt_tile_out < 16777215, "param_btt_tile_out overflows! Layer " + str(layer)
            
            # instr 0
            instr_64 = np.uint64(0)
            instr_64 += np.uint64(0x8 << 60)
            instr_64 += np.uint64((0xff & bs_ceil_k_rows) << 48)
            instr_64 += np.uint64((0xffff & param_bw_tile_times_bp_wgt) << 32)
            instr_64 += np.uint64((0xffff & param_bw_tile_times_bs_wgt) << 16)
            instr_64 += np.uint64((0xffff & param_bw_tile_times_act))
            
            instr_array[layer*8+0] = instr_64
            
            # instr 1
            instr_64 = np.uint64(0)
            instr_64 += np.uint64(0x9 << 60)
            instr_64 += np.uint64((0xff & tile_bs_eb) << 56)
            instr_64 += np.uint64((0xffff & param_tile_number) << 40)
            instr_64 += np.uint64((0xffff & param_tile_cij) << 24)
            instr_64 += np.uint64((0xffffff & param_tile_cij_eb))
            
            instr_array[layer*8+1] = instr_64
            
            # instr 2
            instr_64 = np.uint64(0)
            instr_64 += np.uint64(0xa << 60)
            instr_64 += np.uint64((0xff & bp_ceil_k_rows) << 48)
            instr_64 += np.uint64((0xffffff & param_tile_cij_ceilhw_bp) << 24)
            instr_64 += np.uint64((0xffffff & param_tile_cij_ceilhw_bs))
            
            instr_array[layer*8+2] = instr_64
            
            # instr 3
            instr_64 = np.uint64(0)
            instr_64 += np.uint64(0xb << 60)
            instr_64 += np.uint64((0xffff & param_bp_bw_out_times) << 40)
            instr_64 += np.uint64((0xffff & param_bs_bw_out_times) << 24)
            instr_64 += np.uint64((0xffffff & param_btt_tile_act))
            
            instr_array[layer*8+3] = instr_64
            
            # instr 4
            instr_64 = np.uint64(0)
            instr_64 += np.uint64(0xc << 60)
            instr_64 += np.uint64((0xff & bp_ceil_hw_cols) << 32)
            instr_64 += np.uint64((0xff & bs_ceil_hw_cols) << 24)
            instr_64 += np.uint64((0xffffff & param_btt_tile_wgt))
            
            instr_array[layer*8+4] = instr_64
            
            # instr 5
            instr_64 = np.uint64(0)
            instr_64 += np.uint64(0xd << 60)
            if layer == layer_num - 1:
                instr_64 += np.uint64((0x1 & 1) << 56)
            instr_64 += np.uint64((0xffffff & param_btt_tile_out) << 32)
            instr_64 += np.uint64((0xffffffff & ext_addr_act_tile))
            
            instr_array[layer*8+5] = instr_64
            
            # instr 6
            instr_64 = np.uint64(0)
            instr_64 += np.uint64(0xe << 60)
            instr_64 += np.uint64((0xffffffff & ext_addr_wgt_tile))
            
            instr_array[layer*8+6] = instr_64
            
            # instr 7
            instr_64 = np.uint64(0)
            instr_64 += np.uint64(0xf << 60)
            instr_64 += np.uint64((0xffffffff & ext_addr_out_tile))
            
            instr_array[layer*8+7] = instr_64    
