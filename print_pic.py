from cProfile import label
from collections import defaultdict

import numpy as np
from matplotlib import pyplot as plt, ticker

def get_cdf(data):
    x = sorted(data.keys())
    cdf = []
    for i in range(0, x[-1] + 1):
        cdf.append(data[i])
    return cdf

def calc_cdf(data):
    x = sorted(data.keys(), key=lambda x:data[x],reverse=True)
    y = [data[i] for i in x]
    y = np.cumsum(y / np.sum(y))
    return x, y


def pic1():

    f = open("grafana.txt","r",encoding="utf-16")
    lines = f.readlines()

    lar_poi = []
    sma_poi = []
    les_poi = []

    for line in lines[:-1]:
        tmp = line.strip().split()
        if float(tmp[-1]) >= 100.0:
            lar_poi.append((int(tmp[1]), float(tmp[-1])))
        elif float(tmp[-1]) >= 1.0:
            sma_poi.append((int(tmp[1]), float(tmp[-1])))

    plt.scatter([i[0] for i in sma_poi], [i[1] for i in sma_poi], s=55,linewidths=2, c='none',edgecolors="darkorange", label="layer size <10MB")
    plt.scatter([i[0] for i in lar_poi], [i[1] for i in lar_poi], s=55,linewidths=2, c='royalblue', marker="x", label="layer size >100MB")
    plt.legend(frameon=False,fontsize=17,markerscale=1.5)
    plt.xlabel('Number of layer shared', fontsize=20)
    plt.ylabel('Layer size (MB)', fontsize=20)
    plt.tick_params(labelsize=17)
    plt.tight_layout()
    plt.savefig("grafana_shared.svg")

f = open("pkg_count.txt", "r", encoding="utf-16")
lines = f.readlines()[:1000]

pkg_count = defaultdict(int)

for line in lines:
    tmp = line.strip().split()
    pkg_count[tmp[0]] = int(tmp[1])

x,y = calc_cdf(pkg_count)
x_ticks = x[:20]

fig = plt.figure(figsize=(9, 7))

left,bottom,width,height = 0.1,0.1,0.85,0.85
ax1 = fig.add_axes([left,bottom,width,height])
ax1.plot([i for i in range(len(x))], y, linewidth="4", color='royalblue', linestyle='dotted')
ax1.set_xlabel("Package",fontsize=15)
ax1.set_ylabel("Number of package installed",fontsize=15)
# ax1.set_yticklabels([0.0, 0.2, 0.4, 0.6, 0.8, 1.0],fontsize=12.5)
ax1.tick_params(labelsize=12.5)

left,bottom,width,height = 0.33,0.25,0.61,0.45
ax2 = fig.add_axes([left,bottom,width,height])
ax2.plot(x_ticks, y[:20], linewidth="4", color='royalblue', linestyle='dotted')
ax2.set_xticklabels(x_ticks,rotation=60,fontsize="small")
#plt.xticks(x_ticks)
plt.savefig("pkg_cnt.svg")
x_ticks = x[:20]


