import matplotlib.pyplot as plt
import numpy as np

# colors
color_spu = ['tomato', 'deepskyblue']
color_acc = ['bisque', 'palegreen']
# 8b factors based on fp32
factor = [1.457, 2.385, 2.508]

# VGG16 ResNet18, ResNet50
models = ['VGG-16', 'ResNet18', 'ResNet50']
spu_dim_top = [4.00, 12.00, 12.00]
acc_dim_bot = [40.00, 55.00, 66.00]
acc_dim_top = [80.00, 75.00, 78.00]
speedup_lat_cons = [[2.285, 2.137, 1.988, 1.737, 1.501, 1.000],
                    [2.993, 2.435, 1.985, 1.485, 4.082, 1.000],
                    [3.227, 2.984, 2.485, 1.998, 4.259, 1.000]]
accuracy_lat_cons = [[72.18, 72.46, 73.35, 73.33, 73.45, 73.36],
                     [66.67, 67.00, 68.46, 69.49, 69.40, 69.68],
                     [74.99, 75.86, 75.75, 75.40, 75.92, 76.04]]
x_labels_lat_cons = [['CSD\n'+r'$\alpha$'+'=2.5', 'CSD\n'+r'$\alpha$'+'=2.25', 'CSD\n'+r'$\alpha$'+'=2.0',
                      'CSD\n'+r'$\alpha$'+'=1.75', 'CSD\n'+r'$\alpha$'+'=1', 'Int8'],
                     ['CSD\n'+r'$\alpha$'+'=3', 'CSD\n'+r'$\alpha$'+'=2.5', 'CSD\n'+r'$\alpha$'+'=2',
                      'CSD\n'+r'$\alpha$'+'=1.5', 'CSD\n'+r'$\alpha$'+'=1', 'Int8'],
                     ['CSD\n'+r'$\alpha$'+'=3.25', 'CSD\n'+r'$\alpha$'+'=3', 'CSD\n'+r'$\alpha$'+'=2.5',
                      'CSD\n'+r'$\alpha$'+'=2', 'CSD\n'+r'$\alpha$'+'=1', 'Int8']]
speedup_rmse_cons = [[1.625, 1.493, 1.139, 1.094, 1.400, 1.000],
                     [2.389, 2.098, 1.233, 1.101, 2.385, 1.000],
                     [1.809, 1.694, 1.404, 1.162, 2.508, 1.000]]
accuracy_rmse_cons = [[65.40, 68.35, 68.60, 68.22, 68.53, 71.79],
                      [67.20, 67.34, 69.58, 69.66, 69.66, 69.68],
                      [75.86, 76.02, 76.21, 75.48, 75.86, 76.04]]
x_labels_rmse_cons = [['Dybit\n'+r'$\beta$'+'=2.5', 'Dybit\n'+r'$\beta$'+'=2', 'Dybit\n'+r'$\beta$'+'=1.5',
                       'Dybit\n'+r'$\beta$'+'=1.25', 'Dybit\n'+r'$\beta$'+'=1', 'Int8'],
                      ['Dybit\n'+r'$\beta$'+'=2.25', 'Dybit\n'+r'$\beta$'+'=2', 'Dybit\n'+r'$\beta$'+'=1.5',
                       'Dybit\n'+r'$\beta$'+'=1.25', 'Dybit\n'+r'$\beta$'+'=1', 'Int8'],
                      ['Dybit\n'+r'$\beta$'+'=2.5', 'Dybit\n'+r'$\beta$'+'=2', 'Dybit\n'+r'$\beta$'+'=1.5',
                       'Dybit\n'+r'$\beta$'+'=1.25', 'Dybit\n'+r'$\beta$'+'=1', 'Int8']]

speedup = [speedup_lat_cons, speedup_rmse_cons]
accuracy = [accuracy_lat_cons, accuracy_rmse_cons]
x_labels = [x_labels_lat_cons, x_labels_rmse_cons]

fig, ax1 = plt.subplots(2, 3, figsize=[14.0, 4.8])

for r in range(2):
    for i in range(3):
        # ax1.set_xscale('log')
        if r == 1:
            ax1[r, i].set_xlabel(models[i], weight='bold', fontsize=9)

        spu = [result for result in speedup[r][i]]
        # print(speedup[r][i])
        # print(spu)
        height = [temp * factor[i]
                  for temp in spu[:4]] + [spu[4], spu[5]]
        x = np.arange(len(height))
        legend_p = {'weight': 'bold'}
        ax1[r, i].set_xticks(x)
        if i == 0:
            ax1[r, i].set_ylabel('Normalized Speedup',
                                 weight='bold', fontsize=10)

        if i == 0:
            y_major_locator = plt.MultipleLocator(1)
        else:
            y_major_locator = plt.MultipleLocator(3)

        ax1[r, i].yaxis.set_major_locator(y_major_locator)
        ax1[r, i].set_ylim(bottom=0.000, top=spu_dim_top[i])
        ax1[r, i].set_xticklabels(x_labels[r][i])
        ax1[r, i].grid(linestyle='--', linewidth=0.5, zorder=0)

        handle1 = ax1[r][i].bar(
            x=x-0.15,
            height=height,
            width=0.3,
            linewidth=1,
            edgecolor='black',
            label='Normalized Speedup',
            color=color_spu[r])

        ax2 = ax1[r][i].twinx()
        if i == 0:
            y_major_locator = plt.MultipleLocator(10)
        elif i == 1:
            y_major_locator = plt.MultipleLocator(5)
        else:
            y_major_locator = plt.MultipleLocator(3)

        ax2.yaxis.set_major_locator(y_major_locator)
        ax2.set_ylim(bottom=acc_dim_bot[i], top=acc_dim_top[i])
        height = [result for result in accuracy[r][i]]
        if i == 2:
            ax2.set_ylabel('Accuracy %', weight='bold', fontsize=10)
        handle2 = ax2.bar(
            x=x+0.15,
            height=height,
            width=0.3,
            linewidth=1,
            edgecolor='black',
            label='Accuracy %',
            color=color_acc[r])

        handles = [handle1, handle2]
        labels = [handle.get_label() for handle in handles]
        ax2.legend(handles, labels, loc='upper center',
                   fontsize='medium', ncol=2, framealpha=0.5)

# ax2.legend(handles, labels, loc='upper center', prop=legend_p)


fig.tight_layout()
plt.savefig('combined_results.png')
plt.savefig('combined_results.pdf', bbox_inches='tight', transparent=True)
