#!/usr/bin/perl

# usage: 
#   perl reformat-marcxml.pl < input.xml [>output.xml]
#
# input: 
#   MARC 21 XML
#
# output:
#   MARX XML fuer swissbib document processing
#   - jeder <record> auf 1 separate Zeile
#   - entities numerisch aufgelöst: '&amp;' => '&#38;'
#
# history
#   rev. 21.11.2013/ava

use strict;

$|=1;

open(IN,"<-") or die "cannot open stdin: $!";

# --- XML declaration
$_ = <IN>;
print $_;

# --- <collection> auf 1 Zeile
my $line = '';
do {
    $_ = <IN>;
    chomp;
    s/^\s+//;
    s/\s+$//;
    if ( $line ) {
        $line .= ' ';
    }
    $line .= $_;
} while ( $_ && $_ !~ />/ );
print $line, "\n";

# --- records
$line='';
while ( <IN> )  {
    chomp;
    s/^\s+//;
    # the five holy xml chars
    s/&quot;/&#34;/g;
    s/&amp;/&#38;/g;
    s/&apos;/&#39/g;
    s/&lt;/&#60;/g;
    s/&gt;/&#62;/g;
    if ( /^<\/record>/ ) {
        print $line, $_, "\n";
        $line='';
        next;
    }
    $line .= $_;
    if ( /^<\/collection>/ ) {
        print $_, "\n";
    }
}
