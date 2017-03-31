#!/usr/bin/perl

use strict;

my $XMLfile = '/opt/data/e-books/data/basel-bern-emedia.xml';

my($id);

binmode(STDOUT, ":utf8");
open(IN, "<:utf8", $XMLfile) or die("cannotr read $XMLfile: $!");
while ( <IN> ) {
    if ( m|^\s+<controlfield tag=\"001\">(.*)</| ) {
        $id = $1;
        next;
    }
    if ( m|^\s+<datafield tag=\"020\"| ) {
        $_ = <IN>;
        if ( m|^\s+<subfield code=\"a\">([\dX]+)(.*)</subfield>| ) {
            my $isbn = $1;
            my $blabla = $2;
            print $id, "\t", $isbn, "\t", $blabla, "\n";
        }
        next;
    }
}
