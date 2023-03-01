import numpy as np
import matplotlib.pyplot as plt

  
X = ['int8', 'a=1','a=2','a=3','a=4','a=5', 'a=6']
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

fig, ax1 = plt.subplots()  
X_axis = np.arange(len(X))
  
ax1.bar(X_axis - 0.2, speedup, 0.4, label = 'Speedup', color='tomato',linewidth=1,)

  
plt.xticks(X_axis, X)
ax1.set_xlabel("Config")
ax1.set_ylabel("Speedup")
ax1.legend()

ax2 = ax1.twinx()
ax2.set_ylabel("Top-1 Acc")
ax2.bar(X_axis + 0.2, acc, 0.4, label = 'Acc', color='deepskyblue',linewidth=1,)
ax2.legend()
# plt.show()

plt.savefig('combined_results.png')
plt.savefig('combined_results.pdf', bbox_inches='tight', transparent=True)
