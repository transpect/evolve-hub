<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:saxon="http://saxon.sf.net/"
	xmlns:dbk="http://docbook.org/ns/docbook"
	xmlns:xlink="http://www.w3.org/1999/xlink"
	xmlns:css="http://www.w3.org/1996/css"
	xmlns:hub="http://transpect.io/hub"
	xmlns:tr="http://transpect.io"
  xmlns:docx2hub="http://transpect.io/docx2hub"
	xmlns="http://docbook.org/ns/docbook"
	xpath-default-namespace="http://docbook.org/ns/docbook"
	exclude-result-prefixes="xs saxon xlink hub dbk"
	>

  <!--  group environments -->
  
  <xsl:variable name="hub:environment-paras" as="xs:string" select="'^Kasten(Typ)(start|stop)(_-_.*)?$'"/>
  <xsl:variable name="hub:environment-paras-start" as="xs:string" select="replace($hub:environment-paras, '\|stop', '')"/>
  <xsl:variable name="hub:environment-paras-end" as="xs:string" select="replace($hub:environment-paras-start, 'start', 'stop')"/>
  
   <!-- call environment grouping template like this -->
  <xsl:template match="*[dbk:para[matches(@role, $hub:environment-paras-end)]]" mode="hub:group-environmentsgroup-environments" priority="5">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:call-template name="environments">
        <xsl:with-param name="input" select="*"/>
      </xsl:call-template>
    </xsl:copy>
  </xsl:template>
  
  <xsl:function name="hub:is-environment-end" as="xs:boolean">
    <xsl:param name="element" as="element(*)"/>
    <xsl:sequence select="matches($element/@role, $hub:environment-paras-end)"/>
  </xsl:function>

  <xsl:function name="hub:is-environment-start" as="xs:boolean">
    <xsl:param name="element" as="element(*)"/>
    <xsl:sequence select="matches($element/@role, $hub:environment-paras-start)"/>
  </xsl:function>

  <xsl:function name="hub:is-environment-start" as="xs:boolean">
    <xsl:param name="element" as="element(*)"/>
    <xsl:param name="start-tag" as="xs:string?"/>
	   <xsl:sequence select="if (matches($element/@role, $hub:environment-paras-start) and 
	      												matches($element/@role, $start-tag) and
													      (
													      not(exists($element/preceding-sibling::dbk:para[matches(@role, concat($start-tag, 'start'))])) or 
													      ($element/preceding-sibling::dbk:para[matches(@role, concat($start-tag, 'stop'))]/position() &lt; $element/preceding-sibling::dbk:para[matches(@role, $start-tag)]/position())
													      )
												      ) 
										      then true() 
										      else false()"/>
  </xsl:function>
  

  <xsl:function name="hub:is-in-environment" as="xs:boolean">
    <xsl:param name="group" as="element(*)*"/>
    <xsl:sequence select="if ($group[1][matches(@role, $hub:environment-paras-start)] and $group[last()][matches(@role, $hub:environment-paras-end)]) then true() else false()"/>
  </xsl:function>
	
  <xsl:function name="tr:box-role" as="xs:string">
    <xsl:param name="elt"/>
    <xsl:variable name="div-role" as="xs:string" select="replace($elt/@role, $hub:environment-paras, '$1')"/>
    <xsl:sequence select="normalize-space($div-role)"/>
  </xsl:function>
  
  <xsl:function name="hub:get-input-depth" as="xs:integer">
    <xsl:param name="element" as="element(*)"/>
    <xsl:param name="depth-map" as="document-node()"/>
    <xsl:sequence select="$depth-map/*:item[@s = $element/@srcpath]/@d"/>
  </xsl:function>
  
   <!-- group environments to divs -->
  <xsl:template name="environments" exclude-result-prefixes="#all">
    <xsl:param name="input" as="element(*)*"/>
  	
    <xsl:variable name="starts" select="$input/self::dbk:para[hub:is-environment-start(.)]"/>
    <xsl:variable name="ends" select="$input/self::dbk:para[hub:is-environment-end(.)]"/>
    
    <xsl:variable name="global-depth-map" select="for $d in $starts union $ends
                                             return (count($d/preceding-sibling::*[hub:is-environment-start(.)])
                                                   - count($d/preceding-sibling::*[hub:is-environment-end(.)]))
                                                   + (if (hub:is-environment-start($d)) then 0 else -1)"/>
    <xsl:variable name="min-depth" select="min($global-depth-map)"/>
    <xsl:variable name="enriched-depth-map">
      <xsl:for-each select="$starts union $ends">
        <xsl:variable name="curr" select="."/>
        <xsl:variable name="position" select="index-of($starts/@srcpath union $ends/@srcpath, current()/@srcpath)"/>
        <xsl:variable name="depth" select="$global-depth-map[position() = $position] - $min-depth"/>
          <item s="{$curr/@srcpath}" 
                p="{$position}"
                t="{if (hub:is-environment-end($curr)) then 'e' else 's'}"
                d="{$depth}"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:for-each-group select="$input" group-starting-with="dbk:para[hub:is-environment-start(.)][hub:get-input-depth(.,$enriched-depth-map) = 0]">
      <xsl:choose>
        <xsl:when test="current-group() intersect $starts">
          <xsl:variable name="start" select="current-group()/self::dbk:para[hub:is-environment-start(.)][hub:get-input-depth(.,$enriched-depth-map) = 0]"/>
          <xsl:variable name="end" select="current-group()/self::dbk:para[hub:is-environment-end(.)][hub:get-input-depth(.,$enriched-depth-map) = 0][1]"/>
          <xsl:variable name="environment" select="$start/following-sibling::* intersect $end/preceding-sibling::*"/>
          <xsl:variable name="div-role" as="xs:string" select="tr:box-role(.[1])"/>
        	<div role="{$div-role}">
        	  <xsl:apply-templates select="$start" mode="#current"/>
            <xsl:call-template name="environments">
              <xsl:with-param name="input" select="$environment"/>
            </xsl:call-template>
        	  <xsl:apply-templates select="$end" mode="#current"/>
        	</div>
          <xsl:apply-templates select="current-group()[not(. intersect ($start/following-sibling::* intersect $end/preceding-sibling::* union ($end,$start)))]" mode="#current"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="current-group()" mode="#current"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each-group>
  </xsl:template>
  
</xsl:stylesheet>