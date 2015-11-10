import csv
import hashlib
import math
import sys

hashkey_column = 33
fieldCollectionTree_column = 36
objecttype_column = 5
latlong_column = 34


def pol2cart(rho, phi):
    x = rho * math.cos(phi)
    y = rho * math.sin(phi)
    return (x, y)


with open(sys.argv[2], "wb") as out:
    writer = csv.writer(out, delimiter="\t")
    with open(sys.argv[1], "rb") as original:
        reader = csv.reader(original, delimiter="\t")
        for row in reader:
            try:
                if "United States" in row[fieldCollectionTree_column] and row[objecttype_column] == "archaeology" and row[latlong_column] != '':
                    # obfuscate lat-long

                    # first, get the actual values...
                    latitude = row[latlong_column].split(",")[0].strip()
                    longitude = row[latlong_column].split(",")[1].strip()

                    # read PAHMA-1408 for details of why this is the way it is
                    # 'hashkey_column' is the constant we will be hashing with
                    # (we want to hash to the same value each run, lest someone try to 'zero in' using multiple
                    # observations of the portal data...)
                    location = row[hashkey_column]
                    modulus = 0.2

                    # get md5 hash of secret value, convert to int, normalize this to range of -.05 to .05 degrees
                    lat_offset = int(hashlib.md5(location).hexdigest(), 16)
                    lat_offset = (lat_offset + 0.0) / int("9" * len(str(lat_offset)))  # Clamp value to 0 to 1
                    lat_offset = (lat_offset % modulus) / modulus

                    long_offset = int(hashlib.md5(location[::-1]).hexdigest(), 16)
                    long_offset = (long_offset + 0.0) / int("9" * len(str(long_offset)))  # Clamp value to 0 to 1
                    long_offset = (long_offset % modulus) / modulus

                    # pretend these a polar coordinates and convert them to cartesian coordinates
                    latlongoffset = pol2cart(math.sqrt(lat_offset), long_offset * 2 * math.pi)
                    latlongoffset = [r * 0.05 for r in latlongoffset]

                    latitude = float(latitude) + latlongoffset[0]
                    longitude = float(longitude) + latlongoffset[1]
                    row[latlong_column] = "%s,%s" % (latitude, longitude)
            except:
                print 'problem!!!'
                print row
                sys.exit()

            writer.writerow(row)
