def fixdate(datestring):
    # in Solr:       yyyy-MM-ddThh:mm:ssZ
    #
    try:
        d = datetime.datetime.strptime(datestring, "%Y-%m-%dT%H:%M:%SZ")
        return datestring
    except:
        try:
            datestring = datestring[0:25]
            datestring = datestring.strip()
            d = datetime.datetime.strptime(datestring, "%a, %d %b %Y ")
            return d.strftime("%Y-%m-%dT%H:%M:%SZ")
        except:
            try:
                datestring = datestring.strip()
                datestring = datestring[0:19]
                d = datetime.datetime.strptime(datestring, "%Y/%m/%d")
                return d.strftime("%Y-%m-%dT%H:%M:%SZ")
            except:
                d = datetime.datetime.utcnow()
                return d.strftime("%Y-%m-%dT%H:%M:%SZ")

