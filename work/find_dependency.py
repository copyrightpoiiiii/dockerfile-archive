from collections import defaultdict
import os
import yaml
import re

pkg_list = []
install_list = []
file_list = []

build_stage = []
package_install = {}
file_create = defaultdict(list)
cmd_dep = defaultdict(set)
understandCommand = []
ind = defaultdict(int)

def handle_bash_literal(item):
    return str(item['value'])

def handle_bash_variable(item):
    return '$' + str(item['value'])

def handle_bash_concat(item):
    cmdstr = ""
    for cmd in item['children']:
        cmdstr += handle_value(cmd)
    return cmdstr

def handle_value(cmd):
    if cmd['type'] == 'BASH-LITERAL':
            return handle_bash_literal(cmd)
    elif cmd['type'] == 'BASH-VARIABLE':
        return handle_bash_variable(cmd)
    elif cmd['type'] == 'BASH-CONCAT':
        return handle_bash_concat(cmd)
    if 'value' in cmd.keys():
        return cmd['value'] + ' '
    return ""

def walk(res,num,ta):
    print(ta + str(num) +" command is :")
    for k,v in res.items():
        if k != "children":
            print(ta+k+" : "+v)
    for i in range(len(res['children'])):
        walk(res['children'][i], num+i+1,ta+" \t")

def walkvalue(cmd):
    value = handle_value(cmd)
    if cmd['type'] != "BASH-CONCAT":
        for subcmd in cmd['children']:
            value += walkvalue(subcmd)
    return value

def walkpaths(cmd):
    path = []
    for subcmd in cmd['children']:
        path.append(walkvalue(subcmd))
    return path

def get_use_pkg(item):
    p_list = []
    for cmd in item['children']:
        if cmd['type'] == 'BASH-UNDEFINE-COMMAND' :
            p_list.append(cmd['value'])
        elif cmd['type' ].startswith('SC'):
            for pkg in pkg_list:
                if cmd['type'].startswith(pkg['prefix']):
                    p_list += pkg['providerFor']
        p_list += get_use_pkg(cmd)
    return p_list

def get_pkg_list(cmd):
    return

def get_install_pkg(item):
    p_list = set()
    
    for cmd in item['children']:
        if cmd['type'] == 'BASH-UNDEFINE-COMMAND' :
            flag = False
            for subcmd in cmd['children']:
                if subcmd['type'] == 'BASH-LITERAL' and subcmd['value'] == 'install':
                    flag = True
                    break
            if flag == True:
                for subcmd in cmd['children']:
                    if subcmd['type'] == 'BASH-LITERAL' and (not subcmd['value'].startswith('-') and not subcmd['value'] == 'install'):
                        p_list.add(subcmd['value'])
        elif cmd['type'].startswith('SC'):
            for pkg in install_list:
                if cmd['type'] in pkg['cmd']:
                    for chcmd in cmd['children']:
                        # if chcmd['type'] == 'SC-APK-VIRTUAL':
                        #print(chcmd['type'])
                        if chcmd['type'] in pkg['package']:
                            #print(chcmd)
                            for chpkg in chcmd['children']:
                                p_list.add(walkvalue(chpkg))
        else:
            p_list =  p_list.union(get_install_pkg(cmd))
    return p_list

def match_file_path(item):
    for pkg in file_list:
        if item['type'] in pkg['cmd']:
            out_path = []
            source_path = []
            path_list = []
            for subcmd in item['children']:
                if subcmd['type'] in pkg['source']:
                    source_path += walkpaths(subcmd)
                elif subcmd['type'] in pkg['target']:
                    out_path += walkpaths(subcmd)
                elif subcmd['type'] in pkg['path']:
                    path_list += walkpaths(subcmd)
            if pkg['target-last'] == True and len(out_path)==0 and len(path_list)>0:
                out_path = [path_list[-1]]
                path_list.pop()
            if pkg['multifile'] == True:
                source_path = path_list
            if len(out_path) == 0 and len(source_path) > 0:
                out_path = [source_path[-1].split('/')[-1].replace('.git','')]
            return {'source':source_path, 'target':out_path}
    if item["type"] == "BASH-LITERAL" and "abs-type" in item:
        if "ABS-FILENAME" in item['abs-type'] or "ABS-MAYBE-PATH" in item['abs-type']:
            return {'source':[str(item['value'])], 'target':[str(item['value'])]}
    ans = {'source':[], 'target':[]}
    for subcmd in item['children']:
        tmp =  match_file_path(subcmd)
        ans['source'] += tmp['source']
        ans['target'] += tmp['target']
    return ans

