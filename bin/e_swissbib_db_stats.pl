#!/usr/bin/perl

=for doku

e_swissbib_db_stats.pl
    print stats of table e_swissbib.emedia to "data/shadow_statistik.txt"

history
    10.06.2016 beta / ava
    31.03.2017 Anpassung für E-Zeitschriften / bmt
 
=cut

use Data::Dumper; $Data::Dumper::Indent=1;$Data::Dumper::Sortkeys=1;
use FindBin;
use POSIX 'strftime';
use Sys::Hostname;
use Config::Simple;
my $cfg = new Config::Simple('/opt/scripts/e-books/bin/idsbb_emedia.conf');

binmode(STDOUT,":utf8");
use strict;
use utf8;
use lib $FindBin::Bin;
use e_swissbib_db;

# ---------------------------
# input data sets
# ---------------------------
my @Sets = ( 
    'BS',
    'BE',
    'SBS',
    'SBE',
    'BBZ',
    'EHB',
    'FREE',
    'SFREE',
);

# ---------------------------
# local files and dirs
# ---------------------------
my $DATA_DIR = $cfg->param('DATADIR'); 
my $STATS = $DATA_DIR .'/shadow_statistik.txt';
open(F,">$STATS") or die "cannot append to $STATS: $!";

# ---------------------------
# get data
# ---------------------------
our $dbh;
my $count;
my $mysql_host = which_db_host;
print F <<EOD;
-----------------------------------------------------
record IDs in table e_swissbib.emedia @ $mysql_host
-----------------------------------------------------
MARC published:
EOD
$count = $dbh->selectrow_array("select count(*) from emedia where MARC=1");
printf F ("- total records:    %12.12s\n", pnum($count));
foreach my $set ( sort @Sets ) {
    $count = $dbh->selectrow_array("select count(*) from emedia where Hol$set=1 and MARC=1");
    printf F ("- holdings %-8.8s %12.12s\n", $set .':', pnum($count));
}
print F <<EOD;

MARC not yet published:
EOD
$count = $dbh->selectrow_array("select count(*) from emedia where MARC=0");
printf F ("- total records:    %12.12s\n", pnum($count));
foreach my $set ( sort @Sets ) {
    $count = $dbh->selectrow_array("select count(*) from emedia where Hol$set=1 and MARC=0");
    printf F ("- holdings %-8.8s %12.12s\n", $set .':', pnum($count));
}
print F <<EOD;
-----------------------------------------------------
EOD
    
sub pnum {
    local $_ = int(shift);
    while ( /\d{4}/ ) {
        s|(\d+)(\d\d\d)|$1'$2|;
    }
    $_;
}
