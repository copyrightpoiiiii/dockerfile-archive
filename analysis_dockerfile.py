from email.mime import base
import os
from collections import defaultdict
from matplotlib import pyplot as plt
import numpy as np

error_file = []

f = open("error_file", "r")
lines = f.readlines()
for line in lines:
    error_file.append(line.strip() + ".dockerfile")
f.close()

key_word = ['FROM', 'RUN', 'CMD', 'LABEL', 'MAINTAINER', 'EXPOSE', 'ENV', 'ADD', 'COPY', 'ENTRYPOINT', 'VOLUME', 'USER', 'WORKDIR', 'ARG', 'ONBUILD', 'STOPSIGNAL', 'HEALTHCHECK', 'SHELL']

fake_key_word = ['.MDECHO', 'CROSS_BUILD_COPY', 'COPY_SYSTEM_SPEC_FILE', 'CROSS_BUILD_COPY']

skip_word = ['-y', '-q', '-qq', '-qqy', '-yq', '-qy', '-yqq', '--yes']

count_word = defaultdict(int)

count_shell = defaultdict(int)

count_update = defaultdict(int)

count_cmd = defaultdict(int)

count_pkg = defaultdict(int)

count_run_shell = defaultdict(int)

buildkit_use = 0

shell_form = 0

tot_shell = 0

exec_form = 0

def check_dockerfile(f):
    lines = f.readlines()
    lines_no_comment = []
    for line in lines:
        line = line.strip()
        if len(line) <= 0:
            continue
        if not line[0] == '#':
            lines_no_comment.append(line)
        elif 'syntax' in line :
            buildkit_use += 1
            print(line)
        
    pos = 0
    flag = 0
    while pos < len(lines_no_comment):
        line = lines_no_comment[pos]
        act = line.split(" ")[0].strip('\\').upper()
        if not act in key_word and not act in fake_key_word:
            print(act)
            print(line)
            print('----------------------------------')
            flag = 1
        count_word[act] += 1
        if line[-1] == '\\' or line[-1] == '`':
            while lines_no_comment[pos][-1] == '\\' or lines_no_comment[pos][-1] == '`':
                pos += 1
            if lines_no_comment[pos].endswith("EOT"):
                pos += 1
                while not lines_no_comment[pos].endswith("EOT"):
                    pos += 1
            pos += 1
        else:
            pos += 1
    return flag

def analysis_dockerfile(f):
    global exec_form,shell_form,tot_shell,buildkit_use
    pos = 0
    flag = 0
    lines = f.readlines()
    lines_no_comment = []
    for line in lines:
        line = line.strip()
        if len(line) <= 0:
            continue
        if not line[0] == '#':
            lines_no_comment.append(line)
        elif 'syntax' in line :
            buildkit_use += 1
            # flag = 1
            # print(line)
        
    baseImage = ''

    while pos < len(lines_no_comment):
        line = lines_no_comment[pos]
        act = line.split(" ")[0].strip('\\').upper()
        if act == 'RUN':
            tmp = ''
            if line[-1] == '\\' or line[-1] == '`':
                while lines_no_comment[pos][-1] == '\\' or lines_no_comment[pos][-1] == '`':
                    tmp += lines_no_comment[pos].strip()[:-2] + ' '
                    pos += 1
                if lines_no_comment[pos].endswith("EOT"):
                    tmp += lines_no_comment[pos].strip()[:-4] + ' '
                    pos += 1
                    while not lines_no_comment[pos].endswith("EOT"):
                        tmp += lines_no_comment[pos].strip()[:-4] + ' '
                        pos += 1
                tmp += lines_no_comment[pos].strip() + ' '
                pos += 1
            else:
                tmp += line.strip()
                pos += 1
            tmp = tmp[3:].strip()
            if tmp[0] == '[': # exec form
                exec_form += 1
            else: # shell form
                tmp_list = tmp.strip().split("&&")
                command_list = []
                for item in tmp_list:
                    command_list += item.strip().split(';') 
                for item in command_list:
                    if len(item.strip()) <= 0:
                        continue
                    split_word = item.strip().split()
                    if split_word[0] == 'sudo':
                        split_word = split_word[1:]
                    if split_word[0] == 'apt-get' or split_word[0] == 'apk' or split_word[0] == 'apt' or split_word[0] == 'yum':
                        cnt = 1
                        while split_word[cnt] in skip_word:
                            cnt += 1
                        if split_word[cnt] == 'update':
                            count_update[baseImage] += 1
                            count_cmd[(baseImage, tmp)] += 1
                        elif split_word[cnt] == 'install':
                            cnt += 1
                            while cnt < len(split_word):
                                if not split_word[cnt].startswith('-'):
                                    count_pkg[split_word[cnt].strip()] += 1
                                cnt += 1
                        #count_shell[split_word[0] + " " + split_word[cnt]] += 1
                    # elif split_word[0] == 'rm':
                    #     print(tmp)
                    # count_shell[split_word[0]] += 1
                tot_shell += len(command_list)
                shell_form += 1
        elif act == 'FROM':
            baseImage = line.split()[1].strip()
            pos += 1
        else:
            if line[-1] == '\\' or line[-1] == '`':
                while lines_no_comment[pos][-1] == '\\' or lines_no_comment[pos][-1] == '`':
                    pos += 1
                if lines_no_comment[pos].endswith("EOT"):
                    pos += 1
                    while not lines_no_comment[pos].endswith("EOT"):
                        pos += 1
                pos += 1
            else:
                pos += 1

    return flag

