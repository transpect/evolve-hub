<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:dbk="http://docbook.org/ns/docbook"
  xmlns:css="http://www.w3.org/1996/css"
  xmlns:hub="http://transpect.io/hub"
  xmlns="http://docbook.org/ns/docbook"
  xpath-default-namespace="http://docbook.org/ns/docbook"
  exclude-result-prefixes="xs hub dbk"
  version="2.0">
  
  <xsl:template match="*[*:indexterm[preceding-sibling::node()[self::text() or self::*][1][self::text()][matches(.,'\p{L}$')] and 
                                   following-sibling::node()[self::text() or self::*][1][self::text()][matches(.,'^\p{L}')]]]" 
                mode="hub:indexterms">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:for-each-group select="node()" group-starting-with="*:indexterm[preceding-sibling::node()[self::text() or self::*][1][self::text()][matches(.,'\p{L}$')] and 
        following-sibling::node()[self::text() or self::*][1][self::text()][matches(.,'^\p{L}')]]">
        <xsl:choose>
          <xsl:when test="current-group()[1][self::*:indexterm[preceding-sibling::node()[self::text() or self::*][1][self::text()][matches(.,'\p{L}$')] and 
            following-sibling::node()[self::text() or self::*][1][self::text()][matches(.,'^\p{L}')]]]">
            <xsl:value-of select="replace(current-group()[self::text() or self::*][2][self::text()],'^(\p{L}+)(.*)$','$1')"/>
            <xsl:apply-templates select="current-group()[1]" mode="#current"/>
            <xsl:value-of select="replace(current-group()[self::text() or self::*][2][self::text()],'^(\p{L}+)(.*)$','$2')"/>
            <xsl:apply-templates select="current-group() except (current-group()[1], current-group()[self::text() or self::*][2][self::text()])" mode="#current"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="current-group()" mode="#current"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>
  
</xsl:stylesheet>