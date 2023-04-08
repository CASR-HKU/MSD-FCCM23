import os, warnings
import argparse
import pynq
import pickle
import numpy as np
from functools import reduce

import instr_gen_model
import acc_ctrl

model_sel = ["vgg16", "resnet18", "resnet50", "vitbase"]
# model dict: [layer number, GMACs]
model_dict = {"vgg16": [16, 15.5], "resnet18": [21, 1.82], "resnet50": [54, 4.12], "vitbase": [35, 16.52]}
hw_utl = [151.69, 2312] # [kLUT, DSP]

parser = argparse.ArgumentParser()
parser.add_argument("-m", "--model", type=str, default='resnet18')
dnn_model = parser.parse_args().model
model_csv = "zcu102_" + dnn_model + ".csv"

assert dnn_model in model_sel, "Not support this model in ZCU102!"

print("Start latency evaluation")
print("------------------------")
print("Device: ZCU102 (ZU9EG)")
print("DNN model: ", dnn_model)
print("Hardware frequency (MHz): ", 214)
print("------------------------")
print("Evaluation results")

for test_idx in range(10):
    # load bitstream
    overlay = pynq.Overlay('/home/xilinx/jupyter_notebooks/MSD_FCCM_2023/msd_hw_zcu102.bit')
    overlay.download()

    # set up the maximum size for layer shape
    act_in_shape = (224, 224, 64)
    weight_shape = (64, 128, 3, 3)
    act_out_shape = (224, 224, 128)

    act_in_array = pynq.allocate(shape=act_in_shape, dtype=np.uint8)
    weight_array = pynq.allocate(shape=weight_shape, dtype=np.uint8)
    act_out_array = pynq.allocate(shape=act_out_shape, dtype=np.uint8)

    act_in_base_addr = act_in_array.physical_address
    weight_base_addr = weight_array.physical_address
    act_out_base_addr = act_out_array.physical_address

    # hardware architecture
    hw_arch = [80, 48]
    layer_num = model_dict[dnn_model][0]
    GMACs = model_dict[dnn_model][1]
    instr_len = 4*layer_num

    # instructions
    instr_array = pynq.allocate(shape=(instr_len, 2), dtype=np.uint64)
    ig = instr_gen_model.InstrGen()
    ig.set_act_out_addr(act_out_array.physical_address)
    ig.set_weight_addr(weight_array.physical_address)
    ig.set_act_in_addr(act_in_array.physical_address)
    ig.gen_instr(hw_arch, model_csv, layer_num, instr_array)

    debug_array = pynq.allocate(shape=(80, 4), dtype=np.uint32)
    debug_array[:] = 1  # init data

    # control
    ac = acc_ctrl.AccCtrl(overlay, instr_array, debug_array, instr_len, 0)
    ac.core_scalar_3[:] = 0x000f  # s2mm_tkeep = core_scalar_3[15:0]

    ac.run(wait=False)

    # get data
    latency_ms = ac.report_latency(214)
    # OPs = MACs * 2
    throughput_gops = 1000/latency_ms * GMACs * 2
    eff_klut = throughput_gops/hw_utl[0]
    eff_dsp = throughput_gops/hw_utl[1]
    
    if latency_ms != 1:
        break
    
if (latency_ms == 1):
    print("Error! Time overflow!")
    print("------------------------")
    print("Evaluation Finished...")
    print('\n')
else:
    print("Latency(ms): %.2f" % latency_ms)
    print("Throughput(GOPS): %.2f" % throughput_gops)
    print("GOPS/kLUT: %.2f" % eff_klut)
    print("GOPS/DSP: %.2f" % eff_dsp)
    print("------------------------")
    print("------------------------")
    print("Evaluation Finished...")
    print('\n')