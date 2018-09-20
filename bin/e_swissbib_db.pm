# e_swissbib_db.pm - database interface for e_swissbib
# 09.06.2016 andres.vonarx@unibas.ch

use DBI;
use Config::Simple;
my $cfg = new Config::Simple('/opt/scripts/e-books/bin/idsbb_emedia.conf');
my $cfg_hidden = new Config::Simple($cfg->param('HIDDENCONF'));
use strict;

my $DBHOST     = 'localhost';
my $DB_NAME    = 'e_swissbib_test';
my $DBUSER     = 'e_swissbib_staff';
my $DBPASSWORD = $cfg_hidden->param('DBPASSWORD');

our $dbh = DBI->connect( "DBI:mysql:database=$DB_NAME;host=$DBHOST", 
        $DBUSER, $DBPASSWORD, {RaiseError => 1, PrintError => 0});

sub which_db_host { $DBHOST };
