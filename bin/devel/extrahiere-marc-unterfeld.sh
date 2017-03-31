#!/bin/bash

if [ "$1" != "" ]; then
    if [ "$2" != "" ]; then
        SUBFIELD=$2
    else
        SUBFIELD='#'
    fi
    xsltproc --stringparam FIELD $1 --stringparam SUBFIELD $SUBFIELD extrahiere-marc-unterfeld.xsl /opt/data/e-books/data/basel-bern-emedia.xml
else
    echo "Extrahiere Unterfelder aus MARC Datei basel-bern-emedia.xml"
    echo " "
    echo "usage:"
    echo "    . $BASH_SOURCE fieldtag [subfieldcode]"
    echo " "
    echo "example:"
    echo "    . $BASH_SOURCE 245"
    echo "    . $BASH_SOURCE 245 a"
    echo " "
fi
