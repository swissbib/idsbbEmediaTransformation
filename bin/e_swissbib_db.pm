# e_swissbib_db.pm - database interface for e_swissbib
# 09.06.2016 andres.vonarx@unibas.ch

use DBI;
use strict;

my $DBHOST     = 'localhost';
my $DB_NAME    = 'e_swissbib_test';
my $DBUSER     = 'e_swissbib_staff';
my $DBPASSWORD = 'x0vA82';

our $dbh = DBI->connect( "DBI:mysql:database=$DB_NAME;host=$DBHOST", 
        $DBUSER, $DBPASSWORD, {RaiseError => 1, PrintError => 0});

sub which_db_host { $DBHOST };
