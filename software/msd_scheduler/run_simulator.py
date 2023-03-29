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
result_file_str = "results/" + arch_str + '_' + model_str + ".csv"

hw_simulator = Simulator(arch_file_str)

eb_list_resnet18 = [2] * 21
eb_list_mobilenetv2 = [2] * 53
eb_list_vgg16 = [2] * 16
eb_list_vitbase = [2] * 5
eb_list_resnet50 = [2] * 54
# eb_list_mobilenetv2[31] = 2

eb_list_dict = {'resnet18': eb_list_resnet18,
                'mobilenetv2': eb_list_mobilenetv2,
                'vgg16': eb_list_vgg16,
                'vitbase': eb_list_vitbase,
                'resnet50': eb_list_resnet50}

if 'baseline' in arch_str:
    # print("baseline")
    total_latency, total_latency_ms = hw_simulator.generate_stats_csv_baseline([1]*54,
                                                                               model_file_str, result_file_str, False)
else:
    total_latency, total_latency_ms = hw_simulator.generate_stats_csv_opt(eb_list_dict[model_str],
                                                                          model_file_str, result_file_str, False)
# print("total latency cycle is: ", total_latency)
# print("total latency ms is: ", total_latency_ms)
