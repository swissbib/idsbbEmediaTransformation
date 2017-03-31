<?xml version="1.0" encoding="utf-8"?>
<!--
    Analyse-Tool
    dumpe alle MARC 6## Subfelder (nur MeSH, d.h. mit Indikator2 = "2")
    
    9.12.2013/ava

-->

<xsl:stylesheet version="1.0"
  xmlns:marc="http://www.loc.gov/MARC21/slim"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  >

    <xsl:output method="text" encoding="UTF-8" />
    <xsl:variable name="NL" select="'&#x0A;'"/>
    
    <xsl:template match="/">
        <xsl:for-each select="//marc:record">
            <xsl:for-each select="marc:datafield[substring(@tag,1,1)='6' and @ind2='2']">
                <xsl:for-each select="marc:subfield">
                    <xsl:value-of select="concat(../@tag,@code,' ',.,$NL)"/>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>
    
</xsl:stylesheet>
