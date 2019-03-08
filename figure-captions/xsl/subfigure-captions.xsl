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
  xmlns:tr="http://transpect.io"
  xmlns:hub="http://transpect.io/hub"
  xmlns:css="http://www.w3.org/1996/css"
  xmlns="http://docbook.org/ns/docbook"
  xpath-default-namespace="http://docbook.org/ns/docbook"
  exclude-result-prefixes="w o v wx xs dbk pkg r rel word200x exsl fn tr hub css"
  version="2.0">

  <xsl:import href="figure-caption-vars.xsl"/>

  <xsl:template match="*[para[matches(@role, $hub:subfigure-caption-role-regex-x)]]" mode="hub:subfigure-captions">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:for-each-group select="node()" group-ending-with="*[hub:is-subfigure-caption(.)]">
        <xsl:choose>
          <xsl:when test="current-group()[last()][hub:is-subfigure-caption(.)]">
            <xsl:for-each-group select="current-group()" group-starting-with="*[hub:is-subfigure(.)]">
              <xsl:choose>
                <xsl:when test="current-group()[1][hub:is-subfigure(.)]">
                  <xsl:call-template name="hub:build-subfigure-caption">
                    <xsl:with-param name="media" select="current-group()[1]//(mediaobject, inlinemediaobject)"/>
                    <xsl:with-param name="caption" select="current-group()[position() gt 1]"/>
                  </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:apply-templates select="current-group()" mode="#current"/>
                </xsl:otherwise>
              </xsl:choose>  
            </xsl:for-each-group>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="current-group()" mode="#current"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>

  <xsl:template name="hub:build-subfigure-caption">
    <xsl:param name="media" as="node()"/>
    <xsl:param name="caption" as="node()+"/>
    <para>
      <mediaobject>
        <xsl:apply-templates select="$media/(@*, node())" mode="hub:subfigure-captions"/>
        <caption>
          <xsl:apply-templates select="$caption" mode="hub:subfigure-captions"/>
        </caption>
      </mediaobject>
    </para>
  </xsl:template>
  
</xsl:stylesheet>