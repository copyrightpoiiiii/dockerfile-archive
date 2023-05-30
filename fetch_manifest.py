import json
import os
import subprocess

def is_json(testJson):
    try:
        json_object = json.loads(testJson)
    except ValueError as e:
        return False
    return True

f = open("test.txt", "r")
lines = f.readlines()
f.close()

for line in lines:
    image = eval(line)[0]
    dirname = image.replace(':','#')
    if os.path.exists('manifest//' + dirname) or image == 'scratch':
        continue
    print(line)
    # cmd = "docker manifest inspect -v " + image
    # out = subprocess.getoutput(cmd)
    # if is_json(out):
    #     js = json.loads(out)
    #     os.makedirs('manifest//'+dirname)
    #     f = open('manifest//' + dirname + '//manifest.json', "w+")
    #     print(js,file=f)
    #     f.close()
    #     print(image + " done")
    # else:
    #     print(image + " error")
    #     print(out)


    