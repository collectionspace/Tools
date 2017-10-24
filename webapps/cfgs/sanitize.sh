perl -i -pe  's/password          = .*/password          = xxxinsertpasswordherexxx/' *.cfg
perl -i -pe  's/password=(.*?)( |$)/password=xxxinsertpasswordherexxx\2/' *.cfg
