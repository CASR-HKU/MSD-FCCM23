import numpy as np


def bit_essential(bin_str):
    essential_num = 0
    for b in range(len(bin_str)):
        if bin_str[b] == '1':
            essential_num += 1
    return essential_num


def twoscomp_convert(input_num, bitwidth=8):
    assert (input_num < 2**(bitwidth-1)) and (input_num > -
                                              2**(bitwidth-1)-1), "invalid input number!"
    bin_str = np.binary_repr(input_num)
    if input_num < 0:
        bin_str = bin(-5 % (1 << bitwidth))[2:]
    return bin_str


def channel_wise_bit_level(wgt_arr):
    assert len(wgt_arr.shape) == 4, "Wrong array!"
    weight_int8_arr = np.copy(wgt_arr)
    mean_essbit_arr = []
    std_essbit_arr = []
    for k in range(weight_int8_arr.shape[0]):
        for c in range(weight_int8_arr.shape[1]):
            channel_essbit_arr = []
            for i in range(weight_int8_arr.shape[2]):
                for j in range(weight_int8_arr.shape[3]):
                    # print("real value",weight_int8_arr[k, c, i, j])
                    bin_str = np.binary_repr(weight_int8_arr[k, c, i, j])
                    # print("binary",bin_str)
                    bit_num = bit_essential(bin_str)
                    # print("EB",bit_num)
                    # bit_all = bit_total(bin_str)
                    # print("Bitwidth",bit_all)
                    channel_essbit_arr.append(bit_num)
            mean_ess = np.mean(channel_essbit_arr)
            std_ess = np.std(channel_essbit_arr)
            mean_essbit_arr.append(mean_ess)
            std_essbit_arr.append(std_ess)
    return np.array(mean_essbit_arr), np.array(std_essbit_arr)


def kernel_wise_bit_level(wgt_arr):
    assert len(wgt_arr.shape) == 4, "Wrong array!"
    weight_int8_arr = np.copy(wgt_arr)
    mean_essbit_arr = []
    std_essbit_arr = []
    for k in range(weight_int8_arr.shape[0]):
        kernel_essbit_arr = []
        for c in range(weight_int8_arr.shape[1]):
            for i in range(weight_int8_arr.shape[2]):
                for j in range(weight_int8_arr.shape[3]):
                    # print("real value",weight_int8_arr[k, c, i, j])
                    # bin_str = np.binary_repr(weight_int8_arr[k, c, i, j])
                    bin_str = twoscomp_convert(weight_int8_arr[k, c, i, j])
                    # print("binary",bin_str)
                    bit_num = bit_essential(bin_str)
                    # print("EB",bit_num)
                    # bit_all = bit_total(bin_str)
                    # print("Bitwidth",bit_all)
                    kernel_essbit_arr.append(bit_num)
        mean_ess = np.mean(kernel_essbit_arr)
        std_ess = np.std(kernel_essbit_arr)
        mean_essbit_arr.append(mean_ess)
        std_essbit_arr.append(std_ess)
    return mean_essbit_arr, std_essbit_arr


def layer_wise_bit_level(wgt_arr):
    assert len(wgt_arr.shape) == 4, "Wrong array!"
    weight_int8_arr = np.copy(wgt_arr)
    mean_essbit = 0.0
    std_essbit = 0.0
    essbit_arr = []
    for k in range(weight_int8_arr.shape[0]):
        for c in range(weight_int8_arr.shape[1]):
            for i in range(weight_int8_arr.shape[2]):
                for j in range(weight_int8_arr.shape[3]):
                    # print("real value",weight_int8_arr[k, c, i, j])
                    bin_str = twoscomp_convert(weight_int8_arr[k, c, i, j])
                    # print("binary",bin_str)
                    bit_num = bit_essential(bin_str)
                    # print("EB",bit_num)
                    # bit_all = bit_total(bin_str)
                    # print("Bitwidth",bit_all)
                    essbit_arr.append(bit_num)
    mean_essbit = np.mean(essbit_arr)
    std_essbit = np.std(essbit_arr)
    return mean_essbit, std_essbit
