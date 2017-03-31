<?xml version="1.0" encoding="utf-8"?>
<!--
    
    Analyse-Tool
    Extrahiere ein controlfield aus MARC XML Datei.
    usage:  xsltproc  extrahiere-marc-controlfield.xsl  bib.xml
    
    27.05.2015/ava

-->

<xsl:stylesheet version="1.0"
  xmlns:marc="http://www.loc.gov/MARC21/slim"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  >

    <xsl:output method="text" encoding="UTF-8" />
    <xsl:variable name="NL" select="'&#x0A;'"/>
    
    <xsl:param name="FIELD" select="'001'"/>

    <xsl:template match="/">
        <xsl:for-each select="//marc:record">
            <xsl:value-of select="marc:controlfield[@tag=$FIELD]"/>
            <xsl:value-of select="$NL"/>
        </xsl:for-each>
    </xsl:template>
    
</xsl:stylesheet>
