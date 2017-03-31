<?xml version="1.0" encoding="utf-8"?>
<!--
    
    Analyse-Tool
    Extrahiere selektiv Felder/Unterfelder aus MARC XML Datei.
    usage: siehe extrahiere-marc-unterfeld.sh
    
    9.12.2013/ava

-->

<xsl:stylesheet version="1.0"
  xmlns:marc="http://www.loc.gov/MARC21/slim"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  >

    <xsl:output method="text" encoding="UTF-8" />
    <xsl:variable name="NL" select="'&#x0A;'"/>
    
    <xsl:param name="FIELD" select="'245'"/>
    <xsl:param name="SUBFIELD" select="'a'"/>
    

    <xsl:template match="/">
        <xsl:for-each select="//marc:record">
            <xsl:value-of select="marc:controlfield[@tag='001']"/>
            <xsl:value-of select="$NL"/>
            <xsl:for-each select="marc:datafield[@tag='909']/marc:subfield[@code='f']">
                <xsl:value-of select="concat('-',.,$NL)"/>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>
    
</xsl:stylesheet>
