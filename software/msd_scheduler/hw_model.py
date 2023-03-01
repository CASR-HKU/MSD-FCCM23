from utils import ceil_func, floor_func
from lut_backend import LUTBackend
from dsp_backend import DSPBackend
from mem_backend import MEMBackend
import math
import logging


class HardwareModel(object):
    def __init__(self, lut_arr_arch: list, lut_buf_depth: list, dsp_arr_arch: list, dsp_buf_depth: list, mem_bw: list, freq):
        """Hardware model to get all the latency
            TODO: add energy if possible
        Args:
            lut_arr_arch (list): LUT core systolic array scale 
            lut_buf_depth (list): LUT buf depth [ifm, wgt, ofm]
            dsp_arr_arch (list): DSP core systolic array scale 
            dsp_buf_depth (list): DSP buf depth [ifm, wgt, ofm]
            mem_bw (list): 3 level memory bandwidth
            freq (_type_): hardware frequency
        """
        self.lut_backend = LUTBackend(lut_arr_arch=lut_arr_arch)
        self.dsp_backend = DSPBackend(dsp_arr_arch=dsp_arr_arch)
        self.mem_backend = MEMBackend(mem_bw=mem_bw)
        self.frequency = freq
        self.lut_buf_depth = lut_buf_depth
        self.dsp_buf_depth = dsp_buf_depth

    def get_glb_ld_lat(self, schd_tile: list, ess_bit, och_lut, och_dsp):
        """get global buffer load latency

        Args:
            schd_tile (list): 6-dim tile shape [t_oc, t_oh, t_ow, t_ic, t_kh, t_kw]
            eb_list (list): essential bit config for each och
            och_lut (_type_): och workload for LUT
            och_dsp (_type_): och workload for DSP

        Returns:
            lat_cycle: latency based on cycles
        """
        lat_cycle = self.mem_backend.get_glb_buffer_latency_ld(
            schd_tile, ess_bit, och_lut, och_dsp)
        return lat_cycle

    def get_glb_ld_lat_dpws(self, schd_tile: list, ess_bit, och_lut, och_dsp):
        """get global buffer load latency

        Args:
            schd_tile (list): 6-dim tile shape [t_oc, t_oh, t_ow, t_ic, t_kh, t_kw]
            eb_list (list): essential bit config for each och
            och_lut (_type_): och workload for LUT
            och_dsp (_type_): och workload for DSP

        Returns:
            lat_cycle: latency based on cycles
        """
        lat_cycle = self.mem_backend.get_glb_buffer_latency_ld_dpws(
            schd_tile, ess_bit, och_lut, och_dsp)
        return lat_cycle

    def get_glb_ld_lat_conv(self, schd_tile: list, ess_bit, och_lut, och_dsp):
        """get global buffer load latency

        Args:
            schd_tile (list): 6-dim tile shape [t_oc, t_oh, t_ow, t_ic, t_kh, t_kw]
            eb_list (list): essential bit config for each och
            och_lut (_type_): och workload for LUT
            och_dsp (_type_): och workload for DSP

        Returns:
            lat_cycle: latency based on cycles
        """
        lat_cycle = self.mem_backend.get_glb_buffer_latency_ld_conv(
            schd_tile, ess_bit, och_lut, och_dsp)
        return lat_cycle

    def get_glb_ld_lat_dpws_conv(self, schd_tile: list, ess_bit, och_lut, och_dsp):
        """get global buffer load latency

        Args:
            schd_tile (list): 6-dim tile shape [t_oc, t_oh, t_ow, t_ic, t_kh, t_kw]
            eb_list (list): essential bit config for each och
            och_lut (_type_): och workload for LUT
            och_dsp (_type_): och workload for DSP

        Returns:
            lat_cycle: latency based on cycles
        """
        lat_cycle = self.mem_backend.get_glb_buffer_latency_ld_dpws_conv(
            schd_tile, ess_bit, och_lut, och_dsp)
        return lat_cycle

    def get_glb_wr_lat(self, schd_tile: list):
        """get global buffer write back latency

        Args:
            schd_tile (list): 6-dim tile shape [t_oc, t_oh, t_ow, t_ic, t_kh, t_kw]

        Returns:
            lat_cycle: latency based on cycles
        """
        lat_cycle = self.mem_backend.get_glb_buffer_latency_wb(schd_tile)
        return lat_cycle

    def get_comp_lat(self, schd_tile: list, ess_bit, och_lut, och_dsp):
        """get computation latency for the input tile and eb config

        Args:
            schd_tile (list): 6-dim tile shape [t_oc, t_oh, t_ow, t_ic, t_kh, t_kw]
            eb_list (list): essential bit config for each och
            och_lut (_type_): och workload for LUT
            och_dsp (_type_): och workload for DSP

        Returns:
            lat_cycle: latency based on cycles
            workload_dom: LUT dominates or DSP dominates
        """
        lut_schd_tile = [och_lut] + schd_tile[1:7]
        dsp_schd_tile = [och_dsp] + schd_tile[1:7]
        # lut_buf_lat = self.mem_backend.get_lut_buffer_latency(
        #     lut_schd_tile, ess_bit)
        # dsp_buf_lat = self.mem_backend.get_dsp_buffer_latency(dsp_schd_tile)
        lut_comp_lat = self.lut_backend.get_compute_latency(
            lut_schd_tile, ess_bit)
        dsp_comp_lat = self.dsp_backend.get_compute_latency(dsp_schd_tile)
        # double buffer model to decide latency
        # lut_lat = max(lut_buf_lat, lut_comp_lat)
        # dsp_lat = max(dsp_buf_lat, dsp_comp_lat)

        # workload_dom == 1 -> lut dominates, 0 -> dsp dominates
        if lut_comp_lat >= dsp_comp_lat:
            workload_dom = 1
        else:
            workload_dom = 0
        # comp_lat_cycle = max(lut_lat, dsp_lat)
        comp_lat_cycle = max(lut_comp_lat, dsp_comp_lat)
        comp_lat_ms = comp_lat_cycle * (1/self.frequency) * 1000
        return comp_lat_cycle, workload_dom

    def get_comp_lat_dpws(self, schd_tile: list, ess_bit, och_lut, och_dsp):
        """get computation latency for the input tile and eb config

        Args:
            schd_tile (list): 6-dim tile shape [t_oc, t_oh, t_ow, t_ic, t_kh, t_kw]
            eb_list (list): essential bit config for each och
            och_lut (_type_): och workload for LUT
            och_dsp (_type_): och workload for DSP

        Returns:
            lat_cycle: latency based on cycles
            workload_dom: LUT dominates or DSP dominates
        """

        lut_schd_tile = [och_lut] + schd_tile[1:3] + [och_lut] + schd_tile[4:7]
        dsp_schd_tile = [och_dsp] + schd_tile[1:3] + [och_dsp] + schd_tile[4:7]
        # lut_buf_lat = self.mem_backend.get_lut_buffer_latency_dpws(
        #     lut_schd_tile, ess_bit)
        # dsp_buf_lat = self.mem_backend.get_dsp_buffer_latency_dpws(
        #     dsp_schd_tile)
        lut_comp_lat = self.lut_backend.get_compute_latency_dpws(
            lut_schd_tile, ess_bit)
        dsp_comp_lat = self.dsp_backend.get_compute_latency_dpws(dsp_schd_tile)
        # double buffer model to decide latency
        # lut_lat = max(lut_buf_lat, lut_comp_lat)
        # dsp_lat = max(dsp_buf_lat, dsp_comp_lat)
        # logging.debug("lut buf lat: " + str(lut_buf_lat))
        # logging.debug("lut comp lat: " + str(lut_comp_lat))
        # logging.debug("dsp buf lat: " + str(dsp_buf_lat))
        # logging.debug("dsp comp lat: " + str(dsp_comp_lat))
        # workload_dom == 1 -> lut dominates, 0 -> dsp dominates
        if lut_comp_lat >= dsp_comp_lat:
            workload_dom = 1
        else:
            workload_dom = 0
        # comp_lat_cycle = max(lut_lat, dsp_lat)
        comp_lat_cycle = max(lut_comp_lat, dsp_comp_lat)
        comp_lat_ms = comp_lat_cycle * (1/self.frequency) * 1000
        return comp_lat_cycle, workload_dom

    def get_comp_lat_lut(self, schd_tile: list, ess_bit):
        lut_buf_lat = self.mem_backend.get_lut_buffer_latency(
            schd_tile, ess_bit)
        lut_comp_lat = self.lut_backend.get_compute_latency(
            schd_tile, ess_bit)
        lut_lat = max(lut_buf_lat, lut_comp_lat)
        return lut_lat

    def get_comp_lat_dsp(self, schd_tile: list):
        dsp_buf_lat = self.mem_backend.get_dsp_buffer_latency(schd_tile)
        dsp_comp_lat = self.dsp_backend.get_compute_latency(schd_tile)
        dsp_lat = max(dsp_buf_lat, dsp_comp_lat)
        return dsp_lat

    def if_depth_overflow(self, schd_tile: list, ess_bit, och_lut, och_dsp, verbose=False):
        lut_schd_tile = [och_lut] + schd_tile[1:7]
        dsp_schd_tile = [och_dsp] + schd_tile[1:7]
        lut_utl_depth = self.lut_backend.get_buf_util(lut_schd_tile, ess_bit)
        dsp_utl_depth = self.dsp_backend.get_buf_util(dsp_schd_tile)
        if verbose:
            print("lut depth: ", self.lut_buf_depth)
            print("dsp depth: ", self.dsp_buf_depth)
            print("lut utl: ", lut_utl_depth)
            print("dsp utl: ", dsp_utl_depth)
        if (lut_utl_depth[0] < self.lut_buf_depth[0]) and (lut_utl_depth[1] < self.lut_buf_depth[1]) and \
            (lut_utl_depth[2] < self.lut_buf_depth[2]) and (dsp_utl_depth[0] < self.dsp_buf_depth[0]) and \
                (dsp_utl_depth[1] < self.dsp_buf_depth[1]) and (dsp_utl_depth[2] < self.dsp_buf_depth[2]):
            return False
        else:
            return True

    def if_depth_overflow_dpws(self, schd_tile: list, ess_bit, och_lut, och_dsp, verbose=False):
        lut_schd_tile = [och_lut] + schd_tile[1:7]
        dsp_schd_tile = [och_dsp] + schd_tile[1:7]
        lut_utl_depth = self.lut_backend.get_buf_util_dpws(
            lut_schd_tile, ess_bit)
        dsp_utl_depth = self.dsp_backend.get_buf_util_dpws(dsp_schd_tile)
        if verbose:
            print("lut depth: ", self.lut_buf_depth)
            print("dsp depth: ", self.dsp_buf_depth)
            print("lut utl: ", lut_utl_depth)
            print("dsp utl: ", dsp_utl_depth)
        if (lut_utl_depth[0] < self.lut_buf_depth[0]) and (lut_utl_depth[1] < self.lut_buf_depth[1]) and \
            (lut_utl_depth[2] < self.lut_buf_depth[2]) and (dsp_utl_depth[0] < self.dsp_buf_depth[0]) and \
                (dsp_utl_depth[1] < self.dsp_buf_depth[1]) and (dsp_utl_depth[2] < self.dsp_buf_depth[2]):
            return False
        else:
            return True

    def get_opt_workload_lat(self, schd_tile: list, ess_bit=3, verbose=False):
        """find the optimal workload between LUT and DSP
            NOTE: for now, all the eb is fixed as 3
        Args:
            schd_tile (list): 6-dim tile shape [t_oc, t_oh, t_ow, t_ic, t_kh, t_kw]

        Returns:
            opt_lat_cycle: optimal computation latency cycles 
            opt_lat_ms: optimal computation latency ms
            opt_workload: [och_lut, t_oc - och_lut] workload
        """
        t_oc = schd_tile[0]
        opt_lat_cycle = 0
        opt_och_lut = 1
        # brute-force to find the optimal workload
        for och_lut in range(1, t_oc):
            # TODO: change eb list to a parameter given by top level
            eb_list = [ess_bit] * och_lut
            # check if the buffer depths overflow
            depth_overflow = self.if_depth_overflow(
                schd_tile, eb_list, och_lut, (t_oc-och_lut), verbose)
            if depth_overflow:
                if verbose:
                    print("overflow!" + str(och_lut) +
                          ' ' + str(t_oc - och_lut))
                continue
            # get the optimal workload
            temp_comp_lat_cycle, temp_workload_dom = self.get_comp_lat(
                schd_tile, eb_list, och_lut, (t_oc - och_lut))
            temp_mem_lat_ld_cycle = self.get_glb_ld_lat(
                schd_tile, eb_list, och_lut, (t_oc - och_lut))
            temp_mem_lat_wr_cycle = self.get_glb_wr_lat(schd_tile)
            temp_mem_lat_cycle = max(
                temp_mem_lat_ld_cycle, temp_mem_lat_wr_cycle)
            temp_lat_cycle = max(temp_comp_lat_cycle, temp_mem_lat_cycle)
            if (temp_lat_cycle < opt_lat_cycle) or (opt_lat_cycle == 0):
                opt_lat_cycle = temp_lat_cycle
                opt_och_lut = och_lut

        # if all the workloads overflow, return invalid
        if opt_lat_cycle == 0:
            return False, 0, [0, 0]
        else:
            opt_workload = [opt_och_lut, t_oc - opt_och_lut]
            return True, opt_lat_cycle, opt_workload

    def get_opt_lat(self, schd_tile: list, och_lut, och_dsp, ess_bit=3, verbose=False):
        """find the optimal workload between LUT and DSP
            NOTE: for now, all the eb is fixed as 3
        Args:
            schd_tile (list): 6-dim tile shape [t_oc, t_oh, t_ow, t_ic, t_kh, t_kw]

        Returns:
            opt_lat_cycle: optimal computation latency cycles 
            opt_lat_ms: optimal computation latency ms
            opt_workload: [och_lut, t_oc - och_lut] workload
        """
        t_oc = schd_tile[0]
        assert (och_lut + och_dsp == t_oc), "invalid workload!"
        # check if the buffer depths overflow
        depth_overflow = self.if_depth_overflow(
            schd_tile, ess_bit, och_lut, och_dsp, verbose)
        if depth_overflow:
            if verbose:
                print("overflow!" + str(och_lut) +
                      ' ' + str(t_oc - och_lut))
            return False, 0, "no schedule"
        # get the optimal workload
        temp_comp_lat_cycle, temp_workload_dom = self.get_comp_lat(
            schd_tile, ess_bit, och_lut, och_dsp)
        temp_mem_lat_ld_cycle = self.get_glb_ld_lat(
            schd_tile, ess_bit, och_lut, och_dsp)
        temp_mem_lat_wr_cycle = self.get_glb_wr_lat(schd_tile)
        temp_mem_lat_cycle = max(
            temp_mem_lat_ld_cycle, temp_mem_lat_wr_cycle)
        temp_lat_cycle = max(temp_comp_lat_cycle, temp_mem_lat_cycle)
        if temp_comp_lat_cycle > temp_mem_lat_cycle:
            roofline_bound = "compute bound"
        else:
            roofline_bound = "memory bound"
        # temp_lat_cycle = temp_comp_lat_cycle
        return True, temp_lat_cycle, roofline_bound

    def get_opt_lat_dpws(self, schd_tile: list, och_lut, och_dsp, ess_bit=3, verbose=False):
        """find the optimal workload between LUT and DSP
            NOTE: for now, all the eb is fixed as 3
        Args:
            schd_tile (list): 6-dim tile shape [t_oc, t_oh, t_ow, t_ic, t_kh, t_kw]

        Returns:
            opt_lat_cycle: optimal computation latency cycles 
            opt_lat_ms: optimal computation latency ms
            opt_workload: [och_lut, t_oc - och_lut] workload
        """
        t_ic = schd_tile[3]
        assert (och_lut + och_dsp == t_ic), "invalid workload!"
        # check if the buffer depths overflow
        depth_overflow = self.if_depth_overflow_dpws(
            schd_tile, ess_bit, och_lut, och_dsp, verbose)
        if depth_overflow:
            if verbose:
                logging.debug("overflow!" + str(och_lut) +
                              ' ' + str(t_ic - och_lut))
            return False, 0, "no schedule"
        # get the optimal workload
        # logging.debug(schd_tile)
        # logging.debug(str(och_lut) + str(och_dsp))
        temp_comp_lat_cycle, temp_workload_dom = self.get_comp_lat_dpws(
            schd_tile, ess_bit, och_lut, och_dsp)
        temp_mem_lat_ld_cycle = self.get_glb_ld_lat_dpws(
            schd_tile, ess_bit, och_lut, och_dsp)
        temp_mem_lat_wr_cycle = self.get_glb_wr_lat(schd_tile)
        temp_mem_lat_cycle = max(
            temp_mem_lat_ld_cycle, temp_mem_lat_wr_cycle)
        temp_lat_cycle = max(temp_comp_lat_cycle, temp_mem_lat_cycle)
        # temp_lat_cycle = temp_comp_lat_cycle
        # logging.debug("mem lat: " + str(temp_mem_lat_cycle))
        if temp_comp_lat_cycle > temp_mem_lat_cycle:
            roofline_bound = "compute bound"
        else:
            roofline_bound = "memory bound"
        return True, temp_lat_cycle, roofline_bound
    