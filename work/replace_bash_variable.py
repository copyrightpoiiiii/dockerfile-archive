import re
import abstractions

assign_pair = {}

def handle_bash_literal(item):
    return item['value']

def handle_bash_variable(item):
    return item['value']

def get_bash_variable(item):
    return '${'+item['value']+'}'

def handle_bash_concat(item):
    cmdstr = ""
    for cmd in item['children']:
        cmdstr += handle_value(cmd)
    return cmdstr

def handle_bash_quoted(item):
    cmdstr = ""
    for cmd in item['children']:
        cmdstr += handle_value(cmd)
    return cmdstr

def walkvalue(cmd):
    value = handle_value(cmd)
    if cmd['type'] != "BASH-CONCAT" and cmd['type'] != "BASH-DOUBLE-QUOTED":
        for subcmd in cmd['children']:
            value += walkvalue(subcmd)
    return value

def getvalue(cmd):
    value = get_value(cmd)
    if cmd['type'] != "BASH-CONCAT" and cmd['type'] != "BASH-DOUBLE-QUOTED":
        for subcmd in cmd['children']:
            value += walkvalue(subcmd)
    return value

def handle_value(cmd):
    if cmd['type'] == 'BASH-LITERAL':
            return handle_bash_literal(cmd)
    elif cmd['type'] == 'BASH-VARIABLE':
        return handle_bash_variable(cmd)
    elif cmd['type'] == 'BASH-CONCAT':
        return handle_bash_concat(cmd)
    elif cmd['type'] == 'BASH-DOUBLE-QUOTED':
        return handle_bash_quoted(cmd)
    if 'value' in cmd.keys():
        return cmd['value'] + ' '
    return ""

def get_value(cmd):
    if cmd['type'] == 'BASH-LITERAL':
            return handle_bash_literal(cmd)
    elif cmd['type'] == 'BASH-VARIABLE':
        return get_bash_variable(cmd)
    elif cmd['type'] == 'BASH-CONCAT':
        return handle_bash_concat(cmd)
    elif cmd['type'] == 'BASH-DOUBLE-QUOTED':
        return handle_bash_quoted(cmd)
    if 'value' in cmd.keys():
        return cmd['value'] + ' '
    return ""

def checkDoller(cmd):
    if cmd['type'] == 'BASH-DOLLAR-PARENS':
        return True
    flag = False
    for subcmd in cmd['children']:
        flag |= checkDoller(subcmd)
    return flag

def findNV(childList):
    name = ""
    value = "UNDEFINE"
    for cmd in childList:
        if cmd['type'] == "DOCKER-NAME":
            name = cmd['value']
        elif cmd['type'] == "DOCKER-LITERAL":
            if not 'value' in cmd:
                value = ""
                continue
            learnAndReplaceVariable(cmd)
            value = cmd['value'].strip().strip('"')
    return name,value

def makeDict(value):
    return {"type":"BASH-LITERAL","value":str(value),"children":[]}

def findAssign(res):
    if res['type'] == "BASH-ASSIGN":
        ls = walkvalue(res['children'][0])
        learnAndReplaceVariable(res['children'][1])
        assign_pair[ls] = res['children'][1]['children'][0]
    if res['type'] == "DOCKER-ENV" or res['type'] == "DOCKER-ARG":
        name, value = findNV(res['children'])
        assign_pair[name] = makeDict(value)

def checkValue(cmd):
    flag = True
    if cmd['type'] == "BASH-CONCAT":
        for subcmd in cmd['children']:
            flag &= checkValue(subcmd)
    elif cmd['type'] == 'BASH-LITERAL' or cmd['type'] == 'BASH-VARIABLE-VALUE':
        flag = True
    elif cmd['type'] == 'DOCKER-LITERAL':
        flag = True
    # elif len(cmd['children']) > 0:
    #     for subcmd in cmd['children']:
    #         flag &= checkValue(subcmd)
    else:
        flag = False
    return flag

def calcCompact(cmd):
    if cmd['type'] == 'BASH-CONCAT' and checkValue(cmd):
        value = walkvalue(cmd)
        cmd['type'] = "BASH-LITERAL"
        cmd['children'] = []
        try:
            cmd['value'] = str(eval(value))
        except:
            cmd['value'] = value
    else:
        for subcmd in cmd['children']:
            calcCompact(subcmd)

def copyCmd(target, source):
    for k in source.keys():
        target[k] = source[k]
    for k in list(target.keys()):
        if not k in source.keys():
            del target[k]

def findVariable(cmd):
    regex = r"\$\{[^\$]+\}|\$[^\f\n\r\t\v\$:/\s\(\|\"\']+"
    matches = re.finditer(regex, cmd['value'])
    match_str = set()
    for match in matches:
        match_str.add(match.group())
    for str in match_str:
        variable_key = str.strip('$').lstrip('{').rstrip('}')
        if variable_key in assign_pair.keys():
            cmd['value'] = cmd['value'].replace(str,get_value(assign_pair[variable_key]))

