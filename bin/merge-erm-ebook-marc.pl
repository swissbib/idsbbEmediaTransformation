#!/usr/bin/perl

=head1 NAME

merge-erm-ebook-marc.pl - merge holdings and links from 360MARC data files

=head1 SYNOPSIS

 perl merge-erm-ebook-marc.pl

=head1 DESCRIPTION

Input sind je eine 360MARC Dateien von Serial Solutions fuer die
verschiedenen Instanzen des Intota-ERM (UB Basel, UB Bern, BBZ Bern,
EHB Bern, FREE fuer freie Ressourcen). 
Input-Format ist ISO 2709 (MARC).

Output ist eine Datei im Format MARC21 XML ohne Dubletten und 
mit gemergten Holdings und URL-Links.

Bei einigen Feldern wird die Interpunktion am Ende der Unterfelder entfernt:
    Felder:
        100 110 111 245 260 264 300 600 610 611 630 650 651 653 655 700 710 711
    Entfernt werden: 
        .,:;/ (inkl. vorausgehende Spatien)
    Nicht entfernt werden z.B.:
        ?()[]!
        Punkt nach "Dr.", "Jr.", "Inc." und nach Grossbuchstaben

Im Feld 520 $b werden HTML-Markups und -Entities entfernt.

Im Feld 949 werden Unterfelder normalisiert

=head2 Laufzeit

