# normalize_unicode.pl

# dieses Skript verwandelt UTF-8 in einem "decomposed" Format
# (Grundbuchstabe plus Diakritikum) in die "precomposed" Form
# von Unicode, d.h. in die "Normalization Form D (NFD), Canonical
# Decomposition". Fehlerhafte UTF-8-Zeichen werden geloescht.
#
# Siehe: http://unicode.org/reports/tr15/
#
# History:
# 21.09.2010/andres.vonarx@unibas.ch

use strict;
use Unicode::Normalize;

open(IN,"<-") or die $!;
binmode(IN,":utf8");
binmode(STDOUT,":utf8");

while ( <IN> ) {
    my $nfd = NFD($_);      # decompose
    my $nfc = NFC($nfd);    # compose
    print $nfc;
}

