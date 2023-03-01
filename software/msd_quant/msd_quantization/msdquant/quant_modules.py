import logging
import torch
import torch.nn as nn
import torch.nn.functional as F
from torch import Tensor
import numpy as np
import quant_cuda
import torch.distributed as dist
from quant_affine import *

from binary_converter import float2bit, bit2float
from bisect import bisect_left

def quantize_csd(input_num, eb=2):
    twoslist = [1, 2, 4, 8, 16, 32, 64, 128]
    iter_num = input_num
    quant_num = 0
    for index in range(eb):
        base = findclosest(twoslist, iter_num)
        if index == 0:
            quant_num = base
            # print("the 1st quant num is ", quant_num)
            if base > iter_num:
                sign_flag = 0  # 0-minus
            else:
                sign_flag = 1  # 1-plus
            # print("sign flag =", sign_flag)
        else:
            if sign_flag == 0:
                quant_num = quant_num - base
            else:
                quant_num = quant_num + base
            # print("the quant num is ", quant_num)
            if base > iter_num:
                if old_sign_flag == 0:
                    sign_flag = 1
                else:
                    sign_flag = 0
            else:
                if old_sign_flag == 0:
                    sign_flag = 0
                else:
                    sign_flag = 1
            # print("sign flag =", sign_flag)
        old_sign_flag = sign_flag
        iter_num = abs(base - iter_num)
        # print("new iternum =", iter_num)
    return quant_num


def findclosest(myList, input_num):
    if (input_num > myList[-1] or input_num < myList[0]):
        return False
    pos = bisect_left(myList, input_num)
    if pos == 0:
        return myList[0]
    if pos == len(myList):
        return myList[-1]
    before = myList[pos - 1]
    after = myList[pos]
    if after - input_num < input_num - before:
        return after
    else:
        return before



class QuantBase():
    def _quantization(x, quant_grid):
        shape = x.shape
        quant_array = x.view(-1)
        quant_grid = quant_grid.type_as(quant_array)
        quant_array, _ = quant_cuda.quant(quant_array, quant_grid)
        quant_array = quant_array.view(shape)
        return quant_array

    @staticmethod
    def forward(real_val, quant_grid):
        with torch.no_grad():
         
            dequantized_val = QuantBase._quantization(real_val, quant_grid)
            
            return dequantized_val


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

def bit_essential(bin_str):
       essential_num = 0
       for b in range(len(bin_str)):
        if bin_str[b] == '1':
            essential_num += 1
       return essential_num

def lsb_quant(bin_str,bit_num,expect_eb=3):
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
    

def lsb_quant_0(value,bin_str,bit_num,expect_eb=3):
    EB = bit_num
    quant_bit_num = expect_eb - EB
    quant_bit = list(bin_str)

            
    if value < 0:
            length = len(bin_str) - 1
            one_index = []
            if length < expect_eb:
               for b in range(expect_eb-length):
                 quant_bit.append('1')
                 add_1 = expect_eb - length
            
               for b in range(len(quant_bit)):
                 if quant_bit[length-b] == '0':
                    one_index.append(length-b)
        
               for b in range(quant_bit_num-add_1):
                   quant_index = one_index[b]
                   quant_bit[quant_index] = '1'
            
            if length == expect_eb:
               for b in range(len(bin_str)):
                  if bin_str[b] == '0':
                     one_index.append(b)
           

               for b in range(quant_bit_num):
                  quant_index = one_index[b]
                  quant_bit[quant_index] = '1'
    
            if length > expect_eb:
                # print(bin_str)
                for b in range(len(bin_str)):
                  if bin_str[length-b] == '0':
                     one_index.append(length-b)


                for b in range(quant_bit_num):
                     quant_index = one_index[b]
                     
                     quant_bit[quant_index] = '1'  
                    #  print(quant_bit)
            
            
    if value >= 0:
            length = len(bin_str) 
            one_index = []
            if length < expect_eb:
               for b in range(expect_eb-length):
                 quant_bit.append('1')
                 add_1 = expect_eb - length
            
               for b in range(len(quant_bit)):
                 if quant_bit[length-b] == '0':
                    one_index.append(length-b)
        
               for b in range(quant_bit_num-add_1):
                   quant_index = one_index[b]
                   quant_bit[quant_index] = '1'
            
            if length == expect_eb:
               for b in range(len(bin_str)):
                  if bin_str[b] == '0':
                     one_index.append(b)
           

               for b in range(quant_bit_num):
                  quant_index = one_index[b]
                  quant_bit[quant_index] = '1'
    
            if length > expect_eb:

               for b in range(len(bin_str)):
                  if bin_str[length-b-1] == '0':
                     one_index.append(length-b-1)


               for b in range(quant_bit_num):
                     quant_index = one_index[b]
                     quant_bit[quant_index] = '1'
              
              
            #    print(quant_bit)
    quant_bit = ''.join(quant_bit)
    
    return quant_bit

def extract_bit_level(wgt_arr):
    assert len(wgt_arr.shape) == 4, "Wrong array!"
   

    weight_int8_arr = np.copy(wgt_arr.cpu())
    mean_essbit_arr = []
    std_essbit_arr = []
    for oc in range(weight_int8_arr.shape[0]):
        for ic in range(weight_int8_arr.shape[1]):
            kernel_sp_rate = 0.0
            kernel_essbit_arr = []
            for i in range(weight_int8_arr.shape[2]):
                for j in range(weight_int8_arr.shape[3]):
                    # print("real value",weight_int8_arr[oc, ic, i, j])
                    bin_str = np.binary_repr(weight_int8_arr[oc, ic, i, j])
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




