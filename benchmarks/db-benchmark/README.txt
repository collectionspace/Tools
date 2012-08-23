README.txt
For the database benchmarking script, db_benchmark.pl
Updated 2012-08-22

In an effort to obtain better data about the database optimizations
we try, I've written a benchmarking script. The script takes as
arguments one or more sql files, and/or directories containing sql
files. For the query contained in each sql file, it will run EXPLAIN
ANALYZE a number of times (default 10), and store the results. It will
also store the postgres configuration settings, database descriptions
(including indexes that exist), and OS kernel parameters (e.g. shmmax,
shmall) at the time of execution.

To display usage instructions, run the script without arguments.
E.g. from the current directory:

./db_benchmark.pl

Ray Lee
Informatics Services
University of California, Berkeley

