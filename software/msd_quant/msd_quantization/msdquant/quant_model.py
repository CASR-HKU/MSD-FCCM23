import torch
import torch.nn as nn
import numpy as np
import copy
from quant_modules import TensorQuantizer, Conv2dQuantizer, LinearQuantizer
from multihead_attention import MultiheadAttentionQuantizer
from quant_utils import quant_args
import torch.distributed as dist

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


def convert_tensor(self, values):
        if 2 ** self.bit.item() > len(values):
            values.append(0.)
        assert(2 ** self.bit.item() == len(values))
        values = torch.tensor(values, device=self.quant_grid.device)
        values, _ = torch.sort(values)
        values = values.mul(10.0 / torch.max(values))
        # print(values.shape, values.data, end="--")
        return values

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


def quantize_model(model):
    """
    Recursively quantize a pretrained single-precision model to int8 quantized model
    model: pretrained single-precision model
    """
    # quantize layers
    if type(model) == nn.Conv2d:
        quant_mod = Conv2dQuantizer(**quant_args)
        quant_mod.set_param(model)
        return quant_mod
    elif type(model) == nn.Linear:
        quant_mod = LinearQuantizer(**quant_args)
        quant_mod.set_param(model)
        return quant_mod
    elif type(model) == nn.MultiheadAttention:
        quant_mod = MultiheadAttentionQuantizer(**quant_args)
        quant_mod.set_param(model)
        return quant_mod
    elif type(model) == nn.Sequential:
        mods = []
        for n, m in model.named_children():
            mods.append(quantize_model(m))
        return nn.Sequential(*mods)
    elif type(model) == nn.ModuleList:
        mods = []
        for n, m in model.named_children():
            mods.append(quantize_model(m))
        return nn.Sequential(*mods)
    elif isinstance(model, nn.Sequential):
        mods = []
        for n, m in model.named_children():
            mods.append(quantize_model(m))
        return nn.Sequential(*mods)
    else:
        # recursively use the quantized module to replace the single-precision module
        q_model = copy.deepcopy(model)
        for attr in dir(model):
            mod = getattr(model, attr)
            if isinstance(mod, nn.Module):
                setattr(q_model, attr, quantize_model(mod))
        return q_model

def set_first_last_layer(model):
    module_list_weight = []
    module_list_input = []
    for m in model.modules():
        if isinstance(m, TensorQuantizer) and m.is_input == False:
            module_list_weight += [m]
        if isinstance(m, TensorQuantizer) and m.is_input == True:
            module_list_input += [m]

# def set_8_bit_layer_l(model, layer_list):
#     if layer_list == "None":
#         return
#     layer_list = list(map(lambda x: int(x), layer_list.split(',')))
#     module_list = []

#     for m in model.modules():
#         if isinstance(m, TensorQuantizer):            
#             module_list += [m]
#             m.has_inited_quant_para.data = torch.zeros_like(m.has_inited_quant_para)  

#     if dist.get_rank() == 0:
#         print("------------- 8-bit Re-SET -------------")
#         print(len(layer_list))
#     assert len(layer_list) > 0

#     for i in range(int(len(module_list) / 2)):
#         if i in layer_list:
#             if dist.get_rank() == 0:
#                 print(module_list[i * 2].name, i )
#                 print(module_list[i * 2 + 1].name, i)
#             module_list[i*2].bit.data = torch.tensor(8, device=module_list[i*2].bit.device)
#             module_list[i*2+1].bit.data = torch.tensor(8, device=module_list[i*2+1].bit.device)

#     if dist.get_rank() == 0:
#         print("------------- 8-bit Re-SET -------------")

def set_8_bit_layer_l(model, layer_list):
    if layer_list == "None":
        return
    layer_list = list(map(lambda x: int(x), layer_list.split(',')))
    module_list = []

    for m in model.modules():
        if isinstance(m, TensorQuantizer):            
            module_list += [m]
            m.has_inited_quant_para.data = torch.zeros_like(m.has_inited_quant_para)  
            

    if dist.get_rank() == 0:
        print("------------- 8-bit EB2 Re-SET -------------")
        print(len(layer_list))
    assert len(layer_list) > 0

    for i in range(int(len(module_list) / 2)):
        if i in layer_list:
            if dist.get_rank() == 0:
                print(module_list[i * 2].name, i )
                print(module_list[i * 2 + 1].name, i)
            module_list[i*2].bit.data = torch.tensor(8, device=module_list[i*2].bit.device)
            module_list[i*2].eb = 'csd_eb2'
            # module_list[i*2].quant_grid.data = module_list[i*2].hamha_csd_value(expect_eb=3)
            # print(module_list[i*2].quant_grid.data)
            module_list[i*2+1].bit.data = torch.tensor(8, device=module_list[i*2+1].bit.device)

    if dist.get_rank() == 0:
        print("------------- 8-bit EB2 Re-SET -------------")