def analysis_baseimage(f):
    pos = 0
    flag = 0
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
        if act == 'FROM':
            tmp = line
            for k,v in arg_dic.items():
                tmp=tmp.replace('${'+k+'}',v)
                tmp=tmp.replace('$'+k,v)
            for item in tmp.strip().split()[1:]:
                if(item.startswith("--")):
                    continue
                else:
                    return item
        elif act == 'ARG':
            if '=' in line:
                tmp = line.replace('"',"").replace("'","")
                for k,v in arg_dic.items():
                    tmp=tmp.replace('${'+k+'}',v)
                    tmp=tmp.replace('$'+k,v)
                for item in tmp.split(' '):
                    if '=' in item:
                        arg_dic[item.split('=')[0]] = item.split('=')[1]
        pos += 1

    return ''

def sort_print_dict(dic, rec=True):
    keys = dic.keys()
    keys = sorted(keys, key=lambda x:dic[x], reverse=rec)
    return [(i,dic[i]) for i in keys]


cnt_baseImage = defaultdict(int)

dir_list = os.listdir("dockerfile")
replace_dic = {}
replace_dic['90DaysOfDevOps'] = ('${ELASTIC_VERSION}','8.1.0')
replace_dic['docker-elk'] = ('${ELASTIC_VERSION}','8.3.3')
replace_dic['aiohttp'] = ('$PYTHON_VERSION','3.7')
replace_dic['anki'] = ('$PYTHON_VERSION','3.9')
replace_dic['allennlp'] = ('${TORCH}','1.11.0-cuda11.3')
replace_dic['argo-workflows'] = ('${VARIANT}','bullseye')
replace_dic['backstage'] = ('${IMAGE_TAG}','14-alpine')
replace_dic['beats'] = ('${ZOOKEEPER_VERSION}','3.5.5')
replace_dic['beats'] = ('${ENT_VERSION}','8.0.0-SNAPSHOT')
replace_dic['certbot'] = ('${TARGET_ARCH}','amd64')
replace_dic['certbot'] = ('${BASE_IMAGE}','certbot')
replace_dic['cockroach'] = ('$BAZEL_IMAGE','cockroachdb/bazel')
replace_dic['containerd'] = ('${GO_VERSION}','1.19')
replace_dic['containerd'] = ('$BASE','busybox')
replace_dic['containers'] = ('$BASEIMAGE','debian:jessie')
replace_dic['containers'] = ('${BASEIMAGE}','debian:jessie')
replace_dic['containers'] = ('${KUBE_CROSS_IMAGE}','k8s.gcr.io/build-image/kube-cross')
replace_dic['containers'] = ('${KUBE_CROSS_VERSION}','v1.16.5-1')
replace_dic['kubernetes'] = ('$BASEIMAGE','debian:jessie')
replace_dic['kubernetes'] = ('${BASEIMAGE}','debian:jessie')
replace_dic['kubernetes'] = ('${KUBE_CROSS_IMAGE}','k8s.gcr.io/build-image/kube-cross')
replace_dic['kubernetes'] = ('${KUBE_CROSS_VERSION}','v1.16.5-1')
replace_dic['fabric'] = ('${ALPINE_VER}','3.16')
replace_dic['fabric'] = ('${GO_VER}','1.18.2')
replace_dic['gym'] = ('$PYTHON_VERSION','3.6')
replace_dic['harbor'] = ('${harbor_base_namespace}','goharbor')
replace_dic['harbor'] = ('${harbor_base_image_version}','dev')
replace_dic['ingress-nginx'] = ('${GOLANG_VERSION}','1.18.2')
replace_dic['ingress-nginx'] = ('${BASE_IMAGE}','registry.k8s.io/ingress-nginx/nginx:9fdbef829c327b95a3c6d6816a301df41bda997f@sha256:46c27294e467f46d0006ad1eb5fd3f7005eb3cbd00dd43be2ed9b02edfc6e828')
replace_dic['jaeger'] = ('$cert_image','alpine:3.14')
replace_dic['jaeger'] = ('$golang_image','golang:1.18-alpine')
replace_dic['jaeger'] = ('$base_image','baseimg_alpine:latest')
replace_dic['kubespray'] = ('${KUBESPRAY_VERSION}','v2.19.0')
replace_dic['laradock'] = ('${LARADOCK_PHP_VERSION}','5.6')
replace_dic['incubator-mxnet'] = ('${BASE_IMAGE}','centos:7')
replace_dic['incubator-mxnet'] = ('$BASE_IMAGE','centos:7')
replace_dic['portainer'] = ('${OSVERSION}','')
replace_dic['pulsar'] = ('${ARCH}','x86_64')
replace_dic['pytorch'] = ('${UBUNTU_VERSION}','16.04')
replace_dic['pytorch'] = ('${IMAGE_NAME}','nvidia/cuda:10.2-cudnn7-devel-ubuntu16.04')
replace_dic['pytorch'] = ('${CENTOS_VERSION}','latest')
replace_dic['rancher'] = ('$SERVERCORE','ltsc2022')
replace_dic['rasa'] = ('${IMAGE_BASE_NAME}','rasa/rasa')
replace_dic['rasa'] = ('${BASE_BUILDER_IMAGE_HASH}','localdev')
replace_dic['ray'] = ('$BASE_IMAGE','ubuntu:focal')
replace_dic['recommenders'] = ('${PYTHON_VERSION}','3.6')
replace_dic['skywalking'] = ('$SKYWALKING_CLI_VERSION','0.9.0')
replace_dic['skywalking'] = ('$BASE_IMAGE','eclipse-temurin:17-jre')
replace_dic['spark'] = ('$base_img','spark:latest')
replace_dic['swoole-src'] = ('${PHP_VERSION}','8.0')
replace_dic['swoole-src'] = ('${ALPINE_VERSION}','3.14')
replace_dic['tensorflow'] = ('${ARCH:+-}','x86_64')
replace_dic['tensorflow'] = ('${REDHAT_VERSION}','latests')
replace_dic['traefik-library-image'] = ('$ALPINE_VERSION','3.11')
replace_dic['vector'] = ('${RUST_VERSION}','1.63')
replace_dic['yii2'] = ('${DOCKER_YII2_PHP_IMAGE}','yiisoftware/yii2-php:7.4-apache')
replace_dic['zulip'] = ('$BASE_IMAGE','ubuntu:20.04')

