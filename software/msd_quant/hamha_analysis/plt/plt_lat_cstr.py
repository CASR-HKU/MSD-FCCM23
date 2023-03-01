import matplotlib.pyplot as plt
import numpy as np

# 8b factors based on fp32
factor = [1.457, 2.385, 2.508]

# MobileNet-v2, ResNet18, ResNet50
models = ['MobileNet-v2', 'ResNet18', 'ResNet50']
spu_dim_top = [4.00, 12.00, 12.00]
acc_dim_bot = [63.00, 63.00, 66.00]
acc_dim_top = [75.00, 75.00, 78.00]
speedup = [[1.717, 1.608, 1.507, 1.182, 1.400, 1.604, 1.000],
           [2.993, 2.435, 1.985, 1.485, 2.385, 4.082, 1.000],
           [3.227, 2.984, 2.485, 1.998, 2.508, 4.259, 1.000]]
accuracy = [[0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00],
            [66.67, 67.00, 68.46, 69.49, 69.66, 69.40, 69.68],
            [74.99, 75.86, 75.75, 75.40, 75.95, 75.92, 76.04]]
x_labels = [['Dybit\n'+r'$\alpha$'+'=2', 'Dybit\n'+r'$\alpha$'+'=1.75', 'Dybit\n'+r'$\alpha$'+'=1.5',
            'Dybit\n'+r'$\alpha$'+'=1.25', 'Dybit\n'+r'$\alpha$'+'=1', 'Int8', 'FP32'],
            ['Dybit\n'+r'$\alpha$'+'=3', 'Dybit\n'+r'$\alpha$'+'=2.5', 'Dybit\n'+r'$\alpha$'+'=2',
            'Dybit\n'+r'$\alpha$'+'=1.5', 'Dybit\n'+r'$\alpha$'+'=1', 'Int8', 'FP32'],
            ['Dybit\n'+r'$\alpha$'+'=3.25', 'Dybit\n'+r'$\alpha$'+'=3', 'Dybit\n'+r'$\alpha$'+'=2.5',
            'Dybit\n'+r'$\alpha$'+'=2', 'Dybit\n'+r'$\alpha$'+'=1', 'Int8', 'FP32']]

# plt.rcParams['axes.labelsize'] = 16
# plt.rcParams['xtick.labelsize'] = 12
# plt.rcParams['ytick.labelsize'] = 14
# plt.rcParams['legend.fontsize'] = 12

fig, ax1 = plt.subplots(1, 3, figsize=[14.0, 2.4])

for i in range(3):
    # ax1.set_xscale('log')
    ax1[i].set_xlabel(models[i], weight='bold', fontsize=9)

    spu = [result for result in speedup[i]]
    height = [temp * factor[i] for temp in spu[:4]] + [spu[4], spu[5], spu[6]]
    x = np.arange(len(height))
    legend_p = {'weight': 'bold'}
    ax1[i].set_xticks(x)
    if i == 0:
        ax1[i].set_ylabel('Normalized Speedup', weight='bold', fontsize=10)

    if i == 0:
        y_major_locator = plt.MultipleLocator(1)
    else:
        y_major_locator = plt.MultipleLocator(3)

    ax1[i].yaxis.set_major_locator(y_major_locator)
    ax1[i].set_ylim(bottom=0.000, top=spu_dim_top[i])
    ax1[i].set_xticklabels(x_labels[i])
    ax1[i].grid(linestyle='--', linewidth=0.5, zorder=0)

    handle1 = ax1[i].bar(
        x=x-0.15,
        height=height,
        width=0.3,
        linewidth=1,
        edgecolor='black',
        label='Normalized Speedup',
        color='deepskyblue')

    ax2 = ax1[i].twinx()
    y_major_locator = plt.MultipleLocator(3)
    ax2.yaxis.set_major_locator(y_major_locator)
    ax2.set_ylim(bottom=acc_dim_bot[i], top=acc_dim_top[i])
    height = [result for result in accuracy[i]]
    if i == 2:
        ax2.set_ylabel('Accuracy %', weight='bold', fontsize=10)
    handle2 = ax2.bar(
        x=x+0.15,
        height=height,
        width=0.3,
        linewidth=1,
        edgecolor='black',
        label='Accuracy %',
        color='palegreen')

    handles = [handle1, handle2]
    labels = [handle.get_label() for handle in handles]
    ax2.legend(handles, labels, loc='upper center',
               fontsize='medium', ncol=2, framealpha=0.5)

# ax2.legend(handles, labels, loc='upper center', prop=legend_p)


fig.tight_layout()
plt.savefig('lat_cstr.png')
plt.savefig('lat_cstr.pdf', bbox_inches='tight', transparent=True)
