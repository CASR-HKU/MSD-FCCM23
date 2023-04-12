from utils import ceil_func, floor_func


class MEMBackend(object):
    def __init__(self, mem_bw: list):
        """memory backend for calculating memory latency

        Args:
            mem_bw (list): memory bandwidth for different levels
        """
        assert len(
            mem_bw) == 5, "Memory bandwidth should include global, LUT-ifm, LUT-wgt, DSP-ifm and DSP-wgt"
        self.glb_bw = mem_bw[0]
        self.lut_ifm_bw = mem_bw[1]
        self.lut_wgt_bw = mem_bw[2]
        self.dsp_ifm_bw = mem_bw[3]
        self.dsp_wgt_bw = mem_bw[4]

    def get_glb_buffer_latency_ld(self, schd_tile: list, ess_bit, och_lut, och_dsp):
        """get memory latency (load data) of global buffer

        Args:
            schd_tile (list): 6-dim tile shape [t_oc, t_oh, t_ow, t_ic, t_kh, t_kw]
            eb_list (list): essential bit config for each och
            och_lut (_type_): och workload for LUT
            och_dsp (_type_): och workload for DSP

        Returns:
            glb_ld_cycles: latency cycles 
        """
        assert len(schd_tile) == 7, "Invalid tile dimension!"
        [t_oc, t_oh, t_ow, t_ic, t_kh, t_kw, strd] = schd_tile

        lut_t_oc = och_lut * ess_bit

        mat_ifm_h = t_oh * t_ow
        mat_ifm_w = t_ic * t_kh * t_kw
        t_ih = (t_oh - 1) * strd + t_kh
        t_iw = (t_ow - 1) * strd + t_kw
        # weight size
        wgt_tile_size = ceil_func(
            lut_t_oc * t_ic * t_kh * t_kw, 2) + och_dsp * t_ic * t_kh * t_kw
        # activation size
        ifm_tile_size = t_ic * t_ih * t_iw
        # ifm_tile_size = mat_ifm_h * mat_ifm_w
        # load both weights and activation of one tile
        # glb_ld_cycles = ceil_func(
        #     (wgt_tile_size + ifm_tile_size), self.glb_bw)
        glb_ld_cycles = ceil_func(
            max(wgt_tile_size, ifm_tile_size), self.glb_bw)
        if glb_ld_cycles < 16:
            glb_ld_cycles = glb_ld_cycles * 1.2
        return glb_ld_cycles

    def get_glb_buffer_latency_ld_dpws(self, schd_tile: list, ess_bit, och_lut, och_dsp):
        """get memory latency (load data) of global buffer

        Args:
            schd_tile (list): 6-dim tile shape [t_oc, t_oh, t_ow, t_ic, t_kh, t_kw]
            eb_list (list): essential bit config for each och
            och_lut (_type_): och workload for LUT
            och_dsp (_type_): och workload for DSP

        Returns:
            glb_ld_cycles: latency cycles 
        """
        assert len(schd_tile) == 7, "Invalid tile dimension!"
        [t_oc, t_oh, t_ow, t_ic, t_kh, t_kw, strd] = schd_tile

        lut_t_oc = och_lut * ess_bit

        mat_ifm_h = t_oh * t_ow
        mat_ifm_w = t_ic * t_kh * t_kw
        t_ih = (t_oh - 1) * strd + t_kh
        t_iw = (t_ow - 1) * strd + t_kw
        # weight size
        wgt_tile_size = ceil_func(
            lut_t_oc * t_kh * t_kw, 2) + och_dsp * t_kh * t_kw
        # activation size
        ifm_tile_size = t_ic * t_ih * t_iw
        # ifm_tile_size = mat_ifm_h * mat_ifm_w
        # load both weights and activation of one tile
        # glb_ld_cycles = ceil_func(
        #     (wgt_tile_size + ifm_tile_size), self.glb_bw)
        glb_ld_cycles = ceil_func(
            max(wgt_tile_size, ifm_tile_size), self.glb_bw)
        if glb_ld_cycles < 16:
            glb_ld_cycles = glb_ld_cycles * 1.2
        return glb_ld_cycles

    def get_glb_buffer_latency_wb(self, schd_tile: list):
        """get memory latency (write back data) of global buffer

        Args:
            schd_tile (list): 6-dim tile shape [t_oc, t_oh, t_ow, t_ic, t_kh, t_kw]

        Returns:
            glb_wb_cycles: latency cycles 
        """
        assert len(schd_tile) == 7, "Invalid tile dimension!"
        [t_oc, t_oh, t_ow, t_ic, t_kh, t_kw, strd] = schd_tile

        mat_ofm_h = t_oh * t_ow
        mat_ofm_w = t_oc

        # ofm size
        ofm_tile_size = mat_ofm_h * mat_ofm_w
        # write back both weights and activation of one tile
        glb_wb_cycles = ceil_func(
            ofm_tile_size, self.glb_bw)
        return glb_wb_cycles

    def get_lut_buffer_latency(self, schd_tile: list, ess_bit=3):
        """calculate buffer latency of loading activations/weights from the global buffer to LUT core
           NOTE: we assume the bandwidth of buffer is equal to row/column
        Args:
            schd_tile (list): 6-dim tile shape [t_oc, t_oh, t_ow, t_ic, t_kh, t_kw]
            eb_list (list): essential bit config for each och

        Returns:
            load_ifm_cycles: buffer latency cycles of activations
            load_wgt_cycles: buffer latency cycles of weights
        """
        assert len(schd_tile) == 7, "Invalid tile dimension!"
        [t_oc, t_oh, t_ow, t_ic, t_kh, t_kw, strd] = schd_tile

        # matrix size
        mat_ifm_h = t_oh * t_ow
        mat_ifm_w = t_ic * t_kh * t_kw
        mat_wgt_h = mat_ifm_w
        mat_wgt_w = t_oc

        ifm_tile_size = mat_ifm_h * mat_ifm_w
        wgt_tile_size = mat_wgt_h * mat_wgt_w * ess_bit  # may need in the future
        load_ifm_cycles = ceil_func(ifm_tile_size, self.lut_ifm_bw)
        load_wgt_cycles = ceil_func(wgt_tile_size, self.lut_wgt_bw)
        return max(load_ifm_cycles, load_wgt_cycles)

    def get_dsp_buffer_latency(self, schd_tile: list):
        """calculate buffer latency of loading activations from the global buffer to DSP core
           NOTE: we assume the bandwidth of buffer is equal to row/column
        Args:
            schd_tile (list): 6-dim tile shape [t_oc, t_oh, t_ow, t_ic, t_kh, t_kw]

        Returns:
            load_ifm_cycles: buffer latency cycles of activations
            load_wgt_cycles: buffer latency cycles of weights
        """
        assert len(schd_tile) == 7, "Invalid tile dimension!"
        [t_oc, t_oh, t_ow, t_ic, t_kh, t_kw, strd] = schd_tile

        # matrix size
        mat_ifm_h = t_oh * t_ow
        mat_ifm_w = t_ic * t_kh * t_kw
        mat_wgt_h = mat_ifm_w
        mat_wgt_w = t_oc

        ifm_tile_size = mat_ifm_h * mat_ifm_w
        wgt_tile_size = mat_wgt_h * mat_wgt_w  # may need in the future
        load_ifm_cycles = ceil_func(ifm_tile_size, self.dsp_ifm_bw)
        load_wgt_cycles = ceil_func(wgt_tile_size, self.dsp_wgt_bw)
        return max(load_ifm_cycles, load_wgt_cycles)

    def get_lut_buffer_latency_dpws(self, schd_tile: list, ess_bit=3):
        """calculate buffer latency of loading activations/weights from the global buffer to LUT core
           NOTE: we assume the bandwidth of buffer is equal to row/column
        Args:
            schd_tile (list): 6-dim tile shape [t_oc, t_oh, t_ow, t_ic, t_kh, t_kw]
            eb_list (list): essential bit config for each och

        Returns:
            load_ifm_cycles: buffer latency cycles of activations
            load_wgt_cycles: buffer latency cycles of weights
        """
        assert len(schd_tile) == 7, "Invalid tile dimension!"
        [t_oc, t_oh, t_ow, t_ic, t_kh, t_kw, strd] = schd_tile

        # matrix size
        mat_ifm_h = t_oh * t_ow
        mat_ifm_w = t_ic * t_kh * t_kw
        mat_wgt_h = mat_ifm_w
        mat_wgt_w = 1

        ifm_tile_size = mat_ifm_h * mat_ifm_w
        wgt_tile_size = mat_wgt_h * mat_wgt_w * ess_bit  # may need in the future
        load_ifm_cycles = ceil_func(ifm_tile_size, self.lut_ifm_bw)
        load_wgt_cycles = ceil_func(wgt_tile_size, self.lut_wgt_bw)
        return max(load_ifm_cycles, load_wgt_cycles)

    def get_dsp_buffer_latency_dpws(self, schd_tile: list):
        """calculate buffer latency of loading activations from the global buffer to DSP core
           NOTE: we assume the bandwidth of buffer is equal to row/column
        Args:
            schd_tile (list): 6-dim tile shape [t_oc, t_oh, t_ow, t_ic, t_kh, t_kw]

        Returns:
            load_ifm_cycles: buffer latency cycles of activations
            load_wgt_cycles: buffer latency cycles of weights
        """
        assert len(schd_tile) == 7, "Invalid tile dimension!"
        [t_oc, t_oh, t_ow, t_ic, t_kh, t_kw, strd] = schd_tile

        # matrix size
        mat_ifm_h = t_oh * t_ow
        mat_ifm_w = t_ic * t_kh * t_kw
        mat_wgt_h = mat_ifm_w
        mat_wgt_w = 1

        ifm_tile_size = mat_ifm_h * mat_ifm_w
        wgt_tile_size = mat_wgt_h * mat_wgt_w  # may need in the future
        load_ifm_cycles = ceil_func(ifm_tile_size, self.dsp_ifm_bw)
        load_wgt_cycles = ceil_func(wgt_tile_size, self.dsp_wgt_bw)
        return max(load_ifm_cycles, load_wgt_cycles)

    def get_glb_buffer_latency_ld_conv(self, schd_tile: list, ess_bit, och_lut, och_dsp):
        """get memory latency (load data) of global buffer

        Args:
            schd_tile (list): 6-dim tile shape [t_oc, t_oh, t_ow, t_ic, t_kh, t_kw]
            eb_list (list): essential bit config for each och
            och_lut (_type_): och workload for LUT
            och_dsp (_type_): och workload for DSP

        Returns:
            glb_ld_cycles: latency cycles 
        """
        assert len(schd_tile) == 7, "Invalid tile dimension!"
        [t_oc, t_oh, t_ow, t_ic, t_kh, t_kw, strd] = schd_tile

        lut_t_oc = och_lut * ess_bit

        mat_ifm_h = t_oh * t_ow
        mat_ifm_w = t_ic * t_kh * t_kw

        t_ih = (t_oh - 1) * strd + t_kh
        t_iw = (t_ow - 1) * strd + t_kw

        # weight size
        wgt_tile_size = ceil_func(
            lut_t_oc * t_ic * t_kh * t_kw, 2) + och_dsp * t_ic * t_kh * t_kw
        # activation size
        ifm_tile_size = t_ic * t_iw * t_ih
        tmp_ifm_bw = min(t_ic, self.glb_bw)
        # load both weights and activation of one tile
        wgt_ld_cycles = ceil_func(wgt_tile_size, self.glb_bw)
        ifm_ld_cycles = ceil_func(ifm_tile_size, tmp_ifm_bw)
        glb_ld_cycles = wgt_ld_cycles+ifm_ld_cycles
        # load both weights and activation of one tile
        # glb_ld_cycles = ceil_func(
        #     (wgt_tile_size + ifm_tile_size), self.glb_bw)
        return glb_ld_cycles

    def get_glb_buffer_latency_ld_dpws_conv(self, schd_tile: list, ess_bit, och_lut, och_dsp):
        """get memory latency (load data) of global buffer

        Args:
            schd_tile (list): 6-dim tile shape [t_oc, t_oh, t_ow, t_ic, t_kh, t_kw]
            eb_list (list): essential bit config for each och
            och_lut (_type_): och workload for LUT
            och_dsp (_type_): och workload for DSP

        Returns:
            glb_ld_cycles: latency cycles 
        """
        assert len(schd_tile) == 7, "Invalid tile dimension!"
        [t_oc, t_oh, t_ow, t_ic, t_kh, t_kw, strd] = schd_tile

        lut_t_oc = och_lut * ess_bit

        mat_ifm_h = t_oh * t_ow
        mat_ifm_w = t_ic * t_kh * t_kw

        t_ih = (t_oh - 1) * strd + t_kh
        t_iw = (t_ow - 1) * strd + t_kw

        # weight size
        wgt_tile_size = ceil_func(
            lut_t_oc * t_kh * t_kw, 2) + och_dsp * t_kh * t_kw
        # activation size
        ifm_tile_size = t_ic * t_iw * t_ih
        tmp_ifm_bw = min(t_ic, self.glb_bw)
        # load both weights and activation of one tile
        wgt_ld_cycles = ceil_func(wgt_tile_size, self.glb_bw)
        ifm_ld_cycles = ceil_func(ifm_tile_size, tmp_ifm_bw)
        glb_ld_cycles = wgt_ld_cycles + ifm_ld_cycles
        # glb_ld_cycles = ceil_func(
        #     (wgt_tile_size + ifm_tile_size), self.glb_bw)
        return glb_ld_cycles
