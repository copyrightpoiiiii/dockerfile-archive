from collections import defaultdict
from itertools import count
import json
from logging import lastResort
import os
from turtle import color
from graphviz import Digraph
from matplotlib.patches import ArrowStyle
from matplotlib.pyplot import close
import numpy as np
import analysis_dockerfile
from matplotlib import pyplot as plt

edge = defaultdict(list)
incnt = defaultdict(int)

edgeVis = defaultdict(bool)

baseImgae = defaultdict(str)

count_shell = defaultdict(int)

count_cmd = defaultdict(int)

count_pkg = defaultdict(int)

count_download_pkg = defaultdict(int)

exec_form = 0

download_cmd = ['apt-get', 'apt',  'pip3', 'pip', 'apk', 'yum', 'yarn']

pull_cmd = ['curl', 'git', 'wget']

dependency_cmd = ['make', 'tar', 'cmake', 'update-alternatives', 'tar', 'unzip', 'gcc', 'rm', 'go', 'install']

setting_cmd = ['cd', 'set', 'chmod', 'useradd', 'adduser', 'groupadd']

def dfs(node,v,dep):
    if len(edge[node]) == 0:
        return file_count[node],(node,dep)
    v[node] = True
    cnt = 0
    image_list = ('',1000)
    for item in edge[node]:
        if item in v.keys():
            continue
        x,y = dfs(item,v,dep+1)
        cnt += x
        if y[1] < image_list[1]:
            image_list = y
    return cnt,image_list

def printSubGraph(node,v,dot):
    if len(edge[node]) == 0:
        dot.node(node.replace(':','#'),node.replace(':','#'), shape='egg',color='red')
        return 
    v[node] = True
    dot.node(node.replace(':','#'),'')
    for item in edge[node]:
        if item in v.keys():
            continue
        printSubGraph(item,v,dot)
        if edgeVis[(node.replace(':','#'),item.replace(':','#'))] == False:
            dot.edge(node.replace(':','#'),item.replace(':','#'))
            edgeVis[(node.replace(':','#'),item.replace(':','#'))] = True
    return 

def pushdown(node, v, baseimage):
    if len(edge[node]) == 0:
        baseImgae[node] = baseimage
        return 
    v[node] = True
    for item in edge[node]:
        if item in v.keys():
            continue
        pushdown(item, v, baseimage)

def printGraph(image_layer):
    vis = defaultdict(bool)
    edgevis = defaultdict(bool)

    dot = Digraph()

    for k,v in image_layer.items():
        last_layer = ''
        for layer in v:
            digest = layer['digest'].replace("sha256:","")
            if not vis[digest]:
                dot.node(digest,'')
                vis[digest] = True
            if last_layer != '' and not edgevis[(last_layer,digest)]:
                dot.edge(last_layer,digest)
                edgevis[(last_layer,digest)] = True
            last_layer = digest
        dot.node(k.replace(':','#'),k.replace(':','#'), shape='egg',color='red')
        dot.edge(last_layer,k.replace(':','#'),color='red')

    dot.render('test')

def parseDockerfile(f, bImage):
    global exec_form
    pos = 0
    lines = f.readlines()
    lines_no_comment = []
    arg_dic={}
    for line in lines:
        line = line.strip()
        if len(line) <= 0:
            continue
        if not line[0] == '#':
            lines_no_comment.append(line)

    while pos < len(lines_no_comment):
        line = lines_no_comment[pos]
        act = line.split(" ")[0].strip('\\').upper()
        if act == 'ARG':
            if '=' in line:
                tmp = line.replace('"',"").replace("'","")
                for k,v in arg_dic.items():
                    tmp=tmp.replace('${'+k+'}',v)
                    tmp=tmp.replace('$'+k,v)
                for item in tmp.split(' '):
                    if '=' in item:
                        arg_dic[item.split('=')[0]] = item.split('=')[1]
        elif act == 'FROM':
            pos += 1
            continue
        elif act == 'ENV':
             if '=' in line:
                tmp = line.replace('"',"").replace("'","")
                for k,v in arg_dic.items():
                    tmp=tmp.replace('${'+k+'}',v)
                    tmp=tmp.replace('$'+k,v)
                for item in tmp.split(' '):
                    if '=' in item:
                        arg_dic[item.split('=')[0]] = item.split('=')[1]
        elif act == 'RUN':
            tmp = ''
            while lines_no_comment[pos][-1] == '\\' or lines_no_comment[pos][-1] == '`':
                tmp += lines_no_comment[pos].strip()[:-2] + ' '
                pos += 1
            if lines_no_comment[pos].endswith("EOT"):
                tmp += lines_no_comment[pos].strip()[:-4] + ' '
                pos += 1
                while not lines_no_comment[pos].endswith("EOT"):
                    tmp += lines_no_comment[pos].strip() + ' '
                    pos += 1
                tmp += lines_no_comment[pos].strip()[:-4]
            else:
                tmp += lines_no_comment[pos].strip()
            for k,v in arg_dic.items():
                tmp=tmp.replace('${'+k+'}',v)
                tmp=tmp.replace('$'+k,v)
            tmp = tmp[3:].replace("sudo","").strip()
            count_cmd[tmp] += 1
            # if tmp[0] == '[':
            #     exec_form += 1
            # else:
            #     command_list = tmp.split("&&")
            #     for item in command_list:
            #         tmpcmd = item.strip()
            #         if len(tmpcmd) <= 0:
            #             continue
            #         split_word = tmpcmd.split()[0]
            #         count_cmd[(bImage, tmpcmd)] += 1
            #         count_shell[(bImage, split_word)] += 1
            #         if split_word in download_cmd:
            #             pkg_list = tmpcmd.split()
            #             if len(pkg_list)>1 and (pkg_list[1] != "update" and pkg_list[1] != "upgrade" and pkg_list[1] != "del" and pkg_list[1] != "purge" ):
            #                 count_download_pkg[tmpcmd] += 1
            #             for pkg in pkg_list[1:]:
            #                 if pkg == 'add' or pkg =='install' or pkg == 'del' or pkg == 'update' or pkg == 'upgrade' or pkg.startswith('-'):
            #                     continue
            #                 count_pkg[(bImage, pkg)] += 1
                    
        pos += 1



