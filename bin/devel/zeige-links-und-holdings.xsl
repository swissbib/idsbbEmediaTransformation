<?xml version="1.0" encoding="utf-8"?>
<!--

    extrahiere die Felder 001, 856 und 949 aus der MARC XML Datei
    
    13.11.2013/ava

-->

<xsl:stylesheet version="1.0"
  xmlns:marc="http://www.loc.gov/MARC21/slim"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  >

    <xsl:output method="text" encoding="UTF-8" />
    <xsl:variable name="NL" select="'&#x0A;'"/>

    <xsl:template match="/">
        <xsl:for-each select="//marc:record">
            <xsl:value-of select="marc:controlfield[@tag='001']"/>
            <xsl:value-of select="$NL"/>
            <xsl:for-each select="marc:datafield[@tag='856' or @tag='949']">
                <xsl:value-of select="concat('  ', @tag)" />
                <xsl:for-each select="marc:subfield">
                    <xsl:value-of select="concat(' $',@code,' ',.)" />
                </xsl:for-each>
                <xsl:value-of select="$NL"/>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>
    
</xsl:stylesheet>
