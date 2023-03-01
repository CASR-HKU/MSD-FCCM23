from simulator import Simulator
import argparse
import logging

logging.basicConfig(level=logging.DEBUG,
                    filename='new.log',
                    filemode='a',
                    format='%(asctime)s - %(pathname)s[line:%(lineno)d] - %(levelname)s: %(message)s'
                    )

# In the future, need to generate hardware first
parser = argparse.ArgumentParser(description="simulator_config")
parser.add_argument(
    '--arch', '-a', help='hardware architecture init file', default='xc7z020')
parser.add_argument(
    '--model', '-m', help='dnn model', default='resnet18')
args = parser.parse_args()

arch_str = args.arch
arch_file_str = "archs/" + arch_str + "_8b_arch.ini"
model_str = args.model
model_file_str = "models/" + model_str + ".csv"
result_file_str = "aux_result/" + arch_str + '_' + model_str + ".csv"

hw_simulator = Simulator(arch_file_str)

eb_list_comb = [1, 2, 3]

total_latency, total_latency_ms = hw_simulator.generate_latency_eb_comb(eb_list_comb,
                                                                        model_file_str, result_file_str, False)
print("eb2 latency cycle is: ", total_latency)
print("eb2 latency ms is: ", total_latency_ms)
