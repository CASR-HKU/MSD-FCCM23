from cgi import print_form
import pandas as pd
import csv
import numpy as np
import matplotlib.pyplot as plt


# with open('/home/jjc/hamha_quant/hamha_quant/hamha_analysis/csv/ultra96_resnet18.csv', 'r') as f:
#     reader = csv.reader(f)
#     all = []
#     w8_mse = []
#     a8_mse = []
#     w4_mse = []
#     a4_mse = []
#     w2_mse = []
#     a2_mse = []

#     mse_list = []
#     for row in reader:

#         x = np.array(row)

#         mse_list.append(x)

#     print(mse_list[2])

#     # w_2 mse
#     for i in range(0, 21):
#         n = i*6
#         x = float(mse_list[n])
#         x = np.array(x)
#         w2_mse.append(x)
#     print("2b weight mse :", w2_mse)
#     print("mse idx :", np.argsort(w2_mse))  # small error -> big error

#     # a_2 mse
#     for i in range(0, 21):
#         n = i*6+3
#         x = float(mse_list[n])
#         x = np.array(x)
#         a2_mse.append(x)
#     print("2b activation mse :", a2_mse)
#     print("mse idx :", np.argsort(a2_mse))  # small error -> big error

#     # w_4 mse
#     for i in range(0, 21):
#         n = i*6 + 1
#         x = float(mse_list[n])
#         x = np.array(x)
#         w4_mse.append(x)
#     # print("4b weight mse :", w4_mse)
#     print("4-bit mse idx :", np.argsort(w4_mse))  # small error -> big error

#     # a_4 mse
#     for i in range(0, 21):
#         n = i*6+4
#         x = float(mse_list[n])
#         x = np.array(x)
#         a4_mse.append(x)
#     # print("4b activation mse :", a4_mse)
#     print("4-bit mse idx :", np.argsort(a4_mse))  # small error -> big error

#     # w_8 mse
#     for i in range(0, 21):
#         n = i*6 + 2
#         x = float(mse_list[n])
#         x = np.array(x)
#         w8_mse.append(x)
#     # print("8b weight mse :", w8_mse)
#     print("8-bit mse idx :", np.argsort(w8_mse))  # small error -> big error

#     # a_8 mse
#     for i in range(0, 21):
#         n = i*6+5
#         x = float(mse_list[n])
#         x = np.array(x)
#         a8_mse.append(x)
#     # print("8b activation mse :", a8_mse)
#     print("8-bit mse idx :", np.argsort(a8_mse))  # small error -> big error

#     # total RMSE
#     total_wrmse2 = 0
#     total_armse2 = 0
#     total_wrmse4 = 0
#     total_armse4 = 0
#     total_wrmse8 = 0
#     total_armse8 = 0

#     for i in range(0, len(w8_mse)):
#         total_wrmse8 += float(w8_mse[i])
#     print(total_wrmse8)

#     # w_4 mse
#     wrmse4 = []
#     for i in range(0, 21):
#         n4 = i*6 + 1
#         n8 = i*6 + 2
#         x_4bit = float(mse_list[n4])
#         x_8bit = float(mse_list[n8])
#         x_4bit = np.array(x_4bit)

#         x_8bit = np.array(x_8bit)
#         # RMSE constrained
#         if x_8bit * 5 > x_4bit:
#             wrmse4.append(x_4bit)

#     # small error -> big error
#     # print("4b weight mse :", wrmse4)
#     # small error -> big error; 0 is the best to quantize
#     print(" 8 to 4-bit weight mse idx :", np.argsort(wrmse4))

#     # a_4 mse
#     armse4 = []
#     for i in range(0, 21):
#         n4 = i*6 + 4
#         n8 = i*6 + 5
#         x_4bit = float(mse_list[n4])
#         x_8bit = float(mse_list[n8])
#         x_4bit = np.array(x_4bit)
#         x_8bit = np.array(x_8bit)
#         # RMSE constrained (1-3)
#         if x_8bit * 3 > x_4bit:

#             armse4.append(x_4bit - x_8bit)

#     # small error -> big error
#     # print("4b activation mse :", armse4)
#     # small error -> big error; 0 is the best to quantize
#     print(" 8 to 4-bit activation mse idx :", np.argsort(armse4))

