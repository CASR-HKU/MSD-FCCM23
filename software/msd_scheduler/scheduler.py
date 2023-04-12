from utils import ceil_func
from hw_model import HardwareModel
import math
import logging


class Scheduler(object):
    def __init__(self, hw_model: HardwareModel):
        self.hw_model_obj = hw_model

    def get_best_schedule(self, conv_params: list, ess_bit=3, verbose=False):
        """search for the best schecule.
        NOTE: For now, we only consider latency (cycles)
        Args:
            conv_params (list): 6-dim conv parameters
            ess_bit: essential bit for this layer
        Returns:
            best_lat and best_schd
        """
        assert len(conv_params) == 6, "Invalid conv_params!"

        [K, H, W, C, I, J] = conv_params

        assert H == W, "Not support H!=W"

        # if K and C dim are too large, we need to constraint the upper bound
        if K > 512:
            K_bound = 512
        else:
            K_bound = K

        if C > 512:
            C_bound = 512
        else:
            C_bound = C

        # brute force search
        best_lat = 0
        best_schd = {}
        best_schd['k_size, k_tiles'] = (0, 0)
        best_schd['c_size, c_tiles'] = (0, 0)
        best_schd['o_size, o_tiles'] = (0, 0)
        for tile_k in range(2, K_bound + 1):
            num_k_tiles = ceil_func(K, tile_k)
            for tile_c in range(1, C_bound + 1):
                num_c_tiles = ceil_func(C, tile_c)
                for tile_o in range(1, H + 1):
                    num_o_tiles = ceil_func(H, tile_o)
                    # [K, H, W, C, I, J]
                    # we do not tile I and J (kernel height and weight)
                    schd_tile = [tile_k,
                                 tile_o, tile_o, tile_c, I, J]

                    is_overflow, opt_lat_cycle, opt_workload = self.hw_model_obj.get_opt_workload_lat(
                        schd_tile, ess_bit, verbose)
                    if is_overflow == False:
                        continue

                    schedule = {}
                    schedule['k_size, k_tiles'] = (tile_k, num_k_tiles)
                    schedule['c_size, c_tiles'] = (tile_c, num_c_tiles)
                    schedule['o_size, o_tiles'] = (tile_o, num_o_tiles)

                    # abandon the schedule if buffers overflow (depth)
                    if verbose:
                        print("schedule is ")
                        print(schedule)

                    # calculate memory latency and computation latency
                    eb_list = [ess_bit] * opt_workload[0]
                    mem_lat_first = self.hw_model_obj.get_glb_ld_lat(
                        schd_tile, eb_list, opt_workload[0], opt_workload[1])
                    mem_lat_final = self.hw_model_obj.get_glb_wr_lat(schd_tile)
                    total_num_tiles = num_k_tiles * num_c_tiles * num_o_tiles * num_o_tiles
                    total_latency = total_num_tiles * opt_lat_cycle + mem_lat_first + mem_lat_final

                    # if verbose:
                    #     print("total latency now: ", total_latency)

                    # find the best cycles
                    if best_lat == 0 or best_lat > total_latency:
                        best_lat = total_latency
                        best_schd = schedule

                    # if verbose:
                    #     print("schedule: ", schedule)
                    #     print("best_lat now:", best_lat)
        if best_lat == 0:
            print("fail to schedule this layer!")
        return best_lat, best_schd

    def get_best_schedule_opt(self, conv_params: list, ess_bit=3, verbose=False):
        """search for the best schecule.
        NOTE: For now, we only consider latency (cycles)
        Args:
            conv_params (list): 6-dim conv parameters
            ess_bit: essential bit for this layer
        Returns:
            best_lat and best_schd
        """
        assert len(conv_params) == 7, "Invalid conv_params!"

        [K, H, W, C, I, J, STRD] = conv_params

        assert H == W, "Not support H!=W"

        # if K and C dim are too large, we need to constraint the upper bound
        if K > 512:
            K_bound = 512
        else:
            K_bound = K

        if C > 512:
            C_bound = 512
        else:
            C_bound = C

        # brute force search
        best_lat = 0
        best_schd = {}
        best_ratio = 0.0
        best_roof = "no schedule"
        best_schd['k_size, k_tiles'] = (0, 0)
        best_schd['c_size, c_tiles'] = (0, 0)
        best_schd['o_size, o_tiles'] = (0, 0)

        for tile_k in range(K_bound, 15, -2):
            num_k_tiles = ceil_func(K, tile_k)
            if num_k_tiles > tile_k/2:
                continue
            # different ratio for K, default from 0.2 to 0.8
            for och_lut in range(math.floor(tile_k*0.2), math.floor(tile_k*0.7)):
                ratio_k = och_lut/tile_k
                och_dsp = tile_k - och_lut
                if C_bound < 8:
                    for tile_c in range(C_bound, 0, -1):
                        num_c_tiles = ceil_func(C, tile_c)
                        if num_c_tiles > tile_c:
                            continue
                        if H < 8:
                            for tile_o in range(H, 0, -1):
                                num_o_tiles = ceil_func(H, tile_o)
                                if num_o_tiles > tile_o:
                                    continue
                                # [K, H, W, C, I, J]
                                # we do not tile I and J (kernel height and weight)
                                schd_tile = [tile_k,
                                             tile_o, tile_o, tile_c, I, J, STRD]
                                is_overflow, opt_lat_cycle, roofline_bound = self.hw_model_obj.get_opt_lat(
                                    schd_tile, och_lut, och_dsp, ess_bit, verbose)
                                if is_overflow == False:
                                    continue

                                schedule = {}
                                schedule['k_size, k_tiles'] = (
                                    tile_k, num_k_tiles)
                                schedule['c_size, c_tiles'] = (
                                    tile_c, num_c_tiles)
                                schedule['o_size, o_tiles'] = (
                                    tile_o, num_o_tiles)

                                # abandon the schedule if buffers overflow (depth)
                                if verbose:
                                    print("schedule is ")
                                    print(schedule)
                                # print(ratio_k)
                                if verbose:
                                    print(och_lut, och_dsp)

                                # calculate memory latency and computation latency
                                mem_lat_first = self.hw_model_obj.get_glb_ld_lat(
                                    schd_tile, ess_bit, och_lut, och_dsp)
                                mem_lat_final = self.hw_model_obj.get_glb_wr_lat(
                                    schd_tile)
                                total_num_tiles = num_k_tiles * num_c_tiles * num_o_tiles * num_o_tiles
                                total_latency = total_num_tiles * opt_lat_cycle + mem_lat_first + mem_lat_final

                                # if verbose:
                                #     print("total latency now: ", total_latency)

                                # find the best cycles
                                if best_lat == 0 or best_lat > total_latency:
                                    best_lat = total_latency
                                    best_schd = schedule
                                    best_ratio = ratio_k
                                    best_roof = roofline_bound

                                # if verbose:
                                #     print("schedule: ", schedule)
                                #     print("best_lat now:", best_lat)
                        else:
                            for tile_o in range(H, 3, -2):
                                num_o_tiles = ceil_func(H, tile_o)
                                if num_o_tiles > tile_o/2:
                                    continue
                                # [K, H, W, C, I, J]
                                # we do not tile I and J (kernel height and weight)
                                schd_tile = [tile_k,
                                             tile_o, tile_o, tile_c, I, J, STRD]
                                is_overflow, opt_lat_cycle, roofline_bound = self.hw_model_obj.get_opt_lat(
                                    schd_tile, och_lut, och_dsp, ess_bit, verbose)
                                if is_overflow == False:
                                    continue
                                schedule = {}
                                schedule['k_size, k_tiles'] = (
                                    tile_k, num_k_tiles)
                                schedule['c_size, c_tiles'] = (
                                    tile_c, num_c_tiles)
                                schedule['o_size, o_tiles'] = (
                                    tile_o, num_o_tiles)

                                # abandon the schedule if buffers overflow (depth)
                                if verbose:
                                    print("schedule is ")
                                    print(schedule)
                                # print(ratio_k)
                                och_lut = math.floor(tile_k * ratio_k)
                                och_dsp = tile_k - och_lut
                                if verbose:
                                    print(och_lut, och_dsp)

                                # calculate memory latency and computation latency
                                mem_lat_first = self.hw_model_obj.get_glb_ld_lat(
                                    schd_tile, ess_bit, och_lut, och_dsp)
                                mem_lat_final = self.hw_model_obj.get_glb_wr_lat(
                                    schd_tile)
                                total_num_tiles = num_k_tiles * num_c_tiles * num_o_tiles * num_o_tiles
                                total_latency = total_num_tiles * opt_lat_cycle + mem_lat_first + mem_lat_final

                                # if verbose:
                                #     print("total latency now: ", total_latency)

                                # find the best cycles
                                if best_lat == 0 or best_lat > total_latency:
                                    best_lat = total_latency
                                    best_schd = schedule
                                    best_ratio = ratio_k
                                    best_roof = roofline_bound

                                # if verbose:
                                #     print("schedule: ", schedule)
                                #     print("best_lat now:", best_lat)
                else:
                    for tile_c in range(C_bound, 15, -2):
                        num_c_tiles = ceil_func(C, tile_c)
                        if num_c_tiles > tile_c/2:
                            continue
                        if H < 8:
                            for tile_o in range(H, 0, -1):
                                num_o_tiles = ceil_func(H, tile_o)
                                if num_o_tiles > tile_o:
                                    continue
                                # [K, H, W, C, I, J]
                                # we do not tile I and J (kernel height and weight)
                                schd_tile = [tile_k,
                                             tile_o, tile_o, tile_c, I, J, STRD]
                                is_overflow, opt_lat_cycle, roofline_bound = self.hw_model_obj.get_opt_lat(
                                    schd_tile, och_lut, och_dsp, ess_bit, verbose)
                                if is_overflow == False:
                                    continue

                                schedule = {}
                                schedule['k_size, k_tiles'] = (
                                    tile_k, num_k_tiles)
                                schedule['c_size, c_tiles'] = (
                                    tile_c, num_c_tiles)
                                schedule['o_size, o_tiles'] = (
                                    tile_o, num_o_tiles)

                                # abandon the schedule if buffers overflow (depth)
                                if verbose:
                                    print("schedule is ")
                                    print(schedule)
                                # print(ratio_k)
                                och_lut = math.floor(tile_k * ratio_k)
                                och_dsp = tile_k - och_lut
                                if verbose:
                                    print(och_lut, och_dsp)

                                # calculate memory latency and computation latency
                                mem_lat_first = self.hw_model_obj.get_glb_ld_lat(
                                    schd_tile, ess_bit, och_lut, och_dsp)
                                mem_lat_final = self.hw_model_obj.get_glb_wr_lat(
                                    schd_tile)
                                total_num_tiles = num_k_tiles * num_c_tiles * num_o_tiles * num_o_tiles
                                total_latency = total_num_tiles * opt_lat_cycle + mem_lat_first + mem_lat_final

                                # if verbose:
                                #     print("total latency now: ", total_latency)

                                # find the best cycles
                                if best_lat == 0 or best_lat > total_latency:
                                    best_lat = total_latency
                                    best_schd = schedule
                                    best_ratio = ratio_k
                                    best_roof = roofline_bound

                                # if verbose:
                                #     print("schedule: ", schedule)
                                #     print("best_lat now:", best_lat)
                        else:
                            for tile_o in range(H, 3, -2):
                                num_o_tiles = ceil_func(H, tile_o)
                                if num_o_tiles > tile_o/2:
                                    continue
                                # [K, H, W, C, I, J]
                                # we do not tile I and J (kernel height and weight)
                                schd_tile = [tile_k,
                                             tile_o, tile_o, tile_c, I, J, STRD]
                                is_overflow, opt_lat_cycle, roofline_bound = self.hw_model_obj.get_opt_lat(
                                    schd_tile, och_lut, och_dsp, ess_bit, verbose)
                                if is_overflow == False:
                                    continue

                                schedule = {}
                                schedule['k_size, k_tiles'] = (
                                    tile_k, num_k_tiles)
                                schedule['c_size, c_tiles'] = (
                                    tile_c, num_c_tiles)
                                schedule['o_size, o_tiles'] = (
                                    tile_o, num_o_tiles)

                                # abandon the schedule if buffers overflow (depth)
                                if verbose:
                                    print("schedule is ")
                                    print(schedule)
                                # print(ratio_k)
                                och_lut = math.floor(tile_k * ratio_k)
                                och_dsp = tile_k - och_lut
                                if verbose:
                                    print(och_lut, och_dsp)

                                # calculate memory latency and computation latency
                                mem_lat_first = self.hw_model_obj.get_glb_ld_lat(
                                    schd_tile, ess_bit, och_lut, och_dsp)
                                mem_lat_final = self.hw_model_obj.get_glb_wr_lat(
                                    schd_tile)
                                total_num_tiles = num_k_tiles * num_c_tiles * num_o_tiles * num_o_tiles
                                total_latency = total_num_tiles * opt_lat_cycle + mem_lat_first + mem_lat_final

                                # if verbose:
                                #     print("total latency now: ", total_latency)

                                # find the best cycles
                                if best_lat == 0 or best_lat > total_latency:
                                    best_lat = total_latency
                                    best_schd = schedule
                                    best_ratio = ratio_k
                                    best_roof = roofline_bound

                                # if verbose:
                                #     print("schedule: ", schedule)
                                #     print("best_lat now:", best_lat)
        if best_lat == 0:
            print("fail to schedule this layer!")
            logging.debug("fail to schedule this layer!")
        return best_lat, best_schd, best_ratio, best_roof

    def get_best_schedule_attention(self, conv_params: list, ess_bit=3, verbose=False):
        """search for the best schecule.
        NOTE: For now, we only consider latency (cycles)
        Args:
            conv_params (list): 6-dim conv parameters
            ess_bit: essential bit for this layer
        Returns:
            best_lat and best_schd
        """
        assert len(conv_params) == 7, "Invalid conv_params!"

        [K, H, W, C, I, J, STRD] = conv_params

        # if K and C dim are too large, we need to constraint the upper bound
        if K > 512:
            K_bound = 512
        else:
            K_bound = K

        if C > 512:
            C_bound = 512
        else:
            C_bound = C

        # brute force search
        best_lat = 0
        best_schd = {}
        best_ratio = 0.0
        best_roof = "no schedule"
        best_schd['k_size, k_tiles'] = (0, 0)
        best_schd['c_size, c_tiles'] = (0, 0)
        best_schd['o_size, o_tiles'] = (0, 0)

        for tile_k in range(4, K_bound + 1, 2):
            num_k_tiles = ceil_func(K, tile_k)
            # different ratio for K, default from 0.2 to 0.8
            och_lut = 1
            och_dsp = tile_k - 1
            ratio_k = 0.0
            for tile_c in range(4, C_bound + 1, 2):
                num_c_tiles = ceil_func(C, tile_c)
                for tile_o in range(8, H + 1, 2):
                    num_o_tiles = ceil_func(H, tile_o) * ceil_func(W, tile_o)
                    # [K, H, W, C, I, J]
                    # we do not tile I and J (kernel height and weight)
                    schd_tile = [tile_k,
                                 tile_o, tile_o, tile_c, I, J, STRD]
                    is_overflow, opt_lat_cycle, roofline_bound = self.hw_model_obj.get_opt_lat(
                        schd_tile, och_lut, och_dsp, ess_bit, verbose)
                    if is_overflow == False:
                        continue
                    schedule = {}
                    schedule['k_size, k_tiles'] = (
                        tile_k, num_k_tiles)
                    schedule['c_size, c_tiles'] = (
                        tile_c, num_c_tiles)
                    schedule['o_size, o_tiles'] = (
                        tile_o, num_o_tiles)

                    # abandon the schedule if buffers overflow (depth)
                    if verbose:
                        print("schedule is ")
                        print(schedule)
                    # print(ratio_k)
                    if verbose:
                        print(och_lut, och_dsp)

                    # calculate memory latency and computation latency
                    mem_lat_first = self.hw_model_obj.get_glb_ld_lat(
                        schd_tile, ess_bit, och_lut, och_dsp)
                    mem_lat_final = self.hw_model_obj.get_glb_wr_lat(
                        schd_tile)
                    total_num_tiles = num_k_tiles * num_c_tiles * num_o_tiles
                    total_latency = total_num_tiles * opt_lat_cycle + mem_lat_first + mem_lat_final

                    # if verbose:
                    #     print("total latency now: ", total_latency)

                    # find the best cycles
                    if best_lat == 0 or best_lat > total_latency:
                        best_lat = total_latency
                        best_schd = schedule
                        best_ratio = ratio_k
                        best_roof = roofline_bound

                    # if verbose:
                    #     print("schedule: ", schedule)
                    #     print("best_lat now:", best_lat)
        if best_lat == 0:
            print("fail to schedule this layer!")
            logging.debug("fail to schedule this layer!")
        return best_lat, best_schd, best_ratio, best_roof

    def get_best_schedule_dpws(self, conv_params: list, ess_bit=3, verbose=False):
        """search for the best schecule.
        NOTE: For now, we only consider latency (cycles)
        Args:
            conv_params (list): 6-dim conv parameters
            ess_bit: essential bit for this layer
        Returns:
            best_lat and best_schd
        """
        assert len(conv_params) == 7, "Invalid conv_params!"

        [K, H, W, C, I, J, STRD] = conv_params

        assert H == W, "Not support H!=W"

        # if K and C dim are too large, we need to constraint the upper bound
        if K > 512:
            K_bound = 512
        else:
            K_bound = K

        if C > 512:
            C_bound = 512
        else:
            C_bound = C

        # brute force search
        best_lat = 0
        best_schd = {}
        best_ratio = 0.0
        best_roof = "no schedule"
        best_schd['k_size, k_tiles'] = (0, 0)
        best_schd['c_size, c_tiles'] = (0, 0)
        best_schd['o_size, o_tiles'] = (0, 0)

        tile_k = 1
        for tile_c in range(C_bound, 3, -2):
            num_c_tiles = ceil_func(C, tile_c)
            if num_c_tiles > tile_c/2:
                continue
            # different ratio for C, default from 0.1 to 0.8
            for och_lut in range(math.floor(tile_c*0.1), math.floor(tile_c*0.7)):
                ratio_c = och_lut/tile_c
                och_dsp = tile_c - och_lut
                if H < 8:
                    for tile_o in range(H, 0, -1):
                        num_o_tiles = ceil_func(H, tile_o)
                        # [K, H, W, C, I, J]
                        # we do not tile I and J (kernel height and weight)
                        schd_tile = [tile_c,
                                     tile_o, tile_o, tile_c, I, J, STRD]
                        is_overflow, opt_lat_cycle, roofline_bound = self.hw_model_obj.get_opt_lat_dpws(
                            schd_tile, och_lut, och_dsp, ess_bit, verbose)
                        if is_overflow == False:
                            continue
                        if num_o_tiles > tile_o:
                            continue
                        schedule = {}
                        schedule['k_size, k_tiles'] = (tile_c, num_c_tiles)
                        schedule['c_size, c_tiles'] = (1, 1)
                        schedule['o_size, o_tiles'] = (tile_o, num_o_tiles)

                        # abandon the schedule if buffers overflow (depth)
                        if verbose:
                            print("schedule is ")
                            print(schedule)
                        # print(ratio_k)
                        och_lut = math.floor(tile_c * ratio_c)
                        och_dsp = tile_c - och_lut
                        if verbose:
                            print(och_lut, och_dsp)

                        # calculate memory latency and computation latency
                        mem_lat_first = self.hw_model_obj.get_glb_ld_lat_dpws(
                            schd_tile, ess_bit, och_lut, och_dsp)
                        mem_lat_final = self.hw_model_obj.get_glb_wr_lat(
                            schd_tile)
                        total_num_tiles = num_c_tiles * num_o_tiles * num_o_tiles
                        total_latency = total_num_tiles * opt_lat_cycle + mem_lat_first + mem_lat_final
                        # logging.debug(schedule)
                        # logging.debug(
                        #     "num of tile is " + str(total_num_tiles))
                        # logging.debug(
                        #     "latency for one tile is " + str(opt_lat_cycle))
                        # logging.debug(
                        #     "dpws latency is " + str(total_latency))
                        # if verbose:
                        #     print("total latency now: ", total_latency)

                        # find the best cycles
                        if best_lat == 0 or best_lat > total_latency:
                            best_lat = total_latency
                            best_schd = schedule
                            best_ratio = ratio_c
                            best_roof = roofline_bound

                        # if verbose:
                        #     print("schedule: ", schedule)
                        #     print("best_lat now:", best_lat)
                else:
                    for tile_o in range(H, 3, -2):
                        num_o_tiles = ceil_func(H, tile_o)
                        if num_o_tiles > tile_o/2:
                            continue
                        # [K, H, W, C, I, J]
                        # we do not tile I and J (kernel height and weight)
                        schd_tile = [tile_c,
                                     tile_o, tile_o, tile_c, I, J, STRD]
                        is_overflow, opt_lat_cycle, roofline_bound = self.hw_model_obj.get_opt_lat_dpws(
                            schd_tile, och_lut, och_dsp, ess_bit, verbose)
                        if is_overflow == False:
                            continue
                        if num_c_tiles > (tile_c * 2):
                            continue
                        schedule = {}
                        schedule['k_size, k_tiles'] = (tile_k, 1)
                        schedule['c_size, c_tiles'] = (tile_c, num_c_tiles)
                        schedule['o_size, o_tiles'] = (tile_o, num_o_tiles)

                        # abandon the schedule if buffers overflow (depth)
                        if verbose:
                            print("schedule is ")
                            print(schedule)
                        # print(ratio_k)
                        och_lut = math.floor(tile_c * ratio_c)
                        och_dsp = tile_c - och_lut
                        if verbose:
                            print(och_lut, och_dsp)

                        # calculate memory latency and computation latency
                        mem_lat_first = self.hw_model_obj.get_glb_ld_lat_dpws(
                            schd_tile, ess_bit, och_lut, och_dsp)
                        mem_lat_final = self.hw_model_obj.get_glb_wr_lat(
                            schd_tile)
                        total_num_tiles = num_c_tiles * num_o_tiles * num_o_tiles
                        total_latency = total_num_tiles * opt_lat_cycle + mem_lat_first + mem_lat_final
                        # logging.debug(schedule)
                        # logging.debug(
                        #     "num of tile is " + str(total_num_tiles))
                        # logging.debug(
                        #     "latency for one tile is " + str(opt_lat_cycle))
                        # logging.debug(
                        #     "dpws latency is " + str(total_latency))
                        # if verbose:
                        #     print("total latency now: ", total_latency)

                        # find the best cycles
                        if best_lat == 0 or best_lat > total_latency:
                            best_lat = total_latency
                            best_schd = schedule
                            best_ratio = ratio_c
                            best_roof = roofline_bound

                        # if verbose:
                        #     print("schedule: ", schedule)
                        #     print("best_lat now:", best_lat)
        if best_lat == 0:
            print("fail to schedule this layer!")
            logging.debug("fail to schedule this layer!")
        return best_lat, best_schd, best_ratio, best_roof

    def get_best_schedule_baseline(self, conv_params: list, ess_bit=3, verbose=False):
        """search for the best schecule.
        NOTE: For now, we only consider latency (cycles)
        Args:
            conv_params (list): 6-dim conv parameters
            ess_bit: essential bit for this layer
        Returns:
            best_lat and best_schd
        """
        assert len(conv_params) == 7, "Invalid conv_params!"

        [K, H, W, C, I, J, STRD] = conv_params

        assert H == W, "Not support H!=W"

        # if K and C dim are too large, we need to constraint the upper bound
        if K > 512:
            K_bound = 512
        else:
            K_bound = K

        if C > 512:
            C_bound = 512
        else:
            C_bound = C

        # brute force search
        best_lat = 0
        best_schd = {}
        best_ratio = 0.0
        best_roof = "no schedule"
        best_schd['k_size, k_tiles'] = (0, 0)
        best_schd['c_size, c_tiles'] = (0, 0)
        best_schd['o_size, o_tiles'] = (0, 0)

        for tile_k in range(8, K_bound + 1, 2):
            num_k_tiles = ceil_func(K, tile_k)
            # different ratio for K, default from 0.2 to 0.8
            ratio_k = 0.0
            och_lut = 0
            och_dsp = tile_k
            if C_bound < 16:
                for tile_c in range(1, C_bound + 1):
                    num_c_tiles = ceil_func(C, tile_c)
                    if H < 8:
                        for tile_o in range(1, H + 1):
                            num_o_tiles = ceil_func(H, tile_o)
                            # [K, H, W, C, I, J]
                            # we do not tile I and J (kernel height and weight)
                            schd_tile = [tile_k,
                                         tile_o, tile_o, tile_c, I, J, STRD]
                            is_overflow, opt_lat_cycle, roofline_bound = self.hw_model_obj.get_opt_lat(
                                schd_tile, och_lut, och_dsp, ess_bit, verbose)
                            if is_overflow == False:
                                continue
                            schedule = {}
                            schedule['k_size, k_tiles'] = (
                                tile_k, num_k_tiles)
                            schedule['c_size, c_tiles'] = (
                                tile_c, num_c_tiles)
                            schedule['o_size, o_tiles'] = (
                                tile_o, num_o_tiles)

                            # abandon the schedule if buffers overflow (depth)
                            if verbose:
                                print("schedule is ")
                                print(schedule)
                            # print(ratio_k)
                            if verbose:
                                print(och_lut, och_dsp)

                            # calculate memory latency and computation latency
                            mem_lat_first = self.hw_model_obj.get_glb_ld_lat(
                                schd_tile, ess_bit, och_lut, och_dsp)
                            mem_lat_final = self.hw_model_obj.get_glb_wr_lat(
                                schd_tile)
                            total_num_tiles = num_k_tiles * num_c_tiles * num_o_tiles * num_o_tiles
                            total_latency = total_num_tiles * opt_lat_cycle + mem_lat_first + mem_lat_final

                            # if verbose:
                            #     print("total latency now: ", total_latency)

                            # find the best cycles
                            if best_lat == 0 or best_lat > total_latency:
                                best_lat = total_latency
                                best_schd = schedule
                                best_ratio = ratio_k
                                best_roof = roofline_bound

                            # if verbose:
                            #     print("schedule: ", schedule)
                            #     print("best_lat now:", best_lat)
                    else:
                        for tile_o in range(4, H + 1, 2):
                            num_o_tiles = ceil_func(H, tile_o)
                            # [K, H, W, C, I, J]
                            # we do not tile I and J (kernel height and weight)
                            schd_tile = [tile_k,
                                         tile_o, tile_o, tile_c, I, J, STRD]
                            is_overflow, opt_lat_cycle, roofline_bound = self.hw_model_obj.get_opt_lat(
                                schd_tile, och_lut, och_dsp, ess_bit, verbose)
                            if is_overflow == False:
                                continue
                            schedule = {}
                            schedule['k_size, k_tiles'] = (
                                tile_k, num_k_tiles)
                            schedule['c_size, c_tiles'] = (
                                tile_c, num_c_tiles)
                            schedule['o_size, o_tiles'] = (
                                tile_o, num_o_tiles)

                            # abandon the schedule if buffers overflow (depth)
                            if verbose:
                                print("schedule is ")
                                print(schedule)
                            # print(ratio_k)
                            och_lut = math.floor(tile_k * ratio_k)
                            och_dsp = tile_k - och_lut
                            if verbose:
                                print(och_lut, och_dsp)

                            # calculate memory latency and computation latency
                            mem_lat_first = self.hw_model_obj.get_glb_ld_lat(
                                schd_tile, ess_bit, och_lut, och_dsp)
                            mem_lat_final = self.hw_model_obj.get_glb_wr_lat(
                                schd_tile)
                            total_num_tiles = num_k_tiles * num_c_tiles * num_o_tiles * num_o_tiles
                            total_latency = total_num_tiles * opt_lat_cycle + mem_lat_first + mem_lat_final

                            # if verbose:
                            #     print("total latency now: ", total_latency)

                            # find the best cycles
                            if best_lat == 0 or best_lat > total_latency:
                                best_lat = total_latency
                                best_schd = schedule
                                best_ratio = ratio_k
                                best_roof = roofline_bound

                            # if verbose:
                            #     print("schedule: ", schedule)
                            #     print("best_lat now:", best_lat)
            else:
                for tile_c in range(4, C_bound + 1, 2):
                    num_c_tiles = ceil_func(C, tile_c)
                    if H < 8:
                        for tile_o in range(1, H + 1):
                            num_o_tiles = ceil_func(H, tile_o)
                            # [K, H, W, C, I, J]
                            # we do not tile I and J (kernel height and weight)
                            schd_tile = [tile_k,
                                         tile_o, tile_o, tile_c, I, J, STRD]
                            is_overflow, opt_lat_cycle, roofline_bound = self.hw_model_obj.get_opt_lat(
                                schd_tile, och_lut, och_dsp, ess_bit, verbose)
                            if is_overflow == False:
                                continue
                            schedule = {}
                            schedule['k_size, k_tiles'] = (
                                tile_k, num_k_tiles)
                            schedule['c_size, c_tiles'] = (
                                tile_c, num_c_tiles)
                            schedule['o_size, o_tiles'] = (
                                tile_o, num_o_tiles)

                            # abandon the schedule if buffers overflow (depth)
                            if verbose:
                                print("schedule is ")
                                print(schedule)
                            # print(ratio_k)
                            och_lut = math.floor(tile_k * ratio_k)
                            och_dsp = tile_k - och_lut
                            if verbose:
                                print(och_lut, och_dsp)

                            # calculate memory latency and computation latency
                            mem_lat_first = self.hw_model_obj.get_glb_ld_lat(
                                schd_tile, ess_bit, och_lut, och_dsp)
                            mem_lat_final = self.hw_model_obj.get_glb_wr_lat(
                                schd_tile)
                            total_num_tiles = num_k_tiles * num_c_tiles * num_o_tiles * num_o_tiles
                            total_latency = total_num_tiles * opt_lat_cycle + mem_lat_first + mem_lat_final

                            # if verbose:
                            #     print("total latency now: ", total_latency)

                            # find the best cycles
                            if best_lat == 0 or best_lat > total_latency:
                                best_lat = total_latency
                                best_schd = schedule
                                best_ratio = ratio_k
                                best_roof = roofline_bound

                            # if verbose:
                            #     print("schedule: ", schedule)
                            #     print("best_lat now:", best_lat)
                    else:
                        for tile_o in range(4, H + 1, 2):
                            num_o_tiles = ceil_func(H, tile_o)
                            # [K, H, W, C, I, J]
                            # we do not tile I and J (kernel height and weight)
                            schd_tile = [tile_k,
                                         tile_o, tile_o, tile_c, I, J, STRD]
                            is_overflow, opt_lat_cycle, roofline_bound = self.hw_model_obj.get_opt_lat(
                                schd_tile, och_lut, och_dsp, ess_bit, verbose)
                            if is_overflow == False:
                                continue
                            schedule = {}
                            schedule['k_size, k_tiles'] = (
                                tile_k, num_k_tiles)
                            schedule['c_size, c_tiles'] = (
                                tile_c, num_c_tiles)
                            schedule['o_size, o_tiles'] = (
                                tile_o, num_o_tiles)

                            # abandon the schedule if buffers overflow (depth)
                            if verbose:
                                print("schedule is ")
                                print(schedule)
                            # print(ratio_k)
                            och_lut = math.floor(tile_k * ratio_k)
                            och_dsp = tile_k - och_lut
                            if verbose:
                                print(och_lut, och_dsp)

                            # calculate memory latency and computation latency
                            mem_lat_first = self.hw_model_obj.get_glb_ld_lat(
                                schd_tile, ess_bit, och_lut, och_dsp)
                            mem_lat_final = self.hw_model_obj.get_glb_wr_lat(
                                schd_tile)
                            total_num_tiles = num_k_tiles * num_c_tiles * num_o_tiles * num_o_tiles
                            total_latency = total_num_tiles * opt_lat_cycle + mem_lat_first + mem_lat_final

                            # if verbose:
                            #     print("total latency now: ", total_latency)

                            # find the best cycles
                            if best_lat == 0 or best_lat > total_latency:
                                best_lat = total_latency
                                best_schd = schedule
                                best_ratio = ratio_k
                                best_roof = roofline_bound

                            # if verbose:
                            #     print("schedule: ", schedule)
                            #     print("best_lat now:", best_lat)
        if best_lat == 0:
            print("fail to schedule this layer!")
            logging.debug("fail to schedule this layer!")
        return best_lat, best_schd, best_ratio, best_roof

    def get_best_schedule_baseline_dpws(self, conv_params: list, ess_bit=3, verbose=False):
        """search for the best schecule.
        NOTE: For now, we only consider latency (cycles)
        Args:
            conv_params (list): 6-dim conv parameters
            ess_bit: essential bit for this layer
        Returns:
            best_lat and best_schd
        """
        assert len(conv_params) == 7, "Invalid conv_params!"

        [K, H, W, C, I, J, STRD] = conv_params

        assert H == W, "Not support H!=W"

        # if K and C dim are too large, we need to constraint the upper bound
        if K > 512:
            K_bound = 512
        else:
            K_bound = K

        if C > 512:
            C_bound = 512
        else:
            C_bound = C

        # brute force search
        best_lat = 0
        best_schd = {}
        best_ratio = 0.0
        best_roof = "no schedule"
        best_schd['k_size, k_tiles'] = (0, 0)
        best_schd['c_size, c_tiles'] = (0, 0)
        best_schd['o_size, o_tiles'] = (0, 0)

        tile_k = 1
        for tile_c in range(8, C_bound + 1, 2):
            num_c_tiles = ceil_func(C, tile_c)
            # different ratio for C, default from 0.1 to 0.8
            ratio_c = 0.0
            och_lut = 0
            och_dsp = tile_c
            if H < 8:
                for tile_o in range(1, H + 1):
                    num_o_tiles = ceil_func(H, tile_o)
                    # [K, H, W, C, I, J]
                    # we do not tile I and J (kernel height and weight)
                    schd_tile = [tile_c,
                                 tile_o, tile_o, tile_c, I, J, STRD]
                    is_overflow, opt_lat_cycle, roofline_bound = self.hw_model_obj.get_opt_lat_dpws(
                        schd_tile, och_lut, och_dsp, ess_bit, verbose)
                    if is_overflow == False:
                        continue
                    schedule = {}
                    schedule['k_size, k_tiles'] = (tile_k, K)
                    schedule['c_size, c_tiles'] = (tile_c, num_c_tiles)
                    schedule['o_size, o_tiles'] = (tile_o, num_o_tiles)

                    # abandon the schedule if buffers overflow (depth)
                    if verbose:
                        print("schedule is ")
                        print(schedule)
                    # print(ratio_k)
                    och_lut = math.floor(tile_c * ratio_c)
                    och_dsp = tile_c - och_lut
                    if verbose:
                        print(och_lut, och_dsp)

                    # calculate memory latency and computation latency
                    mem_lat_first = self.hw_model_obj.get_glb_ld_lat_dpws(
                        schd_tile, ess_bit, och_lut, och_dsp)
                    mem_lat_final = self.hw_model_obj.get_glb_wr_lat(
                        schd_tile)
                    total_num_tiles = num_c_tiles * num_o_tiles * num_o_tiles
                    total_latency = total_num_tiles * opt_lat_cycle + mem_lat_first + mem_lat_final
                    # logging.debug(schedule)
                    # logging.debug(
                    #     "num of tile is " + str(total_num_tiles))
                    # logging.debug(
                    #     "latency for one tile is " + str(opt_lat_cycle))
                    # logging.debug(
                    #     "dpws latency is " + str(total_latency))
                    # if verbose:
                    #     print("total latency now: ", total_latency)

                    # find the best cycles
                    if best_lat == 0 or best_lat > total_latency:
                        best_lat = total_latency
                        best_schd = schedule
                        best_ratio = ratio_c
                        best_roof = roofline_bound

                    # if verbose:
                    #     print("schedule: ", schedule)
                    #     print("best_lat now:", best_lat)
            else:
                for tile_o in range(2, H + 1, 2):
                    num_o_tiles = ceil_func(H, tile_o)
                    # [K, H, W, C, I, J]
                    # we do not tile I and J (kernel height and weight)
                    schd_tile = [tile_c,
                                 tile_o, tile_o, tile_c, I, J, STRD]
                    is_overflow, opt_lat_cycle, roofline_bound = self.hw_model_obj.get_opt_lat_dpws(
                        schd_tile, och_lut, och_dsp, ess_bit, verbose)
                    if is_overflow == False:
                        continue
                    schedule = {}
                    schedule['k_size, k_tiles'] = (tile_k, K)
                    schedule['c_size, c_tiles'] = (tile_c, num_c_tiles)
                    schedule['o_size, o_tiles'] = (tile_o, num_o_tiles)

                    # abandon the schedule if buffers overflow (depth)
                    if verbose:
                        print("schedule is ")
                        print(schedule)
                    # print(ratio_k)
                    och_lut = math.floor(tile_c * ratio_c)
                    och_dsp = tile_c - och_lut
                    if verbose:
                        print(och_lut, och_dsp)

                    # calculate memory latency and computation latency
                    mem_lat_first = self.hw_model_obj.get_glb_ld_lat_dpws(
                        schd_tile, ess_bit, och_lut, och_dsp)
                    mem_lat_final = self.hw_model_obj.get_glb_wr_lat(
                        schd_tile)
                    total_num_tiles = num_c_tiles * num_o_tiles * num_o_tiles
                    total_latency = total_num_tiles * opt_lat_cycle + mem_lat_first + mem_lat_final
                    # logging.debug(schedule)
                    # logging.debug(
                    #     "num of tile is " + str(total_num_tiles))
                    # logging.debug(
                    #     "latency for one tile is " + str(opt_lat_cycle))
                    # logging.debug(
                    #     "dpws latency is " + str(total_latency))
                    # if verbose:
                    #     print("total latency now: ", total_latency)

                    # find the best cycles
                    if best_lat == 0 or best_lat > total_latency:
                        best_lat = total_latency
                        best_schd = schedule
                        best_ratio = ratio_c
                        best_roof = roofline_bound

                    # if verbose:
                    #     print("schedule: ", schedule)
                    #     print("best_lat now:", best_lat)
        if best_lat == 0:
            print("fail to schedule this layer!")
            logging.debug("fail to schedule this layer!")
        return best_lat, best_schd, best_ratio, best_roof
