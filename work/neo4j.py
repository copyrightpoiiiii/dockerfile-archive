from collections import defaultdict
import py2neo
import lzma
import json
import os
import queue
import pandas as pd

assistValue = ['install_pkg','used_pkg','file_relate','cmdid','abs-type','children']
skipFile = ['1.dockerfile', '2.dockerfile', '3.dockerfile']
runShell = ['DOCKER-RUN','DOCKER-CMD','DOCKER-SHELL', 'DOCKER-ENTRYPOINT']

graph = py2neo.Graph("neo4j://127.0.0.1:7687")
matcher = py2neo.NodeMatcher(graph)
global num
num=0

nodeDict = {}
baseImgae = {}
cntBaseImage = defaultdict(int)
baseImgaeList = []
baseFile = defaultdict(list)

def findListOrStringValue(v):
    try:
        tmp = eval(v)
        if type(tmp) == type([]):
            return tmp
        if type(tmp) == type(' '):
            return tmp.replace("'",'"').replace('\\u','\\\\u')
        return str(v).replace("'",'"').replace('\\u','\\\\u')
    except:
        if type(v) == type(' '):
            return v.replace("'",'"').replace('\\u','\\\\u')
        return str(v).replace("'",'"').replace('\\u','\\\\u')

def create_node_real(tmp,type='DockerARG'):
    node = py2neo.Node(type)
    for k,v in tmp.items():
        if not k in assistValue:
                node[k] = findListOrStringValue(v)
    node['useTime'] = 0
    graph.create(node)
    return node

def create_node(tmp, faID):
    global num
    query = "match (y)-[]->(x:DockerARG) where"
    for k,v in tmp.items():
        if not k in assistValue:
            tmpValue = findListOrStringValue(v)
            if type(tmpValue) == type(' '):
                query += ' x.`'+k +"`='" + tmpValue + "' and"
            else:
                query += ' x.`'+k +"`=" + str(tmpValue) + " and"
    query = query + ' ID(y)=' + str(faID) + ' return x'
    # print(query)
    try:
        result = graph.run(query).to_series()
    except:
        print(tmp)
        print(str(findListOrStringValue(tmp['value'])))
        exit(-1)
    if len(result) > 0:
        node = result[0]
    else:
        node = create_node_real(tmp)

    node['useTime'] += 1
    graph.push(node)
    for subcmd in tmp['children']:
        subnode = create_node(subcmd, node.identity)
        graph.create(py2neo.Relationship(node, 'inner', subnode))
    return node

def create_dep_node(tmp):
    global num
    query = "match (y)-[r:dep]->(x:DockerCMD) where"
    for k,v in tmp.items():
        if not k in assistValue and k != 'cmd_dep':
            tmpValue = findListOrStringValue(v)
            if type(tmpValue) == type(' '):
                query += ' x.`'+k +"`='" + tmpValue + "' and"
            else:
                query += ' x.`'+k +"`=" + str(tmpValue) + " and"
    query += ' ('
    for depcmd in tmp['cmd_dep']:
        query += ' ID(y)='+str(nodeDict[depcmd].identity) +' or'
    query = query.rstrip('or') + ') return x,count(x)'
    try:
        result = graph.run(query).to_table()
    except:
        print(tmp)
        print(str(findListOrStringValue(tmp['value'])))
        exit(-1)
    if len(result)>0 and result[0][1] == len(tmp['cmd_dep']):
        node = result[0][0]
    else:
        node = create_node_real(tmp,'DockerCMD')
        for depcmd in tmp['cmd_dep']:
            graph.create(py2neo.Relationship(nodeDict[depcmd], 'dep', node))
    node['useTime'] += 1
    graph.push(node)
    for subcmd in tmp['children']:
        subnode = create_node(subcmd, node.identity)
        graph.create(py2neo.Relationship(node, 'inner', subnode))
    return node

def walk(cmd):
    global num
    num += 1
    for item in cmd['children']:
        walk(item)

changeList = []

