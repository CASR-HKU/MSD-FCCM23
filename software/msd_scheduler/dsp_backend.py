from utils import ceil_func, floor_func
import logging


class DSPBackend(object):
    def __init__(self, dsp_arr_arch: list):
        """dsp engine backend

        Args:
            dsp_arr_arch (list): systolic array scale
            dsp_buf_arch (list): buffer depth (per bank)
        """
        self.arr_rows = dsp_arr_arch[0]
        self.arr_cols = dsp_arr_arch[1]

    def get_compute_latency(self, schd_tile: list):
        """calculate computation latency cycles for one tile

        Args:
            schd_tile (list): 6-dim tile shape [t_oc, t_oh, t_ow, t_ic, t_kh, t_kw]

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
        # preload_cycles = min(self.arr_rows, mat_ifm_w) * \
        #     ceil_func(mat_ifm_w, self.arr_rows) * \
        #     ceil_func(mat_ifm_h, (self.arr_cols*2))
        # comp_lat_cycles = mat_wgt_w * \
        #     ceil_func(mat_wgt_h, self.arr_rows) * \
        #     ceil_func(mat_ifm_h, (self.arr_cols*2)) + preload_cycles

        comp_lat_cycles = mat_wgt_h * \
            ceil_func(mat_ifm_h, (self.arr_rows*2)) * \
            ceil_func(mat_wgt_w, self.arr_cols)
        return comp_lat_cycles

    def get_compute_latency_dpws(self, schd_tile: list):
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
        #     ceil_func(mat_ifm_h, (self.arr_cols*2))
        # comp_lat_cycles = mat_wgt_w * \
        #     ceil_func(mat_wgt_h, self.arr_rows) * \
        #     ceil_func(mat_ifm_h, (self.arr_cols*2)) + preload_cycles

        # output stationary
        comp_lat_cycles = ceil_func(t_ic, self.arr_cols) * t_kh * t_kw * \
            ceil_func(mat_ifm_h, (self.arr_rows*2)) * \
            ceil_func(mat_wgt_w, self.arr_cols)
        return comp_lat_cycles

    def get_buf_util(self, schd_tile: list):
        """calculate buffer utilization to check if the buffer overflow

        Args:
            schd_tile (list): 6-dim tile shape [t_oc, t_oh, t_ow, t_ic, t_kh, t_kw]
            eb_list (list): essential bit config for each och

        Returns:
            (bool): Bytes
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
        wgt_tile_size = mat_wgt_h * mat_wgt_w  # may need in the future
        ofm_tile_size = mat_wgt_w * mat_ifm_h
        ifm_buf_utl_depth = ceil_func(ifm_tile_size, (self.arr_cols*2))
        wgt_buf_utl_depth = ceil_func(wgt_tile_size, self.arr_rows)
        ofm_buf_utl_depth = ceil_func(ofm_tile_size, (self.arr_cols*2))

        return [ifm_buf_utl_depth, wgt_buf_utl_depth, ofm_buf_utl_depth]

    def get_buf_util_dpws(self, schd_tile: list):
        """calculate buffer utilization to check if the buffer overflow

        Args:
            schd_tile (list): 6-dim tile shape [t_oc, t_oh, t_ow, t_ic, t_kh, t_kw]
            eb_list (list): essential bit config for each och

        Returns:
            (bool): Bytes
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
        wgt_tile_size = mat_wgt_h * mat_wgt_w  # may need in the future
        ofm_tile_size = mat_wgt_w * mat_ifm_h
        ifm_buf_utl_depth = ceil_func(ifm_tile_size, (self.arr_cols*2))
        wgt_buf_utl_depth = ceil_func(wgt_tile_size, self.arr_rows)
        ofm_buf_utl_depth = ceil_func(ofm_tile_size, (self.arr_cols*2))

        return [ifm_buf_utl_depth, wgt_buf_utl_depth, ofm_buf_utl_depth]
