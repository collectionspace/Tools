REM Go to the directory where the XML files are located
cd C:\XmlMerge\example

REM "append" mainBodyGroup to org

java -Xms256M -Xmx1024M -classpath C:\XmlMerge\bin xmlMerge.MergeGeneric organizations_common:shortIdentifier organizations_common:mainBodyGroupList TMSorg_main.xml TMSorg_mainBodyGroup.xml mrg1_mainBodyGroup.xml 0 2 > mrg1_mainBodyGroup.match_id

REM "replace" contactNames from above merged file

java -Xms256M -Xmx1024M -classpath C:\XmlMerge\bin xmlMerge.MergeGeneric organizations_common:shortIdentifier organizations_common:contactNames mrg1_mainBodyGroup.xml TMSorg_relation.xml mrg2_mainBody_relation.xml 0 1 > mrg2_mainBody_relation.match_id
