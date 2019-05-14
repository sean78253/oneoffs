# refer to https://www.google.com/search?client=firefox-b-1-d&q=python+define+and+return+variable
# To do the serial gram in bash - x=`grep ^Serial /proc/cpuinfo | awk '{print $3}'`
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

