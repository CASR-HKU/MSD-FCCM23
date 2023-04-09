import matplotlib.pyplot as plt
import numpy as np


def autolabel(rects):
    for rect in rects:
        height = rect.get_height()
        plt.text(rect.get_x()+rect.get_width()/2.-0.11, 1.04*height,
                 '%s' % float(height) + 'x', size=11, weight='bold')


# z2, 96, 102
models = ['XC7Z020', 'ZU3EG', 'ZU9EG']

theo_thr = [90.4, 180.0, 710.8]
theo_thr_dsp = [39.2, 64.8, 250.0]

theo_thr_norm = [2.31, 2.78, 2.84]
theo_thr_norm_dsp = [1, 1, 1]

width = 0.3
linewidth = 1
# fig, subfig = plt.subplots(1,2,figsize=(7,2))
fig, ax1 = plt.subplots(figsize=[6.0, 3.0])
X_axis = np.arange(len(models))
ax1.grid(axis="y", ls="-.", zorder=3)
b1 = ax1.bar(X_axis-0.15, theo_thr_norm, label='Heterogenous Arch.', color="#0257bf",
             width=width, linewidth=0, edgecolor='black', zorder=2)
autolabel(b1)
b2 = ax1.bar(X_axis+0.15, theo_thr_norm_dsp, label='DSP Only',
             color="lightgray", width=width, linewidth=0, edgecolor='black', zorder=2)
autolabel(b2)
ax1.set_ylim(0, 4)
# ax1.legend()
ax1.set_xticks(X_axis, models, weight='bold')
ax1.set_yticks([0, 1, 2, 3, 4])
ax1.set_ylabel("Normalized Peak Throughput", weight='bold')
# ax1.get_yaxis().set_visible(False)
# ax1.legend()
ax1.tick_params(axis="y", direction="in")

ax1.legend(loc='upper left', bbox_to_anchor=(
    0, 1), bbox_transform=ax1.transAxes, fontsize=9, prop=dict(weight='bold'))

ax1.spines['left'].set_visible(False)

ax1.spines['right'].set_visible(False)
fig.tight_layout()
plt.savefig('../../plots/theo_peak.png')
plt.savefig('../../plots/theo_peak.pdf', bbox_inches='tight', transparent=True)
