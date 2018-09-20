#!/usr/bin/perl

=for doku

initial-load-e_swissbib-db.pl
    Das Skript initialisiert die DB-Tabelle e_swissbib.emedia.
    
Input: 
    /opt/data/e-books/data/basel-bern-emedia.xml
    MARC-XML-Datei aller E-Media mit gemergeten Holdings.

ACHTUNG:
    - Auswahl des MySQL-Hosts (ub-filesvm oder ub-filesqm) in ../e_swissbib_db.pm
    - vor Ausfuehren muss die DB und die Tabelle angelegt sein
.
    Datenbank anlegen:
        create-e_swissbib-db.sql in:
            GEVER 159/server_und_netzwerk/fileserver/datenbanken
.
    Tabelle anlegen:
        devel/create-e_swissbib-table.sql
    
History:
    09.06.2016 - andres.vonarx@unibas.ch
    04.04.2017 - basil.marti@unibas.ch: Anpassung fuer E-Serials

=cut

use MARC::Batch;
use MARC::Record;
use MARC::Field;
use MARC::File::XML (BinaryEncoding => 'utf8', RecordFormat => 'MARC21' );

use Data::Dumper;
use HTML::Entities();
use POSIX qw(strftime);
use Sys::Hostname;
binmode(STDOUT,":utf8");
use lib '..';
use e_swissbib_db;
use strict;

my $host = which_db_host();
print<<EOD;

host:   $host
table:  e_swissbib.emedia
source: basel-bern-emedia.xml

EOD

@print "komplett neu aufbauen [j/N] ? ";
my $ans = <STDIN>;
exit unless $ans =~ /j/i;

my $PACIF = 500;
my $pacif = $PACIF;
$|=1;

print strftime("START: %Y-%m-%d %H:%M:%S\n",localtime);

my $XML;
if ( hostname eq 'ub-catmandu' ) {
    $XML='/opt/data/e-books_test/data/basel-bern-emedia.xml';
} else {
    $XML = '../../data/basel-bern-emedia.xml';
}
( -f $XML ) or die "cannot read $XML: $!";
my $marc =  MARC::File::XML->in($XML);

our $dbh;
$dbh->do('truncate table emedia');

my $today = strftime("%Y-%m-%d",localtime);
while ( my $rec = $marc->next() ) {
    my $ssid = $rec->field('001')->data;
    my($HolBS,$HolBE,$HolBBZ,$HolEHB,$HolFREE,$HolSFREE);
    $HolBS = $HolBE = $HolBBZ = $HolEHB = $HolFREE = $HolSFREE = 0;
    foreach my $f ( $rec->field('949') ){
        my $sub = $f->subfield('b');
        if ( $sub eq 'A145' ) {
            $HolBS=1;
        } elsif ( $sub eq 'B405' ) {
            $HolBE=1;
        } elsif ( $sub eq 'B406' ) {
            $HolBBZ=1;
        } elsif ( $sub eq 'B407' ) {
            $HolEHB=1;
        } elsif ( $sub eq 'FREE' ) {
            $HolFREE=1;
        } 
    }
    
    foreach my $f ( $rec->field('852') ){
        my $sub = $f->subfield('b');
        if ( $sub eq 'FREE' ) {
            $HolSFREE=1;
        }
    }
    
    my $sql = qq|INSERT INTO emedia VALUES ('$ssid',$HolBS,$HolBE,$HolBBZ,$HolEHB,$HolFREE,1,'$today',$HolSFREE)|;
    $dbh->do($sql);
    unless ( $pacif-- ) {
        $pacif = $PACIF;
        print '.';
    }
}
$marc->close;
$dbh->disconnect;

print strftime("\nEND: %Y-%m-%d %H:%M:%S\n",localtime);