merging der E-Books von BE/BS/BBZ/EHB @ catmandu: 30 Minuten (380'080 records)

=head1 CAVEAT

In den Inputdateien vom 11.09.2014 wurden dublette Records festgestellt
(Records mit derselben ID, laut Stichproben inhaltlich identisch). Die 
Fehler wurden Serial Solutions gemeldet. Sie sind mittlerweile
offenbar behoben.

=head1 AUTHOR

andres.vonarx@unibas.ch
basil.marti@unibas.ch

=head1 HISTORY

 07.03.2013 Testversion
 13.11.2013 generiere Parkfeld 950 fuer 856/ava
 10.12.2013 multiple Parkfelder, fixe Interpunktion/ava
 17.12.2013 weitere fixes.../ava
 23.09.2014 ignoriere dublette BS records
 16.04.2015 workflow fuer frei zugaengliche E-Book Pakete
 02.09.2015 erweitert auf 3. Datenquelle BBZ Bern, Dateinamen hardcoded.
 22.01.2016 erweitert auf 4. Datenquelle EHB Bern, Dateinamen hardcoded.
 19.05.2016 - rewrite fuer beliebige Anzahl Sets, verhindert dublette
            "ssib.." IDs in Records. 
            - Der spezielle Workflow fuer FREE-Pakete wird eliminiert.
            - Feld 898 wird geloescht.
            - Feld 950 wird nicht mehr generiert
            - Feld 949 wird gepatcht
            - Interpunktion fixen zusaetzlich fuer Feld 264
 02.03.2017 Kopie fuer Tests
 09.03.2017 Erweiterung fuer FREE-ZS
 
=cut

use MARC::Batch;
use MARC::Record;
use MARC::File::USMARC;
use MARC::File::XML (BinaryEncoding => 'utf8', RecordFormat => 'MARC21' );

use Data::Dumper; $Data::Dumper::Indent=1;$Data::Dumper::Sortkeys=1;
use FindBin;
use HTML::Entities();
use POSIX 'strftime';
use Sys::Hostname;
use Config::Simple;

my $cfg = new Config::Simple('/opt/scripts/e-books/bin/idsbb_emedia.conf');

binmode(STDOUT,":utf8");

use strict;
use utf8;

# ---------------------------
# input data sets
# ** TIPP ** : Dateien nach Groesse ordnen
# ---------------------------
my @Sets = (
    'BS',       # BS.mrc
    'BE',       # BE.mrc
    'FREE',     # FREE.mrc
    'EHB',      # EHB.mrc
    'SFREE',    # SFREE.mrc
    'BBZ',      # BBZ.mrc
);

# ---------------------------
# local files and dirs
# ---------------------------
my $DATA_DIR = $cfg->param('DATADIR');

chdir $DATA_DIR
    or die( "$0: cannot chdir to $DATA_DIR: $!\n");
my $OUTPUT_XML  = 'tmp.xml';
my $STATS = 'statistik.txt';
my $stats;
my %input_files;
foreach my $set ( @Sets ) {
    $input_files{$set} = $set .'.mrc';
    ( -f $input_files{$set} ) or die "kann $input_files{$set} nicht finden.";
}

# ---------------------------
# configuration
# ---------------------------

# merge these fields:
my @Merge = (qw( 
    852 856 949 
));

# remove some trailing punctuation from all subfields in these fields:
my @RemoveTrailingPunct = (qw(
    100 110 111 245 260 264 300 600 610 611 630 650 651 653 655 700 710 711
));

# escape sign for some replacement magic:
my $ESC = '~';

# --------------------------------------------------------------
# step 1:
# - iterate thru marc file from set 2 thru n
# - store IDs and fields which should be merged
# - store package name (909f)
# --------------------------------------------------------------
my $store;
my $packages;
for ( my $i = 1 ; $i <= $#Sets ; $i++ ) {
    my $set = $Sets[$i];
    print "merge: storing data for $set in memory\n";

    my $marc = MARC::File::USMARC->in($input_files{$set});
    while ( my $rec = $marc->next() ) {
        $stats->{$set}++;
        my $id = $rec->field('001')->data;
        foreach my $tag ( @Merge ) {
            my @f = $rec->field($tag);
            foreach my $f ( @f ) {
                push(@{$store->{$id}->{$set}},$f);
            }
        }
        # Records with one specific id may be part of different
        # packages (909f). We make sure that we output all packages.
        my $f = $rec->field('909')->subfield('f');
        if ( $f ) {
            $packages->{$id}->{$f}=1;
        }
    }
    $marc->close;
}

# --------------------------------------------------------------
# step 2:
# - open XML output file for writing
# - iterate thru marc files from first set and extract ID
# - if the ID matches a stored ID from another set:
#   - merge fields
#   - delete ID from memory
# - output records
# --------------------------------------------------------------

my $xml  =  MARC::File::XML->out($OUTPUT_XML); 
my $done;

my $set = $Sets[0];
print "merge: merging data into $set\n";

my $marc =  MARC::File::USMARC->in($input_files{$set});
while ( my $rec = $marc->next() ) {
    $stats->{$set}++;
    my $id = $rec->field('001')->data;
    
    # dublette Records ignorieren
    next if ( $done->{$id} );
    $done->{$id}=1;

    # wenn ID in anderen Sets existiert: Felder anhaengen
    if ( $store->{$id} ) {
        foreach my $key ( sort keys %{$store->{$id}} ) {
            $rec->append_fields( @{$store->{$id}->{$key}} );
        }
        delete $store->{$id};
    }
    # wenn der Record in mehreren Paketen (909f) vorkommt:
    # allfaellige weiter Felder 909f anhaengen
    my $current_package =  $rec->field('909')->subfield('f');
    if ( $packages->{$id} ) {
        foreach my $package ( sort keys %{$packages->{$id}} ) {
            if ( $package ne $current_package ) {
                my $f = MARC::Field->new('909',' ',' ','f'=>$package);
                $rec->append_fields( $f );
            }
        }
    }
    # Record normalisieren und als XML ausgeben
    fix_record($rec);
    $xml->write($rec);
    $stats->{total}++;
}
$marc->close;

# --------------------------------------------------------------
# step 3:
# - iterate thru remaining marc files 2 thru n
# - ignore record unless its ID is still in memory
# - if stored ID(s) from other Sets are found:
#   - merge fields
#   - delete id from memory
# - output records
# --------------------------------------------------------------
for ( my $i = 1 ; $i <= $#Sets ; $i++ ) {
    my $set = $Sets[$i];

    print "merge: merging data into $set\n";
    my $marc =  MARC::File::USMARC->in($input_files{$set});
    while ( my $rec = $marc->next() ) {
        
        my $id = $rec->field('001')->data;
        
        # for set 2..n: output only if still in memory
        next unless ( ref($store->{$id}) );
        
        # dublette Records ignorieren
        next if ( $done->{$id} );
        $done->{$id}=1;

        # eigene Felder aus memory loeschen
        delete $store->{$id}->{$set};

        # wenn ID in anderen Sets existiert: Felder anhaengen
        if ( keys %{$store->{$id}} ) {
            foreach my $key ( sort keys %{$store->{$id}} ) {
                $rec->append_fields( @{$store->{$id}->{$key}} );
            }
            delete $store->{$id};
        }
        # wenn der Record in mehreren Paketen (909f) vorkommt:
        # allfaellige weiter Felder 909f anhaengen
        my $current_package =  $rec->field('909')->subfield('f');
        if ( $packages->{$id} ) {
            foreach my $package ( sort keys %{$packages->{$id}} ) {
                if ( $package ne $current_package ) {
                    my $f = MARC::Field->new('909',' ',' ','f'=>$package);
                    $rec->append_fields( $f );
                }
            }
        }
        # Record normalisieren und als XML ausgeben
        fix_record($rec);
        $xml->write($rec);
        $stats->{total}++;
    }
    $marc->close;
}
$xml->close;

# --------------------------------------------------------------
# step 4: print some stats
# --------------------------------------------------------------
open(F,">$STATS") or die "cannot write $STATS: $!";
my $now = strftime("%Y-%m-%d %H:%M",localtime);
print F <<EOD;
-----------------------------------------------------
preprocess IDS Basel Bern e-media for swissbib CBS
date: $now
-----------------------------------------------------
360MARC records merged:
-----------------------------------------------------
EOD

printf F ("Total records:%18.18s\n", pnum($stats->{total}));
delete $stats->{total};
foreach my $key (sort keys %$stats ) {
    my $num = pnum($stats->{$key});
    printf F ("- with holdings %-6.6s%10.10s\n", $key, $num);
}
close F;


# --------------------------------------------------------------
sub pnum {
# --------------------------------------------------------------
    # Zahl mit Tausender-Trenner
    local $_ = shift;
    while ( /\d{4}/ ) {
        s|(\d+)(\d\d\d)|$1'$2|;
    }
    $_;
}
# --------------------------------------------------------------
sub fix_record {
# --------------------------------------------------------------
    fix_interpunktion(@_);
    fix_abstract_520(@_);
    fix_field_949_book(@_);
}
# --------------------------------------------------------------
sub fix_interpunktion {
# --------------------------------------------------------------
    my $rec=shift;
    foreach my $tag ( @RemoveTrailingPunct ) {
        my @fields = $rec->field($tag);
        foreach my $field ( @fields ) {
            my @subfields = $field->subfields();
            foreach my $subfield ( @subfields ) {
                my $subf_code = $subfield->[0];
                my $subf_cont = $subfield->[1];
                local $_ = $subf_cont;
                s/\s+$//;
                # protect Jr. 
                s/\b(jr)\.$/$1$ESC/i;
                # protect Dr.
                s/\b(dr)\.$/$1$ESC/i;
                # protect Inc.
                s/\b(inc)\.$/$1$ESC/i;
                # protect abbreviations (uppercase only)
                s/([A-Z])\.$/$1$ESC/;
                # remove trailing «,.:;/» and preceding blanks
                s/[ \,\.:;\/]+$//;
                # restore protected '.'
                s/$ESC$/./;
                if ( $_ ne $subf_cont ) {
                    $field->update( $subf_code => $_ );
                }
            }
        }
    }
}

# --------------------------------------------------------------
sub fix_abstract_520 {
# --------------------------------------------------------------
    # abstracts come in 520 $a (10MB) and $b (5MB)
    my $rec=shift;
    my $field = $rec->field('520');
    if ( $field ) {
        fix_abstract_520_subfield('a',$field);
        fix_abstract_520_subfield('b',$field);        
    }
}
sub fix_abstract_520_subfield {
    my($code, $field)=@_;
    my $subfield = $field->subfield($code);
    if ( $subfield ) {
        local $_ = $subfield;
        # replace HTML markup with spaces
        s/<[^>]*>/ /g;
        # replace HTML entities
        $_ = HTML::Entities::decode($_);
        # normalize blanks
        s/^\s+//;
        s/\s+$//;
        s/\s\s+/ /g;
        $field->update($code => $_);
    }
}
# --------------------------------------------------------------
sub fix_field_949_book {
# --------------------------------------------------------------
    my $rec=shift;
    my @oldf = $rec->field('949');
    my @newf;
    foreach my $oldf ( @oldf ) {
        my $newf =  MARC::Field->new( '949',' ',' ',
            'b' => $oldf->subfield('b'),
            'c' => $oldf->subfield('c'),
            '1' => $oldf->subfield('1'),
            '3' => 'BOOK',
            'u' => $oldf->subfield('u'),
        );
        push(@newf,$newf);
    }
    $rec->delete_fields(@oldf);
    $rec->append_fields(@newf);
}