# second stage - latency
# first, we quantize the weight with the smallest error -> 8 to 4-bit [8_4_4/8]
# second, we quantize the activation with the smallest error -> 8 to 4-bit [4_4_4]
with open('/home/jjc/hamha_quant/hamha_quant/hamha_analysis/csv/ultra96_resnet50.csv', 'r') as f:
    reader = csv.reader(f)
    all = []
    latency_eb1 = []
    latency_eb2 = []
    latency_eb3 = []

    latency_number = []
    hamha_quantized_layer = []
    s = []
    for row in reader:
        # print(row)

        for i in range(1, len(row)):
            x = np.array(row[i])
            s.append(x)

        # print(s)

    length = len(s)/2

    # in_w_out : 8_8_8
    for i in range(0, 51):
        n = i*3
        x = s[n]
        x = np.array(x)
        latency_eb1.append(x)
        # print(s[n])

    # small latency -> big latency
    print("8-bit model EB1 latency idx :", np.argsort(latency_eb1))

    # in_w_out : 8_4_8
    for i in range(0, 51):
        n = i*3 + 1
        x = s[n]
        latency_eb2.append(x)
        # print(latency8_4_8)

    # in_w_out : 4_4_8
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



    # strategy: 8_8_8 -> 8_4_8  -> 8_4_4 -> 4_4_4 -> 4_2_4
    print('Baseline -> EB3 speed up :', baseline_latency/total_latency_eb3)
    print('Baseline -> EB2 speed up :', baseline_latency/total_latency_eb2)
    print('Baseline -> EB1 speed up :', baseline_latency/total_latency_eb1)

    # print('max :', max(total_latency_eb3))

    # Speed Up : 8_8_8 -> 8_4_8
    speed_up_exp = 4
    # speed_up = total_latency8_8_8/expect_latency

    if speed_up_exp < 5:
        renew_latency = latency_eb3
        for i in range(0, 50):
            new_total_latency = 0
            latency_idx = np.argsort(latency_eb3)
            # print('latency index:', latency_idx)
            # print('rmse_sort:', np.argsort(wrmse4))
            # re-sort
  
            # for latency_idx in range(0, latency_idx.shape[0]):
            #     n = latency_idx*6 + 1
            #     new_rank = float(mse_list[n])
            #     new_rank = np.array(new_rank)
            #     new_sort_k.append(new_rank)
            # print('new_sort_k:', np.argsort(new_sort_k))

            # print("4-bit mse idx :", np.argsort(w4_mse))
            quantize_layer = latency_idx[50-i]

            # quantize_layer = np.argsort(latency_idx)[i]
            print('quantize layer :', quantize_layer)
            renew_latency[quantize_layer] = latency_eb2[quantize_layer]

            print('update layer to EB2:', quantize_layer)

            for i in range(0, len(latency_eb3)):
                new_total_latency += float(renew_latency[i])
            latency_number.append(baseline_latency/new_total_latency)
            hamha_quantized_layer.append(quantize_layer)
            print('After eb2 weight-quantized cycles',
                  new_total_latency)
            speed_up = baseline_latency/new_total_latency
            print('After eb2 weight-quantized speed up',
                  speed_up)
            if(speed_up > speed_up_exp):
                break
        print('quantized layer to eb2 :', hamha_quantized_layer)

    # # Speed Up : eb2 -> eb1
        # renew_latency = latency_eb2

        # for i in range(0, len(renew_latency)):
        #     new_total_latency = 0
        #     latency_idx = np.argsort(renew_latency)
        #     print('sort index:', latency_idx)

        #     # quantize_layer = np.argsort(wrmse4)[i]
        #     quantize_layer = latency_idx[20-i]
        #     print('quantize layer :', quantize_layer)
        #     renew_latency[quantize_layer
        #                   ] = latency_eb1[quantize_layer]

        #     print('update layer to EB1:', quantize_layer)

        #     for i in range(0, len(latency_eb1)):
        #         new_total_latency += float(renew_latency[i])
        #     latency_number.append(baseline_latency/new_total_latency)
        #     hamha_quantized_layer.append(quantize_layer)

        #     print('After EB1 weight-quantized cycles',
        #           new_total_latency)
        #     speed_up = baseline_latency/new_total_latency
        #     print('After EB1 weight-quantized speed up',
        #           speed_up)
        #     if(speed_up > speed_up_exp):
        #         break
        # print('quantized layer to EB1 :', hamha_quantized_layer)