def findUsedCmd(item):
    p_list = []
    for cmd in item['children']:
        if cmd['type'] == 'BASH-UNDEFINE-COMMAND' :
            p_list.append(cmd['value'])
        elif cmd['type'].startswith('SC'):
            for pkg in pkg_list:
                if cmd['type'].startswith(pkg['prefix']):
                    for subcmd in pkg['scenarios']:
                        if subcmd['name'] == cmd['type']:
                            p_list += pkg['providerFor']
                            break
        else:
            p_list += findUsedCmd(cmd)
    return p_list


def init(path="pkg_list"):
    global install_list,file_list,understandCommand
    for item in os.listdir(path):
        if item.endswith(".yml"):
            f = open(path+'/'+item, "r")
            data = f.read()
            pkg_list.append(yaml.load(data, Loader=yaml.SafeLoader)['command'])
    for item in pkg_list:
        if 'scenarios' in item:
            for cmd in item['scenarios']:
                understandCommand.append(cmd['name'])
    f = open("install.yml", "r")
    data = f.read()
    install_list = yaml.load(data, Loader=yaml.SafeLoader)['pkg']

    f = open("file.yml", "r")
    data = f.read()
    file_list = yaml.load(data, Loader=yaml.SafeLoader)['pkg']

def propagate_path(related_path, id, base):
    # print(related_path)
    for pth in related_path['source']:
        if pth in file_create:
            cmd_dep[id].add(max(file_create[pth][-1], base))
        else:
            cmd_dep[id].add(base)
    for pth in related_path['target']:
        file_create[pth].append(id)

def trans_workDir(realted_path, workDir):
    for i in range(len(realted_path['target'])):
        if not realted_path['target'][i].startswith("./"):
            realted_path['target'][i] = re.compile(r'/+').sub('/',workDir + '/' + realted_path['target'][i])
    for i in range(len(realted_path['source'])):
        if not realted_path['source'][i].startswith("./"):
            realted_path['source'][i] = re.compile(r'/+').sub('/',workDir + '/' + realted_path['source'][i])
    return realted_path

def handle_RUN_dep(cmd, id, workDir, base):
    cmd['install_pkg'] = list(get_install_pkg(cmd))
    for pkg in cmd['install_pkg']:
        package_install[pkg] = id
    cmd['used_pkg'] = list(set(findUsedCmd(cmd)))
    for pkg in cmd['used_pkg']:
        if pkg in package_install and package_install[pkg] > base:
            cmd_dep[id].add(package_install[pkg])
        else:
            cmd_dep[id].add(base)
    cmd['file_relate'] = trans_workDir(match_file_path(cmd), workDir)
    propagate_path(cmd['file_relate'], id, base)

def pre_check_copy(cmd):
    tarPth = ""
    copy_stage = -1
    remote_copy = False
    source_num = 0
    sourcePth = []
    for subcmd in cmd['children']:
        if subcmd['type'].endswith("TARGET"):
            tarPth = subcmd['children'][0]['value']
        elif subcmd['type'].endswith("FROM"):
            for i in range(len(build_stage)):
                if build_stage[i][0] == subcmd['value']:
                    copy_stage = i
                    break
        elif subcmd['type'].endswith("SOURCE"):
            source_num += 1
            if subcmd['children'][0]['type'].endswith('URL'):
                remote_copy = True
                sourcePth.append(subcmd['children'][0]['value'].split('/')[-1])
            else:
                sourcePth.append(subcmd['children'][0]['value'])
    return tarPth,copy_stage,remote_copy,(source_num > 1),sourcePth

