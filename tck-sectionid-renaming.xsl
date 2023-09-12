<?xml version="1.0" encoding="UTF-8"?>
<!--
  ~ Jakarta Validation: constrain once, validate everywhere.
  ~
  ~ License: Apache License, Version 2.0
  ~ See the license.txt file in the root directory or <http://www.apache.org/licenses/LICENSE-2.0>.
  -->

<!--
  ~ Creates the sed command file for renaming the section ids to their string values
  ~
  ~ @author Guillaume Smet
  -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xalan="http://xml.apache.org/xslt"
    xmlns:exslt="http://exslt.org/common" xmlns:xi="http://www.w3.org/2001/XInclude" version="1.0">

    <xsl:output method="text" indent="no" />

    <xsl:param name="currentDate"/>

    <!-- ### Passes by creating and processing result tree fragments ### -->
    <xsl:variable name="merged">
        <xsl:apply-templates mode="merge" select="/"/>
    </xsl:variable>

    <xsl:variable name="withSectionNums">
        <xsl:apply-templates mode="addSectionNums" select="exslt:node-set($merged)"/>
    </xsl:variable>

    <xsl:template match="/">
        <xsl:apply-templates mode="createSedCommandFile" select="exslt:node-set($withSectionNums)"/>
    </xsl:template>

    <!-- ### Merge templates ### -->

    <xsl:template match="xi:include" mode="merge">
        <xsl:variable name="fileName">en/<xsl:value-of select="@href" /></xsl:variable>
        <xsl:apply-templates select="document($fileName)" mode="merge"/>
    </xsl:template>

    <xsl:template match="@*|node()" mode="merge">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()" mode="merge"/>
        </xsl:copy>
    </xsl:template>

    <!-- ### addSectionNums templates ### -->

    <xsl:template match="/article/section" mode="addSectionNums">
        <xsl:copy>
            <xsl:attribute name="sectionNum"><xsl:number from="article" level="single" /></xsl:attribute>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="addSectionNums"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="section" mode="addSectionNums">
        <xsl:copy>
            <xsl:attribute name="sectionNum"><xsl:number count="section" from="article" level="multiple" /></xsl:attribute>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="addSectionNums"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="@*|node()" mode="addSectionNums">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()" mode="addSectionNums"/>
        </xsl:copy>
    </xsl:template>

    <!-- ### Create sed command file templates ### -->

    <xsl:template match="article"  mode="createSedCommandFile">
        <xsl:text># Generated by tck-sectionid-renaming.xsl at <xsl:value-of select="concat($currentDate, ' ')"/></xsl:text><xsl:text>&#10;</xsl:text>
        <xsl:apply-templates select=".//section" mode="createSedCommandFile"/>
    </xsl:template>

    <xsl:template match="section" mode="createSedCommandFile">
        <!-- add a section only if it has TCK-relevant sub-elements -->
        <xsl:if test=".//*[starts-with(@role, 'tck')]">
            <xsl:call-template name="check-section-id">
                <xsl:with-param name="sectionId"><xsl:value-of select="@xml:id" /></xsl:with-param>
                <xsl:with-param name="sectionNum"><xsl:value-of select="@sectionNum" /></xsl:with-param>
            </xsl:call-template>
            <xsl:text>s/section = "</xsl:text><xsl:value-of select="@sectionNum" /><xsl:text>"/section = Sections.</xsl:text><xsl:call-template name="section-id-to-constant"><xsl:with-param name="sectionId" select="@xml:id" /></xsl:call-template><xsl:text>/g</xsl:text><xsl:text>&#10;</xsl:text>
        </xsl:if>
    </xsl:template>

    <!-- Check that the given section id is manually defined -->
    <xsl:template name="check-section-id">
        <xsl:param name="sectionId" />
        <xsl:param name="sectionNum" />
        <xsl:if test="starts-with($sectionId, '_')">
            <xsl:message  terminate="yes">
                Error: section <xsl:value-of select="$sectionNum" /><xsl:text> - </xsl:text><xsl:value-of select="$sectionId" /> seems to be automatically generated: it starts with an underscore.
            </xsl:message>
        </xsl:if>
    </xsl:template>

    <xsl:template name="section-id-to-constant">
        <xsl:param name="sectionId" />
        <xsl:variable name="smallcase" select="'abcdefghijklmnopqrstuvwxyz-'" />
        <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ_'" />
        <xsl:value-of select="translate($sectionId, $smallcase, $uppercase)" />
    </xsl:template>

</xsl:stylesheet>
