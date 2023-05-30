import copy
import re
import yaml
import dockerfile
import os
import sys
import json
import lzma
import replace_bash_variable
import find_dependency
import tqdm
from shutil import copyfile

def walk(res,num,ta):
    print(ta + str(num) +" command is :")
    for k,v in res.items():
        if k != 'children':
            print(ta+k+" : "+str(v))
    for i in range(len(res['children'])):
        walk(res['children'][i], num+i+1,ta+" \t")

def walk_cmd(cmd):
    ans = cmd['type'] + ' '
    if 'value' in cmd:
        ans += cmd['value'] + ' '
    for subcmd in cmd['children']:
        ans += walk_cmd(subcmd)
    return ans
def middleware():
    find_dependency.init()
    #print(find_dependency.pkg_list[0])

    result = []
    with lzma.open('p2-out/output.jsonl.xz', mode='rt') as f:
        lines = f.readlines()
        for line in lines:
            tmp = json.loads(line)
            # print(tmp['file_sha'])
            # replace_bash_variable.assign_pair = {}
            # replace_bash_variable.learnAndReplaceVariable(tmp)
            replace_bash_variable.calcCompact(tmp)
            result.append(json.dumps(tmp))
            # replace_bash_variable.findURL(tmp)
            # find_dependency.find_dep(tmp)
            # walk(tmp, 0, "")
    f.close()
    copyfile('p2-out/output.jsonl.xz', 'p2-out/output_arch.jsonl.xz')
    with lzma.open('p2-out/output.jsonl.xz', mode='wt') as f:
        for item in tqdm.tqdm(result, total=len(result), desc="Generating"):
            f.write('{}\n'.format(item))

def checkout():
    find_dependency.init()
    #print(find_dependency.pkg_list[0])
    with lzma.open('p3-out/output.jsonl.xz', mode='rt') as f:
        with lzma.open('abstract-out/output.jsonl.xz', mode='wt') as out_file:
            lines = f.readlines()
            for line in lines:
                replace_bash_variable.clean()
                find_dependency.clean()
                file_dict = json.loads(line)
                # if file_dict['file_sha'] != '1.dockerfile':
                #     continue

                replace_bash_variable.assign_pair = {}
                replace_bash_variable.learnAndReplaceVariable(file_dict)
                replace_bash_variable.calcCompact(file_dict)
                
                replace_bash_variable.findURL(file_dict)
                replace_bash_variable.abstract_tree(file_dict)
                replace_bash_variable.split_dockerfile(file_dict)
                
                find_dependency.find_dep(file_dict)
                out_file.write('{}\n'.format(json.dumps(file_dict)))
                # for k in sorted(find_dependency.cmd_dep.keys()):
                #     print(k,walk(file_dict['children'][k], 0, ''))
                #     for pkg in find_dependency.cmd_dep[k]:
                #         print(pkg,walk_cmd(file_dict['children'][pkg]))
                #     print("------------------------------------------------------------")
            
def check(tmp):
    if tmp['type'] == 'UNKNOWN':
        return True
    for item in tmp['children']:
        if check(item):
            return True

def printResult():
    with lzma.open('abstract-out/output.jsonl.xz', mode='rt') as f:
        lines = f.readlines()
        for line in lines:
            tmp = json.loads(line)
            if tmp['file_sha'] == '2.dockerfile':
                continue
            if check(tmp):
                print(tmp['file_sha'])

def checkResult():
    with lzma.open('p2-out/output.jsonl.xz', mode='rt') as f:
        lines = f.readlines()
        for line in lines:
            tmp = json.loads(line)
            if tmp['file_sha'] == '2.dockerfile':
                continue
            if check(tmp):
                print(tmp['file_sha'])

def main():
    if str(sys.argv[1]) == 'middleware':
        middleware()
    elif str(sys.argv[1]) == 'print':
        printResult()
    else:
        checkout()
        checkResult()

if __name__ == '__main__':
    main()

docker run --name tracee --rm -it --pid=host --cgroupns=host --privileged -v /etc/os-release:/etc/os-release-host:ro  -mount type=bind,source=/boot/config-$(uname -r),destination=/boot/config-$(uname -r),readonly -e LIBBPFGO_KCONFIG_FILE=/boot/config-$(uname -r)  -e LIBBPFGO_OSRELEASE_FILE=/etc/os-release-host      aquasec/tracee:0.9.3

docker rmi -f $(docker images -q -a)