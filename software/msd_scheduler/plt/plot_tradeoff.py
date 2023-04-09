import numpy as np
import matplotlib.pyplot as plt


X = ['DSP-only', r'$\omega$'+'=1.7', r'$\omega$'+'=1.75', r'$\omega$' +
     '=2', r'$\omega$'+'=2.1', r'$\omega$'+'=2.2', r'$\omega$'+'=2.5']
speedup = [
    1.0,
    1.681470079,
    1.73761439,
    1.988074266,
    2.0586388,
    2.13651083,
    2.284971772]

acc = [
    73.36,
    73.358,
    73.334,
    73.35,
    72.59,
    72.462,
    72.186
]

width = 0.35
linewidth = 1
# fig, subfig = plt.subplots(1,2,figsize=(7,2))
fig, ax1 = plt.subplots(2, 1, figsize=[7, 5.7])
X_axis = np.arange(len(X))
ax1[0].grid(axis="y", ls="-.", zorder=3)
b1 = ax1[0].bar(X_axis, speedup, label='Speedup', color="#0257bf",
                width=width, linewidth=0, edgecolor='black', zorder=2)
ax1[0].set_ylim(0.5, 2.5)
# ax1.legend()
ax1[0].set_xticks(X_axis, X)
ax1[0].set_yticks([0.5, 1, 1.5, 2, 2.5])
ax1[0].set_ylabel("VGG16(Speedup)", weight='bold')
# ax1.get_yaxis().set_visible(False)
# ax1.legend()
ax1[0].tick_params(axis="y", direction="in")
ax2 = ax1[0].twinx()
ax2.set_ylabel("VGG16(Top-1 Acc)", weight='bold')
# ax2.bar(X_axis + width/2, acc, label = 'Acc', color="silver", width=width, linewidth=linewidth, edgecolor='black')
ax2.plot(acc, color="deepskyblue", marker='o', linestyle="--",
         linewidth=2, markersize=8, label='Acc')
ax2.tick_params(axis="y", direction="in")

ax2.set_ylim(72, 74)
ax2.set_yticks([72, 72.5, 73, 73.5, 74])
ax2.legend(loc='upper center', bbox_to_anchor=(
    0.3, 1), bbox_transform=ax1[0].transAxes)
ax1[0].legend(loc='upper left', bbox_to_anchor=(
    0, 1), bbox_transform=ax1[0].transAxes)


# ax1[0].spines['left'].set_visible(False)
# ax2.spines['left'].set_visible(False)
# ax1[0].spines['right'].set_visible(False)
# ax2.spines['right'].set_visible(False)


X1 = ['DSP-only', r'$\omega$'+'=2.35', r'$\omega$'+'=2.5', r'$\omega$' +
      '=2.6', r'$\omega$'+'=2.75', r'$\omega$'+'=3.1', r'$\omega$'+'=3.5']
speedup1 = [
    1.0,
    2.32696634122243,
    2.43346531278231,
    2.57860774,
    2.74286100350328,
    3.0889103,
    3.22633467673149]

acc1 = [
    75.92,
    76.114,
    76.088,
    76.074,
    76.026,
    74.346,
    73.568
]

width = 0.35
linewidth = 1

X_axis = np.arange(len(X1))
ax1[1].grid(axis="y", ls="-.", zorder=3)
b2 = ax1[1].bar(X_axis, speedup1, label='Speedup', color="darkgreen",
                width=width, linewidth=0, edgecolor='black', zorder=2)
ax1[1].set_ylim(0.5, 3.5)
# ax1.legend()
ax1[1].set_xticks(X_axis, X1)
ax1[1].set_yticks([0.5, 1, 2,  3])
ax1[1].set_ylabel("ResNet50(Speedup)", weight='bold')
# ax1.get_yaxis().set_visible(False)
# ax1.legend()
ax1[1].tick_params(axis="y", direction="in")
ax3 = ax1[1].twinx()
ax3.set_ylabel("ResNet50(Top-1 Acc)", weight='bold')
# ax2.bar(X_axis + width/2, acc, label = 'Acc', color="silver", width=width, linewidth=linewidth, edgecolor='black')
ax3.plot(acc1, color="springgreen", marker='o', linestyle="--",
         linewidth=2, markersize=8, label='Acc')
ax3.tick_params(axis="y", direction="in")

ax3.set_ylim(73.5, 77.0)
ax3.set_yticks([73.5, 74.0, 75.0, 76.0, 77.0])
# ax2.legend()
ax3.legend(loc='upper center', bbox_to_anchor=(
    0.3, 1), bbox_transform=ax1[1].transAxes)

ax1[1].legend(loc='upper left', bbox_to_anchor=(
    0, 1), bbox_transform=ax1[1].transAxes)


plt.savefig('../../plots/vgg16_Resnet50_acc_speedup_tradeoff.png')
plt.savefig('../../plots/vgg16_Resnet50_acc_speedup_tradeoff.pdf',
            bbox_inches='tight', transparent=True)
