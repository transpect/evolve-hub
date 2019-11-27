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
  xmlns:css="http://www.w3.org/1996/css"
  xmlns:hub="http://transpect.io/hub"
  xmlns="http://docbook.org/ns/docbook"
  version="2.0"
  xpath-default-namespace="http://docbook.org/ns/docbook"
  exclude-result-prefixes = "w o v wx xs dbk pkg r rel word200x exsl saxon fn tr hub css">

  <xsl:template match="keywordset[@role eq 'hub']" mode="hub:postprocess-lists">
    <xsl:copy>
      <xsl:sequence select="@*" />
      <xsl:apply-templates select="keyword except keyword[@role eq 'processed-lists']" mode="#current" />
      <keyword role="processed-lists">true</keyword>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="variablelist[not(@role)][every $x in varlistentry/term satisfies (matches($x, '^[a-z]\)?$') and not($x/phrase[@role = 'hub:identifier'][*]))][not(hub:is-variable-list-because-we-know-better(.))]" mode="hub:postprocess-lists">
    <orderedlist numeration="loweralpha">
      <xsl:apply-templates select="varlistentry/listitem" mode="#current">
        <xsl:with-param name="set-override" select="'term'"/>
      </xsl:apply-templates>
    </orderedlist>
  </xsl:template>

  <xsl:template match="variablelist[not(@role)][every $x in varlistentry/term satisfies (matches($x, '^[0-9]+[.\)]?$') and not($x/phrase[@role = 'hub:identifier'][*]))][not(hub:is-variable-list-because-we-know-better(.))]" mode="hub:postprocess-lists">
    <orderedlist numeration="arabic">
      <xsl:apply-templates select="varlistentry/listitem" mode="#current">
        <xsl:with-param name="set-override" select="'term'"/>
      </xsl:apply-templates>
    </orderedlist>
  </xsl:template>

  <xsl:template match="variablelist[matches(varlistentry[1]/term, '^(&#x2022;|&#x2013;|&#x2014;)$')
                       and (every $x in varlistentry/term satisfies $x = current()/varlistentry[1]/term)]" mode="hub:postprocess-lists">
    <itemizedlist mark="{varlistentry[1]/term}">
      <xsl:apply-templates select="varlistentry/listitem" mode="#current"/>
    </itemizedlist>
  </xsl:template>

  <xsl:template match="variablelist[(every $x in varlistentry/term satisfies
                       (count($x/node()) = 1 and $x/inlineequation))
                       and (every $x in varlistentry/listitem satisfies
                       (count($x/node()) = 1 and $x/para[@role = $hub:equation-roles]))]" mode="hub:postprocess-lists">
    <xsl:for-each select="varlistentry">
      <para>
        <xsl:apply-templates select="listitem/para/@*" mode="#current"/>
        <xsl:apply-templates select="term/node()" mode="#current"/>
        <tab/>
        <xsl:apply-templates select="listitem/para/node()" mode="#current"/>
      </para>
    </xsl:for-each>
  </xsl:template>


  <xsl:template match="blockquote[
                       (every $n in node() satisfies ($n/self::para or $n/self::figure))
                       and node()[1]/node()[not(self::anchor)][1][self::text()[matches(., '^[a-z]\)?$') and following-sibling::node()[1][self::tab]]]
                       and ((for $x in node()/node()[not(self::anchor)][1][self::text()[matches(., '^[a-z]\)?$')]]
                       return string-to-codepoints(replace($x, '^([a-z])\)?$', '$1')))
                       = (string-to-codepoints(replace(node()[1]/node()[not(self::anchor)][1], '^([a-z])\)?$', '$1'))
                          to (string-to-codepoints(replace(node()[1]/node()[not(self::anchor)][1], '^([a-z])\)?$', '$1')) - 1 + count(node()/node()[not(self::anchor)][1][self::text()[matches(., '^[a-z]\)?$')]]))))]" mode="hub:postprocess-lists">
    <orderedlist numeration="loweralpha">
      <xsl:for-each-group select="node()" group-starting-with="para[node()[1][self::text() and matches(., '^[a-z]\)$')]]">
        <listitem>
          <xsl:call-template name="hub:move-condition-up"/>
          <xsl:attribute name="override" select="current-group()[1]/text()[1]"/>
          <xsl:apply-templates select="current-group()[1]" mode="#current">
            <xsl:with-param name="override" select="current-group()[1]/text()[1]"/>
          </xsl:apply-templates>
          <xsl:apply-templates select="current-group()[position() &gt; 1]" mode="#current"/>
        </listitem>
      </xsl:for-each-group>
    </orderedlist>
  </xsl:template>

  <xsl:template match="para[parent::blockquote]" mode="hub:postprocess-lists">
    <xsl:param name="override" select="'none'"/>
    <xsl:copy>
      <xsl:choose>
        <xsl:when test="$override = 'none'">
          <xsl:apply-templates select="@*" mode="#current"/>
          <xsl:apply-templates mode="#current"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="@*" mode="#current"/>
          <xsl:variable name="min-pos" select="if (node()[2][self::tab]) then 2 else 1"/>
          <xsl:apply-templates select="node()[position() &gt; $min-pos]" mode="#current"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="itemizedlist[@mark = 'none']/listitem/@override[. = '']" mode="hub:postprocess-lists"/>

  <!--Put this in the importing stylesheet if you want to get rid of these: 
  <xsl:template match="dbk:blockquote[@role = 'hub:lists']" mode="hub:postprocess-lists">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>-->

  <xsl:template match="varlistentry/listitem" mode="hub:postprocess-lists">
    <xsl:param name="set-override" select="'no'"/>
    <xsl:copy>
      <xsl:call-template name="hub:move-condition-up"/>
      <xsl:choose>
        <xsl:when test="$set-override = 'term'">
          <xsl:attribute name="override" select="preceding-sibling::term"/>
          <xsl:apply-templates select="@* except @override" mode="#current"/>
          <xsl:apply-templates select="preceding-sibling::term/processing-instruction() | preceding-sibling::term/anchor" mode="#current"/>
          <xsl:apply-templates mode="#current"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="@*" mode="#current"/>
          <xsl:apply-templates mode="#current"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="blockquote[parent::entry]" mode="hub:postprocess-lists" priority="2">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <xsl:template match="blockquote[every $n in node() satisfies
                       $n[self::table or self::figure or self::para[@role = $hub:equation-roles]]]"
    mode="hub:postprocess-lists">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <xsl:template match="para//tab[not(@role) or @role='docx2hub:generated'][
                         every $t in ancestor::para[1]//(text() | imageobject)
                         satisfies ($t &gt;&gt; .)
                       ]" mode="hub:postprocess-lists"/>
  
  <!--
      all possible tab-positions are defined in para | css:rule
      however, we dont know the exact starting position of the tab (in pt), as it depends on the length of preceding rendered text
      there are many parameters that influence text length (e.g. font-name, style, size, char-spacing ...) and thus the tab position
      Example: with a definition of 'no-leader' 40pt, 'leader' 200pt, the first <tab> will render the leader only if preceding text extends behind 40pt
  -->
  <xsl:template match="para[$tab-leader-as-role = 'yes']//tab[not(@role)]" mode="hub:postprocess-lists">
    <xsl:variable name="para" select="ancestor::para[1]" as="node()?"/>
    <xsl:variable name="tab-defs" select="($para/tabs, //css:rule[@name = $para/@role]/tabs)[1]/tab" as="node()*"/>
    <xsl:variable name="tab-def" as="node()?"
      select="hub:get-tab-def(preceding::node()[some $p in ancestor::para satisfies $p is $para][hub:same-scope(., $para)], $tab-defs)"/>
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:if test="$tab-def/@leader">
        <xsl:attribute name="role" select="'leader-', $tab-def/@leader" separator=""/>
      </xsl:if>
      <xsl:apply-templates select="node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:function name="hub:get-tab-def" as="node()?">
    <xsl:param name="nodes" as="node()*"/>
    <xsl:param name="tab-def" as="node()*"/>
    <xsl:sequence select="$tab-def[xs:decimal(replace(@horizontal-position, 'pt$', '')) gt hub:heuristic-position-in-pt($nodes, $tab-def)][1]"/>
  </xsl:function>

  <xsl:function name="hub:heuristic-position-in-pt" as="xs:decimal?">
    <xsl:param name="nodes" as="node()*"/>
    <xsl:param name="tab-def" as="node()*"/>
    <xsl:if test="exists($nodes)">
      <xsl:variable name="preceding-heuristic-length" as="xs:decimal?"
        select="hub:heuristic-position-in-pt($nodes[position() lt last()], $tab-def)"/>
      <xsl:variable name="self-heurisitic-length" as="xs:decimal*">
        <xsl:choose>
          <xsl:when test="$nodes[last()]/self::text()">
            <xsl:sequence select="hub:text-length-heuristic($nodes[last()])"/>
          </xsl:when>
          <xsl:when test="$nodes[last()]/self::tab[not(parent::tabs)]">
            <xsl:variable name="tab-def-position" select="for $t in $tab-def return xs:decimal(replace($t/@horizontal-position, 'pt$', ''))" as="xs:decimal*"/>
            <xsl:choose>
              <xsl:when test="some $t in $tab-def-position satisfies $t gt $preceding-heuristic-length">
                <xsl:sequence select="$tab-def-position[. gt $preceding-heuristic-length][1] - $preceding-heuristic-length"/>
              </xsl:when>
              <xsl:otherwise>
                <!-- default tab length 20pt -->
                <xsl:sequence select="20"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
        </xsl:choose>
      </xsl:variable>
      <xsl:sequence select="sum(($preceding-heuristic-length, $self-heurisitic-length))"/>
    </xsl:if>
  </xsl:function>
  
  <xsl:function name="hub:text-length-heuristic" as="xs:decimal*">
    <xsl:param name="text" as="text()"/>
    <!-- match invisible (0-width) chars
      https://www.regular-expressions.info/unicode.html#category
    -->
    <xsl:variable name="regex" select="'\p{Mn}|\p{Me}|\p{Zl}|\p{Zp}|\p{Cc}|\p{Cf}'"/>
    <xsl:variable name="one-char-length" select="6.0225" as="xs:decimal?"/>
    <xsl:analyze-string select="$text" regex="{$regex}">
      <xsl:non-matching-substring>
        <!-- FIXME: include font, size etc. in actual calculation -->
        <xsl:sequence select="string-length(.) * $one-char-length"/>
      </xsl:non-matching-substring>
    </xsl:analyze-string>
  </xsl:function>
  
  <xsl:template match="para/phrase[
                         every $p in preceding-sibling::node()
                         satisfies ($p/self::tabs or $p/self::info)
                         (: also covers the common case not(preceding-sibling::node()) ! :)
                        ][count(node()) eq 1][tab]" mode="hub:postprocess-lists" />

  <xsl:template match="para/tabs[
                         every $p in preceding-sibling::node()
                         satisfies ($p/self::info)
                         (: also covers the common case not(preceding-sibling::node()) ! :)
                       ]" mode="hub:postprocess-lists"/>

  <!-- remove attributes set by mode twipsify-lengths and used by lists-by-indent -->
  <xsl:template match="@*[name() = $twipsify-lengths-attribute-names]" mode="hub:postprocess-lists">
    <xsl:variable name="css-rule" as="element()*"
      select="(key('hub:style-by-role', parent::*/@role))[1]"/>
    <xsl:if test="not(
                    $css-rule/@*[name() = current()/name()] = current() or
                    $css-rule/css:attic/@*[name() = current()/name()] = current()
                  )">
      <xsl:copy/>
    </xsl:if>
  </xsl:template>
  
  <!-- remove these attributes below listitem in any case -->
  <xsl:template match="  @margin-left | listitem/para/@css:margin-left
                       | @text-indent | listitem/para/@css:text-indent" 
                mode="hub:postprocess-lists" priority="1"/>

  <!-- copy condtion attribute (for ex., 'PrintOnly') up to listitem if every child has the same value
       https://redmine.le-tex.de/issues/7738 -->
  <xsl:template match="listitem" mode="hub:postprocess-lists">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:call-template name="hub:move-condition-up"/>
      <xsl:apply-templates mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template name="hub:move-condition-up">
    <xsl:if test="exists(*/@condition) 
                  and 
                  (every $p in * satisfies (exists($p/@condition)))
                  and
                  (count(fn:distinct-values(*/@condition)) eq 1)">
      <xsl:copy-of select="*[1]/@condition"/>
    </xsl:if>
  </xsl:template>

  <!-- Idea for improvement: add the net indentation (css:margin-left + text-indent) as css:margin-left to each 
    itemizedlist, orderedlist, variablelist element. The issue with this approach may be: when converting
    the css properties to style attributes on HTML’s ol, ul, or dl elements, the nested lists
    receive an *extra* margin-left, in addition to the default indentation. -->

  
  <xsl:template match="listitem/para" mode="hub:postprocess-lists">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:apply-templates  mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- css:display = 'block' has been introduced by NoList overrides in IDML -->
  <xsl:template match="listitem/para/@css:display[. = 'block']"/>
  
</xsl:stylesheet>