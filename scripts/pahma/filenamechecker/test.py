# does an 'approximate search' for a PAHMA object number
# (not a normal test.py module. invoke as "python test.py", but check the checkfilenamesProd.cfg file)
from cswaExtras import getConfig, getCSID
form = {'webapp': 'checkfilenamesProd'}
config = getConfig(form)
objectnumber = '5-1758'
print getCSID('approxobjectnumbers', objectnumber, config)

