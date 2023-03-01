import matplotlib.pyplot as plt

# 8b factors based on fp32
factor = [1.457, 2.385, 2.508]

# Mobilenet-V2
mobilenet_v2_result = [[1.06, 69.47],
                       [1.09436588, 68.222],
                       [1.1389201, 68.596],
                       [1.16, 68.15],
                       [1.49309437, 67.15],
                       [1.62482205, 68.344],
                       [1.86452095, 61.1],
                       [2.06650702, 58.15]]

# ResNet18
resnet_18_result = [[1, 69.66],
                    [1.10075, 69.66],
                    [1.23282, 69.58],
                    [2.01836583, 69.47],
                    [2.097708, 67.34],
                    [3.005834, 66.87],
                    [3.3301906, 65.46],
                    [3.5122151, 65.41],
                    [3.642453, 61.45],
                    [3.78272665, 58.55]]

# ResNet50
resnet_50_result = [[1, 75.5],
                    [1.1615419, 75.48],
                    [1.40368, 76.206],
                    [1.694175, 76.02],
                    [1.809119, 75.86],
                    [2.2708031, 75.47],
                    [2.76942429, 75.45],
                    [2.78, 75.04],
                    [3.61554, 74.64],
                    [3.6318365, 72.53],
                    [3.7309538, 61.04]]

fig, ax1 = plt.subplots(figsize=[5.0, 2.4])

ax1.set_xlabel('Speedup', weight='bold', fontsize=10)
ax1.set_ylabel('Accuracy', weight='bold', fontsize=10)

spu = [result[0] for result in resnet_18_result]
handle1, = ax1.plot(
    [temp * factor[1] for temp in spu],
    [result[1] for result in resnet_18_result],
    label='ResNet18', color='mediumblue', linewidth=1.5,
    marker="o", mfc="white", ms=4)

spu = [result[0] for result in resnet_50_result]
handle2, = ax1.plot(
    [temp * factor[2] for temp in spu],
    [result[1] for result in resnet_50_result],
    label='ResNet50', color='darkgreen', linewidth=1.5,
    marker="o", mfc="white", ms=4)

spu = [result[0] for result in mobilenet_v2_result]
handle3, = ax1.plot(
    [temp * factor[0] for temp in spu],
    [result[1] for result in mobilenet_v2_result],
    label='mobilenet_v2', color='deeppink', linewidth=1.5,
    marker="o", mfc="white", ms=4)
ax1.set_ylim(bottom=55.00, top=82.00)
ax1.set_xlim(left=0.8, right=10.00)
ax1.grid(linestyle='--', linewidth=0.5)

handles = [handle1, handle2, handle3]
labels = [handle.get_label() for handle in handles]
ax1.legend(handles, labels, loc='upper center',
           fontsize='small', ncol=3, framealpha=0.5)

fig.tight_layout()

plt.savefig('acc_speed.pdf', bbox_inches='tight', transparent=True)
plt.savefig('acc_speed.png')
