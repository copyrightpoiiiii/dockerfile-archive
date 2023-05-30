import json
import subprocess
import os
from collections import defaultdict

def is_json(testJson):
    try:
        json_object = json.loads(testJson)
    except ValueError as e:
        return False
    return True

manifest = defaultdict(list)
layer_cnt = defaultdict(int)
layer_size = defaultdict(int)
v = defaultdict(bool)

for item in os.listdir("\\\\wsl$\docker-desktop-data\\version-pack-data\community\docker\image\overlay2\layerdb\sha256") :
    f = open("\\\\wsl$\docker-desktop-data\\version-pack-data\community\docker\image\overlay2\layerdb\sha256\\"+item+"\\diff")
    diffid = f.readline()
    f.close()
    f = open("\\\\wsl$\docker-desktop-data\\version-pack-data\community\docker\image\overlay2\layerdb\sha256\\"+item+"\\size")
    size = f.readline()
    f.close()
    layer_size[diffid] = int(size)

output = subprocess.getoutput("docker images").split("\n")

sum = 0

for item in output:
    if item.split()[0] == 'grafana':
        out = subprocess.getoutput("docker inspect grafana:"+item.split()[1])
        jo = json.loads(out)
        manifest[item.split()[1]] = jo[0]["RootFS"]['Layers']
        if v[str(jo[0]["RootFS"]['Layers'])]:
            continue
        v[str(jo[0]["RootFS"]['Layers'])] = True
        for layer in jo[0]["RootFS"]['Layers']:
            if layer == "sha256:34d5ebaa5410d2ab4154bbd7c3c99c385ec509eb9c1d03d5486aff01bbd618c5":
                continue
            layer_cnt[layer] += 1
            sum += layer_size[layer]

tot = 0

for k in layer_cnt.keys():
    tot += layer_size[k]
layer_use = [k for k in layer_cnt.keys()]
layer_use = sorted(layer_use, key=lambda x:layer_cnt[x], reverse=True)
for item in layer_use:
    print(item, layer_cnt[item], layer_size[item]/1024/1024)
print(sum/1024/1024, tot/1024/1024)



