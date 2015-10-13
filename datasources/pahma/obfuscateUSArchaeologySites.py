import csv
import hashlib
import math
import sys

fieldCollectionTree_column = 36
objecttype_column = 5
latlong_column = 34

with open(sys.argv[2], "wb") as out:
    writer = csv.writer(out, delimiter="\t")
    with open(sys.argv[1], "rb") as original:
        reader = csv.reader(original, delimiter="\t")
        for row in reader:
            try:
                if "United States" in row[fieldCollectionTree_column] and row[objecttype_column] == "archaeology" and row[latlong_column] != '':
                    # obfuscate lat-long

                    # first, get the actual values...
                    latitude = row[latlong_column].split(",")[0]
                    longitude = row[latlong_column].split(",")[1].strip()
                    # 'fieldCollectionTree_column' is the constant we will be hashing with
                    # (we want to hash to the same value each run, lest someone try to 'zero in' using multiple
                    # observations of the portal data...)
                    location = row[fieldCollectionTree_column]

                    # get md5 hash of secret value, convert to int, normalize this to range of -.05 to .05 degrees
                    lat_offset = int(hashlib.md5(location).hexdigest(), 16)
                    lat_offset = (lat_offset + 0.0) / int("9" * len(str(lat_offset)))  # Clamp value to 0 to 1
                    latitude = float(latitude) + (lat_offset - 0.5) / 10
                    
                    long_offset = int(hashlib.md5(location.encode('rot13')).hexdigest(), 16)
                    long_offset = (long_offset + 0.0) / int("9" * len(str(long_offset)))  # Clamp value to 0 to 1
                    longitude = float(longitude) + (long_offset - 0.5) / 10

                    row[latlong_column] = "%s,%s" % (latitude, longitude)
            except:
                print 'problem!!!'
                print row
                sys.exit()

            writer.writerow(row)
