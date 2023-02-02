<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:fn="http://www.w3.org/2005/xpath-functions"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
  xmlns:word200x="http://schemas.microsoft.com/office/word/2003/wordml"
  xmlns:v="urn:schemas-microsoft-com:vml" 
  xmlns:dbk="http://docbook.org/ns/docbook"
  xmlns:wx="http://schemas.microsoft.com/office/word/2003/auxHint"
  xmlns:o="urn:schemas-microsoft-com:office:office"
  xmlns:pkg="http://schemas.microsoft.com/office/2006/xmlPackage"
  xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
  xmlns:rel="http://schemas.openxmlformats.org/package/2006/relationships"
  xmlns:exsl="http://exslt.org/common"
  xmlns:saxon="http://saxon.sf.net/"
  xmlns:tr="http://transpect.io"
  xmlns:hub="http://transpect.io/hub"
  xmlns:css="http://www.w3.org/1996/css"
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns="http://docbook.org/ns/docbook"
  version="2.0"
  xpath-default-namespace="http://docbook.org/ns/docbook"
  exclude-result-prefixes = "w o v wx xs dbk pkg r rel word200x exsl saxon fn tr">

  <xsl:include href="http://transpect.io/evolve-hub/xsl/hub-functions.xsl"/>
  <xsl:include href="http://transpect.io/xslt-util/num/xsl/num.xsl"/>
  <xsl:include href="lists-by-role-functions.xsl"/>
  <xsl:include href="lists-by-role-vars.xsl"/>
  <xsl:include href="lists-by-role.xsl"/>
  <xsl:include href="postprocess-lists-by-role.xsl"/>
  <xsl:include href="prepare-lists-by-role.xsl"/>
  <xsl:include href="restore-roles.xsl"/>

  <xsl:output
    name="debug"
    method="xml"
    indent="yes"
    encoding="utf-8"/>
  
  <xsl:param name="debug-dir-uri" select="concat(base-uri(),'/debug')"/>
  <xsl:param name="lists-by-role-style-map" select="'lists-by-role-style-map.xhtml'"/>
  
  <xsl:variable name="hub:prepare-lists-by-role">
    <xsl:apply-templates select="/" mode="hub:prepare-lists-by-role"/>
  </xsl:variable>
  
  <xsl:variable name="hub:lists-by-role">
    <xsl:apply-templates select="$hub:prepare-lists-by-role" mode="hub:lists-by-role"/>
  </xsl:variable>
  
  <xsl:variable name="hub:postprocess-lists-by-role">
    <xsl:apply-templates select="$hub:lists-by-role" mode="hub:postprocess-lists-by-role"/>
  </xsl:variable>
  
  <xsl:template name="main">
    <xsl:apply-templates select="$hub:postprocess-lists-by-role" mode="hub:restore-roles"/>
  </xsl:template>
  
  <xsl:template match="node() | @*" mode="hub:lists-by-role hub:list-true-marks hub:prepare-lists-by-role hub:restore-roles hub:postprocess-lists-by-role">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
    
  <xsl:template match="node()" mode="hub:list-true-marks" as="xs:string" priority="10">
    <!-- If someone changed …|[a-z]|… to …|[a-z][.:\)]|… in $hub:orderedlist-mark-regex, we need the double replace
      because $1 then contains the punctuation. You might need to customize this template if you customized the regex further. -->
    <xsl:sequence select="replace(replace(normalize-space(.),  $hub:orderedlist-mark-regex, '$1'), '[.:\)\)]', '', 'i')"/>
  </xsl:template>
  
</xsl:stylesheet>