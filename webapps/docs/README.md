To "deploy" these documents, I did the following:

1. Made a local clone of this repo (Tools) on the target server (in this case, dev.cspace).

2. 

  cd Tools/
  git pull -v
  sudo cp -r webapps/docs/webappmanual/ /var/www/html/webappmanual

Then I was able to see the document at:

 https://dev.cspace.berkeley.edu/webappmanual/webappmanual.html

jbl
7/21/2014
