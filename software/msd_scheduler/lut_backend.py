from utils import ceil_func, floor_func
import logging


class LUTBackend(object):
    def __init__(self, lut_arr_arch: list):
        """LUT engine backend

        Args:
            lut_arr_arch (list): systolic array scale
            lut_buf_arch (list): buffer depth (per bank)
        """
        self.arr_rows = lut_arr_arch[0]
        self.arr_cols = lut_arr_arch[1]

    def get_compute_latency(self, schd_tile: list, ess_bit=3):
        """calculate computation latency cycles for one tile

        Args:
            schd_tile (list): 6-dim tile shape [t_oc, t_oh, t_ow, t_ic, t_kh, t_kw]
            eb_list (list): essential bit config for each och

        Returns:
            lat_cycles: computation latency cycles
        """
        assert len(schd_tile) == 7, "Invalid tile dimension!"
        [t_oc, t_oh, t_ow, t_ic, t_kh, t_kw, strd] = schd_tile

        # matrix size
        mat_ifm_h = t_oh * t_ow
        mat_ifm_w = t_ic * t_kh * t_kw
        mat_wgt_h = mat_ifm_w
        mat_wgt_w = t_oc

        # input stationary
        # preload_cycles = min(self.arr_rows, mat_ifm_w) * \
        #     ceil_func(mat_ifm_w, self.arr_rows) * \
        #     ceil_func(mat_ifm_h, self.arr_cols)
        # comp_lat_cycles = mat_wgt_w * ess_bit * \
        #     ceil_func(mat_wgt_h, self.arr_rows) * \
        #     ceil_func(mat_ifm_h, self.arr_cols) + preload_cycles

        # output stationary
        comp_lat_cycles = mat_wgt_h * ess_bit * ceil_func(mat_ifm_h, self.arr_rows) * ceil_func(
            mat_wgt_w, self.arr_cols)
        return comp_lat_cycles

    def get_compute_latency_dpws(self, schd_tile: list, ess_bit=3):
        """calculate computation latency cycles for one tile based on depthwise conv

        Args:
            schd_tile (list): 6-dim tile shape [t_oc, t_oh, t_ow, t_ic, t_kh, t_kw]
            eb_list (list): essential bit config for each och

        Returns:
            lat_cycles: computation latency cycles
        """
        assert len(schd_tile) == 7, "Invalid tile dimension!"
        [t_oc, t_oh, t_ow, t_ic, t_kh, t_kw, strd] = schd_tile

        # matrix size
        mat_ifm_h = t_oh * t_ow
        mat_ifm_w = t_ic * t_kh * t_kw
        mat_wgt_h = mat_ifm_w
        mat_wgt_w = 1
        # input stationary
        # preload_cycles = min(self.arr_rows, mat_ifm_w) * \
        #     ceil_func(mat_ifm_w, self.arr_rows) * \
        #     ceil_func(mat_ifm_h, self.arr_cols)
        # comp_lat_cycles = mat_wgt_w * ess_bit * \
        #     ceil_func(mat_wgt_h, self.arr_rows) * \
        #     ceil_func(mat_ifm_h, self.arr_cols) + preload_cycles

        # output stationary
        comp_lat_cycles = ceil_func(t_ic, self.arr_cols) * t_kh * t_kw * ess_bit * ceil_func(mat_ifm_h, self.arr_rows) * ceil_func(
            mat_wgt_w, self.arr_cols)
        return comp_lat_cycles

    def get_buf_util(self, schd_tile: list, ess_bit=3):
        """calculate buffer utilization to check if the buffer overflow

        Args:
            schd_tile (list): 6-dim tile shape [t_oc, t_oh, t_ow, t_ic, t_kh, t_kw]
            eb_list (list): essential bit config for each och

        Returns:
            ifm and wgt buffer depth: Bytes
        """
        assert len(schd_tile) == 7, "Invalid tile dimension!"
        [t_oc, t_oh, t_ow, t_ic, t_kh, t_kw, strd] = schd_tile

        # matrix size
        mat_ifm_h = t_oh * t_ow
        mat_ifm_w = t_ic * t_kh * t_kw
        mat_wgt_h = mat_ifm_w
        mat_wgt_w = t_oc

        # calculate utilized buffer depth
        ifm_tile_size = mat_ifm_h * mat_ifm_w
        wgt_tile_size = mat_wgt_h * mat_wgt_w * ess_bit
        ofm_tile_size = mat_wgt_w * mat_ifm_h
        ifm_buf_utl_depth = ceil_func(ifm_tile_size, self.arr_cols)
        wgt_buf_utl_depth = ceil_func(wgt_tile_size, self.arr_rows)
        ofm_buf_utl_depth = ceil_func(ofm_tile_size, self.arr_cols)

        return [ifm_buf_utl_depth, wgt_buf_utl_depth, ofm_buf_utl_depth]

    def get_buf_util_dpws(self, schd_tile: list, ess_bit=3):
        """calculate buffer utilization to check if the buffer overflow

        Args:
            schd_tile (list): 6-dim tile shape [t_oc, t_oh, t_ow, t_ic, t_kh, t_kw]
            eb_list (list): essential bit config for each och

        Returns:
            ifm and wgt buffer depth: Bytes
        """
        assert len(schd_tile) == 7, "Invalid tile dimension!"
        [t_oc, t_oh, t_ow, t_ic, t_kh, t_kw, strd] = schd_tile

        # matrix size
        mat_ifm_h = t_oh * t_ow
        mat_ifm_w = t_ic * t_kh * t_kw
        mat_wgt_h = mat_ifm_w
        mat_wgt_w = 1

        # calculate utilized buffer depth
        ifm_tile_size = mat_ifm_h * mat_ifm_w
        wgt_tile_size = mat_wgt_h * mat_wgt_w * ess_bit
        ofm_tile_size = mat_wgt_w * mat_ifm_h
        ifm_buf_utl_depth = ceil_func(ifm_tile_size, self.arr_cols)
        wgt_buf_utl_depth = ceil_func(wgt_tile_size, self.arr_rows)
        ofm_buf_utl_depth = ceil_func(ofm_tile_size, self.arr_cols)

        return [ifm_buf_utl_depth, wgt_buf_utl_depth, ofm_buf_utl_depth]
