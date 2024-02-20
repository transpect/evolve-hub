<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:dbk="http://docbook.org/ns/docbook"
  xmlns:css="http://www.w3.org/1996/css" 
  xmlns:tr="http://transpect.io"
  xmlns:hub="http://transpect.io/hub"
  xmlns="http://docbook.org/ns/docbook"
  xpath-default-namespace="http://docbook.org/ns/docbook"
  exclude-result-prefixes = "xs dbk tr css hub"
  version="2.0">

  <!-- variable mark-regex: a node matching this regex always has to be followed by a tab element! -->
  <xsl:variable name="mark-regex" select="'^([&#x25a1;&#x25cf;&#x2212;&#x2022;&#x2012;-&#x2015;&#x23AF;&#xF0B7;&#xF0BE;&#61485;-]|[\(\[]?(\p{Ll}+|\p{Lu}+|[0-9]+)[.\)\]]?)$'"/>
  <xsl:variable name="mark-exceptions" select="'^(BEISPIEL|ANMERKUNG)$'" as="xs:string"/>
  <xsl:variable name="hub:float-names" select="('figure', 'table', 'informaltable')"/>
  <xsl:variable name="hub:default-tabstop" as="xs:double" select="400"/>
	<xsl:variable name="hub:no-tabs" select="('bibliomisc','biblioentry','anchor', 'appendix', 'citation')"/>
  

  <!-- seems to work for IDML output already (@margin-left, @text-indent already present). 
       To do: use the tabstop information from style definitions. -->

  <!-- GI 2015-11-26: There hasn’t been a @tab-stops attribute for quite some time. This template isn’t used any more.
    The question is whether [@tab-stops] should be replaced with [tabs | key('hub:style-by-role', @role)/tabs] -->

  <!--<xsl:template match="*[
                         @tab-stops
                         and (node()[not(self::*/name()=$hub:no-tabs)])[1]/self::tab
                       ][
                         not(ancestor::*/name() = $hub:float-names)
                       ]" mode="hub:tabs-to-indent">
   	<xsl:copy>
      <xsl:attribute name="text-indent" select="tokenize(tokenize(@tab-stops, ' ')[1], ';')[1]"/>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:apply-templates select="node() except node()[1]" mode="#current"/>
    </xsl:copy>
  </xsl:template>-->
  
  <xsl:template match="  *[not(self::title or child::title) or self::figure or self::table or self::equation]
                          [hub:element-with-tab-and-matching-mark-regex(.)] 
                       | dbk:para[not(hub:is-equation-para(.))]" 
                mode="hub:tabs-to-indent">
      <xsl:copy>
      <xsl:variable name="default-tabstop" as="xs:double"
        select="if (hub:element-with-tab-and-matching-mark-regex(.))
                then $hub:default-tabstop
                else 0"/>
      <xsl:attribute name="text-indent" 
        select="if((@css:text-indent, key('hub:style-by-role', @role)/@css:text-indent)[1] ne '')
                then hub:to-twips((@css:text-indent, key('hub:style-by-role', @role)/@css:text-indent)[1]) 
                else concat('-', $default-tabstop)"/>
      <xsl:attribute name="margin-left" 
        select="if((@css:margin-left, key('hub:style-by-role', @role)/@css:margin-left)[1] ne '') 
                then hub:to-twips((@css:margin-left, key('hub:style-by-role', @role)/@css:margin-left)[1]) 
                else $default-tabstop"/>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:apply-templates select="node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- Remove leading and trailing tabs, add leading tab indent to @text-indent -->
  <xsl:template match="dbk:para[not(@role = $hub:equation-roles)]
                               [
                               .//dbk:tab[not(@role) or @role='docx2hub:generated']
                                           [hub:same-scope(., current())]
                                           [not(parent::dbk:tabs)]
                                           [every $text in current()//(text()[normalize-space()] | * except .)
                                                                        [hub:same-scope(., current())]
                                            satisfies ($text >> .)
                                            or
                                            (every $text in current()//(text()[normalize-space()] | * except .)
                                                                        [hub:same-scope(., current())]
                                            satisfies (. >> $text))]
                               ]"
                mode="hub:tabs-to-indent" priority="1.5">
    <xsl:variable name="tab-decl" as="element(dbk:tab)?"
                  select="(dbk:tabs/dbk:tab[1], key('hub:style-by-role', @role)/dbk:tabs/dbk:tab[1])[1]"/>
    <xsl:variable name="tabstop" as="xs:double"
      select="(for $t in $tab-decl return hub:to-twips($t/@horizontal-position), $hub:default-tabstop)[1]"/>
    <xsl:copy>
      <xsl:attribute name="hub:tab-stop" select="string($tabstop)"/>
      <xsl:apply-templates select="@* except @text-indent" mode="#current"/>
      <!-- If there was no tab decl, the default tab stop was added to an existing text-indent. Hogrefe’s
        101024_12345_DOC (search for '>oder<' after an item 3.) seems to suggest otherwise. -->
      <xsl:attribute name="text-indent" 
        select="(@text-indent[. castable as xs:double], 0)[1] + $tabstop">
        <!-- A negative @text-indent may be compensated by a tab stop of the same width -->
      </xsl:attribute>
      <xsl:apply-templates mode="#current">
        <xsl:with-param name="remove-nodes" as="node()*" tunnel="yes" 
          select=".//dbk:tab[not(@role) or @role='docx2hub:generated']
                             [hub:same-scope(., current())]
                             [not(parent::dbk:tabs)]
                             [every $text in current()//(text()[normalize-space()] | * except .)
                                                                        [hub:same-scope(., current())]
                              satisfies ($text >> .)
                              or
                              (every $text in current()//(text()[normalize-space()] | * except .)
                                                                        [hub:same-scope(., current())]
                              satisfies (. >> $text))
                              (: Example for ($text &lt;&lt; .):
                              http://svn.le-tex.de/svn/ltxbase/Difftestdata/evolve-hub-lists/idml/VDE-S.idml, 
    	                        below chapter 5 heading: Tab at end of para, will become a varlistitem :)]"/>
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="dbk:tab" mode="hub:tabs-to-indent">
    <xsl:param name="remove-nodes" as="node()*" tunnel="yes"/>
    <xsl:choose>
      <xsl:when test="some $n in $remove-nodes satisfies ($n is current())"/>
      <xsl:otherwise>
        <xsl:next-match/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="@hub:tab-stop" mode="hub:lists"/>
  
  <xsl:template match="*[self::figure | self::table][title/(. | key('hub:style-by-role', @role))/@css:margin-left]"
                mode="hub:tabs-to-indent" priority="2.5">
    <xsl:copy>
      <xsl:if test="exists(title/(.| key('hub:style-by-role', @role))/@css:margin-left) and matches(xs:string(hub:to-twips((title/@css:margin-left, key('hub:style-by-role', title/@role)/@css:margin-left)[1])),'^[0-9\.-]+$')">
        <xsl:attribute name="margin-left" 
          select="hub:to-twips((title/@css:margin-left, key('hub:style-by-role', title/@role)/@css:margin-left)[1])"/>
      </xsl:if>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*[name() = ('figure', 'table', 'informalfigure', 'informaltable')]
                        [(. | key('hub:style-by-role', @role))/@css:margin-left]"
                mode="hub:tabs-to-indent">
    <xsl:copy>
      <xsl:if test="exists((.| key('hub:style-by-role', @role))/@css:margin-left) and matches(xs:string(hub:to-twips((@css:margin-left, key('hub:style-by-role', @role)/@css:margin-left)[1])),'^[0-9\.-]+$')">
        <xsl:attribute name="margin-left" 
          select="hub:to-twips((@css:margin-left, key('hub:style-by-role', @role)/@css:margin-left)[1])"/>
      </xsl:if>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*[hub:element-with-tab-and-matching-mark-regex(.)]
    /node()[not(self::anchor) and not(self::tabs)][1][. instance of text()][not(tr:exception-from-identifier-detection(.))]" mode="hub:tabs-to-indent">
    <xsl:param name="identifier-already-tagged" select="false()" tunnel="yes"/>
    <xsl:choose>
      <xsl:when test="$identifier-already-tagged">
        <xsl:next-match>
          <xsl:with-param name="identifier-already-tagged" select="true()" tunnel="yes"/>
        </xsl:next-match>
      </xsl:when>
      <xsl:otherwise>
      <phrase role="hub:identifier">
        <xsl:sequence select="hub:set-origin($set-debugging-info-origin, 'tabs-to-indent_markmatch')"/>
        <xsl:next-match>
          <xsl:with-param name="identifier-already-tagged" select="true()" tunnel="yes"/>
        </xsl:next-match>
      </phrase>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:function name="hub:element-with-tab-and-matching-mark-regex" as="xs:boolean">
    <xsl:param name="element" as="element()"/>
    <xsl:sequence select="boolean(
                            $element[
                              not(self::dbk:phrase or self::dbk:formalpara or self::dbk:footnote or self::subscript or self::superscript)
                            ][
                              not(@tab-stops) 
                              and exists($hub:default-tabstop) 
                              and node()[not(self::anchor) and not(self::tabs)][1][matches(., $mark-regex)][not(matches(., $mark-exceptions))]
                              and (: next content element is an tabulator :)
                              (
                                (:simplest case: second node is the tab :)
                                node()[not(self::anchor) and not(self::tabs)][2]/self::tab 
                                or
                                (: more complex: the next first text node (anywhere nested) is the tabulatur :)
                                node()[not(self::anchor) and not(self::tabs)][2]//node()[hub:same-scope(., $element)][. instance of text()][1]/parent::tab
                              )
                            ][
                              not(ancestor::*/name() = $hub:float-names) and not(self::*/name() = $hub:no-tabs)
                            ]
                          )"/>
  </xsl:function>

  <!--<xsl:function name="hub:element-with-tab" as="xs:boolean">
    <xsl:param name="element" as="element()"/>
    <xsl:sequence select="boolean(
                            $element[
                              not(self::dbk:phrase or self::formalpara)
                            ][
                              not(@tab-stops) 
                              and exists($hub:default-tabstop) 
                              and (: next content element is an tabulator :)
                              (
                                (:simplest case: second node is the tab :)
                                node()[2]/self::tab 
                                or
                                (: more complex: the next first text node (anywhere nested) is the tabulatur :)
                                node()[2]//node()[. instance of text()][1]/parent::tab
                                or
                                (self::para and count(descendant::tab[not(ancestor::*:tabs)])=1)
                              )
                            ][
                              not(ancestor::*/name() = $hub:float-names) and not(self::*/name() = $hub:no-tabs)
                            ]
                          )"/>
  </xsl:function>-->

  <!-- Another class of input: style definitions with css:display="list-item" -->
  
  <xsl:template  mode="hub:tabs-to-indent" priority="2"
    match="*[not(self::title or self::css:rule)]
            [
              (@css:display, key('hub:style-by-role', @role)/@css:display)[1] = 'list-item'
              or
              exists((@css:pseudo-marker_content, key('hub:style-by-role', @role)/@css:pseudo-marker_content))
            ]">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:if test="not(exists(.//phrase[@role = 'hub:identifier'][hub:same-scope(., current())]))">
        <xsl:apply-templates select="(@css:pseudo-marker_content, @css:list-style-type, 
                                      key('hub:style-by-role', @role)/(@css:pseudo-marker_content, @css:list-style-type)
                                     )[1]" mode="hub:list-style-type"/>  
      </xsl:if>
      <xsl:apply-templates mode="#current"/>
    </xsl:copy>
  </xsl:template>

  
  <xsl:template match='@css:pseudo-marker_content[not(. = ("", "&apos;&apos;"))]' mode="hub:list-style-type">
    <phrase role="hub:identifier">
      <xsl:sequence select="hub:set-origin($set-debugging-info-origin, 'tabs-to-indent_pseudocontent')"/>
      <xsl:apply-templates select="../@*[matches(name(), '^css:pseudo-marker_font')]" mode="#current"/>
      <xsl:value-of select='replace(., "^&apos;?(.+?)&apos;?", "$1")'/>
    </phrase>
    <tab>&#9;</tab>
  </xsl:template>
  
  <xsl:template match="@*[matches(name(), '^css:pseudo-marker_font')]" mode="hub:list-style-type">
    <xsl:attribute name="{replace(name(), 'pseudo-marker_', '')}" select="."/>
  </xsl:template>
  
  <xsl:template match="@css:list-style-type" mode="hub:list-style-type">
    <xsl:if test=". ne 'decimal'">
      <phrase role="hub:identifier">
        <xsl:sequence select="hub:set-origin($set-debugging-info-origin, 'tabs-to-indent_liststyletype')"/>
        <xsl:choose>
          <xsl:when test=". = 'box'"><xsl:value-of select="'&#x25fd;'"/></xsl:when>
          <xsl:when test=". = '&#x25fb;'"><xsl:value-of select="."/></xsl:when>
          <xsl:when test=". = 'check'"><xsl:value-of select="'&#x2713;'"/></xsl:when>
          <xsl:when test=". = 'circle'"><xsl:value-of select="'&#x25e6;'"/></xsl:when>
          <xsl:when test=". = 'diamond'"><xsl:value-of select="'&#x25c6;'"/></xsl:when>
          <xsl:when test=". = 'disc'"><xsl:value-of select="'&#x2022;'"/></xsl:when>
          <xsl:when test=". = 'dash'"><xsl:value-of select="'&#x2014;'"/></xsl:when>
          <xsl:when test=". = 'square'"><xsl:value-of select="'&#x25fe;'"/></xsl:when>
          <xsl:when test='matches(., "&apos;")'><xsl:value-of select='replace(., "&apos;","")'/></xsl:when>
        </xsl:choose>
      </phrase>
      <tab>&#9;</tab>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