def set_4_bit_layer_l(model, layer_list):
    if layer_list == "None":
        return
    layer_list = list(map(lambda x: int(x), layer_list.split(',')))
    module_list = []

    for m in model.modules():
        if isinstance(m, TensorQuantizer):            
            module_list += [m]
            m.has_inited_quant_para.data = torch.zeros_like(m.has_inited_quant_para)  
            

    if dist.get_rank() == 0:
        print("------------- 8-bit EB1 Re-SET -------------")
        print(len(layer_list))
    assert len(layer_list) > 0

    for i in range(int(len(module_list) / 2)):
        if i in layer_list:
            if dist.get_rank() == 0:
                print(module_list[i * 2].name, i )
                print(module_list[i * 2 + 1].name, i)
            module_list[i*2].bit.data = torch.tensor(8, device=module_list[i*2].bit.device)
            module_list[i*2].eb = 'csd_eb1'
            # module_list[i*2].quant_grid.data = module_list[i*2].hamha_csd_value(expect_eb=3)
            # print(module_list[i*2].quant_grid.data)
            module_list[i*2+1].bit.data = torch.tensor(8, device=module_list[i*2+1].bit.device)

    if dist.get_rank() == 0:
        print("------------- 8-bit EB1 Re-SET -------------")

def set_8_bit_layer_n(model, l_num):
    #set l_num layers with 8-bit
    module_list = []
    mse_list    = []

    mse_linear_list = []
    linear_list = []
    mse = 0
    for m in model.modules():
        if isinstance(m, TensorQuantizer):            
            module_list += [m]
            mse_list    += [m.mse.item()]
            mse += m.mse.item()
            m.has_inited_quant_para.data = torch.zeros_like(m.has_inited_quant_para)  

    if dist.get_rank() == 0:
        print("------------- 8-bit Re-SET -------------")
        print(l_num)
    assert l_num > 0
    l_num *= 2

    first_num = 0 * 2
    for i in range(0, first_num):
        if dist.get_rank() == 0:
            print(module_list[i].name)
        module_list[i].bit.data = torch.tensor(8, device=module_list[i].bit.device)

    # For BERT last n layers.
    last_num = 2 * 2
    for i in range(len(mse_list) - last_num, len(mse_list)):
        if dist.get_rank() == 0:
            print(module_list[i].name)
        module_list[i].bit.data = torch.tensor(8, device=module_list[i].bit.device)

    if dist.get_rank() == 0:
        print("------------- First and Last end -------------")


    module_list = module_list[first_num: len(mse_list) - last_num]
    mse_list = mse_list[first_num: len(mse_list) - last_num]

    mse_list_pair = []
    for i in range(0, int(len(mse_list)/ 2)):
        mse_list_pair += [mse_list[i * 2] + mse_list[i * 2 + 1]]

    mses = np.array(mse_list_pair)
    mse_idx = np.argsort(-mses)
    l_num -= first_num
    l_num -= last_num
    l_num = int(l_num / 2)

    if l_num > 0:
        for i in mse_idx[0:l_num]:
            if dist.get_rank() == 0:
                print(module_list[i * 2].name, mses[i], i )
                print(module_list[i * 2 + 1].name, mses[i], i)
            module_list[i*2].bit.data = torch.tensor(8, device=module_list[i*2].bit.device)
            module_list[i*2+1].bit.data = torch.tensor(8, device=module_list[i*2+1].bit.device)

    if dist.get_rank() == 0:
        print("------------- 8-bit Re-SET -------------")

def load_ant_state_dict(model, checkpoint):
    for name, module in model.named_modules():
        if name + ".quant_grid" in checkpoint.keys():
            module.quant_grid.data = checkpoint[name + ".quant_grid"]
