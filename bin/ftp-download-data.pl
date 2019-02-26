#!/usr/bin/perl

=for doku

ftp-download-data.pl 

Das Skript holt die aktuellen E-Book-MARC-Dateien als Zipfiles
per FTP von Serial Solutions.

Output: (im Verzeichnis */data):
    - fuer jede ERM-Instanz eine "*-mono.mrc" Datei 
      im Verzeichnis */data
    - */data/RunSummary-Mono.txt
    - fuer jede ERM-Instanz ein "*_mono_delta" Unterverzeichnis 
      im Verzeichnis */download

CAVEAT:
    - das Skript löscht vorhandene *zip, *mrc Dateien und alle
      Unterverzeichnisse im Ordner */download

History
    2016.06.08  rewrite fuer merge und delta/ava
    2016.10.12  added FREE instance/ava
    2017.03.31  added support for OA-serials
    2018.09.20  added support for serials 

Autor
    andres.vonarx@unibas.ch
    basil.marti@unibas.ch
  
=cut

use Cwd;
use File::Copy;
use File::Spec;
use Net::FTP;
use Sys::Hostname;
use Config::Simple;
my $cfg = new Config::Simple('/opt/scripts/e-books/bin/idsbb_emedia.conf');
my $cfg_hidden = new Config::Simple($cfg->param('HIDDENCONF'));

use strict;

# ---------------------------
# ftp configuration
# ---------------------------
my ($ftp,$ftp_error);
my $ftp_host = $cfg_hidden->param('ftp_host');
my $be = [ $cfg_hidden->param('be_user'), $cfg_hidden->param('be_pw') ];
my $bs = [ $cfg_hidden->param('bs_user'), $cfg_hidden->param('bs_pw') ];

my $quiet = 0;  # do not output messages if true

my $downloads = {
    mono_full => {
        BE   => '1UB_360MARC_Update_mono.zip',
        BS   => '2UB_360MARC_Update_mono.zip',
        BBZ  => 'BB3_360MARC_Update_mono.zip',
        EHB  => 'EH1_360MARC_Update_mono.zip',
        FREE => '3UB_360MARC_Update_mono.zip',
        },
    ser_full => {
        SBE    => '1UB_360MARC_Update_ser.zip',
        SBS    => '2UB_360MARC_Update_ser.zip',
        SFREE  => '3UB_360MARC_Update_ser.zip',
        },
    mono_delta => {
        BE   => '1UB_360MARC_Update_new_changed_deleted_files.zip',
        BS   => '2UB_360MARC_Update_new_changed_deleted_files.zip',
        BBZ  => 'BB3_360MARC_Update_new_changed_deleted_files.zip',
        EHB  => 'EH1_360MARC_Update_new_changed_deleted_files.zip',
        FREE => '3UB_360MARC_Update_mono_new_changed_deleted_files.zip',
        },
    ser_delta => {
        SBE   => '1UB_360MARC_Update_ser_new_changed_deleted_files.zip',
        SBS   => '2UB_360MARC_Update_ser_new_changed_deleted_files.zip',
        SFREE => '3UB_360MARC_Update_ser_new_changed_deleted_files.zip',
        },
};

# ---------------------------
# local files and dirs
# ---------------------------
my($DATA_DIR,$DOWNLOAD_DIR);

$DATA_DIR       =  $cfg->param('DATADIR');
$DOWNLOAD_DIR   =  $cfg->param('DOWNLOADDIR');

chdir $DOWNLOAD_DIR
    or die( "$0: cannot chdir to $DOWNLOAD_DIR: $!\n");
my $MONO_RUN_SUMMARY = $DATA_DIR .'/RunSummary-Mono.txt';
my $SER_RUN_SUMMARY = $DATA_DIR .'/RunSummary-Ser.txt';

# ------------------------------------------------------
# main program
# ------------------------------------------------------
sub say { print @_ unless $quiet }

delete_old_files_and_dirs();
ftp_download();
check_download();
extract_mono_full();
extract_mono_delta();
extract_ser_full();
extract_ser_delta();

# ------------------------------------------------------
sub delete_old_files_and_dirs {
# ------------------------------------------------------
    # remove *.src *.mrc files and subdirectories
    opendir(DIR,'.') or die "$0: cannot open download dir: $!\n";
    my @files = readdir DIR;
    closedir DIR;
    my @zip = grep { /\.zip/i } @files;
    my @mrc = grep { /\.mrc/i } @files;
    my @dirs = grep { -d $_  && ! /^\./ } @files;
    unlink @zip;
    unlink @mrc;
    foreach my $dir ( @dirs ) {
        system qq|rm -rf $dir|;
    }
}    

