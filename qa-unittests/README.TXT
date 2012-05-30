Please read http://wiki.collectionspace.org/display/collectionspace/Running+Automated+QA+Tests



SUMMARY
For some of the more time consuming tests, we have as a temporary solution implemented some test automation using Selenium. These tests are amongst other deletion of records, leave edited page warning, cancel button and checking whether all fields are saved. This has been done for primary tab of all procedural and cataloging records as well as for the secondary tab.

This page explains how to run these automated tests.



PREREQUISITES:
To run the tests you need to have java and ant installed. To do this under windows:

Download and install Java JDK 6

Open this page in a browser: http://www.oracle.com/technetwork/java/javase/downloads/index.html
click the "Java Download" button with the text "Java Platform (JDK)" written underneath it.
This will bring you to a listing of downloads. If you are on a 32-bit machine, select the Windows x86 link, if you are under 64-bit, download Windows x64 .. Or if in doubt just default to the x86 one.
Once you accept licence terms agreement, download should start, and once done the program should guide you through the installation. Make sure you notice (or choose) where java is installed - you'll need that info for when installing ant.
Finally set the JAVA_HOME environment variable by opening the console and typing: set JAVA_HOME=C:\path_to\java\jdk1.6.0_02 - typing in the location where you install java

Download and install ant

Go to http://code.google.com/p/winant/
Use the link under "get it" to download ant
Open the downloaded file and follow the instructions



RETRIEVING THE CODE
The code can be found on GitHub: https://github.com/collectionspace/Tools. To download it as a zip-file, either go to the GitHub page, click the download button, and select how you want to download it. Alternatively, use this direct link to get a zipped version of the file: https://github.com/collectionspace/Tools/zipball/master

Once you got the file unpack it.



RUNNING THE AUTOMATED TESTS
Running the tests consist of two steps; starting a selenium server and running the actual tests. This is explained below.

Starting the Selenium server
Assuming you are in the root of the code downloaded from git:

----
home$ cd lib
home$ java -jar selenium-server-standalone-2.3.0.jar
----

tip: If you want to run the Selenium server on a specific port, use:
   ----
   home$ java -jar selenium-server-standalone-2.3.0 -port 8888
   ----


Running Primary Tab Tests:
Assuming you're in the root of the downloaded code, enter the following to run the tests against the QA server:
----
home$ ant primaryTabTests
----

tip:
   If you are running the selenium server on another port than the default (port 4444), you can set this using the portnum parameter, like so:
   ----
   home$ ant primaryTabTests -Dportnum=8888
   ----

   If you want to test against another server - localhost for example, use the baseurl parameter, like so:
   ----
   home$ ant primaryTabTests -Dbaseurl=http://localhost:8180/collectionspace/ui/core/html/
   ----

   Of course, these can be combined, like so:
   ----
   home$ ant primaryTabTests -Dportnum=8888 -Dbaseurl=http://localhost:8180/collectionspace/ui/core/html/
   ----
   Where 8888 is substituted with the desired portnumber.


Running Secondary Tab Tests Only:
Assuming you're in the root of the downloaded code:
----
home$ ant secondaryTabTests -Dbaseurl=http://qa.collectionspace.org:8180/collectionspace/ui/core/html/
----

If you are running the selenium server on another port than the default (port 4444), you can set this using the portnum parameter, like so:
----
home$ ant secondaryTabTests -Dportnum=8888
----

If you want to test against another server - localhost for example, use the baseurl parameter, like so:
----
home$ ant secondaryTabTests -Dbaseurl=http://localhost:8180/collectionspace/ui/core/html/
----

Of course, these can be combined, like so:
----
home$ ant secondaryTabTests -Dportnum=8888 -Dbaseurl=http://localhost:8180/collectionspace/ui/core/html/
----