f = open('test.txt', 'r', encoding="utf-8")
lines = f.readlines()
f.close()

image_layer = {}
image_config = {}
image_manifest = {}

file_count = defaultdict(int)

for line in lines:
    image = eval(line)[0]
    if image == 'archlinux/base:latest':
        image = 'archlinux:base'
    image = image.replace('nvcr.io//','').replace('nvcr.io//','').replace('registry.k8s.io//build-image//','').replace('gcr.io//','').replace('ghcr.io//','').replace('registry.k8s.io//','')
    file_count[image] = int(eval(line)[1])
    dirname = image.replace(':','#')
    if not os.path.exists('manifest//' + dirname + '//manifest.json'):
        continue
    f = open('manifest//' + dirname + '//manifest.json', "r")
    line = f.readline()
    f.close()
    json_file = json.loads(line.replace("'",'"'))
    if type(json_file) == type({}):
        arch = json_file['Descriptor']['platform']['architecture']
        osy = json_file['Descriptor']['platform']['os']
        if arch == 'amd64' and osy == 'linux':
            image_manifest[image] = json_file['Descriptor']['digest']
            image_config[image] = json_file['SchemaV2Manifest']['config']
            image_layer[image] = json_file['SchemaV2Manifest']['layers']
    else:
        for item in json_file:
            arch = item['Descriptor']['platform']['architecture']
            osy = item['Descriptor']['platform']['os']
            if arch == 'amd64' and osy == 'linux':
                image_manifest[image] = item['Descriptor']['digest']
                image_config[image] = item['SchemaV2Manifest']['config']
                image_layer[image] = item['SchemaV2Manifest']['layers']

for k,v in image_layer.items():
    last_layer = ''
    for layer in v:
        digest = layer['digest'].replace("sha256:","")
        if last_layer != '':
            edge[last_layer].append(digest)
            incnt[digest] += 1
        last_layer = digest
    edge[last_layer].append(k)
    edge[k] = []
    incnt[k] += 1

ans = {}

# dot = Digraph()
#dot.attr(rankdir='LR')

top35_base = []

for k in edge.keys():
    if incnt[k] == 0:
        v = {}
        cnt,image_list = dfs(k,v,0)
        ans[image_list[0]] = cnt
        if cnt > 10:
            v = {}
            top35_base.append(image_list[0])
            pushdown(k, v, image_list[0])

dir_list = os.listdir("dockerfile")

for item in dir_list:
    uri = "dockerfile/" + item + "/"
    file_list = os.listdir(uri)
    for file in file_list:
        if item + "/" + file in analysis_dockerfile.error_file:
            continue
        f = open(uri+file,encoding='utf-8')
        bimgae = analysis_dockerfile.analysis_baseimage(f)
        f,close()
        if '$' in bimgae:
            if item in analysis_dockerfile.replace_dic.keys():
                bimgae = bimgae.replace(analysis_dockerfile.replace_dic[item][0],analysis_dockerfile.replace_dic[item][1])
        bimgae = bimgae.replace('"','').replace('nvcr.io//','').replace('nvcr.io//','').replace('registry.k8s.io//build-image//','').replace('gcr.io//','').replace('ghcr.io//','').replace('registry.k8s.io//','')
        if bimgae == 'scratch':
            continue
        if baseImgae[bimgae] != '':
            f = open(uri+file,encoding='utf-8')
            parseDockerfile(f, baseImgae[bimgae])
            f.close()

cmd_dir = defaultdict(list)

# download_count = defaultdict(int)

# dependency_count = defaultdict(int)

# else_count = defaultdict(int)

x = sorted(count_cmd.keys(), key=lambda x:count_cmd[x], reverse=True)

f = open("count_cmd.out","w")
for v in x:
    print(v,count_cmd[v], file=f)

# count_dict = defaultdict(int)
# for v in count_cmd.values():
#     count_dict[v-1] += 1

# x = sorted(count_dict.keys())
# y = [count_dict[i] for i in x]
# y = np.cumsum(y / np.sum(y))

# plt.plot(x,y,color='royalblue',linewidth=3)
# #plt.text(x[1],y[1],"  90% layers are shared less than once")
# plt.annotate(text="90% layers are shared less than once",xy=(x[1],y[1]),xytext=(3.5,y[1]+0.05),color='r',arrowprops=dict(arrowstyle='->',color='r'))
# #plt.vlines([1],0,1,colors="black", linestyles="dotted", linewidth=1.5)
# plt.xticks([0,1,10,20,30,40])
# plt.xlabel('the number of command shared', fontsize=15)
# # plt.show()
# plt.savefig("cmdcount.svg")







#         if cnt > 10:
#             v = {}
#             printSubGraph(k,v,dot)

# dot.render('top35')

# out = ans.keys()
# out= sorted(out,key=lambda x:ans[x],reverse=True)
# cc = 0
# for item in out:
#     print(item+" "+str(ans[item]))
#     cc += ans[item]
# print(cc)








