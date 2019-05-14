# refer to https://www.google.com/search?client=firefox-b-1-d&q=python+define+and+return+variable
# To do the serial number in bash - x=`grep ^Serial /proc/cpuinfo | awk '{print $3}'`
# General use case is a python script RESTful call where you need to know which Pi is talking to you.
# Sure, it can be hand set to whatever serial number a evil person wants to set, but in my use case there
# are other unrelated to the PI itself that have unique serial numbers, so I'll know if someone is farting around. 

def getserial():
  # Extract serial from cpuinfo file
  cpuserial = "0000000000000000"
  try:
    f = open('/proc/cpuinfo','r')
    for line in f:
      if line[0:6]=='Serial':
        cpuserial = line[10:26]
    f.close()
  except:
    cpuserial = "ERROR000000000"

  return cpuserial

ser = getserial()

print (ser)

