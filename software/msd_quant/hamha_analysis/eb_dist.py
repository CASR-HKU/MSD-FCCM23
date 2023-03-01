import numpy as np
from torchvision.models.quantization import resnet18, resnet50, ResNet18_QuantizedWeights, ResNet50_QuantizedWeights
from eb_anal import layer_wise_bit_level, kernel_wise_bit_level
import matplotlib.pyplot as plt

# For resnet 18
# weights = ResNet18_QuantizedWeights.DEFAULT
# model = resnet18(weights=weights, quantize=True)

# For resnet 50
weights = ResNet50_QuantizedWeights.DEFAULT
model = resnet50(weights=weights, quantize=True)
model.eval()

# Select different layers here
# Names can be get in wgt_test_quant.ipynb
# wgt_arr = model.layer1[0].conv2.weight().int_repr().cpu().detach().numpy()

# plot

fig, ax1 = plt.subplots(figsize=[3.5, 3.5])

ax1.set_xlabel('Average EB', weight='bold', fontsize=8)
ax1.set_ylabel('Standard Deviation of EB', weight='bold', fontsize=8)

handles = []
# handle1, = ax1.plot(
#     conv1_essbit_mean,
#     conv1_essbit_std,
#     'o',
#     markersize=2.5,
#     color='mediumblue')

# Access all conv layers in the model
# NOTE: For kernel-wise, it needs further for-loop (loop output channel)
essbit_mean_arr = []
essbit_std_arr = []
for name, m in model.named_children():
    if "conv" in name:
        wgt_arr = m.weight().int_repr().cpu().detach().numpy()
        essbit_mean, essbit_std = kernel_wise_bit_level(wgt_arr)
        essbit_mean_arr.append(essbit_mean)
        essbit_std_arr.append(essbit_std)
    elif "layer" in name:
        for i in range(len(m)):
            for blk_name, n in m[i].named_children():
                if "conv" in blk_name:
                    seq_blk_name = name + '[' + str(i) + ']' + blk_name
                    wgt_arr = n.weight().int_repr().cpu().detach().numpy()
                    essbit_mean, essbit_std = kernel_wise_bit_level(
                        wgt_arr)
                    essbit_mean_arr.append(essbit_mean)
                    essbit_std_arr.append(essbit_std)


for id_point in range(len(essbit_mean_arr)):
    ebmean = essbit_mean_arr[id_point]
    ebstd = essbit_std_arr[id_point]
    handle, = ax1.plot(
        ebmean,
        ebstd,
        'o',
        markersize=3.5)
    handles.append(handle)

# For resnet 18
# ax1.set_ylim(bottom=1.0, top=1.5)
# ax1.set_xlim(left=1.6, right=2.6)

# For resnet 50
ax1.set_ylim(bottom=1, top=4)
ax1.set_xlim(left=2, right=7)

ax1.grid(linestyle='--', linewidth=0.5)

# labels = [handle.get_label() for handle in handles]
# ax1.legend(handles, labels, loc='upper center',
#            fontsize='xx-small', ncol=3, framealpha=0.5)

fig.tight_layout()

# plt.savefig('figs/layer_wise_eb_res50.pdf',
#             bbox_inches='tight', transparent=True)
# plt.savefig('figs/layer_wise_eb_res50.png')
plt.savefig('figs/kernel_wise_eb_res50.pdf',
            bbox_inches='tight', transparent=True)
plt.savefig('figs/kernel_wise_eb_res50.png')
