import numpy as np
import math


class DNNModel(object):

    def __init__(self):
        self.model_arrays = []
        self.num_layers = 0
        self.model_load_flag = False

    def load_model_csv(self, modelfile=""):
        first = True
        f = open(modelfile, 'r')
        for row in f:
            row = row.strip()
            if first or row == '':
                first = False
            else:
                elems = row.split(',')[:-1]
                # depth-wise convolution
                if 'DP' in elems[0].strip():
                    for dp_layer in range(int(elems[5].strip())):
                        layer_name = elems[0].strip(
                        ) + "Channel_" + str(dp_layer)
                        elems[5] = str(1)
                        self.append_model_arrays(layer_name, elems)
                else:
                    layer_name = elems[0].strip()
                    self.append_model_arrays(layer_name, elems)

        self.num_layers = len(self.model_arrays)
        self.model_load_flag = True

    def append_model_arrays(self, layer_name, elems):
        entry = [layer_name]

        for i in range(1, len(elems)):
            val = int(str(elems[i]).strip())
            entry.append(val)
            if i == 7 and len(elems) < 9:
                # Add the same stride in the col direction automatically
                entry.append(val)

        # ISSUE #9 Fix
        assert entry[3] <= entry[1], 'Filter height cannot be larger than IFMAP height'
        assert entry[4] <= entry[2], 'Filter width cannot be larger than IFMAP width'

        self.model_arrays.append(entry)
        # print(entry)

    def calc_model_conv_params(self):
        layers_calculated_conv_params = []
        for array in self.model_arrays:
            ifmap_h = array[1]
            ifmap_w = array[2]
            filt_h = array[3]
            filt_w = array[4]
            num_ch = array[5]
            num_filt = array[6]
            stride_h = array[7]
            stride_w = array[8]
            ofmap_h = int(math.ceil((ifmap_h - filt_h + stride_h) / stride_h))
            ofmap_w = int(math.ceil((ifmap_w - filt_w + stride_w) / stride_w))
            # if need mac in the future
            # num_mac = ofmap_h * ofmap_w * filt_h * filt_w * num_ch * num_filt
            entry = [num_filt, ofmap_h, ofmap_w,
                     num_ch, filt_h, filt_w, stride_h]
            layers_calculated_conv_params.append(entry)
        return layers_calculated_conv_params

    def get_layer_names(self):
        layer_names = []
        for array in self.model_arrays:
            layername = array[0]
            layer_names.append(layername)
        return layer_names

    def get_model_arrays(self):
        return self.model_arrays