def checkCmd(cmd):
    if cmd['type'] in understandCommand:
        return True
    res = (len(cmd['children']) > 0)
    for item in cmd['children']:
        res |= checkCmd(item)
    return res

def find_dep(dockerJson):
    cnt = 0
    base = 0
    workDir = "./"
    
    for cmd in dockerJson['children']:
        # 
        if cmd['type'] == "DOCKER-RUN":
            # print(cmd)
            if checkCmd(cmd):
                handle_RUN_dep(cmd, cnt, workDir, base)
                cmd_dep[cnt].add(base)
            else:
                for i in range(base, cnt):
                    if ind[i] == 0:
                        cmd_dep[cnt].add(i)
                base = cnt
        elif cmd["type"] == "DOCKER-ADD" or cmd["type"] == "DOCKER-COPY":
            targetPath, copy_stage, remote_copy, mult_source, sourcePth = pre_check_copy(cmd)
            if not remote_copy and copy_stage != -1:
                for pth in sourcePth:
                    flag = True
                    if pth in file_create:
                        for depcmd in file_create[pth][::-1]:
                            if depcmd > build_stage[copy_stage][-1]:
                                cmd_dep[cnt].add(depcmd)
                                flag = False
                                break
                    if flag:
                        if copy_stage+1 >= len(build_stage):
                            continue
                        cmd_dep[cnt].add(build_stage[copy_stage+1][-1]-1)
            if not mult_source:
                sourcePth = [targetPath]
            realted_path = {'source':[], 'target':sourcePth}
            cmd['file_relate'] = trans_workDir(realted_path, workDir)
            propagate_path(cmd['file_relate'], cnt, base)
            cmd_dep[cnt].add(base)
        elif cmd['type'] == "DOCKER-WORKDIR":
            workDir = cmd['children'][0]['value']
            cmd['file_relate'] = {'source':[cmd['children'][0]['value']], 'target':[cmd['children'][0]['value']]}
            propagate_path(cmd['file_relate'], cnt, base)
            cmd_dep[cnt].add(base)
        elif cmd['type'] == "DOCKER-FROM":
            base = cnt
            for subcmd in cmd['children']:
                if subcmd['type'] == 'DOCKER-IMAGE-ALIAS':
                    build_stage.append((subcmd['value'],cnt))
                else:
                    build_stage.append(('main-stage',cnt))
        else:
            cmd_dep[cnt].add(base)
        if cnt in cmd_dep[cnt]:
            cmd_dep[cnt].remove(cnt)
        cmd['cmd_dep'] = list(cmd_dep[cnt])
        for item in cmd['cmd_dep']:
            ind[item] += 1
        cmd['cmdid'] = cnt
        cnt += 1
  

def clean():
    global package_install,file_create,cmd_dep,build_stage,ind
    package_install = {}
    file_create = defaultdict(list)
    build_stage = []
    cmd_dep = defaultdict(set)
    ind = defaultdict(int)





# with lzma.open('.\p3-out\output.jsonl.xz', mode='rt') as f:
#     lines = f.readlines()
#     for line in lines[:-1]:
#         walk(json.loads(line),0,"")
    # df = open("inputs/2.dockerfile","r")
    # ls = df.readlines()
    # now = 0
    # for line in lines[1:]:
    #     tmp = json.loads(line)
    #     for item in tmp['children']:
    #         #print(item['type'])
    #         print("command is: ",ls[now])
    #         now += 1
    #         if item['type'] == "DOCKER-RUN":
    #             #print(item)
    #             print("related packages: ", list(set(get_install_pkg(item))))
    #             print("related files: ", match_file_path(item))
    #         print("-----------------------------------------------------------------------")
        