import sys

tables_backed_up = {}
for line in open(sys.argv[1],'rb').readlines():
    (vocab_list, db_table, db_column) = line.strip().split(',')
    print "select distinct %s from %s;" % (db_column, db_table)
    if db_table in tables_backed_up:
        pass
    else:
        tables_backed_up[db_table] = "select * into %s_backup from %s;" % (db_table,db_table)

for table in tables_backed_up:
    print tables_backed_up[table]
    print "drop table %s_backup;" % table
    print "truncate table %s ; insert into %s select * from %s_backup;" % ((table,) * 3)
