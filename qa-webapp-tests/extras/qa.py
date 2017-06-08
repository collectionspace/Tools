from bs4 import BeautifulSoup
from collections import Counter
import sys

# directions:
#
# 1. save 'https://wiki.collectionspace.org/display/collectionspace/Testing+Tasks+Release+4.3' on your local
#    system as, say, 'qa1.html'
#
# 2. python qa.py qa1.html > qastatus.html
#
# (you have to save the page from a browser because the javascript in the page must be executed to
# set the values; if you just wget or curl the page, this does not happen.

url = sys.argv[1]

columns = ['', 'started', 'done']

done = Counter()
started = Counter()
testers = Counter()

tests = {'started': 0, 'done': 0, 'counted': 0, '': 0}

soup = BeautifulSoup(open(url))

print '<html>\n<div><h1>QA Status</h1>\n'
print '<table border="1" width="100%">'
for tr in soup.find_all('tr'):
    for td in tr:
        for a in td.find_all('a'):
            print '<tr><td style="width: 440px;">'
            print a
            tests['counted'] += 1

        for t in 'Chrome Safari Firefox'.split(' '):
            if t in td.text:
                print '<td>%s' % t
                break

    column = -1
    for li in tr.find_all('li'):
        if 'class' in li.attrs:
            if li['class'][0] == u'checked':
                column += 1
                try:
                    status = columns[column]
                except:
                    status = ''
                if status != '': print '<td>%s' % status
                tests[status] += 1
                if column == 0:
                    tester = li.text.encode('ascii', 'ignore')
                    print '<td>%s' % tester
                testers[tester] += 0
                if status == 'done':
                    testers[tester] += 1
                    done[tester] += 1
                elif status == 'started':
                    started[tester] += 1

print '</table></div>'

tests['unstarted'] = tests['counted'] - tests['started']

print '<div><h1>Leaderboard</h1>'
print '<h4>'
for t in tests:
    if t != '': print 'tests %s = %s ' % (t, tests[t])
print '</h4>'
print '<table border="1" width="100%"><tr>'
for h in 'tester started done'.split(' '):
    print '<th>%s' % h
for t in testers.most_common():
    print "<tr><td>%s<td>%s<td>%s" % (t[0], started[t[0]], done[t[0]])
print '</table></div></html>'