# cnt = 0
# for item in dir_list:
#     uri = "dockerfile/" + item + "/"
#     file_list = os.listdir(uri)
#     for file in file_list:
#         if item + "/" + file in error_file:
#             continue
#         cnt += 1
#         f = open(uri+file,encoding="utf-8")
#         baseImage = analysis_baseimage(f)
#         if '$' in baseImage:
#             if item in replace_dic.keys():
#                 baseImage = baseImage.replace(replace_dic[item][0],replace_dic[item][1])
#         if not '$' in baseImage:
#             cnt_baseImage[baseImage.lower()] += 1
#         # flag = analysis_dockerfile(f)
#         # try:
#         #     flag = analysis_dockerfile(f)
#         # except Exception:
#         #     print(uri+file)
#         # if flag:
#         #     print(uri+file)
#         #     print('-------------------------------------------------------')
#         f.close()

# items = sort_print_dict(cnt_baseImage)
# for item in items:
#     print(item)

# print(buildkit_use)
# print(exec_form)
# print(shell_form)
# print(tot_shell)
# keys = count_run_shell.keys()
# keys = sorted(keys,key = lambda x:count_run_shell[x], reverse=True)
# for item in keys:
#     print(item, count_run_shell[item])
# keys = count_pkg.keys()
# keys = sorted(keys, key= lambda x:count_pkg[x],reverse=True)
# val = []
# x = []
# tot = 0
# for item in keys:
#     tot += count_pkg[item]
#     x.append(str(count_pkg[item]))
#     val.append(tot)
# val = [i/tot for i in val]
# for i in range(len(keys)):
#     print(keys[i], count_pkg[keys[i]], val[i])

# plt.figure(figsize=(20, 20))
# plt.plot(np.linspace(0, 1, len(val), endpoint=True),val)
# plt.xticks(rotation=45)
# plt.show()