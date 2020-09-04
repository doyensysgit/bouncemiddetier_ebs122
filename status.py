import os
pwd=os.getenv("WL_PWD")
url=os.getenv("WL_URL")
oacorelst=os.getenv("OACORE_LIST")
location=os.getenv("HOME")
connect('weblogic',pwd,url)
filename = open(oacorelst,"r")
for line in filename:
        server_name=line.strip()
        status (server_name,'Server')
filename.close()