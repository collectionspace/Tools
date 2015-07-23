import sys
import fileinput

# rewrite the fruiting and flowering values as character arrays, as follows:
#
# t|f|f|f|f|f|f|f|f|f|t|f => jan|dec
# No|No|No|No|No|No|No|Some|Many|No|No|No => aug|sep
#

months = 'jan feb mar apr may jun jul aug sep oct nov dec'.split(' ')


def rpl(values, trigger):
    result = []
    for i, m in enumerate(values.split('|')):
        if m in trigger:
            result.append(months[i])
    return '|'.join(result)

if __name__ == "__main__":

    for i,line in enumerate(fileinput.input()):
        datacolumns = line.split('\t')
        datacolumns[54] = rpl(datacolumns[54],['t',])
        datacolumns[55] = rpl(datacolumns[55],['Some','Many'])
        print '\t'.join(datacolumns)


