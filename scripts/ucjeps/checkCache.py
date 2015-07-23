__author__ = 'jblowe'

import os


def count(cachedir):
    try:
        filelist = sorted(os.listdir(cachedir))
    except (IOError, OSError):
        return

    numfiles = 0
    numdirs = 0
    sizesinbytes = 0
    for i, k in enumerate(filelist):
        topdir = os.path.join(cachedir, k)
        try:
            for root, _, files in os.walk(topdir):
                numdirs += 1
                for f in files:
                    numfiles += 1
                    sizesinbytes += os.path.getsize(os.path.join(root, f))
                    #countup(os.path.join(root, f))
        except (IOError, OSError):
            pass

    return numfiles, numdirs, sizesinbytes


if __name__ == "__main__":
    import sys
    import time

    #counts, sizeinbytes = count(sys.arg[1])
    print time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),
    print "files %s, dirs %s, size %s" % (count(sys.argv[1]))