# ------------------------------------------------------
sub ftp_download {
# ------------------------------------------------------
    # contacts FTP server and downloads data
    # returns:
    #   0 : completed without errors
    #   1 : download aborted (sets $ftp_error)

    say "ftp: contact $ftp_host\n";
    foreach my $credentials ( $be, $bs ) {
        my $ftp = Net::FTP->new( $ftp_host, Passive => 1)
            or die("cannot connect to $ftp_host. $@");
        $ftp->login(@$credentials)
            or ftp_abort("cannot login");
            
        # --- mono
        $ftp->cwd('360MARC-Monographs')
            or ftp_abort("cannot change directory");
        
        # --- mono metadata combined ---
        my @list = $ftp->ls
            or ftp_abort("cannot list directory");
        while ( @list ) {
            my $zipfile = shift @list;
            next unless ($zipfile =~ /\.zip$/ );
            say "ftp: downloading $zipfile...\n";
            $ftp->binary;
            $ftp->get($zipfile)
               or ftp_abort("cannot get $zipfile");
        }
        # --- mono metadata delta ---
        $ftp->cwd('New_Changed_Deleted')
            or ftp_abort("cannot change directory");
        @list = $ftp->ls
            or ftp_abort("cannot list directory");
        while ( @list ) {
            my $zipfile = shift @list;
            next unless ($zipfile =~ /\.zip$/ );
            say "ftp: downloading $zipfile...\n";
            $ftp->binary;
            $ftp->get($zipfile)
               or ftp_abort("cannot get $zipfile");
        }
       
        $ftp->quit;
    }

    foreach my $credentials ( $be, $bs ) {
        my $ftp = Net::FTP->new( $ftp_host, Passive => 1)
            or die("cannot connect to $ftp_host. $@");
        $ftp->login(@$credentials)
            or ftp_abort("cannot login");

        # --- ser
        $ftp->cwd('360MARC-Serials')
            or ftp_abort("cannot change directory");

        # --- ser metadata combined ---
        my @list = $ftp->ls
            or ftp_abort("cannot list directory");
        while ( @list ) {
            my $zipfile = shift @list;
            next unless ($zipfile =~ /\.zip$/ );
            say "ftp: downloading $zipfile...\n";
            $ftp->binary;
            $ftp->get($zipfile)
               or ftp_abort("cannot get $zipfile");
        }
        # --- ser metadata delta ---
        $ftp->cwd('New_Changed_Deleted')
            or ftp_abort("cannot change directory");
        @list = $ftp->ls
            or ftp_abort("cannot list directory");
        while ( @list ) {
            my $zipfile = shift @list;
            next unless ($zipfile =~ /\.zip$/ );
            say "ftp: downloading $zipfile...\n";
            $ftp->binary;
            $ftp->get($zipfile)
               or ftp_abort("cannot get $zipfile");
        }

        $ftp->quit;
     }
}

sub ftp_abort {
    my $msg = "FTP ERROR: " .$_[0] .". " . $ftp->message;
    $ftp->quit;
    die $msg;
}
    
# ------------------------------------------------------
sub check_download {
# ------------------------------------------------------
    # check if the requested files have been downloaded
    my @expected_ftp_files = ( 
        values(%{$downloads->{mono_full}}), 
        values(%{$downloads->{mono_delta}}),
        values(%{$downloads->{ser_full}}), 
        values(%{$downloads->{ser_delta}}),
        );
    foreach my $file ( @expected_ftp_files ) {
        if ( ! -f $file ) {
            die "FTP ERROR: Kann erwartete Datei $file nicht finden.\n";
        }
    }
    say "ftp: download complete\n";
}