def build(AST):
    global num
    for cmd in AST['children']:
        if cmd['type'] == 'DOCKER-FROM':
            imageName = ''
            imageTag = 'latest'
            for subcmd in cmd['children']:
                if subcmd['type'] == 'DOCKER-IMAGE-NAME':
                    imageName = subcmd['value']
                elif subcmd['type'] == 'DOCKER-IMAGE-TAG':
                    imageTag = subcmd['value']
            depImage = (imageName, imageTag)
            if (imageName, imageTag) in baseImgae:
                depImage = baseImgae[depImage]
            num += 1
            if not depImage in nodeDict:
                baseNode = py2neo.Node('baseImage')
                baseNode['repo'] = imageName
                baseNode['tag'] = imageTag
                nodeDict[depImage] = baseNode
                graph.create(baseNode)
            baseNode = nodeDict[depImage]
            nodeDict[cmd['cmdid']] = baseNode
        else:
            recordCmd = {'children':cmd['children']}
            for k,v in cmd.items():
                if k in assistValue:
                    continue
                recordCmd[k]=v
            node = create_dep_node(recordCmd)
            nodeDict[cmd['cmdid']] = node
            # for depcmd in cmd['cmd_dep']:
            #     graph.create(py2neo.Relationship(nodeDict[depcmd], 'dep', node))
    # changeList.append(cnt)

def findBaseImage(AST):
    for cmd in AST['children']:
        if cmd['type'] == 'DOCKER-FROM':
            imageName = ''
            imageTag = 'latest'
            for subcmd in cmd['children']:
                if subcmd['type'] == 'DOCKER-IMAGE-NAME':
                    imageName = subcmd['value']
                elif subcmd['type'] == 'DOCKER-IMAGE-TAG':
                    imageTag = subcmd['value']
            depImage = (imageName, imageTag)
            if (imageName, imageTag) in baseImgae:
                depImage = baseImgae[depImage]
            return depImage
    return ('noImage','noTag')

image_layer = {}
image_config = {}
image_manifest = {}
edge = defaultdict(list)
incnt = defaultdict(int)

edgeVis = defaultdict(bool)

def bfs(layer):
    vis = defaultdict(bool)
    que = queue.Queue()
    que.put(layer)
    vis[layer] = True
    image = ('','')
    while not que.empty():
        node = que.get()
        if type(node) == type(image):
            if image == ('',''):
                image = node
                baseImgaeList.append(image)
            baseImgae[node] = image
            cntBaseImage[image] += 1
        else:
            for item in edge[node]:
                if not vis[item]:
                    que.put(item)
                    vis[item] = True



def init():
    for p,_,file in os.walk('../manifest'):
        if len(file) > 0:
            f = open(p+ '/manifest.json')
            imageName = p.replace('../manifest\\','')
            if '#' in imageName:
                image = (imageName.split('#')[0],imageName.split('#')[-1])
            else:
                image = (imageName, 'latest')
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

    cnt = 0
    for k in edge.keys():
        if incnt[k] == 0:
            cnt += 1
            bfs(k)
    
    # print(len(baseImgaeList))
    # # for item in baseImgaeList:
    # #     print(item)
    # for item in sorted(cntBaseImage.keys(),key=lambda x:cntBaseImage[x],reverse=True):
    #     print(item, cntBaseImage[item])
# graph.delete_all()
init()
f = lzma.open('abstract-out/output.jsonl.xz', 'rt')
# line = f.readlines()
# tmp = json.loads(line)
# node = create_node(tmp)
fileIndex = {}
lines = f.readlines()
for line in lines:
    tmp = json.loads(line)
    if tmp['file_sha'] in skipFile:
        continue
    # print(tmp['file_sha'])
    # if tmp['file_sha'] != '2.dockerfile':
    #     continue
    # build(tmp)
    baseFile[findBaseImage(tmp)].append(tmp['file_sha'])
    fileIndex[tmp['file_sha']] = tmp

for item in sorted(baseFile.keys(), key=lambda x:len(baseFile[x]), reverse=True):
    if len(baseFile[item]) == 1:
        break
    graph.delete_all()
    for file in baseFile[item][:4]:
        # if file != 'photoprism_docker_develop_bullseye-slim_Dockerfile202204180.dockerfile':
        #     continue
        print(file)
        build(fileIndex[file])
    # f = open('baseImageShard/'+str(cnt)+'.txt','w+')
    # print(item[0],file=f)
    # print(item[1],file=f)
    # print(baseFile[item],file=f)
    # f.close()
    # cnt += 1
    exit(0)