def learnAndReplaceVariable(cmd):
    # print(cmd)
    # learn Variable 
    if cmd['type'] == "BASH-ASSIGN" or cmd['type'] == "DOCKER-ENV" or cmd['type'] == "DOCKER-ARG":
        # print(cmd)
        findAssign(cmd)
        return
    # Replace Variable
    if cmd['type'] == "BASH-VARIABLE":
        # print(cmd)
        value = handle_bash_variable(cmd)
        if value in assign_pair.keys():
            copyCmd(cmd, assign_pair[value])
            # Variable propagate
            learnAndReplaceVariable(cmd)
        else:
            cmd['type'] = "BASH-VARIABLE-VALUE"
            cmd['value'] = '$' + value
            cmd['children'] = []
    elif cmd['type'] == "DOCKER-LITERAL" or cmd['type'] == "DOCKER-PATH":
        findVariable(cmd)
    else:
        for subcmd in cmd['children']:
            learnAndReplaceVariable(subcmd)

def findURL(cmd):
    if len(cmd['children']) == 0 and 'value' in cmd:
        if re.search(abstractions.ABSTRACTIONS['ABS-PROBABLY-URL'], str(cmd['value'])):
            cmd['type'] += "-ABS-URL"
        return
    for subcmd in cmd['children']:
        findURL(subcmd)    

def abstract_tree(tree, parent={'type':'UNKNOWN'}):
  def _check_virtual_apk(x):
    if x['type'] != 'SC-APK-PACKAGE' or len(x['children']) != 1:
      return
    
    if 'value' in x['children'][0] and x['children'][0]['value'].startswith('.'):
      x['type'] = 'SC-APK-VIRTUAL:{}'.format(x['children'][0]['value'])
      x['children'] = []

  KEEP_TYPES = [
    'SC-APT-GET-PACKAGE',
    'SC-APT-PACKAGE',
    'SC-APK-PACKAGE',
    'SC-YUM-PACKAGE',
    'SC-DNF-PACKAGE',
    'SC-NPM-PACKAGE',
    'SC-PIP-PACKAGE',
    'DOCKER-IMAGE-NAME',
    'DOCKER-IMAGE-REPO',
    'DOCKER-IMAGE-TAG',
    'DOCKER-PORT',
    'DOCKER-NAME',
    'BASH-VARIABLE'
  ]

  KEEP_PARENTS = [
    'SC-APK-VIRTUAL'
  ]

  CUSTOMS = [
    _check_virtual_apk
  ]

  def _abstract_value(node):
    value = str(node['value'])

    children = set()
    for conditional_type,test in abstractions.ABSTRACTIONS.items():
      if re.search(test, value):
        children.add(conditional_type)

    return list(children)

  for custom in CUSTOMS:
    custom(tree)
  
  if tree['type'] in KEEP_TYPES:
    # if len(tree['children']) == 1 and 'value' in tree['children'][0]:
    #   tree['type'] += ':{}'.format(tree['children'][0]['value'].upper())
    # elif 'value' in tree:
    #   tree['type'] += ':{}'.format(tree['value'])

    # if 'value' in tree:
    #   del tree['value']
    # tree['children'] = []
    return
  elif parent['type'] in KEEP_PARENTS and 'value' in tree:
    # parent['type'] += ':{}'.format(tree['value'])
    # parent['children'] = []
    return
  elif 'value' in tree:
    tree['abs-type']=_abstract_value(tree)
    # del tree['value']
  
  for child in tree['children']:
    abstract_tree(child, tree)

def split_dockerfile(file_dict):
    tmp = file_dict['children']
    file_dict['children'] = []
    for cmd in tmp:
        if cmd['type'] == 'DOCKER-RUN':
            file_dict['children'] += split_bash(cmd)
        else:
            file_dict['children'].append(cmd)

def split_bash(cmd):
    cmd_list = []
    if cmd['type'] == 'DOCKER-RUN' and len(cmd['children']) == 1 and cmd['children'][0]['type'] == 'BASH-SCRIPT':
        for subcmd in cmd['children'][0]['children']:
            if subcmd['type'] == 'BASH-AND-IF':
                cmd_list += split_bash(subcmd)
            else:
                cmd_list.append({
                    'type':'DOCKER-RUN',
                    'children':[
                        {
                            'type':'BASH-SCRIPT',
                            'children':[
                                subcmd
                            ]
                        }
                    ]
                })
    elif cmd['type'] == 'BASH-AND-IF':
        for subcmd in cmd['children']:
            cmd_list.append({
                    'type':'DOCKER-RUN',
                    'children':[
                        {
                            'type':'BASH-SCRIPT',
                            'children':subcmd['children']
                        }
                    ]
            })
    else:
        cmd_list.append(cmd)
    return cmd_list
        

def clean():
    global assign_pair
    assign_pair = {}
    
    