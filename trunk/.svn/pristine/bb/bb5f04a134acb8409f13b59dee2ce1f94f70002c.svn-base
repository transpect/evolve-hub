<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:saxon="http://saxon.sf.net/"
	xmlns:dbk="http://docbook.org/ns/docbook"
	xmlns:xlink="http://www.w3.org/1999/xlink"
	xmlns:css="http://www.w3.org/1996/css"
	xmlns:hub="http://transpect.io/hub"
  xmlns:docx2hub="http://transpect.io/docx2hub"
	xmlns="http://docbook.org/ns/docbook"
	xpath-default-namespace="http://docbook.org/ns/docbook"
	exclude-result-prefixes="xs saxon xlink hub dbk"
	>

  <xsl:template match="phrase[every $c in child::node() satisfies ($c/self::text() and matches($c,'^[&#160;\s]*$'))]
                             [every $a in @* satisfies name($a)=('css:top','css:position','css:font-size','css:font-weight','css:font-style','srcpath')]" 
                mode="hub:handle-phrase">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
</xsl:stylesheet>