class Quantizer(nn.Module):
    def __init__(self, mode="base", bit=8,eb="4", is_signed=True, is_enable=False, is_input=False, args=None, operator=None):
        super(Quantizer, self).__init__()
        self.mode = mode
        self.eb = eb
        self.is_input = is_input
        self.is_signed = is_signed
        self.is_enable = is_enable
        self.is_enable_activation = is_enable
        self.is_enable_weight = is_enable
        self.args = args
        self.operator = operator
        self.quant_count = 0
        self.scale_count = 0 
        
        

        self.alpha = nn.Parameter(torch.tensor(1.0, requires_grad=True))
        self.register_buffer('bit', torch.tensor(bit))
        self.register_buffer('has_inited_quant_para', torch.tensor(0.0))
        self.register_buffer('quant_grid', torch.ones(2**bit))
        
        self.w_up = self.args.w_up
        self.a_up = self.args.a_up
        self.w_low = self.args.w_low
        self.a_low = self.args.a_low

        self.percent = self.args.percent / 100
        self.is_perchannel = True
        # self.is_perchannel = False
        self.squant_k = True
        if is_input:
            # Input shouldn't be per-channel quantizaton！
            self.is_perchannel = False
        self.search = args.search
        self.mse = torch.tensor(0.0)

        ## debug
        self.name = None
        

    def disable_input_quantization(self):
        self.is_enable_activation = False
        
    def enable_quantization(self, name):
        self.name = name
        self.quant_layer = self.name
        self.is_enable = True

    def disable_quantization(self, name):
        self.name = name
        self.is_enable = False

    def update_signed(self, tensor):
        if tensor.min() < 0:
            self.is_signed = True

    def convert_tensor(self, values):
        if 2 ** self.bit.item() > len(values):
            values.append(0.)
        assert(2 ** self.bit.item() == len(values))
        values = torch.tensor(values, device=self.quant_grid.device)
        values, _ = torch.sort(values)
        values = values.mul(10.0 / torch.max(values))
        # print(values.shape, values.data, end="--")
        return values
    
    

    def apot_value(self):
        B = self.bit.item()
        if self.is_signed:
            B = B - 1
        base_a = [0.]
        base_b = [0.]
        base_c = [0.]
        if B == 2:
            for i in range(3):
                base_a.append(2 ** (-i - 1))
        elif B == 4:
            for i in range(3):
                base_a.append(2 ** (-2 * i - 1))
                base_b.append(2 ** (-2 * i - 2))
        elif B == 6:
            for i in range(3):
                base_a.append(2 ** (-3 * i - 1))
                base_b.append(2 ** (-3 * i - 2))
                base_c.append(2 ** (-3 * i - 3))
        elif B == 3:
            for i in range(3):
                if i < 2:
                    base_a.append(2 ** (-i - 1))
                else:
                    base_b.append(2 ** (-i - 1))
                    base_a.append(2 ** (-i - 2))
        elif B == 5:
            for i in range(3):
                if i < 2:
                    base_a.append(2 ** (-2 * i - 1))
                    base_b.append(2 ** (-2 * i - 2))
                else:
                    base_c.append(2 ** (-2 * i - 1))
                    base_a.append(2 ** (-2 * i - 2))
                    base_b.append(2 ** (-2 * i - 3))
        else:
            pass

        values = []
        for a in base_a:
            for b in base_b:
                for c in base_c:
                    values.append((a + b + c))
                    if self.is_signed:
                        values.append(-(a + b + c))
                    
        return self.convert_tensor(values)
    
    def float_value(self):
        B = self.bit.item()
        if self.is_signed:
            B = B - 1
        exp_bit = 3
        man_bit = B - 3
        if B == 2:
            exp_bit = 2
            man_bit = 0
        values = []
        min_to_zero = True
        for i in range(2 ** exp_bit):
            for j in range(2 ** man_bit):
                if min_to_zero:
                    values.append(0.)
                    min_to_zero = False
                else:
                    values.append(2 ** i * (1 + j * 2 ** (-man_bit)))
                    if self.is_signed:
                        values.append(- 2 ** i * (1 + j * 2 ** (-man_bit)))

        return self.convert_tensor(values)


    def float_value(self, eb = 3):
        B = self.bit.item()
        if self.is_signed:
            B = B - 1
        exp_bit = eb
        man_bit = B - exp_bit
        if B == 2:
            exp_bit = 2
            man_bit = 0
        values = []
        min_to_zero = True
        subnormal = True
        for i in range(2 ** exp_bit):
            for j in range(2 ** man_bit):
                if min_to_zero:
                    values.append(0.)
                    min_to_zero = False
                else:
                    if subnormal:
                        values.append((2 ** i) * (j * 2 ** (-man_bit)))
                    else:
                        values.append((2 ** (i - 1)) * (1 + j * 2 ** (-man_bit)))

                    if self.is_signed:
                        if subnormal:
                            values.append(-(2 ** i) * (j * 2 ** (-man_bit)))
                        else:
                            values.append(-(2 ** (i - 1)) * (1 + j * 2 ** (-man_bit)))
            subnormal = False

        return self.convert_tensor(values)

    def pot_value(self):
        B = self.bit.item()
        if self.is_signed:
            B = B - 1
        exp_bit = B
        values = []
        values.append(0.)
        for i in range(0, 2 ** exp_bit - 1):
            values.append(2 ** i)
            if self.is_signed:
                values.append(-2 ** i)

        return self.convert_tensor(values)


    def int_value(self, q_type="int",expect_eb=7):
        bit_width = self.bit.item()
        B = bit_width
        if self.is_signed:
            B = bit_width - 1

        values = []
        values.append(0.)
        for i in range(1, 2 ** B):
            bin_str = np.binary_repr(i)
            bit_num = bit_essential(bin_str)
            # print("EB",bit_num)
            # print("binary",bin_str)
            # expect_eb = int(self.eb)
            
            for s in range(expect_eb):
                        quant_value = i
                        # print("orignal value",quant_value)
                        bin_str = np.binary_repr(quant_value)
                        # print("binary",bin_str)
                        bit_num = bit_essential(bin_str)
                        # print("EB",bit_num)
                        quant_bit = lsb_quant_0(i,bin_str,bit_num,expect_eb)
                        # print("quant bit", quant_bit)
                        quant_bit_num = bit_essential(quant_bit)
                        # print("Quant EB",quant_bit_num)
                        bin2dec = Bin2Dec()
                        a = bin2dec.bin2dec_auto(quant_bit)
                        i = a 
            
            
            bin_str = np.binary_repr(i)
            bit_num = bit_essential(bin_str)
            for m in range(7-expect_eb):
                        quant_value = i
                        # print("orignal value",quant_value)
                        bin_str = np.binary_repr(quant_value)
                        # print("binary",bin_str)
                        bit_num = bit_essential(bin_str)
                        # print("EB",bit_num)
                        quant_bit = lsb_quant(bin_str,bit_num,expect_eb)
                        # print("quant bit", quant_bit)
                        quant_bit_num = bit_essential(quant_bit)
                        # print("Quant EB",quant_bit_num)
                        bin2dec = Bin2Dec()
                        a = bin2dec.bin2dec_auto(quant_bit)
                        i = a 
                        
            bin_str = np.binary_repr(i)
            bit_num = bit_essential(bin_str)            
            if bit_num != expect_eb and self.is_signed:
                          bin_str = np.binary_repr(i)
                          new_bit_num = bit_essential(bin_str)
                          print("binary",i)
                          print("new EB",new_bit_num)
                          
            values.append(i)
            if self.is_signed:
                values.append(-i)

        if q_type == "int":
            if self.is_signed:
                values.append(-2 ** B)
        # print("int values :", values)

        return self.convert_tensor(values)
    
    
    def hamha_csd_value(self, q_type="int",expect_eb=3):


           
        bit_width = self.bit.item()
        B = bit_width
        if self.is_signed:
            B = bit_width - 1

        values = []
        values.append(0.)
        for i in range(1, 2 ** B):
            bin_str = np.binary_repr(i)
            bit_num = bit_essential(bin_str)

            for s in range(expect_eb):
                        quant_value = i
                        # print("orignal value",quant_value)
                        quant_bit_num = quantize_csd(quant_value,expect_eb)
                        # print("csd quant",quant_bit_num)
                        i = quant_bit_num
            
            if bit_num != expect_eb and self.is_signed:
                        bin_str = np.binary_repr(i)
                        new_bit_num = bit_essential(bin_str)
                        #   print("binary",i)
                        #   print("new EB",new_bit_num)
                          
            values.append(i)
            if self.is_signed:
                values.append(-i)

        if q_type == "int":
              if self.is_signed:
                values.append(-2 ** B)
        # values = torch.sort(values)
        # print("int csd values :", values)

        return self.convert_tensor(values)
            
        
    
    
    def act_int_value(self, q_type="int",expect_eb=7):
        bit_width = self.bit.item()
        B = bit_width
        if self.is_signed:
            B = bit_width - 1

        values = []
        values.append(0.)
        for i in range(1, 2 ** B):

        
            
            
            bin_str = np.binary_repr(i)
            bit_num = bit_essential(bin_str)
            for m in range(7-expect_eb):
                        quant_value = i
                        # print("orignal value",quant_value)
                        bin_str = np.binary_repr(quant_value)
                        # print("binary",bin_str)
                        bit_num = bit_essential(bin_str)
                        # print("EB",bit_num)
                        quant_bit = lsb_quant(bin_str,bit_num,expect_eb)
                        # print("quant bit", quant_bit)
                        quant_bit_num = bit_essential(quant_bit)
                        # print("Quant EB",quant_bit_num)
                        bin2dec = Bin2Dec()
                        a = bin2dec.bin2dec_auto(quant_bit)
                        i = a 
                        
            bin_str = np.binary_repr(i)
            bit_num = bit_essential(bin_str)            
            if bit_num > expect_eb and self.is_signed:
                          bin_str = np.binary_repr(i)
                          new_bit_num = bit_essential(bin_str)
                          print("binary",i)
                          print("new EB",new_bit_num)
                          
            values.append(i)
            if self.is_signed:
                values.append(-i)

        if q_type == "int":
            if self.is_signed:
                values.append(-2 ** B)
        # print("int values :", values)

        return self.convert_tensor(values)
    
    
    def ori_int_value(self, q_type="int"):
        bit_width = self.bit.item()
        B = bit_width
        if self.is_signed:
            B = bit_width - 1

        values = []
        values.append(0.)
        for i in range(1, 2 ** B):
            values.append(i)
            if self.is_signed:
                values.append(-i)

        if q_type == "int":
            if self.is_signed:
                values.append(-2 ** B)
        # print("int values :", values)

        return self.convert_tensor(values)

    def flint_value(self,  exp_base = 0):
        ################## Flint Representation #################
        B = self.bit.item()
        if self.is_signed:
            B = B - 1
        value_bit = B
        assert(value_bit >= 2)

        exp_num =     value_bit * 2 - 1
        neg_exp_num = value_bit - 1
        pos_exp_num = value_bit - 1
       
        
        exp_max = pos_exp_num + exp_base
        exp_min = -neg_exp_num

        ## zero
        values = [0.]

        # values = [0.]
        ## exponent negtive
        for i in range(0, neg_exp_num + 1):
            exp_bit = i + 2
            exp_value = -(exp_bit - 1)
            mant_bit = value_bit - exp_bit
            for j in range(int(2 ** mant_bit)):
                v = 2 ** exp_value * (1 + 2 ** (-mant_bit) * j)
                values.append(v)
                if self.is_signed:
                    values.append(-v)

        ## exponent zero
        exp_bit = 2
        exp_value = 0
        mant_bit = value_bit - exp_bit
        for j in range(int(2 ** mant_bit)):
            v = 2 ** (exp_value + exp_base) * (1 + 2 ** (-mant_bit) * j)
            values.append(v)
            if self.is_signed:
                values.append(-v)
        ## exponent positive     
        for i in range(1, pos_exp_num):
            exp_bit = i + 2
            exp_value = i
            mant_bit = value_bit - exp_bit
            for j in range(int(2 ** mant_bit)):
                v = 2 ** (exp_value + exp_base) * (1 + 2 ** (-mant_bit) * j)
                values.append(v)
                if self.is_signed:
                    values.append(-v)
        ## max value
        values.append(2 ** exp_max)
        if self.is_signed:
            values.append(-2 ** exp_max)

        return self.convert_tensor(values)

    def mse_loss(self, quant_tensor, source_tensor, p=2.0, is_perchannel = True):
        if is_perchannel:
            mean_tensor =  (quant_tensor-source_tensor).abs().pow(p).view(quant_tensor.shape[0], -1).mean(-1).unsqueeze(1)
            return mean_tensor
        else:
            return (quant_tensor-source_tensor).abs().pow(p).mean()

    def search_mse(self, tensor):
        if self.is_perchannel and (not self.is_input):
            x_max, _ = tensor.view(tensor.shape[0], -1).abs().max(1)
            x_max = x_max.unsqueeze(1)            
            best_score = torch.ones_like(x_max) * 1e10
            
            alpha = x_max.clone()
            base_alpha = x_max.clone()
            lb = int(self.w_low)
            if self.bit > 6:
                lb = int(95)
            ub = int(self.w_up)
            for i in range(lb, ub):
                new_alpha = base_alpha * (i * 0.01)
                self.alpha.data = new_alpha
                quant_tensor = self._forward(tensor)

                score = self.mse_loss(quant_tensor, tensor)
                alpha[score < best_score] = new_alpha[score < best_score]
                best_score[score < best_score] = score[score < best_score]
        else:        
            x_max = tensor.abs().max()
            best_score = 1e10
            alpha = x_max.clone()
            base_alpha = alpha.clone()
            
            lb = int(self.a_low)
            if self.bit > 6:
                lb = int(95)
            ub = int(self.a_up)
            for i in range(lb, ub):
                new_alpha = base_alpha * (i * 0.01)
                self.alpha.data = new_alpha
                quant_tensor = self._forward(tensor)
                score = self.mse_loss(quant_tensor, tensor, p = 2, is_perchannel=False)
                if score < best_score:
                    best_score = score
                    alpha = new_alpha

        return best_score.sum(), alpha, (alpha / x_max).mean().item()

    def search_adaptive_numeric_type(self, data):
        modes = []
        mse_list = []
        mode = self.mode
        if "-int" in mode:
            self.mode = 'int'
            self.quant_grid.data = self.int_value()
            best_score_int, _, _ = self.search_mse(data)
            modes.append('int')
            mse_list.append(best_score_int.item())
            # if dist.get_rank() == 0:
            #     print("ANT search, INT   score: %f" %best_score_int)
        
        if "-flint" in mode:
            self.mode = 'flint'
            self.quant_grid.data = self.flint_value()
            best_score_flint, _, _ = self.search_mse(data)
            modes.append('flint')
            mse_list.append(best_score_flint.item())
            # if dist.get_rank() == 0:
            #     print("ANT search, Flint score: %f" %best_score_flint)
        
        if "-pot" in mode:
            self.mode = 'pot'
            self.quant_grid.data = self.pot_value()
            best_score_pot, _, _ = self.search_mse(data)
            modes.append('pot')
            mse_list.append(best_score_pot.item())
            # if dist.get_rank() == 0:
            #     print("ANT search, POT   score: %f" %best_score_pot)

        if "-float" in mode:
            self.mode = 'float'
            self.quant_grid.data = self.float_value()
            best_score_float, _, _ = self.search_mse(data)
            modes.append('float')
            mse_list.append(best_score_float.item())
            # if dist.get_rank() == 0:
            #     print("ANT search, FLOAT score: %f" %best_score_float)

        if "-float1" in mode:
            self.mode = 'float1'
            self.quant_grid.data = self.float_value(1)
            best_score_float, _, _ = self.search_mse(data)
            modes.append('float1')
            mse_list.append(best_score_float.item())
            # if dist.get_rank() == 0:
            #     print("ANT search, FLOAT 1 score: %f" %best_score_float)

        if "-float2" in mode:
            self.mode = 'float2'
            self.quant_grid.data = self.float_value(1)
            best_score_float, _, _ = self.search_mse(data)
            modes.append('float2')
            mse_list.append(best_score_float.item())
            # if dist.get_rank() == 0:
            #     print("ANT search, FLOAT 2 score: %f" %best_score_float)

        if "-float3" in mode:
            self.mode = 'float3'
            self.quant_grid.data = self.float_value(1)
            best_score_float, _, _ = self.search_mse(data)
            modes.append('float3')
            mse_list.append(best_score_float.item())
            # if dist.get_rank() == 0:
            #     print("ANT search, FLOAT 3 score: %f" %best_score_float)

        if "-float4" in mode:
            self.mode = 'float4'
            self.quant_grid.data = self.float_value(1)
            best_score_float, _, _ = self.search_mse(data)
            modes.append('float4')
            mse_list.append(best_score_float.item())
            # if dist.get_rank() == 0:
            #     print("ANT search, FLOAT 4 score: %f" %best_score_float)

        if "-apot" in mode:
            self.mode = 'apot'
            self.quant_grid.data = self.apot_value()
            best_score_apot, _, _ = self.search_mse(data)
            modes.append('apot')
            mse_list.append(best_score_apot.item())
            # if dist.get_rank() == 0:
            #     print("ANT search, APOT score: %f" %best_score_apot)

        mse_list = np.array(mse_list)
        mse_idx = np.argsort(mse_list)
        self.mode = modes[mse_idx[0]]



    def search_adaptive_effective_bit_kernel(self, data):
        ebs = []
        mse_list = []
        eb = self.eb
        # print(eb)
        if "-1" in eb:
            self.eb = "1"
            self.quant_grid.data = self.int_value(expect_eb=1)
            for k in range(data.shape[0]):
                    kernel_essbit_arr = []
                    for c in range(data.shape[1]):
                        for i in range(data.shape[2]):
                             for j in range(data.shape[3]):
                                 # print("real value",weight_int8_arr[k, c, i, j])
                                 bin_str = np.binary_repr(data[k, c, i, j])
                                 # print("binary",bin_str)
                                 bit_num = bit_essential(bin_str)
                                 # print("EB",bit_num)
                                 # bit_all = bit_total(bin_str)
                                 # print("Bitwidth",bit_all)
                                 kernel_essbit_arr.append(bit_num)

                    best_score_eb1, _, _ = self.search_mse(data)
                    ebs.append('eb1')
                    mse_list.append(best_score_eb1.item())
                    if dist.get_rank() == 0:
                       print("eb1 search, INT   core: %f" %best_score_eb1)
                
        if "-2" in eb:
            self.eb = "2"
            self.quant_grid.data = self.int_value(expect_eb=2)
            for k in range(data.shape[0]):
                    for c in range(data.shape[1]):
                        for i in range(data.shape[2]):
                             for j in range(data.shape[3]):
                                 bin_str = np.binary_repr(data[k, c, i, j])
                                 bit_num = bit_essential(bin_str)
                                 kernel_essbit_arr.append(bit_num)

                    best_score_eb2, _, _ = self.search_mse(data)
                    ebs.append('eb2')
                    mse_list.append(best_score_eb2.item())
                    if dist.get_rank() == 0:
                       print("eb2 search, INT   core: %f" %best_score_eb2)
        
        if "-3" in eb:
            self.eb = "3"
            self.quant_grid.data = self.int_value(expect_eb=3)
            for k in range(data.shape[0]):
                    for c in range(data.shape[1]):
                        for i in range(data.shape[2]):
                             for j in range(data.shape[3]):
                                 bin_str = np.binary_repr(data[k, c, i, j])
                                 bit_num = bit_essential(bin_str)
                                 kernel_essbit_arr.append(bit_num)

                    best_score_eb3, _, _ = self.search_mse(data)
                    ebs.append('eb3')
                    mse_list.append(best_score_eb3.item())
                    if dist.get_rank() == 0:
                       print("eb3 search, INT   core: %f" %best_score_eb3)
        
        if "-4" in eb:
            self.eb = "4"
            self.quant_grid.data = self.int_value(expect_eb=4)
            for k in range(data.shape[0]):
                    for c in range(data.shape[1]):
                        for i in range(data.shape[2]):
                             for j in range(data.shape[3]):
                                 bin_str = np.binary_repr(data[k, c, i, j])
                                 bit_num = bit_essential(bin_str)
                                 kernel_essbit_arr.append(bit_num)

                    best_score_eb4, _, _ = self.search_mse(data)
                    ebs.append('eb4')
                    mse_list.append(best_score_eb4.item())
                    if dist.get_rank() == 0:
                       print("eb4 search, INT   core: %f" %best_score_eb4)
        
        if "-5" in eb:
            self.eb = "5"
            self.quant_grid.data = self.int_value(expect_eb=5)
            for k in range(data.shape[0]):
                    for c in range(data.shape[1]):
                        for i in range(data.shape[2]):
                             for j in range(data.shape[3]):
                                 bin_str = np.binary_repr(data[k, c, i, j])
                                 bit_num = bit_essential(bin_str)
                                 kernel_essbit_arr.append(bit_num)

                    best_score_eb5, _, _ = self.search_mse(data)
                    ebs.append('eb5')
                    mse_list.append(best_score_eb5.item())
                    if dist.get_rank() == 0:
                       print("eb5 search, INT   core: %f" %best_score_eb5)
        
        
     
        #on-the-fly 
        mse_list = np.array(mse_list)
        mse_idx = np.argsort(mse_list)
        # print(mse_list)
        # print(mse_idx)
        
      
        mse_ratio0 = 2
        mse_ratio1 = 3
        mse_ratio2 = 6
        # quant bit > eb strategy
        # if mse_list[2] / mse_list[3] < mse_ratio0:
        #     self.eb = ebs[mse_idx[1]]
        #     if mse_list[1] / mse_list[2] < mse_ratio1:
        #         self.eb = ebs[mse_idx[2]]
        #         if mse_list[0] / mse_list[1] < mse_ratio2:
        #             self.eb = ebs[mse_idx[3]]
        # else:
        #     self.eb = ebs[mse_idx[0]]
        self.eb = ebs[mse_idx[0]]

    def search_adaptive_effective_bit(self, data):
        ebs = []
        mse_list = []
        eb = self.eb
        # print(eb)
        if "-1" in eb:
            self.eb = "1"
            self.quant_grid.data = self.int_value(expect_eb=1)
            best_score_eb1, _, _ = self.search_mse(data)
            ebs.append('eb1')
            mse_list.append(best_score_eb1.item())
            if dist.get_rank() == 0:
                print("eb1 search, INT   core: %f" %best_score_eb1)
                
        if "-2" in eb:
            self.eb = "2"
            self.quant_grid.data = self.int_value(expect_eb=2)
            best_score_eb2, _, _ = self.search_mse(data)
            ebs.append('eb2')
            mse_list.append(best_score_eb2.item())
            if dist.get_rank() == 0:
                print("eb2 search, INT   core: %f" %best_score_eb2)
        
        if "-3" in eb:
            self.eb = "3"
            self.quant_grid.data = self.int_value(expect_eb=3)
            best_score_eb3, _, _ = self.search_mse(data)
            ebs.append('eb3')
            mse_list.append(best_score_eb3.item())
            if dist.get_rank() == 0:
                print("eb3 search, INT   core: %f" %best_score_eb3)
        
        if "-4" in eb:
            self.eb = "4"
            self.quant_grid.data = self.int_value(expect_eb=4)
            best_score_eb4, _, _ = self.search_mse(data)
            ebs.append('eb4')
            mse_list.append(best_score_eb4.item())
            if dist.get_rank() == 0:
                print("eb4 search, INT   core: %f" %best_score_eb4)
        
        if "-5" in eb:
            self.eb = "5"
            self.quant_grid.data = self.int_value(expect_eb=5)
            best_score_eb5, _, _ = self.search_mse(data)
            ebs.append('eb5')
            mse_list.append(best_score_eb5.item())
            if dist.get_rank() == 0:
                print("eb5 search, INT   core: %f" %best_score_eb5)
        
        
     
        #on-the-fly 
        mse_list = np.array(mse_list)
        mse_idx = np.argsort(mse_list)
        # print(mse_list)
        # print(mse_idx)
        
      
        mse_ratio0 = 2
        mse_ratio1 = 3
        mse_ratio2 = 6
        # quant bit > eb strategy
        # if mse_list[2] / mse_list[3] < mse_ratio0:
        #     self.eb = ebs[mse_idx[1]]
        #     if mse_list[1] / mse_list[2] < mse_ratio1:
        #         self.eb = ebs[mse_idx[2]]
        #         if mse_list[0] / mse_list[1] < mse_ratio2:
        #             self.eb = ebs[mse_idx[3]]
        # else:
        #     self.eb = ebs[mse_idx[0]]
        self.eb = ebs[mse_idx[0]]

 
    def kernel_search_adaptive_effective_bit(self, data):
        ebs = []
        mse_list = []
        eb = self.eb
        # print(eb)
        
        # self.eb = "csd2"
        # self.quant_grid.data = self.hamha_csd_value(expect_eb=2)
        # best_score_csd_eb2, _, _ = self.search_mse(data)
        # ebs.append('csd_eb2')
        # mse_list.append(best_score_csd_eb2.item())
        # if dist.get_rank() == 0:
        #         print("csd_eb2 search, INT   core: %f" %best_score_csd_eb2)
                
        # self.eb = "csd3"
        # self.quant_grid.data = self.hamha_csd_value(expect_eb=3)
        # best_score_csd_eb3, _, _ = self.search_mse(data)
        # ebs.append('csd_eb3')
        # mse_list.append(best_score_csd_eb3.item())
        # if dist.get_rank() == 0:
        #         print("csd_eb3 search, INT   core: %f" %best_score_csd_eb3)
    
        self.eb = "1"
        self.quant_grid.data = self.int_value(expect_eb=1)
        best_score_eb1, _, _ = self.search_mse(data)
        ebs.append('eb1')
        mse_list.append(best_score_eb1.item())
        # if dist.get_rank() == 0:
        #         print("eb1 search, INT   core: %f" %best_score_eb1)
                
 
        # self.eb = "2"
        # self.quant_grid.data = self.int_value(expect_eb=2)
        # best_score_eb2, _, _ = self.search_mse(data)
        # ebs.append('eb2')
        # mse_list.append(best_score_eb2.item())
        # if dist.get_rank() == 0:
        #         print("lsb eb2 search, INT   core: %f" %best_score_eb2)
        

        # self.eb = "3"
        # self.quant_grid.data = self.int_value(expect_eb=3)
        # best_score_eb3, _, _ = self.search_mse(data)
        # ebs.append('eb3')
        # mse_list.append(best_score_eb3.item())
        # if dist.get_rank() == 0:
        #         print("lsb eb3 search, INT   core: %f" %best_score_eb3)
        
   
        # self.eb = "4"
        # self.quant_grid.data = self.int_value(expect_eb=4)
        # best_score_eb4, _, _ = self.search_mse(data)
        # ebs.append('eb4')
        # mse_list.append(best_score_eb4.item())
        # # if dist.get_rank() == 0:
        # #         print("eb4 search, INT   core: %f" %best_score_eb4)
        
    
        # self.eb = "5"
        # self.quant_grid.data = self.int_value(expect_eb=5)
        # best_score_eb5, _, _ = self.search_mse(data)
        # ebs.append('eb5')
        # mse_list.append(best_score_eb5.item())
        # # if dist.get_rank() == 0:
        # #         print("eb5 search, INT   core: %f" %best_score_eb5)

        # self.eb = "6"
        # self.quant_grid.data = self.int_value(expect_eb=6)
        # best_score_eb6, _, _ = self.search_mse(data)
        # ebs.append('eb6')
        # mse_list.append(best_score_eb5.item())
        # # if dist.get_rank() == 0:
        # #         print("eb6 search, INT   core: %f" %best_score_eb6)

        # self.eb = "7"
        # self.quant_grid.data = self.ori_int_value()
        # best_score_eb7, _, _ = self.search_mse(data)
        # ebs.append('eb7')
        # mse_list.append(best_score_eb7.item())
        # if dist.get_rank() == 0:
        #         print("eb7 search, INT   core: %f" %best_score_eb7)
        
        
     
        #on-the-fly 
        mse_list = np.array(mse_list)
        mse_idx = np.argsort(mse_list)
        # print(mse_list)
        # print(mse_idx)
        
      
        mse_ratio0 = 2
        mse_ratio1 = 3
        mse_ratio2 = 6
        # quant bit > eb strategy
        # if mse_list[2] / mse_list[3] < mse_ratio0:
        #     self.eb = ebs[mse_idx[1]]
        #     if mse_list[1] / mse_list[2] < mse_ratio1:
        #         self.eb = ebs[mse_idx[2]]
        #         if mse_list[0] / mse_list[1] < mse_ratio2:
        #             self.eb = ebs[mse_idx[3]]
        # else:
        #     self.eb = ebs[mse_idx[0]]
        self.eb = ebs[mse_idx[0]]

    def outlier_set(self, data):
        def reduce_ave_tensor(tensor):
            rt = tensor.clone()
            dist.all_reduce(rt, op=dist.ReduceOp.SUM)
            rt /= dist.get_world_size()
            return rt

        q = torch.tensor([self.percent], device = data.device)
        # self.percent_value_int4 = torch.quantile(data.abs().view(-1), q, dim=0)
        self.percent_value_int4 = torch.tensor(np.percentile(data.abs().cpu().numpy(),self.percent*100), device=data.device)
        self.percent_value_int16 = data.abs().max()

        self.percent_value_int4.data = reduce_ave_tensor(self.percent_value_int4.data)
        self.percent_value_int16.data = reduce_ave_tensor(self.percent_value_int16.data)

        if dist.get_rank() == 0: 
            print(self.name, self.percent_value_int4.item(), self.percent_value_int16.item())
        self.is_perchannel = False
        self.quant_grid.data = self.int_value()
        self.has_inited_quant_para.data = torch.ones_like(self.has_inited_quant_para)

    def outlier_quant(self, data):
        mask_int16 = data.abs() > self.percent_value_int4

        if self.percent_value_int4 > 0:
            scale = self.percent_value_int4 / torch.max(self.quant_grid)
            data_int4 = data / scale
            quant_data = QuantBase.forward(data_int4, self.quant_grid)
            tensor = quant_data.clone().detach()
            tensor =  tensor * scale
        else:
            tensor = data.clone().detach()

        if self.is_signed:
            level = 2**16 - 1
        else:
            level = 2**15 - 1
            
        if self.percent < 100:
            scale = (self.percent_value_int16 - self.percent_value_int4) / level
            data_int16 = data[mask_int16].abs()
            sign_int16 = data[mask_int16].sign()
            data_int16 = data_int16 - self.percent_value_int4
            quant_data = (data_int16 / scale).round() * scale
            quant_data = quant_data + self.percent_value_int4
            quant_data = quant_data * sign_int16
            tensor[mask_int16] = (quant_data - tensor[mask_int16]).detach() + tensor[mask_int16]

        return tensor


    def _init_quant_para(self, data, data_b):
        with torch.no_grad():     
                         
            if self.has_inited_quant_para == 0:
                self.update_signed(data)  
                # print("times:",data_b)   
                # conver_shape = data.view(data.shape[0], data.shape[1], -1).shape    
           

                if self.is_perchannel:
                    x_max = data.view(data.shape[0], -1).abs().max(1).values
                    # x_max = data.view(data.shape[1], -1).abs().max(1).values
                    self.alpha.data = x_max.unsqueeze(1)
                else:
                    self.alpha.data = data.abs().max()

                if self.mode == 'outlier':
                    return self.outlier_set(data)

                if self.bit > 6:
                    self.mode = 'int'
                else:
                    if "ant-" in self.mode:
                        self.search_adaptive_numeric_type(data)
                # if "sel-" in self.eb:
                
                # self.kernel_search_adaptive_effective_bit(data)
                
                
               
      
                    # print("real value",weight_int8_arr[k, c, i, j])
                           
                # self.kernel_search_adaptive_effective_bit(data)
                        # self.search_adaptive_effective_bit(data)
                
                # if self.mode == "flint":
                #     self.quant_grid.data = self.flint_value()
                    # _, self.alpha.data, alpha_ratio = self.search_mse(data)
                # elif self.mode == "int":
                # if self.eb == "2":
                #         self.quant_grid.data = self.int_value(expect_eb=2)
                # if self.eb == "3":
                #         self.quant_grid.data = self.int_value(expect_eb=3)
                # if self.eb == "4":
                #         self.quant_grid.data = self.int_value(expect_eb=4)
                # if self.eb == "5":
                #         self.quant_grid.data = self.int_value(expect_eb=5)
                # if self.eb == "7":
                #         self.quant_grid.data = self.int_value(expect_eb=7)
                if self.eb == "csd_eb1":
                        self.quant_grid.data = self.hamha_csd_value(expect_eb=1)
                if self.eb == "csd_eb2":
                        self.quant_grid.data = self.hamha_csd_value(expect_eb=2)
                if self.eb == "csd_eb3":
                        self.quant_grid.data = self.hamha_csd_value(expect_eb=3)
                if self.eb == "eb2":
                        self.quant_grid.data = self.int_value(expect_eb=2)
                if self.eb == "eb3":
                        self.quant_grid.data = self.int_value(expect_eb=3)
                if self.eb == "eb4":
                        self.quant_grid.data = self.int_value(expect_eb=4)
                if self.eb == "eb5":
                        self.quant_grid.data = self.int_value(expect_eb=5)
                if self.eb == "eb7":
                        self.quant_grid.data = self.ori_int_value()
                if self.eb == "abit-1":
                        # self.quant_grid.data = self.act_int_value(expect_eb=7)
                        self.quant_grid.data = self.ori_int_value()
                if self.is_input == True:
                        self.eb = "abit-1"
                        self.quant_grid.data = self.ori_int_value()
    
                print("Layer quant EB", self.eb)

                
                alpha_ratio = 1.0
                _, self.alpha.data, alpha_ratio = self.search_mse(data)



                def reduce_ave_tensor(tensor):
                    rt = tensor.clone()
                    dist.all_reduce(rt, op=dist.ReduceOp.SUM)
                    rt /= dist.get_world_size()
                    return rt

                quant_data = self._forward(data)
                kernel_scale = []
           




                self.mse = self.mse_loss(quant_data, data, 2, is_perchannel=self.is_perchannel).mean()
                dist.broadcast(self.mse, 0)
                if dist.get_rank() == 0:
                  print(self.mode, end="\t")
                  print("%d-bit \t %s," %(self.bit.item(), self.name))
                
                self.alpha.data = reduce_ave_tensor(self.alpha.data)
                kernel_scale.append(self.alpha.data)
                dist.broadcast(self.quant_grid, 0)
              
                
                # if self.is_signed == True and len(data_b.shape) == 4:
                #   if data_b[0][0][0][0].item() != 0.0:
                #      self.has_inited_quant_para.data = torch.ones_like(self.has_inited_quant_para)
                #      print("conv weight set init to",1)
                
                # if self.is_signed == False or self.is_input == True or len(data_b.shape) == 2:
                #      self.has_inited_quant_para.data = torch.ones_like(self.has_inited_quant_para)
                #      print("conv input / fc set init to",1)
                
              


                self.has_inited_quant_para.data = torch.ones_like(self.has_inited_quant_para)
                print("set init to",1)
                     
                # if self.is_input == False and len(data_b.shape) == 2:
                #   if data_b[0][0].item() != 0.0:
                #      self.has_inited_quant_para.data = torch.ones_like(self.has_inited_quant_para)
                 
                # # Ratio command
                # if self.is_input == True or len(data_b.shape) == 2:
                #      self.has_inited_quant_para.data = torch.ones_like(self.has_inited_quant_para)
                    
                
                return kernel_scale
          



    def _init_quant_para_int8(self, data, data_b):
        with torch.no_grad():     
                         
            if self.has_inited_quant_para == 0:
                self.update_signed(data)  

                if self.is_perchannel and len(data.shape) == 4:
                    # x_max = data.view(data.shape[0], -1).abs().max(1).values
                    x_max = data.view(data.shape[0], -1).abs().max(1).values
                    self.alpha.data = x_max.unsqueeze(1)
                else:
                    self.alpha.data = data.abs().max()

                if self.mode == 'outlier':
                    return self.outlier_set(data)

                if self.bit > 6:
                    self.mode = 'int'
                else:
                    if "ant-" in self.mode:
                        self.search_adaptive_numeric_type(data)

                self.quant_grid.data = self.ori_int_value()

                print("Kernel quant EB", 7)
                alpha_ratio = 1.0
                _, self.alpha.data, alpha_ratio = self.search_mse(data)
                kernel_scale = []
            


                def reduce_ave_tensor(tensor):
                    rt = tensor.clone()
                    dist.all_reduce(rt, op=dist.ReduceOp.SUM)
                    rt /= dist.get_world_size()
                    return rt

                quant_data = self._forward(data)
                self.mse = self.mse_loss(quant_data, data, 2, is_perchannel=self.is_perchannel).mean()
                dist.broadcast(self.mse, 0)
                if dist.get_rank() == 0:
                    print(self.mode, end="\t")
                    print("%d-bit \t %s," %(self.bit.item(), self.name))
                
                self.alpha.data = reduce_ave_tensor(self.alpha.data)
                kernel_scale.append(self.alpha.data)
                dist.broadcast(self.quant_grid, 0)
                
                if self.is_signed == True and len(data_b.shape) == 4:
                  if data_b[0][0][0][0].item() != 0.0:
                     self.has_inited_quant_para.data = torch.ones_like(self.has_inited_quant_para)
                     print("conv weight set init to",1)
                
                if self.is_signed == False or self.is_input == True or len(data_b.shape) == 2:
                     self.has_inited_quant_para.data = torch.ones_like(self.has_inited_quant_para)
                     print("conv input / fc set init to",1)
                     
                # if self.is_input == False and len(data_b.shape) == 2:
                #   if data_b[0][0].item() != 0.0:
                #      self.has_inited_quant_para.data = torch.ones_like(self.has_inited_quant_para)
                 
                
                # if self.is_input == True :
                #      self.has_inited_quant_para.data = torch.ones_like(self.has_inited_quant_para)
                    
                
                return kernel_scale
            
                


                # self.has_inited_quant_para.data = torch.ones_like(self.has_inited_quant_para)
                # print("set init to",1)
                
    def _init_quant_scale(self, data, data_b):
        with torch.no_grad():     
                         
            if self.has_inited_quant_para == 0:
                
                alpha_ratio = 1.0
                _, self.alpha.data, alpha_ratio = self.search_mse(data)



                def reduce_ave_tensor(tensor):
                    rt = tensor.clone()
                    dist.all_reduce(rt, op=dist.ReduceOp.SUM)
                    rt /= dist.get_world_size()
                    return rt

                quant_data = self._forward(data)
                kernel_scale = []
           




                self.mse = self.mse_loss(quant_data, data, 2, is_perchannel=self.is_perchannel).mean()
                dist.broadcast(self.mse, 0)
                if dist.get_rank() == 0:
                  print(self.mode, end="\t")
                  print("%d-bit \t %s," %(self.bit.item(), self.name))
                
                self.alpha.data = reduce_ave_tensor(self.alpha.data)
                kernel_scale.append(self.alpha.data)
                dist.broadcast(self.quant_grid, 0)
              
                
                if self.is_signed == True and len(data_b.shape) == 4:
                  if data_b[0][0][0][0].item() != 0.0:
                     self.has_inited_quant_para.data = torch.ones_like(self.has_inited_quant_para)
                     print("conv weight set init to",1)
                
                if self.is_signed == False or self.is_input == True or len(data_b.shape) == 2:
                     self.has_inited_quant_para.data = torch.ones_like(self.has_inited_quant_para)
                     print("conv input / fc set init to",1)
                
                return kernel_scale

             
                
   
    def _forward_kernel(self, data):
        scale = self.alpha / torch.max(self.quant_grid)
        # scale = scale / torch.max(self.quant_grid)
        # print("alpha:",scale.shape)
        # print("data:",data.shape)

        
        # if self.is_perchannel:
        data = (data.view(data.shape[0], -1) / scale).view(data.shape)
        # else:
        #     data = data / scale

        quant_data = QuantBase.forward(data, self.quant_grid)
        tensor = (quant_data - data).detach() + data



        # if self.is_perchannel:
        tensor =  (tensor.view(tensor.shape[0], -1) * scale).view(data.shape)
           
        # else:
        #     tensor =  tensor * scale

        return tensor  
    
    
            
    def _forward(self, data):
        # self.alpha.data = torch.ones([data.shape[0],1])
        scale = self.alpha / torch.max(self.quant_grid)
        # print("alpha:",scale.shape)
        # print("data:",data.shape)


        if self.is_perchannel:
            data = (data.view(data.shape[0], -1) / scale).view(data.shape)
            # data = (data.view(data.shape[1], -1) / scale).view(data.shape)
            # print("data shape 0 :",data.shape[0])
            # print("data shape 1 :",data.shape[1])
            # print("data shape  :",data.shape)


        else:
            data = data / scale

        quant_data = QuantBase.forward(data, self.quant_grid)
        tensor = (quant_data - data).detach() + data

        if self.is_perchannel:
            tensor =  (tensor.view(tensor.shape[0], -1) * scale).view(data.shape)
            # tensor =  (tensor.view(tensor.shape[1], -1) * scale).view(data.shape)
           
        else:
            tensor =  tensor * scale

        return tensor
    
    def tensor_forward(self, tensor, input_tensor = None):
        if self.mode == "base":
            return tensor
        if not self.is_enable:
            return tensor
        if self.is_input:
            if not self.is_enable_activation:
                return tensor
        else:
            if not self.is_enable_weight:
                return tensor
        
        # with torch.no_grad():
        #   if self.is_signed == True and len(tensor.shape) == 4:
        #     kernel_weight = torch.zeros([1,tensor.shape[1],tensor.shape[2],tensor.shape[3]])
        #     layer_weight = torch.zeros([tensor.shape[0],tensor.shape[1],tensor.shape[2],tensor.shape[3]])
        #     fake_weight = torch.zeros([tensor.shape[1],tensor.shape[1],tensor.shape[2],tensor.shape[3]])
        #     for k in range(tensor.shape[0]):
        #         kernel_weight[0, ...] = tensor[k, ...]
        #         kernel_weight = kernel_weight.to("cuda")
        #         if k == tensor.shape[0]-1:
        #            fake_weight[0][0][0][0] = torch.tensor(1.0)
        #         # self.kernel_search_adaptive_effective_bit(kernel_weight)
        #         self._init_quant_para(kernel_weight, fake_weight)
        #         layer_weight[k, ...] = kernel_weight
        #         layer_weight = layer_weight.to("cuda")
        #     q_tensor = self._forward(layer_weight)
        #   if self.is_signed == False or len(tensor.shape) == 2:
        #     # self.kernel_search_adaptive_effective_bit(tensor)
        #     self._init_quant_para(tensor, input_tensor)
        #     q_tensor = self._forward(tensor)

        #kernel-wise quant
        with torch.no_grad():
        #   if self.is_signed == True and len(tensor.shape) == 4:
        #     if self.has_inited_quant_para.data != 1. :
        #      kernel_weight = torch.zeros([1,tensor.shape[1],tensor.shape[2],tensor.shape[3]])
        #      layer_weight = torch.zeros([tensor.shape[0],tensor.shape[1],tensor.shape[2],tensor.shape[3]])
        #      fake_weight = torch.zeros([tensor.shape[0],tensor.shape[1],tensor.shape[2],tensor.shape[3]])
        #      ratio = 0.5
        #      eb_quant = torch.tensor(ratio * tensor.shape[0])
        #      eb_quant = torch.Tensor.int(torch.round(eb_quant))
        #      kernel_scale_array = torch.ones([tensor.shape[0],1])
 
        #      for k in range(tensor.shape[0]):
        #         kernel_weight[0, ...] = tensor[k, ...]
        #         kernel_weight = kernel_weight.to("cuda")
        #         if k < eb_quant-1:
        #             fake_weight[0][0][0][0] = torch.tensor(0.0)
        #         if k == eb_quant-1:
        #             fake_weight[0][0][0][0] = torch.tensor(1.0)
        #         if k <= eb_quant:
        #          kernel_scale = self._init_quant_para(kernel_weight, fake_weight)
        #         if k > eb_quant-1:
        #          fake_weight[0][0][0][0] = torch.tensor(0.0)
        #          if k == tensor.shape[0]-1:
        #            fake_weight[0][0][0][0] = torch.tensor(1.0)
        #          kernel_scale = self._init_quant_para_int8(kernel_weight, fake_weight)
        #         if kernel_scale != None:
        #         #    kernel_scale_array[k] = kernel_scale
        #         #    print("kernel scale - 1",kernel_scale)
        #            kernel_scale_array[k,...] = torch.tensor(kernel_scale) 
                
        #         layer_weight[k, ...] = kernel_weight
        #         layer_weight = layer_weight.to("cuda")
            
        #      kernel_scale_array = kernel_scale_array.to("cuda")
        #     # print("init scale ",kernel_scale_array)
        #     # print("before scale count",self.scale_count)
        #     # print("kernel scale",self.alpha.data)
        #     # if self.has_inited_quant_para.data == 1. and self.scale_count == 0:
        #      self.alpha.data = kernel_scale_array
        #      self.scale_count = 1
        #     #  print("init scale ",self.has_inited_quant_para.data)
        #     #  print("kernel scale",self.alpha.data)
            
        #      q_tensor = self._forward_kernel(layer_weight)
        #     if self.has_inited_quant_para.data == 1. :
        #         # print("kernel scale",self.alpha.data)
        #         # q_tensor = self._forward_kernel(tensor)
        #         q_tensor = self._forward(tensor)
   
        #   if self.is_signed == False or len(tensor.shape) == 2:
            kernel_scale = self._init_quant_para(tensor, input_tensor)
            # print("kernel scale - 1",self.alpha.data)
            q_tensor = self._forward(tensor)

        # Tranformer-kernel-wise
        #   if self.is_input == False and len(tensor.shape) == 2:
        #     kernel_weight = torch.zeros([1,tensor.shape[1]])
        #     layer_weight = torch.zeros([tensor.shape[0],tensor.shape[1]])
        #     fake_weight = torch.zeros([tensor.shape[0],tensor.shape[1]])
        #     for k in range(tensor.shape[0]):
        #         kernel_weight[0, ...] = tensor[k, ...]
        #         kernel_weight = kernel_weight.to("cuda")
        #         if k == tensor.shape[0]-1:
        #            fake_weight[0][0]= torch.tensor(1.0)
        #         self._init_quant_para(kernel_weight, fake_weight)
        #         layer_weight[k, ...] = kernel_weight
        #         layer_weight = layer_weight.to("cuda")
        #     q_tensor = self._forward(layer_weight)              
    
        #   else:
        #     self._init_quant_para(tensor, input_tensor)
        #     q_tensor = self._forward(tensor)
            # self._init_quant_para(tensor, input_tensor)
            # q_tensor = self._forward(tensor)
        # with torch.no_grad():
        #   if self.is_input == False and len(tensor.shape) == 2:
        #     if self.has_inited_quant_para.data != 1. :
        #      kernel_weight = torch.zeros([1,tensor.shape[1]])
        #      layer_weight = torch.zeros([tensor.shape[0],tensor.shape[1]])
        #      fake_weight = torch.zeros([tensor.shape[0],tensor.shape[1]])
        #      ratio = 1.0
        #      eb_quant = torch.tensor(ratio * tensor.shape[0])
        #      eb_quant = torch.Tensor.int(torch.round(eb_quant))
        #      kernel_scale_array = torch.ones([tensor.shape[0],1])
            
 
        #      for k in range(tensor.shape[0]):
        #         kernel_weight[0, ...] = tensor[k, ...]
        #         kernel_weight = kernel_weight.to("cuda")
        #         if k < eb_quant-1:
        #             fake_weight[0][0] = torch.tensor(0.0)
        #         if k == eb_quant-1:
        #             fake_weight[0][0] = torch.tensor(1.0)
        #         if k <= eb_quant:
        #          kernel_scale = self._init_quant_para(kernel_weight, fake_weight)
        #         if k > eb_quant-1:
        #          fake_weight[0][0] = torch.tensor(0.0)
        #          if k == tensor.shape[0]-1:
        #            fake_weight[0][0] = torch.tensor(1.0)
        #          kernel_scale = self._init_quant_para_int8(kernel_weight, fake_weight)
        #         if kernel_scale != None:
        #         #    kernel_scale_array[k] = kernel_scale
        #         #    print("kernel scale - 1",kernel_scale)
        #            kernel_scale_array[k,...] = torch.tensor(kernel_scale) 
                
        #         layer_weight[k, ...] = kernel_weight
        #         layer_weight = layer_weight.to("cuda")

        #      kernel_scale_array = kernel_scale_array.to("cuda")
        
        #      self.alpha.data = kernel_scale_array
        #      self.scale_count = 1
        #     #  print("init scale ",self.has_inited_quant_para.data)
        #     #  print("kernel scale",self.alpha.data)
            
        #      q_tensor = self._forward_kernel(layer_weight)
        #     if self.has_inited_quant_para.data == 1. :
        #         # print("kernel scale",self.alpha.data)
        #         q_tensor = self._forward_kernel(tensor)
        #   else:
        #     kernel_scale = self._init_quant_para(tensor, input_tensor)
        #     # print("kernel scale - 1",self.alpha.data)
        #     q_tensor = self._forward(tensor)
            
            
        return q_tensor    

