from turtle import color
import pandas as pd
import csv
import numpy as np
import matplotlib.pyplot as plt
# df = pd.read_csv(
#     r'/home/enai/Desktop/project/DAC2023/Unified_Quantization/Dybit_type/dybit_8b_mix_resnet50.csv')
# print(df)
# print(df["Latency"])

# w8_a8 = df["Latency"][0]
# print(w8_a8)

with open('/home/enai/Desktop/project/DAC2023/Unified_Quantization/Dybit_type/dybit_framework_linegraph.csv', 'r') as f:
    reader = csv.reader(f)
    all = []
    resnet18_speedup = []
    resnet18_acc = []
    resnet50_speedup = []
    resnet50_acc = []
    mb2_speedup = []
    mb2_acc = []

    s = []
    for row in reader:
        # print(row)

        for i in range(0, len(row)):
            x = np.array(row[i])
            s.append(x)

        # print(len(s))

    for i in range(0, 8):
        n = i*2+2
        x = s[n]
        print(x)
        x = np.array(x)
        resnet18_speedup.append(x)
    print(resnet18_speedup)

    for i in range(0, 8):
        n = i*2+3
        x = s[n]
        print(x)
        x = np.array(x)
        resnet18_acc.append(x)
    print(resnet18_acc)

    for i in range(0, 8):
        n = i*2+22
        x = s[n]
        print(x)
        x = np.array(x)
        resnet50_speedup.append(x)
    print(resnet50_speedup)

    for i in range(0, 8):
        n = i*2+23
        x = s[n]
        print(x)
        x = np.array(x)
        resnet50_acc.append(x)
    print(resnet50_acc)

    for i in range(0, 8):
        n = i*2+44
        x = s[n]
        print(x)
        x = np.array(x)
        mb2_speedup.append(x)
    print(mb2_speedup)

    for i in range(0, 8):
        n = i*2+45
        x = s[n]
        print(x)
        x = np.array(x)
        mb2_acc.append(x)
    print(mb2_acc)

    x = np.linspace(1, 4, 8)

    resnet18_acc = [69.66, 69.66, 69.58, 69.5, 69.47, 67.34, 66.87, 65.46]
    resnet50_acc = [75.5, 75.48, 76.02, 75.86, 75.47, 75.45, 75.04, 74.64]
    mob2_acc = [69.47, 68.22, 68.596, 68.15, 67, 66.87, 65.46, 65.46]

    plt.figure(num=2, figsize=(8, 6))

    plt.plot(x, resnet18_acc, color='red', label='ResNet18')
    plt.plot(x, resnet50_acc, color='blue', label='ResNet50')
    plt.plot(x, mob2_acc, color='green', label='MobileNetV2')

    plt.legend()

    plt.xlabel('Speedup')
    plt.ylabel('Top-1 Accuracy')
    plt.show()