# ------------------------------------------------------
sub extract_mono_full {
# ------------------------------------------------------
    say "ftp: extracting monographs full\n";
    unlink $MONO_RUN_SUMMARY;
    unlink 'RunSummary.txt';

    my @lib = keys %{$downloads->{mono_full}};
 
    foreach my $lib ( @lib ) {
        my @zip = glob( $downloads->{mono_full}->{$lib} );
        my $zip = $zip[0];
        my $prefix = $zip;
        $prefix =~ s/_.*$//;
        my $mono_zip = $prefix ."_360MARC_Update_mono_monographs.zip";
        my $mono_mrc = $prefix ."_360MARC_Update_mono_monographs_new.mrc";
        my $target_mrc = $DATA_DIR .'/' .$lib .'.mrc';
        my $cmds=<<EOD;
unzip -qq $zip $mono_zip RunSummary.txt
echo '--------------------------------------------' >> $MONO_RUN_SUMMARY
echo ' Run Summary (Total) for $lib'  >> $MONO_RUN_SUMMARY
echo '--------------------------------------------' >> $MONO_RUN_SUMMARY
cat RunSummary.txt >> $MONO_RUN_SUMMARY
unzip -qq $mono_zip $mono_mrc
mv $mono_mrc $target_mrc
rm RunSummary.txt
rm $mono_zip
EOD
        my @cmds = split(/\n/,$cmds);
        foreach my $cmd ( @cmds ) {
            #say $cmd, "\n";
            system $cmd;
        }
   }
}   

# ------------------------------------------------------
sub extract_ser_full {
# ------------------------------------------------------
    say "ftp: extracting serials full\n";
    unlink $SER_RUN_SUMMARY;
    unlink 'RunSummary.txt';

    my @lib = keys %{$downloads->{ser_full}};
 
    foreach my $lib ( @lib ) {
        my @zip = glob( $downloads->{ser_full}->{$lib} );
        my $zip = $zip[0];
        my $prefix = $zip;
        $prefix =~ s/_.*$//;
        my $ser_zip = $prefix ."_360MARC_Update_ser_serials.zip";
        my $ser_mrc = $prefix ."_360MARC_Update_ser_serials_new.mrc";
        my $target_mrc = $DATA_DIR .'/' .$lib .'.mrc';
        my $cmds=<<EOD;
unzip -qq $zip $ser_zip RunSummary.txt
echo '--------------------------------------------' >> $SER_RUN_SUMMARY
echo ' Run Summary (Total) for $lib'  >> $SER_RUN_SUMMARY
echo '--------------------------------------------' >> $SER_RUN_SUMMARY
cat RunSummary.txt >> $SER_RUN_SUMMARY
unzip -qq $ser_zip $ser_mrc
mv $ser_mrc $target_mrc
rm RunSummary.txt
rm $ser_zip
EOD
        my @cmds = split(/\n/,$cmds);
        foreach my $cmd ( @cmds ) {
            #say $cmd, "\n";
            system $cmd;
        }
   }
}   

# ------------------------------------------------------
sub extract_mono_delta {
# ------------------------------------------------------
    # move delta zipfile to subdirectories
    # and extract all data

    say "ftp: extracting monographs delta\n";

    my @key = keys %{$downloads->{mono_delta}};
    
    foreach my $key ( @key ) {
        my $dir = $key .'_delta';
        mkdir $dir
            or die "$0; cannot mkdir $dir: $!\n";
        my @zip = glob($downloads->{mono_delta}->{$key});
        my $zip = $zip[0];
        my $cmds=<<EOD;
mv $zip $dir
unzip -qq $dir/$zip -d $dir
rm -rf $dir/$zip

mv $dir/ChangeMonographRecords.csv $dir/ChangeRecords.csv
mv $dir/DeleteMonographRecords.csv $dir/DeleteRecords.csv
mv $dir/NewMonographRecords.csv $dir/NewRecords.csv

EOD
        my @cmds = split(/\n/,$cmds);
        foreach my $cmd ( @cmds ) {
            #say $cmd, "\n";
            system $cmd;
        }
    }
}

# ------------------------------------------------------
sub extract_ser_delta {
# ------------------------------------------------------
    # move delta zipfile to subdirectories
    # and extract all data

    say "ftp: extracting serials delta\n";

    my @key = keys %{$downloads->{ser_delta}};
    
    foreach my $key ( @key ) {
        my $dir = $key .'_delta';
        mkdir $dir
            or die "$0; cannot mkdir $dir: $!\n";
        my @zip = glob($downloads->{ser_delta}->{$key});
        my $zip = $zip[0];
        my $cmds=<<EOD;
mv $zip $dir
unzip -qq $dir/$zip -d $dir
rm -rf $dir/$zip

mv $dir/ChangeSerialRecords.csv $dir/ChangeRecords.csv
mv $dir/DeleteSerialRecords.csv $dir/DeleteRecords.csv
mv $dir/NewSerialRecords.csv $dir/NewRecords.csv

EOD
        my @cmds = split(/\n/,$cmds);
        foreach my $cmd ( @cmds ) {
            #say $cmd, "\n";
            system $cmd;
        }
    }
}
