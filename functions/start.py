import os
servers=os.listdir("mcserver")
server_cores=[]
server_name=[]
server_versions=[]
punctuation="-"
for server in servers:####列出服务器核心、名称、版本
    jx=server.split(punctuation)
    server_cores.append(jx[0])
    server_name.append(jx[1])
    server_versions.append(jx[2])