class TensorQuantizer(Quantizer):
    def __init__(self, **kwargs):
        super(TensorQuantizer, self).__init__(**kwargs)

    def forward(self, tensor, input_tensor = None):
        return self.tensor_forward(tensor, input_tensor)

class Conv2dQuantizer(nn.Module):
    """
    Class to quantize given convolutional layer
    """
    def __init__(self, mode=None,eb=None, wbit=None, abit=None, args=None):
        super(Conv2dQuantizer, self).__init__()
        assert mode is not None,'Quantizer is not initilized!'
        self.quant_weight = TensorQuantizer(mode=mode, bit=wbit, eb=eb, is_signed=True, is_enable=True, args=args, operator=self._conv_forward)
        # self.quant_kernel_weight = TensorQuantizer(mode=mode, bit=wbit, eb=eb, is_signed=True, is_enable=True, args=args, operator=self._conv_forward)

        self.quant_input  = TensorQuantizer(mode=mode, bit=abit, eb="abit-1", is_signed=False, is_enable=True, args=args, operator=self._conv_forward, is_input=True)

    def set_param(self, conv):
        self.in_channels = conv.in_channels
        self.out_channels = conv.out_channels
        # self.quant_weight.alpha.data = torch.ones([1,1])
        
        self.quant_weight.alpha.data = torch.ones([self.out_channels,1])
        self.kernel_scale_array = torch.ones([self.out_channels,1])

        # self.quant_weight.alpha.data = torch.ones([self.in_channels,1])


        self.kernel_size = conv.kernel_size
        self.stride = conv.stride
        self.padding = conv.padding
        self.dilation = conv.dilation
        self.groups = conv.groups
        self.weight = nn.Parameter(conv.weight.data.clone())
        self.layer_weight = nn.Parameter(conv.weight.data.clone())
        try:
            self.bias = nn.Parameter(conv.bias.data.clone())
        except AttributeError:
            self.bias = None

    def _conv_forward(self, input, weight):
        return F.conv2d(input, weight, self.bias, self.stride,
                        self.padding, self.dilation, self.groups)

    def forward(self, input):

        # print("weight", self.weight.shape)
        kernel_weight = torch.zeros([1,self.weight.shape[1],self.weight.shape[2],self.weight.shape[3]])
        layer_weight = torch.zeros([self.weight.shape[0],self.weight.shape[1],self.weight.shape[2],self.weight.shape[3]])
        fake_weight = torch.zeros([self.weight.shape[1],self.weight.shape[1],self.weight.shape[2],self.weight.shape[3]])

        # for k in range(self.weight.shape[0]):
        #     for c in range(self.weight.shape[1]):
        #         for i in range(self.weight.shape[2]):
        #           for j in range(self.weight.shape[3]):
        #             # print("real value",weight_int8_arr[k, c, i, j])
        #             kernel_weight[0][c][i][j] = self.weight[k, c, i, j]
                    

        #     kernel_weight = kernel_weight.to("cuda")
        #     if k == self.weight.shape[0]-1:
        #          fake_weight[0][0][0][0] = torch.tensor(1.0)
        #         #  print("times", fake_weight[0][0][0][0].item())
        #      # print("kernel weight",kernel_weight.shape)
        #     fake_weight = fake_weight.to("cuda")
        #     kernel_weight_quant = self.quant_weight(kernel_weight, fake_weight)
        #     # print("quant kernel weight",kernel_weight_quant.shape)
        #     # print("quant kernel weight",kernel_weight_quant)
        #     layer_weight[k, ...] = kernel_weight_quant
  
        layer_weight = layer_weight.to("cuda")
        # with torch.no_grad():
        #   self.layer_weight = nn.Parameter(layer_weight)
        # print(layer_weight)
        weight = self.quant_weight(self.weight, input)
        # print(weight)
        input = self.quant_input(input, layer_weight)
        # print(input)
        # print("convolution", input.unique().numel(), self.quant_input.name)
        return self._conv_forward(input, weight)


