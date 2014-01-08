"""
A collection of functions for processing parent-child lists into hierarchical dictionaries.
The goal, which buildConceptDict accomplishes, is to go from a list like this:

    inp = [['San Francisco','California'], ['California','United States'], ['North America',None], ['Africa',None],\
    ['New York','United States'], ['United States','North America'], ['Angola','Africa'], ['Eastern Cape','South Africa'],\
    ['South Africa','Africa'], ['Rapa Nui',None]]
    
to a dictionary like this:

    res = {PARENT: ['Rapa Nui', {'North America': [{'United States': ['New York', {'California': ['San Francisco']}]}]}, {'Africa':\
    ['Angola', {'South Africa': ['Eastern Cape']}]}]}

Or in hierarchical form:

    <PARENT>
        Rapa Nui
        North America
            United States
                New York
                California
                    San Francisco
        Africa
            Angola
            South Africa
                Eastern Cape


Additionally, if a non-null root value is already set, the "if pair[3] == NONE:" statement in nullStrip()
should be replaced with "if pair[3] == <ROOT_VALUE>:". Bear in mind that the final root value is controlled by PARENT.

-----------------------------------

N.B.: The old two-column list has been replaced by a list of the form [[childName, parentName, childID, parentID],[...]...].
The hierarchy is now built from the third and fourth rows and displayed using the first and second.

"""

#This should be set to whatever the root value should be.
PARENT = 'ROOT'


def buildConceptDict(l):
    """
    Wrapper that takes in a 4-column list L and builds a hierarchical dictionary from the 3rd and 4th column of each row.
    (The first & second rows are the display names of the third & fourth rows).
    """
    return dictBuilder(nullStrip(l))


def nullStrip(l):
    """Strips out all the null values in the third column of a list L, replacing them with PARENT."""
    for pair in l:
        if pair[3] == None:
            pair[3] = PARENT
    return l


def dictBuilder(l, root=PARENT):
    """
    Takes in a list of child-parent pairs L and a root value ROOT and returns a hierarchical dictionary, maintaining sorting.
    """
    seen = 0
    d = {root: []}
    for pair in l:
        if pair[3] != root and seen:
            break
        if pair[3] == root:
            if seen == 0:
                seen = 1
            d[root].append(dictBuilder(l, pair[2]))
    if d == {root: []}:
        return root
    return d


def stripRoot(res):
    """Removes the ROOT level from the JSON tree"""
    res = res[:res.rfind(',]}')]
    return res.replace('{ label: "' + PARENT + '",\nchildren: [', '')


def buildJSON(d, indent=0, lookup=None):
    """
    Given a dictionary D, an optional initial indent INDENT, and a lookup table LOOKUP,
    returns a string representation of the tree needed for jqTree without a root level.
    """
    return stripRoot(makeJSON(d, indent, lookup))


def makeJSON(d, indent=0, lookup=None):
    """
    Given a dictionary D, an optional initial indent INDENT, and a lookup table LOOKUP,
    returns a string representation of the tree needed for jqTree.
    """
    res = ''
    if not (lookup):
        print '<tr>NO LOOKUP TABLE!</tr>'
    space = ' '
    if not (isinstance(d, dict)):
        res += space * indent + '{ label: "' + str(lookup[d]) + '"}\n'
    for key in d:
        res += space * indent + '{ label: "' + str(lookup[key]) + '",\n'
        if isinstance(d[key], basestring):
            res += space * indent + '{ label: "' + str(lookup(d[key])) + '"}\n'
        else:
            res += space * indent + 'children: [\n'
            for val in d[key]:
                if isinstance(val, dict):
                    res += makeJSON(val, indent + 4, lookup)
                else:
                    res += space * (indent + 4) + '{ label: "' + str(lookup[val]) + '"},\n'
        if indent:
            res = res[:-2]
            res += ']},\n'
        else:
            res = res[:-1]
            res += ']}'
    return res


def printDict(dictionary, indent=0, lookupTable=None):
    """
    Given a dictionary and an optional initial indent, prints the dictionary hierarchically, i.e.:
    <ROOT>
        <LEVEL 1>
            <LEVEL 2>
            <LEVEL 2>
        <LEVEL 1>
            <LEVEL 2>
                <LEVEL 3>
        <LEVEL 1>
        ... etc...
    """
    if not (lookupTable):
        print '<tr>NO LOOKUP TABLE!</tr>'
    space = ' '
    if not (isinstance(dictionary, dict)):
        print '<tr><th align="left"><pre>' + space * indent + str(lookupTable[dictionary]) + '</pre></tr>'
    for key in dictionary:
        print '<tr><th align="left"><pre>' + space * indent + str(lookupTable[key]) + '</pre></tr>'
        if isinstance(dictionary[key], basestring):
            print '<tr><th align="left"><pre>' + space * (indent + 4) + str(
                lookupTable[dictionary[key]]) + '</pre></tr>'
        else:
            for val in dictionary[key]:
                if isinstance(val, dict):
                    printDict(val, indent + 4, lookupTable)
                else:
                    print '<tr><th align="left"><pre>' + space * (indent + 4) + str(lookupTable[val]) + '</pre></tr>'


if __name__ == '__main__':

    import sys
    import cswaDB as cswaDB
    from cswaUtils import getConfig, doHierarchyView

    #authoritylist = [ \
    #    ("Ethnographic Culture", "concept"),
    #    ("Places", "places"),
    #    ("Archaeological Culture", "archculture"),
    #    ("Ethnographic File Codes", "ethusecode"),
    #    ("Materials", "material_ca")
    #]

    form = {'authority': 'material_ca', 'webapp': 'hierarchyViewerDev' }
    config = getConfig(form)

    doHierarchyView(form, config)
    #sys.exit()

    res = cswaDB.gethierarchy('material_ca', config)

    PARENT = 'ROOT'
    lookup = {PARENT: PARENT}
    #for row in res:
    #    prettyName = row[0].replace('"', "'")
    #    if prettyName[0] == '@':
    #        prettyName = '<' + prettyName[1:] + '>'
    #    lookup[row[2]] = prettyName
    #print '''var data = ['''
    #print concept.buildJSON(concept.buildConceptDict(res), 0, lookup)
    d = buildConceptDict(res)
    for top in d[PARENT]:
        if type(top) == type('str'): print top
    #print d
    #if sys.argv[2] == '-j' or sys.argv[2] == '-J':
    #    print makeJSON(d) #doesn't actually work anymore without lookup table
    #else:
    #    printDict(d) #doesn't work either for the same reason
