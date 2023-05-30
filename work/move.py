import os
from shutil import copyfile
cnt = 0
for item in os.listdir('../dockerfile_historyVersion/new_Dockerfile'):
    for file in os.listdir('../dockerfile_historyVersion/new_Dockerfile/'+item):
        copyfile('../dockerfile_historyVersion/new_Dockerfile/'+item+'/'+file, 'inputs/'+item+'_'+file)
        cnt += 1
        # print('source:'+'../dockerfile_historyVersion/Dockerfile/'+item+'/'+file)
        # print('target:'+'inputs/'+item+'_'+file)
print(cnt)