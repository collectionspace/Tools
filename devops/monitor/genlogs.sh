t=$1
grep -h INFO ~/${t}/logs/logfile.txt* | grep -v AuthN | grep -v accountperms | grep -v delete| perl -pe 's/\[(.*?) (.*?)\] (\w+) \[(.*?)\] (.*?) :: (.*?) :: (.*?)( :: .*?)?/${t}\t\1\t\2\t\3\t\4\t\5\t\6\t\7\t\8/'  > ${t}.temp1
grep -h DEBUG ~/${t}/logs/logfile.txt* | grep -v 'could not authenticate' | perl -pe 's/\[(.*?) (.*?)\] (\w+) \[(.*?)\] User: (.*) authenticated with Host: (.*)/${t}\t\1\t\2\t\3\t\4\t\5\t\6/' >> ${t}.temp1
cat ${t}.temp1 ${t}.django.log | sort -u > ${t}.temp2
mv ${t}.temp2 ${t}.django.log
rm ${t}.temp*
cut -f5 ${t}.django.log | perl -pe 's/:\d+//;s/.(views|authn|utils)//' | sort |uniq -c | sort -rn | head -20 > ${t}.logsummary.txt
echo "	${t}" > ${t}.temp.txt
perl -ne 's/^ *(\d+) (.*)$/\2\t\1/;print unless (length > 25)' ${t}.logsummary.txt | sort >> ${t}.temp.txt
#echo "<hr/><h3>${t}</h3><hr/><pre>" >> summary.html
#echo "`cut -f2 ${t}.django.log | sort -u | perl -pe 's/\// /g' | sort -k3 -k2M -k1 | wc -l` days have activity" >> summary.html
#echo "`cut -f2 ${t}.django.log | sort -u | perl -pe 's/\// /g' | sort -k3 -k2M -k1 | head -1` start" >> summary.html
#echo "`cut -f2 ${t}.django.log | sort -u | perl -pe 's/\// /g' | sort -k3 -k2M -k1 | tail -1` end" >> summary.html
#echo "" >> summary.html
#cat ${t}.logsummary.txt >> summary.html
#echo "</pre>" >> summary.html
