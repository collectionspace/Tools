def fixdate(datestring):
    # in data:  EEE, dd MMM yyyy HH:mm:ss 
    # in Solr:       yyyy-MM-dd'T'hh:mm:ss
    #
    # not yet handled
    #
    # 13 Aug 09 / 18:59:31
    # 2009-06-01T18:51:04+00:00
    # 27.10.2008
    # Thu, 13 Aug 2009 14:00  -0400
    #  4 Aug 2009
    # 2009-08-13
    # Thu, 13 August 2009 13:56:52 +12:00
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

