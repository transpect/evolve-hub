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
  version="2.0"
  xpath-default-namespace="http://docbook.org/ns/docbook"
  exclude-result-prefixes="w o v wx xs dbk pkg r rel word200x exsl saxon fn tr hub">

  <xsl:variable name="hub:table-title-role-regex-x" as="xs:string" 
    select="'^(
                 Table_?title
               | TabletitleinA
               | tablelegend
               | Table_Legend_\d+-row
               | Tabelle
               | Table
	       | Caption
	       | Beschriftung
              )$'"/>

  <xsl:variable name="hub:table-caption-start-regex" as="xs:string"
    select="'Tab\.|Tabellen?|Tabel|Tables?'"/>

  <xsl:variable name="hub:table-caption-must-begin-with-table-caption-start-regex"  as="xs:boolean"
    select="true()" />

  <xsl:variable name="hub:table-graphic-creation-enabled" as="xs:boolean" 
    select="true()" />

  <!-- For preprocessing (merging stand-alone table number paras with title paras): -->
  <xsl:variable name="hub:table-number-role-regex-x" as="xs:string" 
    select="'^Table_Number$'"/>
  
  <xsl:variable name="hub:table-note-style-regex-x" as="xs:string" 
    select="'^letex_table_note$'"/>

  <xsl:variable name="hub:role-thats-never-table-title" as="xs:string" 
    select="'^letex_standard$|^letex_linking$'"/>
  
  <xsl:variable name="hub:use-title-child-anchor-id-for-table-id"  as="xs:boolean"
    select="true()" />

  <xsl:variable name="hub:table-copyright-style-regex-x" as="xs:string" select="'^letex_table_copyright$'"/>
  
  <xsl:function name="hub:is-table-title" as="xs:boolean">
    <xsl:param name="node" as="node()?"/>
    <xsl:sequence select="if (
                               $node/self::para[
                                 matches(@role, $hub:table-title-role-regex-x, 'x')
                                 and not(informaltable)
                               ]
                               or 
                               (
                                 $node/self::para[ 
                                   matches(
                                     string-join(descendant::text()[hub:same-scope(., $node)], ''), 
                                     concat('^(', $hub:table-caption-start-regex, ')')
                                   )
                                   and not(some $role in descendant-or-self::*/@role 
                                           satisfies matches($role,$hub:role-thats-never-table-title))
                                   and
                                   (
                                     $node/following-sibling::node()[1][
                                       self::informaltable or para[
                                         count(node()) = 1 and mediaobject
                                       ]
                                     ]
                                     or
                                     not( $hub:table-caption-must-begin-with-table-caption-start-regex )
                                   )
                                 ]
                               )
                             )
                             then true() 
                             else false()"/>
  </xsl:function>
  
  <xsl:function name="hub:is-informaltable-para" as="xs:boolean">
    <xsl:param name="_para" as="element(para)"/>
    <xsl:sequence select="exists($_para/informaltable)
                          and 
                          count(
                            $_para/node()[
                              empty(self::processing-instruction() 
                                    | self::text()[not(normalize-space())]
                                    | self::anchor 
                                    | self::tabs)
                            ]
                          ) = 1"/>
  </xsl:function>

  <xsl:function name="hub:is-table-not-in-table-env" as="xs:boolean">
    <xsl:param name="node" as="node()"/>
    <xsl:sequence select="exists($node/self::informaltable)
                          or
                          exists($node/self::para[hub:is-informaltable-para(.)])"/>
  </xsl:function>

</xsl:stylesheet>
