<?xml version="1.0" encoding="UTF-8"?>
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
  
  <!-- display elements at the end of a list should be removed from that list -->
  <xsl:template match="*[matches(name(),'list$')]
                        [not(ancestor::*[matches(name(),'list$')])]
                        [child::*[last()]
                                 [(descendant-or-self::node()[parent::listitem]
                                                             [(local-name()=$hub:level-element-names) or 
                                                              self::para[not(matches(@role,'^list\-'))]
                                                                        [tr:is-level-element-para(.)] or
                                                              self::*[matches(@role,'^list\-')]])[last()]
                                                                                                 [self::*[(local-name()=$hub:level-element-names) or 
                                                                                                          self::para[not(matches(@role,'^list\-'))]
                                                                                                                    [tr:is-level-element-para(.)]]]]]" 
                mode="hub:postprocess-lists-by-role">
    <xsl:next-match/>
    <xsl:apply-templates select="(descendant-or-self::node()[parent::listitem]
                                                            [(local-name()=$hub:level-element-names) or 
                                                             self::para[not(matches(@role,'^list\-'))]
                                                                       [tr:is-level-element-para(.)] or
                                                             self::*[matches(@role,'^list\-')]])[last()]
                                                                                                [self::*[(local-name()=$hub:level-element-names) or 
                                                                                                         self::para[not(matches(@role,'^list\-'))]
                                                                                                                   [tr:is-level-element-para(.)]]]" mode="#current">
      <xsl:with-param name="display-last-element" select="true()"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template match="node()[parent::listitem]
                             [(local-name()=$hub:level-element-names) or 
                              self::para[not(matches(@role,'^list\-'))]
                                        [tr:is-level-element-para(.)] or
                              self::*[matches(@role,'^list\-')]]
                             [generate-id()=
                              (//*[matches(name(),'list$')]
                                  [not(ancestor::*[matches(name(),'list$')])]/child::*[last()]/
                                        (descendant-or-self::node()[parent::listitem]
                                                                   [(local-name()=$hub:level-element-names) or 
                                                                    self::para[not(matches(@role,'^list\-'))]
                                                                              [tr:is-level-element-para(.)] or
                                                                    self::*[matches(@role,'^list\-')]])[last()]
                                                                                                       [self::*[(local-name()=$hub:level-element-names) or 
                                                                                                                self::para[not(matches(@role,'^list\-'))]
                                                                                                                          [tr:is-level-element-para(.)]]]/generate-id())]" 
                mode="hub:postprocess-lists-by-role">
    <xsl:param name="display-last-element" select="false()"/>
    <xsl:if test="$display-last-element">
      <xsl:next-match/>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="orderedlist/listitem/para[1]/phrase[@role eq 'hub:identifier'][1]
                      |itemizedlist/listitem/para[1]/phrase[@role eq 'hub:identifier'][1]" mode="hub:postprocess-lists-by-role"/>
  
  <xsl:template match="orderedlist/listitem[para[1]/phrase[@role eq 'hub:identifier'][1]]" mode="hub:postprocess-lists-by-role">
    <xsl:copy>
      <xsl:attribute name="override" select="para[1]/phrase[@role eq 'hub:identifier'][1]"/>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
</xsl:stylesheet>