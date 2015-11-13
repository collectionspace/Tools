import csv
import hashlib
import math
import sys


skip_columns = ["id",
                "csid_s",
                "inventoryid_s",
                "inventoryanalyst_s",
                "inventorydate_dt",
                "inventoryiscomplete_b",
                "osteoageestimateverbatim_s",
                "osteoageestimateupper_f",
                "osteoageestimatelower_f",
                "sexdetermination_s",
                "osteoageestimatenote_s",
                "sexdeterminationnote_s",
                "notes_postcranialpathology_s",
                "notes_cranialpathology_s",
                "notes_dentalpathology_s",
                "notes_nhtaphonomicalterations_s",
                "notes_curatorialsuffixing_s",
                "notes_culturalmodifications_s"]


def processHeader(header):
    outputheader =[]
    for j, cell in enumerate(header):
        if header[j] in skip_columns:
            outputheader.append(cell)
    outputheader.append('aggregate_ss')
    return outputheader


with open(sys.argv[2], "wb") as out:
    writer = csv.writer(out, delimiter="\t")
    with open(sys.argv[1], "rb") as original:
        reader = csv.reader(original, delimiter="\t")
        for i, row in enumerate(reader):
            bunch = []
            outputrow = []
            if i == 0:
                writer.writerow(processHeader(row))
                h = row
                continue
            try:
                for j, cell in enumerate(row):
                    if h[j] in skip_columns:
                        outputrow.append(cell)
                    else:
                        if cell == '1':
                            bunch.append(h[j][:-2])
            except:
                raise
                print 'problem!!!'
                print row
                sys.exit()
            outputrow.append((',').join(bunch))
            writer.writerow(outputrow)
