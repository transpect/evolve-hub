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
  
  <xsl:variable name="hub:equation-roles" as="xs:string+" select="('Formula', 'Equation', 'equation')" />
  
  <!-- roles that should be ignored if mapping heuristically -->
  <xsl:variable name="hub:exclude-prepare-list-roles-regexes"
                select="($hub:hierarchy-role-regexes-x,
                         '[bB]iblio',
                         $hub:equation-roles,
                         '[Ff](oot|u)note',
                         '[lL]egend',
                         '[hH]ead',
                         '[Tt]itle',
                         '([uU]nt|b)erschrift',
                         '[cC]aption')"/>
  
  <!-- determines the elements apart from para that can be part of a list -->
  <xsl:variable name="hub:level-element-names" select="('table','figure','equation','informalfigure','informaltable')"/>
  
  <!-- regex for possible list continuation styles -->
  <xsl:variable name="hub:list-continue-style-regex" 
                select="'((num|list|aufzhl).*?(continue|fort(ge)?setz)|(continue|fort(ge)?setz).*?(num|list|aufzhl))'"/>

  <!-- determines the roles apart from the mapped list roles whose paras can be part of a list -->
  <xsl:variable name="hub:list-role-strings" select="('Note')"/>

  <!-- para/@roles matching this regex are part of an ordered list -->
  <xsl:variable name="hub:ordered-list-styles-regex" select="'^((lower|upper)(alpha|roman)|arabic|decimal(leadingzero)?)$'"/>
  
</xsl:stylesheet>