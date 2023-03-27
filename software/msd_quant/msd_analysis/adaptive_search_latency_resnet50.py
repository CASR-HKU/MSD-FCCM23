from cgi import print_form
import pandas as pd
import csv
import numpy as np
import matplotlib.pyplot as plt


# latency
# first, we quantize the weight with the smallest error -> EB3 to EB2
# second, we quantize the activation with the smallest error -> EB2 to EB1
with open('../MSD-FCCM23/software/msd_quant/msd_analysis/csv/ultra96_resnet50.csv', 'r') as f:
    reader = csv.reader(f)
    all = []
    latency_eb1 = []
    latency_eb2 = []
    latency_eb3 = []

    latency_number = []
    msd_quantized_layer = []
    s = []
    for row in reader:
        # print(row)

        for i in range(1, len(row)):
            x = np.array(row[i])
            s.append(x)

        # print(s)

    length = len(s)/2


    for i in range(0, 51):
        n = i*3
        x = s[n]
        x = np.array(x)
        latency_eb1.append(x)
        # print(s[n])

    # small latency -> big latency
    print("8-bit model EB1 latency idx :", np.argsort(latency_eb1))


    for i in range(0, 51):
        n = i*3 + 1
        x = s[n]
        latency_eb2.append(x)
        # print(latency8_4_8)


    for i in range(0, 51):
        n = i*3 + 2
        x = s[n]
        latency_eb3.append(x)
        # print(latency4_4_8)

    # total latency
    total_latency_eb1 = 0
    total_latency_eb2 = 0
    total_latency_eb3 = 0


    for i in range(0, len(latency_eb1)):
        total_latency_eb1 += float(latency_eb1[i])
    print(total_latency_eb1)

    for i in range(0, len(latency_eb2)):
        total_latency_eb2 += float(latency_eb2[i])
    print(total_latency_eb2)

    for i in range(0, len(latency_eb3)):
        total_latency_eb3 += float(latency_eb3[i])
    print(total_latency_eb3)

    baseline_latency = 12463618



    # strategy: EB3 -> EB2 -> EB1
    print('Baseline -> EB3 speed up :', baseline_latency/total_latency_eb3)
    print('Baseline -> EB2 speed up :', baseline_latency/total_latency_eb2)
    print('Baseline -> EB1 speed up :', baseline_latency/total_latency_eb1)



    speed_up_exp = 4


    if speed_up_exp < 5:
        renew_latency = latency_eb3
        for i in range(0, 50):
            new_total_latency = 0
            latency_idx = np.argsort(latency_eb3)

            quantize_layer = latency_idx[50-i]

            # quantize_layer = np.argsort(latency_idx)[i]
            print('quantize layer :', quantize_layer)
            renew_latency[quantize_layer] = latency_eb2[quantize_layer]

            print('update layer to EB2:', quantize_layer)

            for i in range(0, len(latency_eb3)):
                new_total_latency += float(renew_latency[i])
            latency_number.append(baseline_latency/new_total_latency)
            msd_quantized_layer.append(quantize_layer)
            print('After eb2 weight-quantized cycles',
                  new_total_latency)
            speed_up = baseline_latency/new_total_latency
            print('After eb2 weight-quantized speed up',
                  speed_up)
            if(speed_up > speed_up_exp):
                break
        print('quantized layer to eb2 :', msd_quantized_layer)

    # Speed Up : eb2 -> eb1
        renew_latency = latency_eb2

        for i in range(0, len(renew_latency)):
            new_total_latency = 0
            latency_idx = np.argsort(renew_latency)
            print('sort index:', latency_idx)

            # quantize_layer = np.argsort(wrmse4)[i]
            quantize_layer = latency_idx[20-i]
            print('quantize layer :', quantize_layer)
            renew_latency[quantize_layer
                          ] = latency_eb1[quantize_layer]

            print('update layer to EB1:', quantize_layer)

            for i in range(0, len(latency_eb1)):
                new_total_latency += float(renew_latency[i])
            latency_number.append(baseline_latency/new_total_latency)
            msd_quantized_layer.append(quantize_layer)

            print('After EB1 weight-quantized cycles',
                  new_total_latency)
            speed_up = baseline_latency/new_total_latency
            print('After EB1 weight-quantized speed up',
                  speed_up)
            if(speed_up > speed_up_exp):
                break
        print('quantized layer to EB1 :', msd_quantized_layer)
