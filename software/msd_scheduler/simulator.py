from utils import ceil_func
import configparser

from hw_model import HardwareModel
from scheduler import Scheduler
from dnn_model import DNNModel


class Simulator(object):
    def __init__(self, hw_conf_ini="archs/xc7z020_8b_arch.ini"):
        """object
        Args:
            hw_conf_ini (str, optional): configuration file. Defaults to 'hw_conf.ini'.
            e.g. systolic array rows, cols, bandwidth, buffer size...
        """
        self.hw_config = configparser.ConfigParser()
        self.hw_config.read(hw_conf_ini)
        self.lut_arr_arch = [self.hw_config.getint(
            "array", "bs_rows"), self.hw_config.getint("array", "bs_cols")]
        lut_buf_arch = [self.hw_config.getint("array", "bs_ifm_bram18"), self.hw_config.getint(
            "array", "bs_wgt_bram18"), self.hw_config.getint("array", "bs_ofm_bram18")]
        self.dsp_arr_arch = [self.hw_config.getint(
            "array", "bp_rows"), self.hw_config.getint("array", "bp_cols")]
        dsp_buf_arch = [self.hw_config.getint("array", "bp_ifm_bram18"), self.hw_config.getint(
            "array", "bp_wgt_bram18"), self.hw_config.getint("array", "bp_ofm_bram18")]
        self.hw_bandwidth = self.hw_config.getint(
            "system", "hardware_bandwidth")
        self.frequency = self.hw_config.getint("system", "hardware_frequency")
        self.dnn_model = DNNModel()
        # transfer arch into depth
        self.lut_buf_depth = []
        self.dsp_buf_depth = []
        lut_datawidth = [8, 4, 8]
        dsp_datawidth = [16, 8, 16]
        for i in range(3):
            buf_depth = self.bram_depth_calculator(
                bram18_utl=lut_buf_arch[i], data_width=lut_datawidth[i])
            self.lut_buf_depth.append(buf_depth)
            buf_depth = self.bram_depth_calculator(
                bram18_utl=dsp_buf_arch[i], data_width=dsp_datawidth[i])
            self.dsp_buf_depth.append(buf_depth)

        mem_bw = [self.hw_bandwidth, self.lut_arr_arch[1],
                  self.lut_arr_arch[0], self.dsp_arr_arch[1]*2, self.dsp_arr_arch[0]]
        self.hw_model = HardwareModel(
            self.lut_arr_arch, self.lut_buf_depth, self.dsp_arr_arch, self.dsp_buf_depth, mem_bw, self.frequency)
        self.scheduler = Scheduler(self.hw_model)

    def bram_depth_calculator(self, bram18_utl, data_width=8):
        bram_bit_utl = bram18_utl * 16384
        bram_depth = ceil_func(bram_bit_utl, data_width)
        return bram_depth

    def get_layer_latency(self, layer_conv_params: list, ess_bit=3, verbose=False):
        best_latency_layer = 0
        best_schedule_layer = {}

        best_latency_layer, best_schedule_layer = self.scheduler.get_best_schedule(
            layer_conv_params, ess_bit, verbose)
        # for debug only
        if verbose:
            print("best latency for this layer is", best_latency_layer)
            print("best schedule is", best_schedule_layer)
        return best_latency_layer, best_schedule_layer

    def get_layer_latency_opt(self, layer_conv_params: list, ess_bit=3, verbose=False):
        best_latency_layer = 0
        best_schedule_layer = {}
        best_ratio = 0.0
        if layer_conv_params[3] == 1:
            # print("dpws layer")
            layer_conv_params[3] = layer_conv_params[0]
            best_latency_layer, best_schedule_layer, best_ratio, best_roof = self.scheduler.get_best_schedule_dpws(
                layer_conv_params, ess_bit, verbose)
        else:
            best_latency_layer, best_schedule_layer, best_ratio, best_roof = self.scheduler.get_best_schedule_opt(
                layer_conv_params, ess_bit, verbose)
        # for debug only
        if verbose:
            print("best latency for this layer is", best_latency_layer)
            print("best schedule is", best_schedule_layer)
            print("best ratio is", best_ratio)
        return best_latency_layer, best_schedule_layer, best_ratio, best_roof

    def get_layer_latency_baseline(self, layer_conv_params: list, ess_bit=3, verbose=False):
        best_latency_layer = 0
        best_schedule_layer = {}
        best_ratio = 0.0
        if layer_conv_params[3] == 1:
            print("dpws layer")
            layer_conv_params[3] = layer_conv_params[0]
            best_latency_layer, best_schedule_layer, best_ratio, best_roof = self.scheduler.get_best_schedule_baseline_dpws(
                layer_conv_params, ess_bit, verbose)
        else:
            best_latency_layer, best_schedule_layer, best_ratio, best_roof = self.scheduler.get_best_schedule_baseline(
                layer_conv_params, ess_bit, verbose)
        # for debug only
        if verbose:
            print("best latency for this layer is", best_latency_layer)
            print("best schedule is", best_schedule_layer)
            print("best ratio is", best_ratio)
        return best_latency_layer, best_schedule_layer, best_ratio, best_roof

    def get_layer_latency_attention(self, layer_conv_params: list, ess_bit=3, verbose=False):
        best_latency_layer = 0
        best_schedule_layer = {}
        best_ratio = 0.0
        best_latency_layer, best_schedule_layer, best_ratio, best_roof = self.scheduler.get_best_schedule_attention(
            layer_conv_params, ess_bit, verbose)
        # for debug only
        if verbose:
            print("best latency for this layer is", best_latency_layer)
            print("best schedule is", best_schedule_layer)
            print("best ratio is", best_ratio)
        return best_latency_layer, best_schedule_layer, best_ratio, best_roof

    def get_total_latency(self, model_csv, ess_bit=3, verbose=False):
        self.dnn_model.load_model_csv(model_csv)
        dnn_model_array = self.dnn_model.get_model_arrays()
        conv_params_array = self.dnn_model.calc_model_conv_params()

        if verbose:
            print("dnn model array:", dnn_model_array)
            print("layer conv params:", conv_params_array)

        total_latency = 0
        layer_latency = 0
        for layer_idx in range(len(conv_params_array)):
            layer_conv_params = conv_params_array[layer_idx]
            layer_latency, layer_schecule = self.get_layer_latency(
                layer_conv_params, ess_bit, verbose)
            total_latency = total_latency + layer_latency

        return total_latency

    def get_layer_util_rate(self, layer_conv_params, quantizations: list):
        """Implement in the future
        Args:
            layer_conv_params (_type_): _description_
            quantizations (list): _description_
        Returns:
            _type_: _description_
        """
        return None

    def get_total_util_rate(self, model_csv):
        """Implement in the future
        Args:
            model_csv (_type_): _description_
        Returns:
            _type_: _description_
        """
        return None

    def generate_stats_csv(self, model_csv="", stats_csv="", ess_bit=3, verbose=False):
        self.get_hw_info()
        ff = open(stats_csv, "w")
        self.dnn_model.load_model_csv(model_csv)
        conv_params_array = self.dnn_model.calc_model_conv_params()
        layer_names = self.dnn_model.get_layer_names()
        total_latency = 0
        for layer_idx in range(len(conv_params_array)):
            str_layer_name = layer_names[layer_idx]
            print("Starting schedule: " + str_layer_name)
            wr_line = str_layer_name + ', '
            layer_conv_params = conv_params_array[layer_idx]
            stats_latency, stats_schedule = self.get_layer_latency(
                layer_conv_params, ess_bit, verbose)
            total_latency += stats_latency
            wr_line += str(stats_latency) + ', '
            wr_line += str(stats_schedule['k_size, k_tiles']) + ', '
            wr_line += str(stats_schedule['c_size, c_tiles']) + ', '
            wr_line += str(stats_schedule['o_size, o_tiles'])
            wr_line += "\n"
            ff.write(wr_line)

        total_latency_ms = total_latency * (1/self.frequency) * 1000
        ff.close()

        return total_latency, total_latency_ms

    def generate_stats_csv_opt(self, eb_list: list, model_csv="", stats_csv="", verbose=False):
        # self.get_hw_info()
        ff = open(stats_csv, "w")
        self.dnn_model.load_model_csv(model_csv)
        conv_params_array = self.dnn_model.calc_model_conv_params()
        layer_names = self.dnn_model.get_layer_names()
        total_latency = 0
        assert len(conv_params_array) == len(
            eb_list), "Make sure each layer has an essential bit number."
        for layer_idx in range(len(conv_params_array)):
            str_layer_name = layer_names[layer_idx]
            # print("Starting schedule: " + str_layer_name)
            layer_conv_params = conv_params_array[layer_idx]
            stats_latency, stats_schedule, stats_ratio, best_roof = self.get_layer_latency_opt(
                layer_conv_params, eb_list[layer_idx], verbose)
            if "Encoder_0" in str_layer_name:
                total_latency += stats_latency * 12
                for i in range(12):
                    wr_line = str_layer_name + '_' + str(i) + ', '
                    wr_line += str(stats_latency) + ', '
                    wr_line += str(stats_schedule['k_size, k_tiles'][0]) + ', '
                    wr_line += str(stats_schedule['k_size, k_tiles'][1]) + ', '
                    wr_line += str(stats_schedule['c_size, c_tiles'][0]) + ', '
                    wr_line += str(stats_schedule['c_size, c_tiles'][1]) + ', '
                    wr_line += str(stats_schedule['o_size, o_tiles'][0]) + ', '
                    wr_line += str(stats_schedule['o_size, o_tiles'][1]) + ', '
                    wr_line += str(layer_conv_params[5]) + ', '
                    wr_line += str(layer_conv_params[6]) + ', '
                    wr_line += str(stats_ratio) + ', '
                    wr_line += str(eb_list[layer_idx]) + ', '
                    wr_line += best_roof
                    wr_line += "\n"
                    ff.write(wr_line)
            else:
                total_latency += stats_latency
                wr_line = str_layer_name + ', '
                wr_line += str(stats_latency) + ', '
                wr_line += str(stats_schedule['k_size, k_tiles'][0]) + ', '
                wr_line += str(stats_schedule['k_size, k_tiles'][1]) + ', '
                wr_line += str(stats_schedule['c_size, c_tiles'][0]) + ', '
                wr_line += str(stats_schedule['c_size, c_tiles'][1]) + ', '
                wr_line += str(stats_schedule['o_size, o_tiles'][0]) + ', '
                wr_line += str(stats_schedule['o_size, o_tiles'][1]) + ', '
                wr_line += str(layer_conv_params[5]) + ', '
                wr_line += str(layer_conv_params[6]) + ', '
                wr_line += str(stats_ratio) + ','
                wr_line += str(eb_list[layer_idx]) + ', '
                wr_line += best_roof
                wr_line += "\n"
                ff.write(wr_line)

        total_latency_ms = total_latency * (1/self.frequency) * 1000
        # ff.write("latency cycles: " + str(total_latency) + '\n')
        # ff.write("latency: " + str(total_latency_ms) + " ms")
        ff.close()

        return total_latency, total_latency_ms

    def generate_stats_csv_opt_mobnet(self, eb_list: list, model_csv="", stats_csv="", verbose=False):
        # self.get_hw_info()
        ff = open(stats_csv, "w")
        self.dnn_model.load_model_csv(model_csv)
        conv_params_array = self.dnn_model.calc_model_conv_params()
        layer_names = self.dnn_model.get_layer_names()
        total_latency = 0
        assert len(conv_params_array) == len(
            eb_list), "Make sure each layer has an essential bit number."
        for layer_idx in range(32):
            str_layer_name = layer_names[layer_idx]
            # print("Starting schedule: " + str_layer_name)
            layer_conv_params = conv_params_array[layer_idx]
            stats_latency, stats_schedule, stats_ratio, best_roof = self.get_layer_latency_opt(
                layer_conv_params, eb_list[layer_idx], verbose)
            total_latency += stats_latency
            wr_line = str_layer_name + ', '
            wr_line += str(stats_latency) + ', '
            wr_line += str(stats_schedule['k_size, k_tiles'][0]) + ', '
            wr_line += str(stats_schedule['k_size, k_tiles'][1]) + ', '
            wr_line += str(stats_schedule['c_size, c_tiles'][0]) + ', '
            wr_line += str(stats_schedule['c_size, c_tiles'][1]) + ', '
            wr_line += str(stats_schedule['o_size, o_tiles'][0]) + ', '
            wr_line += str(stats_schedule['o_size, o_tiles'][1]) + ', '
            wr_line += str(layer_conv_params[5]) + ', '
            wr_line += str(layer_conv_params[6]) + ', '
            wr_line += str(stats_ratio) + ','
            wr_line += str(eb_list[layer_idx]) + ', '
            wr_line += best_roof
            wr_line += "\n"
            ff.write(wr_line)
        ff.close()
        total_latency_ms = total_latency * (1/self.frequency) * 1000
        ff = open("results/xc7z020_mobilenetv2_2.csv", "w")
        for layer_2_idx in range(32, len(conv_params_array)):
            str_layer_name = layer_names[layer_2_idx]
            # print("Starting schedule: " + str_layer_name)
            layer_conv_params = conv_params_array[layer_2_idx]
            stats_latency, stats_schedule, stats_ratio, best_roof = self.get_layer_latency_opt(
                layer_conv_params, eb_list[layer_2_idx], verbose)
            total_latency += stats_latency
            wr_line = str_layer_name + ', '
            wr_line += str(stats_latency) + ', '
            wr_line += str(stats_schedule['k_size, k_tiles'][0]) + ', '
            wr_line += str(stats_schedule['k_size, k_tiles'][1]) + ', '
            wr_line += str(stats_schedule['c_size, c_tiles'][0]) + ', '
            wr_line += str(stats_schedule['c_size, c_tiles'][1]) + ', '
            wr_line += str(stats_schedule['o_size, o_tiles'][0]) + ', '
            wr_line += str(stats_schedule['o_size, o_tiles'][1]) + ', '
            wr_line += str(layer_conv_params[5]) + ', '
            wr_line += str(layer_conv_params[6]) + ', '
            wr_line += str(stats_ratio) + ','
            wr_line += str(eb_list[layer_2_idx]) + ', '
            wr_line += best_roof
            wr_line += "\n"
            ff.write(wr_line)
        ff.close()
        # ff.write("latency cycles: " + str(total_latency) + '\n')
        # ff.write("latency: " + str(total_latency_ms) + " ms")

        return total_latency, total_latency_ms

    def generate_latency_eb_comb(self, eb_list: list, model_csv="", stats_csv="", verbose=False):
        ff = open(stats_csv, "w")
        self.dnn_model.load_model_csv(model_csv)
        conv_params_array = self.dnn_model.calc_model_conv_params()
        layer_names = self.dnn_model.get_layer_names()
        total_latency_eb2 = 0
        for layer_idx in range(len(conv_params_array)):
            str_layer_name = layer_names[layer_idx]
            print("Starting schedule: " + str_layer_name)
            layer_conv_params = conv_params_array[layer_idx]
            for eb_sel in eb_list:
                print("Starting eb " + str(eb_sel))
                if "attention" in str_layer_name:
                    stats_latency, stats_schedule, stats_ratio, best_roof = self.get_layer_latency_attention(
                        layer_conv_params, eb_sel, verbose)
                else:
                    stats_latency, stats_schedule, stats_ratio, best_roof = self.get_layer_latency_opt(
                        layer_conv_params, eb_sel, verbose)
                if eb_sel == 2:
                    total_latency_eb2 += stats_latency
                wr_line = str_layer_name + ', '
                wr_line += str(eb_sel) + ', '
                wr_line += str(stats_latency) + ', '
                wr_line += str(stats_schedule['k_size, k_tiles']) + ', '
                wr_line += str(stats_schedule['c_size, c_tiles']) + ', '
                wr_line += str(stats_schedule['o_size, o_tiles']) + ', '
                wr_line += str(stats_ratio) + ','
                wr_line += best_roof
                wr_line += "\n"
                ff.write(wr_line)

        total_latency_ms = total_latency_eb2 * (1/self.frequency) * 1000
        ff.write("eb2 latency cycles: " + str(total_latency_eb2) + '\n')
        ff.write("eb2 latency: " + str(total_latency_ms) + " ms")
        ff.close()

        return total_latency_eb2, total_latency_ms

    def generate_stats_csv_baseline(self, eb_list: list, model_csv="", stats_csv="", verbose=False):
        self.get_hw_info()
        ff = open(stats_csv, "w")
        self.dnn_model.load_model_csv(model_csv)
        conv_params_array = self.dnn_model.calc_model_conv_params()
        layer_names = self.dnn_model.get_layer_names()
        total_latency = 0
        assert len(conv_params_array) == len(
            eb_list), "Make sure each layer has an essential bit number."
        for layer_idx in range(len(conv_params_array)):
            str_layer_name = layer_names[layer_idx]
            print("Starting schedule: " + str_layer_name)
            wr_line = str_layer_name + ', '
            layer_conv_params = conv_params_array[layer_idx]
            stats_latency, stats_schedule, stats_ratio, best_roof = self.get_layer_latency_baseline(
                layer_conv_params, eb_list[layer_idx], verbose)
            total_latency += stats_latency
            wr_line += str(stats_latency) + ', '
            wr_line += str(stats_schedule['k_size, k_tiles']) + ', '
            wr_line += str(stats_schedule['c_size, c_tiles']) + ', '
            wr_line += str(stats_schedule['o_size, o_tiles']) + ', '
            wr_line += str(stats_ratio) + ','
            wr_line += best_roof
            wr_line += "\n"
            ff.write(wr_line)

        total_latency_ms = total_latency * (1/self.frequency) * 1000
        ff.write("latency cycles: " + str(total_latency) + '\n')
        ff.write("latency: " + str(total_latency_ms) + " ms")
        ff.close()

        return total_latency, total_latency_ms

    def get_hw_info(self):
        print("lut buffer: ", self.lut_buf_depth)
        print("dsp buffer: ", self.dsp_buf_depth)
