# idsbbEmediaTransformation
Scripts to transform Proquest metadata for import into swissbib.

Author: Andres von Arx, Basil Marti

The shell skript make-idsbb-emedia.sh runs different Perl scripts in order to transform Proquest metadata exported from Intota ERM 
into swissbib.

In order to run the script sucessfully the bin directory has to be present on the ub-catmandu server under /opt/scripts/e-book/bin.
The files downloaded from the Proquest ftp-server, temp files, the end result of the transformation and the log files are stored
under /opt/data/e-books/ when using the MASTER branch. For the TEST branch a corresponding directory exists under 
/opt/data/e-books_test/. The data directories are not managend by git.

To start the process, start make-idsbb-emedia.sh. Attention: When running the script productively, 
make sure the MASTER branch is active.

When switching branches, the following files are important:

idsbb_emedia.conf -> contains branch-specific information (path to directories, and the path to the hidden conf file).

idsbb_emedia_hidden.conf/idss_emedia_hidden_test.conf -> contains sensitive information (e-mail-adresses and passwords). 
Accordingly, it is not managed by git and is present in two versions (for the MASTER and the TEST branches) on the ub-catmandu 
server.

e_swissbib_db.pm -> Perl module with information about the shadow-databases used in the script. The MASTER version points to a
mysql database on ub-filesvm, the TEST version to a similar database on ub-catmandu.




