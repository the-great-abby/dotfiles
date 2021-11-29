import sys, json
import os
from os import listdir
from os.path import isfile, join

# from os import walk
pathToSearch = "/home/user/.aws/sso/cache/"
# filenames = next(walk(pathToSearch), (None, None, []))
onlyfiles = [f for f in listdir(pathToSearch) if isfile(join(pathToSearch, f))]

for a in onlyfiles:
    print join(pathToSearch, a)
    if "botocore" in a:
        f = open(join(pathToSearch, a))
        data_f = json.load(f)
    else:
        g = open(join(pathToSearch, a))
        data_g = json.load(g)

# Build secrets
print os.environ["AWS_SECRET_ACCESS_KEY"]
os.environ["AWS_SECRET_ACCESS_KEY"] = data_g["accessToken"]
os.environ["AWS_ACCESS_KEY_ID"] = data_f["clientId"]
os.environ["AWS_SESSION_TOKEN"] = data_f["clientSecret"]
AWS_SECRET_ACCESS_KEY = data_g["accessToken"]
AWS_ACCESS_KEY_ID = data_f["clientId"]
AWS_SESSION_TOKEN = data_f["clientSecret"]

print "export AWS_SECRET_ACCESS_KEY='" + AWS_SECRET_ACCESS_KEY + "'"
print "export AWS_ACCESS_KEY_ID='" + AWS_ACCESS_KEY_ID + "'"
print "export AWS_SESSION_TOKEN='" + AWS_SESSION_TOKEN + "'"