class LinearQuantizer(nn.Module):
    """
    Class to quantize given linear layer
    """
    def __init__(self, mode=None,eb=None, wbit=None, abit=None, args=None):
        super(LinearQuantizer, self).__init__()
        assert mode is not None,'Quantizer is not initilized!'
        self.quant_weight = TensorQuantizer(mode=mode, bit=wbit,eb=eb, is_signed=True, is_enable=True, args=args, operator=F.linear)
        self.quant_input  = TensorQuantizer(mode=mode, bit=abit, eb="abit-1", is_signed=False, is_enable=True, args=args, operator=F.linear, is_input=True)


    def set_param(self, linear):
        self.in_features = linear.in_features
        self.out_features = linear.out_features
        self.quant_weight.alpha.data = torch.ones([self.out_features, 1])
        # self.quant_weight.alpha.data = torch.ones([self.in_features, 1])

        self.weight = nn.Parameter(linear.weight.data.clone())
        try:
            self.bias = nn.Parameter(linear.bias.data.clone())
        except AttributeError:
            self.bias = None

    def forward(self, input): 
        weight = self.quant_weight(self.weight, input) 
        input = self.quant_input(input, self.weight)
        # print(input.unique().numel(), self.quant_input.name)
        return F.linear(input, weight, self.bias)
        # kernel_weight = torch.zeros([1,self.weight.shape[1],self.weight.shape[2],self.weight.shape[3]])
        # layer_weight = torch.zeros([self.weight.shape[0],self.weight.shape[1],self.weight.shape[2],self.weight.shape[3]])

        # for k in range(self.weight.shape[0]):
        #     for c in range(self.weight.shape[1]):
        #         for i in range(self.weight.shape[2]):
        #           for j in range(self.weight.shape[3]):
        #             # print("real value",weight_int8_arr[k, c, i, j])
        #             kernel_weight[0][c][i][j] = self.weight[k, c, i, j]
                    

        #     kernel_weight = kernel_weight.to("cuda")
        #      # print("kernel weight",kernel_weight.shape)
        #     kernel_weight_quant = self.quant_weight(kernel_weight, input)
        #     # print("quant kernel weight",kernel_weight_quant.shape)
        #     # print("quant kernel weight",kernel_weight_quant)
        #     layer_weight[k, ...] = kernel_weight_quant
        # # wgt_arr = weight
        # # print("weight", weight.shape)
        # # self.has_inited_quant_para.data = torch.ones_like(self.has_inited_quant_para)

        # layer_weight = layer_weight.to("cuda")
        # input = self.quant_input(input, layer_weight)
        # # print("convolution", input.unique().numel(), self.quant_input.name)
        # return F.linear(input, layer_weight, self.bias)
