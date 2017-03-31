#!/bin/bash

# make-idsbb-emedia.sh
#   Skript fuer Preprocessing und Mergen der 360MARC Daten 
# 
# author:   
#   andres.vonarx@unibas.ch
#
# history:
#   17.12.2013/ava: produktiv fuer swissbib orange
#   23.05.2016/ava: rewrite fuer ub-catmandu, swissbib gruen
#   04.11.2016/bmt: anlegen und verschicken eines log-files eingerichtet 

DO_DOWNLOAD=1
DO_MERGE=1
DO_SYNC=1
DO_DELTA=1
DO_UPLOAD=1
DO_CLEANUP=1

DATE=`date +%Y%m%d`
LINE='------------------------------------------------'

BINDIR=/opt/scripts/e-books/bin
LOGDIR=/opt/scripts/e-books/log
DATADIR=/opt/data/e-books/data

LOG=$LOGDIR/idsbb_emedia_log_$DATE.log
MAIL_EDV="basil.marti@unibas.ch,silvia.witzig@unibas.ch,sonja.kupferschmied@unibas.ch,bernd.luchner@unibas.ch"
MAIL_ERM="barbara.kurz@unibas.ch,database-ub@unibas.ch,beatrice.frick@ehb.swiss,petra.bertschy@bzpflege.ch,jan.stutzmann@ub.unibe.ch,esupport@ub.unibe.ch"

INFOMAIL=$BINDIR/idsbb_emedia_infomail.txt
STATS=$DATADIR/statistik.txt
STATS_ARCH=$LOGDIR/idsbb_emedia_statistik_$DATE.txt
SHADOW_STATS=$DATADIR/shadow_statistik.txt
SHADOW_STATS_ARCH=$LOGDIR/idsbb_emedia_shadow_statistik_$DATE.txt

echo $LINE >> $LOG
echo "Download and preprocess 360MARC data for swissbib" >> $LOG
echo $LINE >> $LOG
echo "-------------------------------------------------"
printf 'START: ' && date >> $LOG

cd $DATADIR

if [ "$DO_DOWNLOAD" == "1" ]; then
    echo "* download and extract data" >> $LOG
    perl $BINDIR/ftp-download-data.pl
    if [ "$?" !=  "0" ]; then
        exit;
    fi
fi

if [ "$DO_MERGE" == "1" ]; then
    echo "* merge all ERM instances" >> $LOG
    echo "* [please be patient for about 30 minutes...]" >> $LOG
    rm -f tmp.xml
    rm -f basel-bern-emedia.xml
    perl $BINDIR/merge-erm-ebook-marc.pl
    if [ "$?" !=  "0" ]; then
        exit;

    fi
    echo "* fix unicode" >> $LOG
    perl $BINDIR/normalize_unicode.pl < tmp.xml > basel-bern-emedia.xml
    if [ "$?" !=  "0" ]; then
        exit;
    fi
fi
    
if [ "$DO_SYNC" == "1" ]; then
    echo "* synchronizing MySQL database" >> $LOG
    perl $BINDIR/sync-deltas-with-local-db.pl
    if [ "$?" !=  "0" ]; then
        exit;
    fi
fi

if [ "$DO_DELTA" == "1" ]; then
    echo "* writing delta files" >> $LOG
    echo "* [please be patient for about 15 minutes...]" >> $LOG
    rm -f sersol-idsbb-emedia-updates.xml
    rm -f sersol-idsbb-emedia-updates.xml.gz
    rm -f sersol-idsbb-emedia-deletions.txt
    perl $BINDIR/create-delta-files.pl
    if [ "$?" !=  "0" ]; then
        exit;
    fi
    echo "* reformatting updates xml" >> $LOG
    perl $BINDIR/reformat-marcxml.pl < sersol-idsbb-emedia-updates.xml > sersol-idsbb-emedia-updates-reformatted.xml
    if [ "$?" !=  "0" ]; then
        exit;
    fi
    echo "* gzipping xml" >> $LOG
    gzip -f sersol-idsbb-emedia-updates-reformatted.xml
    echo "* writing stats" >> $LOG
    perl $BINDIR/e_swissbib_db_stats.pl
    if [ "$?" !=  "0" ]; then
        exit;
    fi
fi

if [ "$DO_UPLOAD" == "1" ]; then
    echo "* upload data" >> $LOG
	scp sersol-idsbb-emedia-updates-reformatted.xml.gz harvester@sb-coai1.swissbib.unibas.ch:/swissbib/harvesting/incomingSersol/./
	scp sersol-idsbb-emedia-deletions.txt harvester@sb-coai1.swissbib.unibas.ch:/swissbib/harvesting/oaiDeletes/./
fi

if [ "$DO_CLEANUP" == "1" ]; then
    echo "* clean up temp files" >> $LOG
    rm -f *.mrc
    rm -f tmp.xml
fi

printf 'END ' && date >> $LOG

cp $STATS $STATS_ARCH
cp $SHADOW_STATS $SHADOW_STATS_ARCH

# Log-Datei an EDV nach jedem Lauf verschicken:
cat $LOG | mailx -a "From:basil.marti@unibas.ch" -s "Logfile: E-Media-Metadaten vom $DATE nach Swissbib exportiert" $MAIL_EDV
cat $INFOMAIL $STATS_ARCH| mailx -a "From:basil.marti@unibas.ch" -s "Infomail: E-Media-Metadaten vom $DATE nach Swissbib exportiert" $MAIL_EDV
# Info-Mail an ERM-Abteilungen nach jedem Lauf verschicken:
cat $INFOMAIL $STATS_ARCH| mailx -a "From:basil.marti@unibas.ch" -s "E-Media-Metadaten vom $DATE nach Swissbib exportiert" $MAIL_ERM
