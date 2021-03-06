#!/usr/bin/perl

=head1 NAME

create-full-files.pl

=head1 SYNOPSIS

 perl create-full-files.pl

=head1 DESCRIPTION

The program produces a MARC21 XML file with allupdated E-media
records from all ProQuest ERM, ready for import into Swissbib. It
also produces a list of E-media IDs for which no holdings exist
anymore; these records should be deleted from Swissbib.

=head2 Data sources

=item basel-bern-emedia.xml

A merge of the complete 360MARC files of all ProQuest ERM instances.
Holdings and specific URLs are merged. Converted to MARC21 XML format.

=item e_swissbib.emedia @ ub-filesvm

The local MySQL database e_swissbib contains a table emedia. There
we keep track of all the messages regarding added, new or deleted
files.

=head2 Output

=item sersol-idsbb-emedia-updates.xml

MARC21 XML file for import into Swissbib. 
Must be reformatted, gzipped and uploaded to Swissbib host.

=item sersol-idsbb-emedia-deletions.txt

List of IDSs to be deleted. Note: first line contains date stamp

=head2 Program flow

B<Step 1:> The program queries the emedia table to find IDs whithout
any holdings. It adds these IDs to the deletion list and removes the
record from the table.

B<Step 2:>The program iterates over basel-bern-emedia.xml. It checks
the records ID against the emedia table. It will set the MARC flag
for the record and output the record to sersol-idsbb-emedia-updates.xml 
if one of two conditions are met: (1) The I<modified> field is set to 
the current date, signaling a recent addition, update or deletion.
(2) The MARC flag is not set, signaling that the record has been
reported as addition in an earlier run but the MARC record has not
been delivered.

=head2 Run time

15 minutes (ub-catmandu, 380'000 records total, 2016-06-09)

=head2 CAVEAT

ProQuest/SerialSolutions produces the 360MARC data and the lists for 
new/changed/deleted records asynchronously. Therefore it is possible
the recourds will be reported as new B<before> the 360MARC record
has been delivered. - The MARC flag in the local DB table is used to
keep track of which MARC record has been delivered.

=head1 AUTHOR

andres.vonarx@unibas.ch
basil.marti@unibas.ch

=head1 HISTORY

 09.06.2016 beta / ava
 02.03.2017 Testversion / bmt
 09.03.2017 Erweiterung für freie E-Zeitschriften / bmt
 21.09.2018 Erweiterung für E-Zeitschriften / bmt
 
=cut

use DBI;
use Data::Dumper; $Data::Dumper::Indent=1;$Data::Dumper::Sortkeys=1;
use FindBin;
use POSIX 'strftime';
use Sys::Hostname;
use Config::Simple;
my $cfg = new Config::Simple('/opt/scripts/e-books/bin/idsbb_emedia.conf');

use MARC::Batch;
use MARC::Record;
use MARC::File::USMARC;
use MARC::File::XML (BinaryEncoding => 'utf8', RecordFormat => 'MARC21' );

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
    'BBZ',
    'EHB',
    'FREE',
    'SBS',
    'SBE',
    'SFREE',
);

my %Codes = (
    'BS'   => 'A145',
    'BE'   => 'B405',
    'SBS'  => 'A145',
    'SBE'  => 'B405',
    'BBZ'  => 'B406',
    'EHB'  => 'B407',
    'FREE' => 'FREE',
    'SFREE'=> 'FREE',
);

# ---------------------------
# local files and dirs
# ---------------------------
my $FULL_XML    = 'basel-bern-emedia.xml';
my $DELTA_XML   = 'sersol-idsbb-emedia-full.xml';

my $DATA_DIR       =  $cfg->param('DATADIR');
my $DOWNLOAD_DIR   =  $cfg->param('DOWNLOADDIR');

chdir $DATA_DIR
    or die( "$0: cannot chdir to $DATA_DIR: $!\n");

our $dbh;
my $today = strftime("%Y-%m-%d",localtime);

step_2_write_delta_xml();

# ---------------------------
sub step_2_write_delta_xml {
# ---------------------------
    print "delta: writing updates xml\n";
    my $marcIn   = MARC::File::XML->in($FULL_XML);
    my $marcOut  = MARC::File::XML->out($DELTA_XML);
    my $sth_query = $dbh->prepare(qq|select * from emedia where ssid=?|);
    my $sth_update= $dbh->prepare(qq|update emedia set MARC=1 where ssid=?|);

    while ( my $rec = $marcIn->next ) {
        my $id = $rec->field('001')->data;
        $sth_query->bind_param(1,$id);
        $sth_query->execute;
        next unless ( $sth_query->fetch );
        $sth_update->bind_param(1,$id);
        $sth_update->execute;
            
        my @oldfields_book = $rec->field('949');
        my @newfields_book;

        foreach my $field ( @oldfields_book ) {
            foreach my $set (@Sets) {
                my $sth_query_nel = $dbh->prepare(qq|select Nel$set from emedia where ssid=? and Hol$set=1|);
                $sth_query_nel->bind_param(1,$id);
                $sth_query_nel->execute;
                my $nel = $sth_query_nel->fetchrow_array();
            
                if ($field->subfield( 'b' ) =~ /$Codes{$set}/) {
                    $field->add_subfields( 'x' => ('NEL' . $Codes{$set} . $nel  )) if $nel;
                }
            }
            push(@newfields_book,$field);
        }

        $rec->delete_fields(@oldfields_book);
        $rec->append_fields(@newfields_book);
        
        my @oldfields_journal = $rec->field('852');
        my @newfields_journal;

        foreach my $field ( @oldfields_journal ) {
            foreach my $set (@Sets) {
                my $sth_query_nel = $dbh->prepare(qq|select Nel$set from emedia where ssid=? and Hol$set=1|);
                $sth_query_nel->bind_param(1,$id);
                $sth_query_nel->execute;
                my $nel = $sth_query_nel->fetchrow_array();
            
                if ($field->subfield( 'b' ) =~ /$Codes{$set}/) {
                    $field->add_subfields( 'x' => ('NEL' . $Codes{$set} . $nel  )) if $nel;
                }
            }
            push(@newfields_journal,$field);
        }

        $rec->delete_fields(@oldfields_journal);
        $rec->append_fields(@newfields_journal);
        $marcOut->write($rec);
    }

    $marcIn->close;
    $marcOut->close;

    print "delta: done\n";
}

