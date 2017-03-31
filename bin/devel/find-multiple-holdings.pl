#!/usr/bin/perl

=for doku

Das Skript findet Records, die für eine Site mehrere Holdings haben.
Diese Holdings (Feld 949) unterscheiden sich nur in der URL.
Einige Aufnahmen wie ssib002621584 ("Topographischer Atlas vom Königreiche
Bayern") haben bis zu 118 Felder 949.

13.10.2016/ava

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
use strict;

my $XML='/opt/data/e-books/data/basel-bern-emedia.xml';
( -f $XML ) or die "cannot read $XML: $!";
my $marc =  MARC::File::XML->in($XML);

while ( my $rec = $marc->next() ) {
    my $ssid = $rec->field('001')->data;
    my $hol;
    foreach my $f ( $rec->field('949') ){
        my $sub = $f->subfield('b');
        $hol->{$sub} += 1;
    }
    foreach my $key ( keys %$hol ) {
        if ( $hol->{$key} > 1 ) {
            print $ssid, "\t", $key, "\t", $hol->{$key}, "\n";
        }
    }
}
$marc->close;
