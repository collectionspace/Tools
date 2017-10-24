from smb.SMBConnection import SMBConnection
import codecs, csv, os, re


def uploadCmdrWatch(barcodeFile, dataType, data, config):
    try:
        localslug = re.sub('[^\w-]+', '_', barcodeFile).strip().lower()
        barcodeFh = codecs.open('/tmp/%s' % localslug, 'w', 'utf-8-sig')
        csvlogfh = csv.writer(barcodeFh, delimiter=",", quoting=csv.QUOTE_ALL)
        if dataType == 'locationLabels':
            csvlogfh.writerow('termdisplayname'.split(','))
            for d in data:
                csvlogfh.writerow((d[0],))  # writerow needs a tuple or array
        elif dataType == 'objectLabels':
            csvlogfh.writerow(
                'MuseumNumber,ObjectName,PieceCount,FieldCollectionPlace,AssociatedCulture,EthnographicFileCode'.split(
                    ','))
            for d in data:
                csvlogfh.writerow(d[3:9])
        barcodeFh.close()
    except:
        # raise
        barcodeFile = '<span style="color:red;">could not write to /tmp/%s</span>' % localslug
        return barcodeFile

    try:

        # OK, now we have the file object with the data in it. write it to the
        # commanderWatch server via SMB

        domain = config.get('files', 'domain')
        userID = config.get('files', 'userID')
        password = config.get('files', 'password')
        client_name = config.get('files', 'client_name')
        server_ip = config.get('files', 'server_ip')
        service_name = config.get('files', 'service_name')

        # client_machine_name can be an arbitary ASCII string
        # server_name should match the remote machine name, or else the connection will be rejected
        #
        # SMBConnection(username, password, my_name, remote_name, domain='')
        conn = SMBConnection(userID, password, client_name, service_name, domain, is_direct_tcp=True)
        assert conn.connect(server_ip, 445)

        # storeFile(service_name, path, file_obj, timeout=30)
        # service_name - the name of the shared folder for the path

        barcodeFh = open('/tmp/%s' % localslug, 'rb')
        bytes = conn.storeFile(service_name, barcodeFile, barcodeFh)

        barcodeFh.close()
        os.unlink('/tmp/%s' % localslug)
        return barcodeFile
    except:
        # raise
        os.unlink('/tmp/%s' % localslug)
        barcodeFile = '<span style="color:red;">could not transmit %s to commanderWatch</span>' % barcodeFile
        return barcodeFile
