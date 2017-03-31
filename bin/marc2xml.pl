#!/usr/bin/perl

# marc2xml.pl - konvertiere marc.mrc nach marc.xml
# 
# history:
#   19.12.2012/ava


use Getopt::Long;
use MARC::File::USMARC;
use MARC::File::XML (BinaryEncoding => 'utf8', RecordFormat => 'MARC21' );
use strict;

my $MaxRec=0;      # nnn = Limite (für Tests). 0 = keine Limite

sub usage {
    print STDERR <<EOD;
usage: perl [options] marc2xml.pl marcfile

converts an ISO 2790 MARC file to MARC21 XML

options:
--force  -f   force overwriting of xml file

example: perl marc2xml.pl beispiel.mrc
         (will produce beispiel.xml)

EOD
    exit;
}

# -- arguments and options 
my $force;
GetOptions("force" => \$force ) or usage;
my $USMARC = shift @ARGV;
( -f $USMARC ) or usage;
my $XML = $USMARC;
$XML =~ s/\.mrc$//;
$XML .= '.xml';
if ( -f $XML && ! $force ) {
    print "xml file already exists. use '-f' option\n\n";
    usage;
}

# -- conversion
my $counter=0;
my $marcfile = MARC::File::USMARC->in( $USMARC );
my $xmlfile  = MARC::File::XML->out( $XML );
while ( my $rec = $marcfile->next() ) {
    $xmlfile->write($rec);
    $counter++;
    exit if ( $MaxRec && $counter > $MaxRec );
}
$xmlfile->close;
