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
  exclude-result-prefixes = "w o v wx xs dbk pkg r rel word200x exsl saxon fn tr hub">
  
  <xsl:param name="hub:handle-several-images-per-caption" as="xs:boolean" select="false()">
    <!-- will call another template in figure captions that tries to create figures of several images having just one caption -->
  </xsl:param>
  
  <xsl:param name="hub:merge-several-caption-paras" as="xs:boolean" select="false()">
    <!-- will create figure title consisting of all caption para nodes separated by <br/> so it can be split later on -->
  </xsl:param>

  <xsl:variable name="hub:figure-title-role-regex-x" as="xs:string"
    select="'^(
                 Figure_?title
               | figlegend
               | Figure_Legend
              )$'" />
  
  <xsl:variable name="hub:subfigure-caption-role-regex-x" as="xs:string"
    select="'^this-should-be-overriden-by-a-custom-regex$'" />
  
  <xsl:variable name="hub:figure-title-further-paras-role-regex-x" as="xs:string" select="'figure_title_2'"/>
  
  <xsl:variable name="hub:figure-caption-start-regex"  as="xs:string" select="'Bild|Abbildung|Abbildungen|Abb\.|Figuu?res?|Figs?\.?'"/>

  <xsl:variable name="hub:figure-note-role-regex"  as="xs:string" select="'^figure_note$'" />
  
  <xsl:variable name="hub:figure-copyright-statement-role-regex"  as="xs:string" select="'^figure_copyright$'" />
  
  <!-- variable hub:use-title-child-anchor-id-for-figure-id
       Wether if there is an anchor[@xml:id] in the figure environment (will be suppressed), 
       should the ID be used as figure/@xml:id ?
  -->
  <xsl:variable name="hub:use-title-child-anchor-id-for-figure-id"  as="xs:boolean"
    select="true()" />

  <!-- In IDML2APP we always know the paragraph with style 'Figure_Legend' is a figure title -->
  <xsl:variable name="hub:figure-caption-must-begin-with-figure-caption-start-regex"  as="xs:boolean"
    select="true()" />

  <!-- variable hub:remove-para-wrapper-for-mediaobject:
       Context: <para><mediaobject></para>
       With this variable set to 'true()' the surrounding para element will be removed.
       'false()' doesn't touch the context - no changes.

       You may need this (and remove the paragraph later) when lists-by-indent 
       should consider also the indentation of any figure or mediaobject-para.
  -->
  <xsl:variable name="hub:remove-para-wrapper-for-mediaobject"  as="xs:boolean"
    select="true()" />

  <!-- For preprocessing (merging stand-alone figure number paras with title paras): -->
  <xsl:variable name="hub:figure-number-role-regex-x" as="xs:string" 
    select="'^Figure_Number$'"/>
  
  <!-- checks whether the current node 
      (1) contains para/mediaobject and only breaks and whitespace,
      (2) contains para/phrase/mediaobject and only breaks and whitespace on each level or 
      (3) is an mediaobject itself.
      result is boolean.
  -->
  
  <xsl:function name="hub:is-figure" as="xs:boolean">
    <xsl:param name="node" as="node()?"/>
    <xsl:sequence select="if 
                          (
                            $node/self::para[mediaobject and matches(hub:same-scope-text(.),'^[\s&#xa0;&#x2002;]*$')]
                            or 
                            $node/self::para[phrase/mediaobject and matches(hub:same-scope-text(.),'^[\s&#xa0;&#x2002;]*$')
                              and matches(hub:same-scope-text(phrase),'^[\s&#xa0;&#x2002;]*$')]
                            or 
                            $node/self::mediaobject
                          )
                          then true() 
                          else false()"/>
  </xsl:function>

  <xsl:function name="hub:is-figure-title" as="xs:boolean">
    <xsl:param name="node" as="node()?"/>
    <xsl:sequence select="exists(
                               $node/self::para[
                                 matches(@role, $hub:figure-title-role-regex-x, 'x')
                                 and descendant::text()
                                 and 
                                 ( 
                                   matches( hub:same-scope-text(.), concat('^(', $hub:figure-caption-start-regex, ')'))
                                   or not( $hub:figure-caption-must-begin-with-figure-caption-start-regex )
                                 )
                               ]
                             )"/>
  </xsl:function>
  
  <xsl:function name="hub:is-subfigure" as="xs:boolean">
    <xsl:param name="node" as="node()?"/>
    <xsl:sequence select="
      count($node/(mediaobject, inlinemediaobject, phrase/(mediaobject, inlinemediaobject))) = 1
      and 
        (
          hub:is-subfigure-caption($node/following-sibling::element()[1])
          or
          hub:is-subfigure-caption(($node/mediaobject/caption/para)[1])
        )"/>
  </xsl:function>
  
  <xsl:function name="hub:is-subfigure-caption" as="xs:boolean">
    <xsl:param name="node" as="node()?"/>
    <xsl:sequence select="exists(
                               $node/self::para[matches(@role, $hub:subfigure-caption-role-regex-x, 'x')]
                             )"/>
  </xsl:function>

</xsl:stylesheet>
