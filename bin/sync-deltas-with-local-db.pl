#!/usr/bin/perl

=head1 NAME

sync-deltas-with-local-db.pl

=head1 SYNOPSIS

 perl sync-deltas-with-local-db.pl

=head1 DESCRIPTION

Pro ERM-Instanz wird eine CSV-Datei mit den Mutationen geliefert:
    DeleteMonographRecords.csv
    ChangeMonographRecords.csv
    NewMonographRecords.csv

Die Mutationen werden in der lokalen DB e_swissbib.emedia @ ub-filesvm
nachgetragen. Fuer jede Aenderung wird ein Timestamp gesetzt.

Zusaetzlich werden die RunSummary.txt Dateien gemerged nach
*/data/Mono-Delta-RunSummary.txt

Laufzeit: < 1 Minute

=head1 AUTHOR

andres.vonarx@unibas.ch

=head1 HISTORY

 08.06.2016 beta / ava
 
=cut

use Data::Dumper; $Data::Dumper::Indent=1;$Data::Dumper::Sortkeys=1;
use FindBin;
use POSIX 'strftime';
use Sys::Hostname;

binmode(STDOUT,":utf8");
use strict;
use utf8;
use lib $FindBin::Bin;
use e_swissbib_db;

# ---------------------------
# input data sets
# ---------------------------
my @monoSets = ( 
    'BS',
    'BE',
    'BBZ',
    'EHB',
    'FREE',
);

# ---------------------------
# local files and dirs
# ---------------------------
my($DATA_DIR,$DOWNLOAD_DIR);
$DATA_DIR       = '/opt/data/e-books/data';
$DOWNLOAD_DIR   = '/opt/data/e-books/download';
chdir $DOWNLOAD_DIR
    or die( "$0: cannot chdir to $DOWNLOAD_DIR: $!\n");
my $STATS = $DATA_DIR .'/statistik.txt';    
my $stats;

# ---------------------------
# sync monographs
# ---------------------------
our $dbh;    
my $sth = $dbh->prepare("select ssid from emedia where ssid=?");
my $today = strftime("%Y-%m-%d",localtime);

my $MONO_RUN_SUMMARY = $DATA_DIR .'/RunSummary-Mono-Delta.txt';
unlink $MONO_RUN_SUMMARY;

foreach my $set ( @monoSets ) {
    my $dir = $set .'_mono_delta';
    
    system qq|echo "----------------------------------" >> $MONO_RUN_SUMMARY|;
    system qq|echo "Run Summary (Delta Mono) for $set" >> $MONO_RUN_SUMMARY|;
    system qq|echo "----------------------------------" >> $MONO_RUN_SUMMARY|;
    system qq|cat $dir/RunSummary.txt >> $MONO_RUN_SUMMARY|;

    my $file = "$dir/NewMonographRecords.csv";
    if ( -f $file ) {
        print "delta: reading $file\n";
        open(F, "<$file") or die "kann Datei $file nicht lesen: $!";
        $_ = <F>;   # zap header
        while ( <F> ) {
            chomp;
            s/\,.*$//;
            insert_or_update($_,$set);
            $stats->{$set}->{new}++;
        }
    }
    $file = "$dir/ChangeMonographRecords.csv";
    if ( -f $file ) {
        print "delta: reading $file\n";
        open(F, "<$file") or die "kann Datei $file nicht lesen: $!";
        $_ = <F>;   # zap header
        while ( <F> ) {
            chomp;
            s/\,.*$//;
            insert_or_update($_,$set);
            $stats->{$set}->{changed}++;
        }
    }
    $file = "$dir/DeleteMonographRecords.csv";
    if ( -f $file ) {
        print "delta: reading $file\n";
        open(F, "<$file") or die "kann Datei $file nicht lesen: $!";
        $_ = <F>;   # zap header
        while ( <F> ) {
            chomp;
            s/\,.*$//;
            my $sql = "update emedia set Hol$set=0,modified='$today' where ssid='$_'";
            $dbh->do($sql);
            $stats->{$set}->{deleted}++;
        }
    }
}

# print some stats
open(F,">>$STATS") or die "cannot append to $STATS: $!";
print F <<EOD;
-----------------------------------------------------
new/changed/deleted 360MARC messages:
-----------------------------------------------------
EOD
foreach my $key (sort keys $stats ) {
    printf F ("%-8.8s | new:%8.8s | chg:%8.8s | del:%8.8s\n",
        $key,
        pnum($stats->{$key}->{new}), 
        pnum($stats->{$key}->{changed}),
        pnum($stats->{$key}->{deleted}),
        );
}
close F;
sub pnum {
    local $_ = int(shift);
    while ( /\d{4}/ ) {
        s|(\d+)(\d\d\d)|$1'$2|;
    }
    $_;
}

# ---------------------------
sub insert_or_update {
# ---------------------------
    my($id,$set)=@_;
    my $HOL = "Hol$set";
    $sth->bind_param(1,$id);
    $sth->execute;
    my $sql;
    my ($rec) = $sth->fetchrow_arrayref;
    if ( $rec ) {
        $sql = "update emedia set $HOL=1,modified='$today' where ssid='$id'";
    } else {
        $sql = "insert into emedia set ssid='$id',$HOL=1,modified='$today'";
    }
    $dbh->do($sql);
}
