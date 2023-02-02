<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
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
  
  <xsl:variable name="lists-by-role-style-map-doc" 
    select="if (not($lists-by-role-style-map='') and doc-available($lists-by-role-style-map)) then document($lists-by-role-style-map) else ()"/>
  
  <!-- map of roles to replace by standardized list-roles 
       If via $lists-by-role-style-map an existing map is present, no new map will be generated from current document -->
  <xsl:variable name="lists-by-role-map" as="element(html:html)">
    <xsl:choose>
      <xsl:when test="not(empty($lists-by-role-style-map-doc))">
        <xsl:sequence select="$lists-by-role-style-map-doc//html:html"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="//css:rules" mode="hub:build-style-map"/>        
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <!-- generates style map using included word styles -->
  <xsl:template match="css:rules" mode="hub:build-style-map">
    <html xmlns="http://www.w3.org/1999/xhtml">
      <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
        <title>lists by role style map</title>
      </head>
      <body>
        <table>
          <tr>
            <th>Systemname</th>
            <th>Benutzername</th>
          </tr>
          <xsl:for-each select="css:rule[@layout-type='para'][@name=//para/@role]">
            <xsl:sort order="descending" select="string-length(@name)"/>
            <tr>
              <td>
                <xsl:value-of select="if (@css:list-style-type) 
                                      then tr:get-list-type-new-role(.) 
                                      else tr:get-non-list-type-new-role(@name)"/>
              </td>
              <td>
                <xsl:value-of select="@name"/>
              </td>
            </tr>  
          </xsl:for-each>
        </table>
      </body>
    </html>
  </xsl:template>
  
  <xsl:template match="/" mode="hub:prepare-lists-by-role">
    <xsl:message>
      Style map can be found in <xsl:value-of select="concat($debug-dir-uri,'/evolve-hub/lists-by-role-style-map.xhtml')"/>
    </xsl:message>
    <xsl:result-document  href="{concat($debug-dir-uri,'/evolve-hub/lists-by-role-style-map.xhtml')}">
      <xsl:sequence  select="$lists-by-role-map"/>
    </xsl:result-document>
    <xsl:next-match/>
  </xsl:template>
  
  <!-- all roles are mapped to normalized list roles according to $lists-by-role-map
       original roles are kept in @orig-role (will be restored in mode hub:restore-roles) -->
  <xsl:template match="para/@role" mode="hub:prepare-lists-by-role">
    <xsl:variable name="map-role" select="$lists-by-role-map//html:tr[count(html:td)=2][matches(current(),html:td[2])][1]/html:td[1]"/>
    <xsl:choose>
      <xsl:when test="not(empty($map-role))">
        <xsl:attribute name="orig-role" select="."/>
        <xsl:attribute name="role" select="if (matches($map-role,'^list\-.*\-[0-9]+$') and 
                                               not(parent::*/descendant::phrase[@role='hub:identifier'][not(ancestor::footnote)]) and
                                               not(matches($map-role,'^list\-(definition|simple)\-[0-9]+$')))
                                           then replace($map-role,'^(list\-).*(\-[0-9]+)$','$1continue$2')
                                           else $map-role"/>        
      </xsl:when>
      <xsl:otherwise>
        <xsl:next-match/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
</xsl:stylesheet>