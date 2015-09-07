<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:dbk="http://docbook.org/ns/docbook"
  xmlns:css="http://www.w3.org/1996/css"
  xmlns:hub="http://transpect.io/hub"
  xmlns="http://docbook.org/ns/docbook"
  xpath-default-namespace="http://docbook.org/ns/docbook"
  exclude-result-prefixes="xs hub dbk"
  version="2.0">

  <xsl:variable name="hub:hierarchy-role-regexes-x" as="xs:string+"
    select="('^[Hh]eading[ ]?1$', '^[Hh]eading[ ]?2$', '^[Hh]eading[ ]?3$', '^[Hh]eading[ ]?4$', '^[Hh]eading[ ]?5$', '^[Hh]eading[ ]?6$')" />

  <xsl:variable name="hub:anchor-ids-to-section" as="xs:boolean" select="false()"/> 

  <!-- Whether title elements should retain their underlying paras’ role attributes.
       In order to override this default setting, declare this as a variable in 
       importing stylesheets and assign a value of true() to that variable. -->
  <xsl:param name="hub:hierarchy-title-roles" as="xs:boolean" select="false()"/>

  <xsl:template match="*[para[@role]]" mode="hub:hierarchy">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:variable name="all-headings" as="element(hub:headings)*">
        <xsl:for-each-group select="*[@role]" group-by="hub:hierarchize_heading-level(., 1)">
          <xsl:if test="current-grouping-key() gt 0">
            <hub:headings level="{current-grouping-key()}">
              <xsl:for-each select="current-group()">
                <hub:heading id="{generate-id()}"/>
              </xsl:for-each>
            </hub:headings>
          </xsl:if>
        </xsl:for-each-group>
      </xsl:variable>
      <xsl:sequence select="hub:hierarchize-by-role(*, $all-headings, 1)" />
    </xsl:copy>
  </xsl:template>
  
  
  <xsl:key name="hub:by-genId" match="*" use="generate-id()"/>
  
  <xsl:function name="hub:hierarchize_heading-level" as="xs:integer+">
    <xsl:param name="elt" as="element(*)"/>
    <xsl:param name="starting-level" as="xs:integer"/>
    <xsl:for-each select="($starting-level to count($hub:hierarchy-role-regexes-x))">
      <xsl:sequence select="hub:hierarchize_level-dispatcher($elt, .)"/>
    </xsl:for-each>
  </xsl:function>

  <!-- Yes, we need function objects… and maps -->
  <xsl:function name="hub:hierarchize_level-dispatcher" as="xs:integer">
    <xsl:param name="elt" as="element(*)"/>
    <xsl:param name="level" as="xs:integer"/>
    <xsl:choose>
      <xsl:when test="$elt/ancestor-or-self::bridgehead"><xsl:sequence select="0"/></xsl:when>
      <xsl:when test="$elt/ancestor-or-self::*/@css:display = 'none'"><xsl:sequence select="0"/></xsl:when>
      <xsl:when test="$level eq 1"><xsl:sequence select="hub:hierarchize_level1($elt)"/></xsl:when>
      <xsl:when test="$level eq 2"><xsl:sequence select="hub:hierarchize_level2($elt)"/></xsl:when>
      <xsl:when test="$level eq 3"><xsl:sequence select="hub:hierarchize_level3($elt)"/></xsl:when>
      <xsl:when test="$level eq 4"><xsl:sequence select="hub:hierarchize_level4($elt)"/></xsl:when>
      <xsl:when test="$level eq 5"><xsl:sequence select="hub:hierarchize_level5($elt)"/></xsl:when>
      <xsl:when test="$level eq 6"><xsl:sequence select="hub:hierarchize_level6($elt)"/></xsl:when>
      <xsl:when test="$level eq 7"><xsl:sequence select="hub:hierarchize_level7($elt)"/></xsl:when>
      <xsl:when test="$level eq 8"><xsl:sequence select="hub:hierarchize_level8($elt)"/></xsl:when>
      <xsl:when test="$level eq 9"><xsl:sequence select="hub:hierarchize_level9($elt)"/></xsl:when>
      <xsl:when test="$level eq 10"><xsl:sequence select="hub:hierarchize_level10($elt)"/></xsl:when>
      <xsl:otherwise><xsl:sequence select="0"/></xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- Distinct functions so that they can be overridden more easily -->
  <xsl:function name="hub:hierarchize_level1" as="xs:integer"><xsl:param name="elt" as="element(*)"/>
    <xsl:sequence select="if ($hub:hierarchy-role-regexes-x[1]) then 1 * xs:integer(matches($elt/@role, $hub:hierarchy-role-regexes-x[1], 'x')) else 0"/></xsl:function>
  <xsl:function name="hub:hierarchize_level2" as="xs:integer"><xsl:param name="elt" as="element(*)"/>
    <xsl:sequence select="if ($hub:hierarchy-role-regexes-x[2]) then 2 * xs:integer(matches($elt/@role, $hub:hierarchy-role-regexes-x[2], 'x')) else 0"/></xsl:function>
  <xsl:function name="hub:hierarchize_level3" as="xs:integer"><xsl:param name="elt" as="element(*)"/>
    <xsl:sequence select="if ($hub:hierarchy-role-regexes-x[3]) then 3 * xs:integer(matches($elt/@role, $hub:hierarchy-role-regexes-x[3], 'x')) else 0"/></xsl:function>
  <xsl:function name="hub:hierarchize_level4" as="xs:integer"><xsl:param name="elt" as="element(*)"/>
    <xsl:sequence select="if ($hub:hierarchy-role-regexes-x[4]) then 4 * xs:integer(matches($elt/@role, $hub:hierarchy-role-regexes-x[4], 'x')) else 0"/></xsl:function>
  <xsl:function name="hub:hierarchize_level5" as="xs:integer"><xsl:param name="elt" as="element(*)"/>
    <xsl:sequence select="if ($hub:hierarchy-role-regexes-x[5]) then 5 * xs:integer(matches($elt/@role, $hub:hierarchy-role-regexes-x[5], 'x')) else 0"/></xsl:function>
  <xsl:function name="hub:hierarchize_level6" as="xs:integer"><xsl:param name="elt" as="element(*)"/>
    <xsl:sequence select="if ($hub:hierarchy-role-regexes-x[6]) then 6 * xs:integer(matches($elt/@role, $hub:hierarchy-role-regexes-x[6], 'x')) else 0"/></xsl:function>
  <xsl:function name="hub:hierarchize_level7" as="xs:integer"><xsl:param name="elt" as="element(*)"/>
    <xsl:sequence select="if ($hub:hierarchy-role-regexes-x[7]) then 7 * xs:integer(matches($elt/@role, $hub:hierarchy-role-regexes-x[7], 'x')) else 0"/></xsl:function>
  <xsl:function name="hub:hierarchize_level8" as="xs:integer"><xsl:param name="elt" as="element(*)"/>
    <xsl:sequence select="if ($hub:hierarchy-role-regexes-x[8]) then 8 * xs:integer(matches($elt/@role, $hub:hierarchy-role-regexes-x[8], 'x')) else 0"/></xsl:function>
  <xsl:function name="hub:hierarchize_level9" as="xs:integer"><xsl:param name="elt" as="element(*)"/>
    <xsl:sequence select="if ($hub:hierarchy-role-regexes-x[9]) then 9 * xs:integer(matches($elt/@role, $hub:hierarchy-role-regexes-x[9], 'x')) else 0"/></xsl:function>
  <xsl:function name="hub:hierarchize_level10" as="xs:integer"><xsl:param name="elt" as="element(*)"/>
    <xsl:sequence select="if ($hub:hierarchy-role-regexes-x[10]) then 10 * xs:integer(matches($elt/@role, $hub:hierarchy-role-regexes-x[10], 'x')) else 0"/></xsl:function>
  
  <xsl:function name="hub:hierarchize-by-role" as="element(*)*" xmlns="http://docbook.org/ns/docbook">
    <xsl:param name="elts" as="element(*)*"/>
    <xsl:param name="all-headings" as="element(hub:headings)*"/>
    <xsl:param name="starting-level" as="xs:integer"/>
    <xsl:choose>
      <xsl:when test="empty($elts)"/>
      <xsl:when test="empty($all-headings)">
        <xsl:apply-templates select="$elts" mode="hub:hierarchy"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="root" select="root($elts[1])" as="document-node()"/>
        <xsl:variable name="headings"
          select="$all-headings/hub:heading[not(empty(key('hub:by-genId', @id, $root) intersect $elts))]"
          as="element(hub:heading)*"/>
        <xsl:choose>
          <xsl:when test="empty($headings)">
            <xsl:apply-templates select="$elts" mode="hub:hierarchy"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="top-level" select="if ($headings) then xs:integer(min($headings/../@level)) else 0"
              as="xs:integer"/>
            <xsl:variable name="top-level-headings" select="$headings[xs:integer(../@level) eq $top-level]" as="element(hub:heading)*"/>
            <xsl:for-each-group select="$elts" group-starting-with="*[generate-id() = $top-level-headings/@id]">
              <xsl:choose>
                <xsl:when test="generate-id() = $top-level-headings/@id">
                  <section>
                    <xsl:variable name="anchor" as="element(anchor)?" select="(.//anchor[@xml:id][not(matches(@xml:id, 'page(end)?_'))][hub:same-scope(., current())])[1]"/>
                    <xsl:if test="$hub:anchor-ids-to-section">
                      <xsl:copy-of select="$anchor/@xml:id"/>
                    </xsl:if>
                    <xsl:apply-templates select="@role" mode="hub:hierarchy"/>
                    <xsl:if test="$top-level gt $starting-level">
                      <xsl:attribute name="renderas" select="concat('sect', $top-level)"/>
                    </xsl:if>
                    <title>
                      <xsl:if test="$hub:hierarchy-title-roles">
                        <xsl:apply-templates select="@role" mode="hub:hierarchy"/>
                      </xsl:if>
                      <xsl:variable name="potential-end-anchor" as="element(anchor)?"
                        select=".//anchor[hub:same-scope(., current())]
                                         [@xml:id = string-join(($anchor/@xml:id, '_end'), '')]"/>
                      <xsl:apply-templates select="@* except @role, node()" mode="hub:hierarchy">
                        <xsl:with-param name="suppress" select="if ($hub:anchor-ids-to-section) 
                                                                then ($anchor, $potential-end-anchor) 
                                                                else ()" tunnel="yes"/>
                      </xsl:apply-templates>
                    </title>
                    <xsl:sequence
                      select="hub:hierarchize-by-role(
                                current-group()[position() gt 1], 
                                $all-headings[xs:integer(@level) gt $top-level], 
                                $starting-level + 1
                              )"/>
                  </section>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:sequence
                    select="hub:hierarchize-by-role(
                              current-group(),
                              $all-headings[xs:integer(@level) gt $top-level], 
                              $top-level
                            )"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:for-each-group>  
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:template match="info/keywordset[@role eq 'hub']" mode="hub:hierarchy">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*" mode="#current" />
      <xsl:apply-templates select="keyword[not(@role eq 'hierarchized')]" mode="#current" />
      <keyword role="hierarchized">true</keyword>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="section/@role[$hub:hierarchy-title-roles]" mode="hub:postprocess-hierarchy"/>

</xsl:stylesheet>
