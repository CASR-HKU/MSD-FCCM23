import numpy as np
import bitstring
from bitstring import BitArray


def bit_essential(bin_str):
    essential_num = 0
    for b in range(len(bin_str)):
        if bin_str[b] == '1':
            essential_num += 1
    return essential_num


def lsb_quant(bin_str, bit_num, expect_eb=3):
    EB = bit_num
    quant_bit_num = EB - expect_eb
    quant_bit = list(bin_str)
    length = len(bin_str) - 1
    one_index = []
    for b in range(len(bin_str)):
        if bin_str[length-b] == '1':
            one_index.append(length-b)

    for b in range(quant_bit_num):
        quant_index = one_index[b]
        quant_bit[quant_index] = '0'

    quant_bit = ''.join(quant_bit)
    return quant_bit


class Bin2Dec():
    def __init__(self):
        pass

    def bin2dec(self, a):
        a_reverse = self.reverse(a)  # 取反

        a_add_1 = self.add_1(a_reverse)  # 二进制加1
        a_int = -int(a_add_1, 2)
        return a_int

    def bin2dec_auto(self, a):
        if a[0] == '1':  # 如果首位是1，复数转换
            a_output = int(a, 2)
        else:
            a_output = int(a, 2)
        return a_output

    def add_1(self, binary_inpute):  # 二进制编码加1
        _, out = bin(int(binary_inpute, 2) + 1).split("b")
        return out

    def reverse(self, binary_inpute):  # 取反操作
        binary_out = list(binary_inpute)
        for epoch, i in enumerate(binary_out):
            if i == "0":
                binary_out[epoch] = "1"
            else:
                binary_out[epoch] = "0"
        return "".join(binary_out)


def bit_total(bin_str):
    total_num = 1  # sign
    for b in range(len(bin_str)):
        if bin_str[b] == '1' or bin_str[b] == '0':
            total_num += 1
    return total_num


def extract_bit_level(wgt_arr):
    assert len(wgt_arr.shape) == 4, "Wrong array!"
    weight_int8_arr = np.copy(wgt_arr)
    mean_essbit_arr = []
    std_essbit_arr = []
    for k in range(weight_int8_arr.shape[0]):
        for c in range(weight_int8_arr.shape[1]):
            kernel_sp_rate = 0.0
            kernel_essbit_arr = []
            for i in range(weight_int8_arr.shape[2]):
                for j in range(weight_int8_arr.shape[3]):
                    # print("real value",weight_int8_arr[k, c, i, j])
                    bin_str = np.binary_repr(weight_int8_arr[k, c, i, j])
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
    return np.array(mean_essbit_arr), np.array(std_essbit_arr)


def layer_wise_bit_level(wgt_arr):
    assert len(wgt_arr.shape) == 4, "Wrong array!"
    weight_int8_arr = np.copy(wgt_arr)
    mean_essbit = 0.0
    std_essbit = 0.0
    kernel_essbit_arr = []
    for k in range(weight_int8_arr.shape[0]):
        for c in range(weight_int8_arr.shape[1]):
            for i in range(weight_int8_arr.shape[2]):
                for j in range(weight_int8_arr.shape[3]):
                    # print("real value",weight_int8_arr[k, c, i, j])
                    bin_str = np.binary_repr(weight_int8_arr[k, c, i, j])
                    # print("binary",bin_str)
                    bit_num = bit_essential(bin_str)
                    # print("EB",bit_num)
                    # bit_all = bit_total(bin_str)
                    # print("Bitwidth",bit_all)
                    kernel_essbit_arr.append(bit_num)
    mean_essbit = np.mean(kernel_essbit_arr)
    std_essbit = np.std(kernel_essbit_arr)
    return np.array(mean_essbit), np.array(std_essbit)


def Quantize_bit_level(wgt_arr):
    assert len(wgt_arr.shape) == 4, "Wrong array!"
    weight_int8_arr = np.copy(wgt_arr)
    new_weight_int_arr = np.empty([weight_int8_arr.shape[0], weight_int8_arr.shape[1],
                                  weight_int8_arr.shape[2], weight_int8_arr.shape[3]], dtype=int)
    mean_essbit_arr = []
    std_essbit_arr = []
    for k in range(weight_int8_arr.shape[0]):
        for c in range(weight_int8_arr.shape[1]):
            kernel_sp_rate = 0.0
            kernel_essbit_arr = []
            for i in range(weight_int8_arr.shape[2]):
                for j in range(weight_int8_arr.shape[3]):
                    # print("real value",weight_int8_arr[k, c, i, j])
                    bin_str = np.binary_repr(weight_int8_arr[k, c, i, j])
                    # print("binary",bin_str)
                    bit_num = bit_essential(bin_str)
                    expect_eb = 4
                    # print("EB",bit_num)

                    if bit_num == 5:
                        quant_value = weight_int8_arr[k, c, i, j]
                        # print("orignal value",quant_value)
                        bin_str = np.binary_repr(quant_value)
                        # print("binary",bin_str)
                        bit_num = bit_essential(bin_str)
                        # print("EB",bit_num)
                        quant_bit = lsb_quant(bin_str, bit_num, expect_eb)
                        # print("quant bit", quant_bit)
                        quant_bit_num = bit_essential(quant_bit)
                        # print("Quant EB",quant_bit_num)
                        bin2dec = Bin2Dec()
                        a = bin2dec.bin2dec_auto(quant_bit)
                        # print(a)
                        weight_int8_arr[k, c, i, j] = a

                    if bit_num == 6:
                        quant_value = weight_int8_arr[k, c, i, j]
                        print("orignal value", quant_value)
                        bin_str = np.binary_repr(quant_value)
                        print("binary", bin_str)
                        bit_num = bit_essential(bin_str)
                        print("EB", bit_num)
                        quant_bit = lsb_quant(bin_str, bit_num, expect_eb)
                        print("quant bit", quant_bit)
                        quant_bit_num = bit_essential(quant_bit)
                        print("Quant EB", quant_bit_num)
                        bin2dec = Bin2Dec()
                        a = bin2dec.bin2dec_auto(quant_bit)
                        weight_int8_arr[k, c, i, j] = a

                    new_bin_str = np.binary_repr(weight_int8_arr[k, c, i, j])
                    print("binary", new_bin_str)
                    new_bit_num = bit_essential(new_bin_str)

                    print("new EB", new_bit_num)
                    if new_bit_num > expect_eb:
                        print(weight_int8_arr[k, c, i, j])
                    new_weight_int_arr[k, c, i,
                                       j] = weight_int8_arr[k, c, i, j]

                    # bit_all = bit_total(bin_str)
                    # print("Bitwidth",bit_all)
                    kernel_essbit_arr.append(bit_num)

    return new_weight_int_arr
