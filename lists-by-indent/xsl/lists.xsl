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
  xmlns:exsl='http://exslt.org/common'
  xmlns:saxon="http://saxon.sf.net/"
  xmlns:tr="http://transpect.io"
  xmlns:hub="http://transpect.io/hub"
  xmlns="http://docbook.org/ns/docbook"
  version="2.0"
  xpath-default-namespace="http://docbook.org/ns/docbook"
  exclude-result-prefixes = "w o v wx xs dbk pkg r rel word200x exsl saxon fn tr">

  <xsl:variable name="hub:itemizedlist-mark-chars-regex" as="xs:string"
    select="'([&#xb7;&#x25aa;&#x25a1;&#x25b6;&#x25cf;&#x2212;&#x2022;\p{So}\p{Pd}&#x23af;&#xF0B7;&#xF0BE;&#61485;-])'"/>
  <!-- [A-Z] not followed by dot: confusion with people’s initials in indented paras -->
  <xsl:variable name="hub:orderedlist-mark-chars-regex" as="xs:string"
    select="'[\(\[]?(([ivx]+|[IVX]+|[a-z]|[A-Z]|&#x2007;*[0-9]+)(\.\d+)*)[.:]?[\)\]]?'"/>
  <xsl:variable name="hub:itemizedlist-mark-regex" as="xs:string"
    select="concat('^', $hub:itemizedlist-mark-chars-regex, '$')"/>
  <xsl:variable name="hub:orderedlist-mark-regex" as="xs:string"
    select="concat('^', $hub:orderedlist-mark-chars-regex, '$')"/>
  <xsl:variable name="hub:itemizedlist-mark-at-start-regex" as="xs:string"
    select="concat('^', $hub:itemizedlist-mark-chars-regex, '([\p{Zs}\s]+|$)')"/>
  <xsl:variable name="hub:orderedlist-mark-at-start-regex" as="xs:string"
    select="concat('^(', $hub:orderedlist-mark-chars-regex, ')([\p{Zs}\s]+|$)')"/>

  <!-- var hub:equation-roles:
       List of paragraph role attribute values to exclude from list processing. 
  -->
  <xsl:variable name="hub:equation-roles" as="xs:string+" select="('Formula', 'Equation')" />


  <!-- itemizedlist -->

  <xsl:template match="orderedlist[
                                    hub:is-itemized-list(.) and
                                    listitem[1]/para[1]//phrase[
                                      hub:same-scope(., current()/listitem[1]/para[1])
                                    ][hub:is-identifier(.)]
                                  ]" mode="hub:lists" priority="1">
    <xsl:variable name="first-para" as="element(para)" select="listitem[1]/para[1]"/>
    <xsl:variable name="identifier" as="element(phrase)" 
      select="($first-para//phrase[hub:same-scope(., $first-para)][hub:is-identifier(.)])[1]"/>
    <itemizedlist mark="{hub:get-list-type-with-warning($identifier)}">
      <!-- mark="{listitem[1]/para[1]//descendant::phrase[hub:is-identifier(.)]}" -->
      <xsl:apply-templates mode="#current">
        <xsl:with-param name="set-override" select="'no'" tunnel="yes"/>
        <xsl:with-param name="identifier-needed" select="'no'" tunnel="yes"/>
      </xsl:apply-templates>
    </itemizedlist>
  </xsl:template>

  <!-- orderedlist -->

  <xsl:template match="orderedlist[hub:is-ordered-list(.)]" mode="hub:lists">
    <xsl:variable name="list-type" select="hub:get-list-type-with-warning(listitem/para[1]//phrase[hub:is-identifier(.)])"/>
    <xsl:copy>
      <xsl:attribute name="numeration" select="$list-type"/>
      <xsl:apply-templates mode="#current">
        <xsl:with-param name="set-override" select="'yes'" tunnel="yes"/>
        <xsl:with-param name="identifier-needed" select="'no'" tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="listitem" mode="hub:lists">
    <xsl:param name="set-override" select="'no'" tunnel="yes"/>
    <xsl:copy>
      <xsl:if test="$set-override = 'yes'">
        <xsl:attribute name="override" select="para[1]//phrase[hub:same-scope(., current())][hub:is-identifier(.)]"/>
      </xsl:if>
      <xsl:apply-templates mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <!-- variablelist -->

  <xsl:template match="orderedlist[hub:is-variable-list(.)]" mode="hub:lists">
    <variablelist>
      <xsl:apply-templates mode="#current">
        <xsl:with-param name="is-variable-list" select="true()"/>
      </xsl:apply-templates>
    </variablelist>
  </xsl:template>

  <xsl:template match="listitem[parent::orderedlist[hub:is-variable-list(.)]]" mode="hub:lists">
    <xsl:param name="is-variable-list" select="false()"/>
    <xsl:variable name="first-para" select="para[1]" as="element(para)?"/>
    <xsl:choose>
      <xsl:when test="$is-variable-list and not($first-para)"><!-- for ex., informaltable in listitem -->
      	<varlistentry>
          <term/>
          <xsl:copy>
            <xsl:apply-templates select="node()" mode="#current"/>
          </xsl:copy>
        </varlistentry>
      </xsl:when>
    	<xsl:when test="$is-variable-list">
    	  <xsl:variable name="first-tab" select="($first-para//tab[not(parent::tabs)][hub:same-scope(., current())])[1]" as="element(tab)"/>
        <varlistentry>
          <term>
            <xsl:copy-of select="hub:split-term-at-tab($first-para,$first-tab)"/>
          </term>
          <xsl:copy>
            <xsl:apply-templates select="node()[. &lt;&lt; $first-para]" mode="#current"/>
            <xsl:copy-of select="hub:split-listitem-at-tab($first-para,$first-tab)"/>
            <xsl:apply-templates select="node()[. &gt;&gt; $first-para]" mode="#current"/>
          </xsl:copy>
        </varlistentry>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy>
          <xsl:apply-templates select="@*" mode="#current"/>
        	<xsl:attribute name="override" select="$first-para//phrase[hub:same-scope(., current())][hub:is-identifier(.)]"/>
          <xsl:apply-templates mode="#current"/>
        </xsl:copy>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:function name="hub:split-term-at-tab">
    <xsl:param name="node" as="node()"/>
    <xsl:param name="split-point" as="node()"/>
    
    <xsl:apply-templates select="$node/node() intersect $split-point/preceding::node()" mode="hub:lists-remove-identifier"/>
    <xsl:if test="count($node/node() intersect $split-point) = 0">
      <xsl:apply-templates select="hub:split-term-element-at-tab($node/node()[count(descendant::node() intersect $split-point)=1],$split-point)" mode="hub:lists"/>
    </xsl:if>
  </xsl:function>
  
  <xsl:function name="hub:split-term-element-at-tab">
    <xsl:param name="node" as="node()"/>
    <xsl:param name="split-point" as="node()"/>
    
    <xsl:element name="{$node/local-name()}">
      <xsl:apply-templates select="$node/@*" mode="hub:lists"/>
      <xsl:apply-templates select="$node/node() intersect $split-point/preceding::node()" mode="hub:lists"/>
      <xsl:if test="count($node/node() intersect $split-point) = 0">
        <xsl:apply-templates select="hub:split-term-element-at-tab($node/node()[count(descendant::node() intersect $split-point)=1],$split-point)" mode="hub:lists"/>
      </xsl:if>
    </xsl:element>
  </xsl:function>
  
  <xsl:function name="hub:split-listitem-at-tab">
    <xsl:param name="node" as="node()"/>
    <xsl:param name="split-point" as="node()"/>
    
    <xsl:element name="{$node/local-name()}">
      <xsl:apply-templates select="$node/@*" mode="hub:lists"/>
      <xsl:if test="count($node/node() intersect $split-point) = 0">
        <xsl:apply-templates select="hub:split-listitem-at-tab($node/node()[count(descendant::node() intersect $split-point)=1],$split-point)" mode="hub:lists"/>
      </xsl:if>
      <xsl:apply-templates select="$node/node() intersect $split-point/following::node()" mode="hub:lists"/>
    </xsl:element>
  </xsl:function>

  <xsl:template match="node()[not(self::phrase[@role eq 'hub:identifier'])]" mode="hub:lists-remove-identifier">
    <xsl:apply-templates select="." mode="hub:lists"/>
  </xsl:template>

  <xsl:template match="phrase[@role eq 'hub:identifier']" mode="hub:lists-remove-identifier">
    <xsl:apply-templates mode="hub:lists"/>
  </xsl:template>

  <!-- continuations: -->
  <xsl:template match="orderedlist[parent::listitem]
                                  [hub:has-no-identifiers(.)]
                                  [not(hub:is-variable-list(.))]
                                  [hub:same-margin-left(., parent::listitem/para[1]/@margin-left)]" 
                mode="hub:lists" priority="1.5"><!-- higher priority than 1, which is the priority of the itemizedlist template (around line 50) -->
    <xsl:apply-templates select="listitem/node()" mode="#current"/>
  </xsl:template>


  <!-- Mischung aus Folgeabsätzen und Unterpunkten oder Listen verschiedenen Typs, die zerschnitten werden müssen -->
  <xsl:template match="orderedlist[some $x in listitem/para[1] satisfies exists($x//phrase[hub:same-scope(., $x)][hub:is-identifier(.)])
                       and not(hub:is-ordered-list(.)) and not(hub:is-itemized-list(.)) and not(hub:is-variable-list(.))]" mode="hub:lists">
    <xsl:for-each-group select="*" 
      group-adjacent="if (para[1][descendant::phrase[hub:same-scope(., current())][hub:is-identifier(.)][1]])
                      then 
                        if (matches(para[1]/descendant::phrase[hub:same-scope(., current())][hub:is-identifier(.)][1], $hub:itemizedlist-mark-regex))
                        then 'itemizedlist' 
                        else 
                          if (matches(para[1]/descendant::phrase[hub:same-scope(., current())][hub:is-identifier(.)][1], $hub:orderedlist-mark-regex))
                          then 'orderedlist' 
                          else 'variablelist'
                      else 
                        if (hub:is-variable-list-listitem-without-phrase-identifier(para[1]))
                        then 'variablelist'
                        else 'nolist'">
      <xsl:choose>
        <xsl:when test="current-grouping-key() = 'itemizedlist'">
          <xsl:for-each-group select="current-group()" group-adjacent="hub:get-list-type-with-warning(para[1]//phrase[hub:same-scope(.,current-group()[1]/para[1])][hub:is-identifier(.)][1])">                
            <itemizedlist mark="{current-grouping-key()}">
              <xsl:apply-templates select="current-group()" mode="#current">
                <xsl:with-param name="identifier-needed" tunnel="yes" select="'no'"/>
                <xsl:with-param name="set-override" select="'no'" tunnel="yes"/>
              </xsl:apply-templates>
            </itemizedlist>
          </xsl:for-each-group>
        </xsl:when>
        <xsl:when test="current-grouping-key() = 'orderedlist'">
          <xsl:for-each-group select="current-group()" group-adjacent="hub:get-list-type-with-warning(para[1]//phrase[hub:same-scope(.,current-group()[1]/para[1])][hub:is-identifier(.)][1])">
            <orderedlist numeration="{current-grouping-key()}">
              <xsl:apply-templates select="current-group()" mode="#current">
                <xsl:with-param name="set-override" select="'yes'" tunnel="yes"/>
                <xsl:with-param name="identifier-needed" tunnel="yes" select="'no'"/>
              </xsl:apply-templates>
            </orderedlist>
          </xsl:for-each-group>
        </xsl:when>
        <xsl:when test="current-grouping-key() = 'variablelist'">
          <variablelist>
            <xsl:for-each select="current-group()">
              <xsl:variable name="li" select="." as="element(listitem)"/>
              <xsl:variable name="first-para" select="para[1]" as="element(para)?"/>
              <varlistentry>
                <xsl:choose>
                  <xsl:when test="$first-para//phrase[hub:same-scope(., $li/$first-para)][hub:is-identifier(.)]">
                    <term>
                      <xsl:copy-of select="$first-para//phrase[hub:same-scope(., $li/$first-para)][hub:is-identifier(.)]"/>
                    </term>
                    <xsl:copy>
                      <para>
                        <xsl:apply-templates select="$first-para/@*, 
                                                     $first-para/node()[hub:same-scope(., $li/$first-para)] 
                                                     except (
                                                       $first-para/tab[preceding-sibling::*[1][hub:is-identifier(.)]],
                                                       $first-para//phrase[hub:same-scope(., $li/$first-para)][hub:is-identifier(.)]
                                                     )" mode="#current"/>
                      </para>
                      <xsl:apply-templates select="node()[. &gt;&gt; $li/$first-para]" mode="#current"/>
                    </xsl:copy>
                  </xsl:when>
                  <xsl:otherwise>
                    
                    <xsl:variable name="first-tab" select="($first-para//tab[hub:same-scope(., current())][not(ancestor::tabs)])[1]"/>
                    <term>
                      <xsl:sequence select="hub:split-term-at-tab($first-para, $first-tab)"/>
                    </term>
                    <xsl:copy>
                      <xsl:sequence select="hub:split-listitem-at-tab($first-para, $first-tab)"/>
                      <xsl:apply-templates select="node()[. &gt;&gt; $li/$first-para]" mode="#current"/>
                    </xsl:copy>
                  </xsl:otherwise>
                </xsl:choose>
              </varlistentry>
            </xsl:for-each>
          </variablelist>
        </xsl:when>
        <xsl:otherwise>
          <!--
          <xsl:message>
            <xsl:value-of select="current-group()/node()"/>
          </xsl:message>
          -->
          <xsl:apply-templates select="current-group()/node()" mode="#current"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each-group>
  </xsl:template>


  <!-- indentations that are not list items as blockquote -->
  <xsl:template match="orderedlist[not(hub:is-itemized-list(.))]
                                  [not(hub:is-ordered-list(.))]
                                  [not(hub:is-variable-list(.))]
                                  [hub:has-no-identifiers(.)]
                                  [if (parent::listitem/para[1]/@margin-left) then not(hub:same-margin-left(., parent::listitem/para[1]/@margin-left)) else true()]
                                  [not(every $n in listitem/node() satisfies $n/self::para[@role = $hub:equation-roles 
                                                                                           or (count(node()) = 1 and inlineequation)
                                                                                          ]
                                      )]"
                mode="hub:lists">
    <xsl:choose>
      <xsl:when test="parent::listitem">
        <xsl:apply-templates select="listitem/node()" mode="#current"/>
      </xsl:when>
      <xsl:otherwise>
        <blockquote role="hub:lists">
          <xsl:apply-templates select="listitem/node()" mode="#current"/>
        </blockquote>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <!-- identifier im listitem entfernen, wenn durch itemizedlist oder orderedlist erfasst -->

  <xsl:template match="phrase[@role = 'hub:identifier' and ancestor::listitem and not(ancestor::footnote) and not(ancestor::remark[@role = 'endnote'])]" mode="hub:lists">
    <xsl:param name="identifier-needed" select="'yes'" tunnel="yes"/>
    <xsl:if test="$identifier-needed = 'yes'">
      <xsl:next-match/>
    </xsl:if>
  <xsl:if test="not($identifier-needed = 'yes') and descendant::anchor">
      <xsl:apply-templates select=".//anchor" mode="#current"/>
    </xsl:if>
  </xsl:template>


  <!-- identifier-needed (tunnel) zuruecksetzen -->
  
  <xsl:template match="informaltable | table | figure" mode="hub:lists">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" mode="#current">
        <xsl:with-param name="identifier-needed" select="'yes'" tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>

  <!-- Funktionen -->

  <xsl:function name="hub:same-margin-left" as="xs:boolean">
    <xsl:param name="list" as="element(*)"/>
    <xsl:param name="margin" as="xs:string?"/>
    <xsl:variable name="margin-int" select="xs:integer(number(($margin, 0)[1]))" as="xs:integer"/>
    <xsl:value-of select="if (every $x in $list/listitem/para[1]/@margin-left[. castable as xs:integer] 
                              satisfies abs(xs:integer($x) - $margin-int) le $hub:indent-epsilon) then true() else false()"/>
  </xsl:function>

  <xsl:function name="hub:has-no-identifiers" as="xs:boolean">
    <xsl:param name="list" as="element(*)"/>
    <xsl:value-of select="if (every $x in $list/listitem/para[1] satisfies not($x//phrase[hub:is-identifier(.)]))
                          then true() else false()"/>
  </xsl:function>
  
  <xsl:function name="hub:is-itemized-list" as="xs:boolean">
    <xsl:param name="list" as="element(*)"/>
    <xsl:value-of select="if ( 
                              (
                                matches(
                                  $list/listitem[1]/para[1]//phrase[hub:same-scope(., $list/listitem[1]/para[1])][hub:is-identifier(.)][1], 
                                  $hub:itemizedlist-mark-regex
                                )
                                and (
                                  every $first-para-in-listitem in $list/listitem/para[1]
                                  satisfies exists(
                                    $first-para-in-listitem//phrase[hub:same-scope(., $first-para-in-listitem)][hub:is-identifier(.)]
                                  )
                                )
                                and (
                                  every $first-para-in-listitem in $list/listitem/para[1]
                                  satisfies (
                                    every $first-identifier 
                                    in $first-para-in-listitem//phrase[
                                      hub:same-scope(., $first-para-in-listitem)][hub:is-identifier(.)
                                    ][1]
                                    satisfies matches($first-identifier, $hub:itemizedlist-mark-regex)
                                  )
                                )
                              )
                              or hub:is-itemized-list-because-we-know-better($list)
                          ) then true() else false()"/>
  </xsl:function>

  <xsl:function name="hub:is-itemized-list-because-we-know-better" as="xs:boolean">
    <xsl:param name="list" as="element(*)"/>
    <xsl:sequence select="false()"/>
  </xsl:function>

  <xsl:function name="hub:is-ordered-list" as="xs:boolean">
    <xsl:param name="list" as="element(*)"/>
    <xsl:value-of select="if ( 
                              (
                                exists(
                                  $list/listitem/para[1]//phrase[hub:same-scope(., $list/listitem[1]/para[1])][hub:is-identifier(.)]
                                )
                                and (
                                  every $first-para-in-listitem in $list/listitem/para[1]
                                  satisfies exists(
                                    $first-para-in-listitem//phrase[hub:same-scope(., $first-para-in-listitem)][hub:is-identifier(.)]
                                  )
                                )
                                and (
                                  hub:get-list-type(
                                    for $para in $list/listitem/para[1] 
                                    return $para//phrase[hub:is-identifier(.)][hub:same-scope(., $para)][1]
                                  ) = $hub:known-ordered-list-types
                                )
                              )
                              or hub:is-ordered-list-because-we-know-better($list)
                          ) then true() else false()"/>
  </xsl:function>

  <xsl:function name="hub:is-ordered-list-because-we-know-better" as="xs:boolean">
    <xsl:param name="list" as="element(*)"/>
    <xsl:sequence select="false()"/>
  </xsl:function>

  <xsl:function name="hub:is-variable-list" as="xs:boolean">
    <xsl:param name="list" as="element(*)"/>
    <xsl:value-of select="if ( 
                              (
                                exists($list/listitem/para) (: we don’t require that every listitem needs a para – there may be complete tables in listitem, for ex. :)
                                and 
                                  (
                                    hub:get-list-type(
                                      for $first-para-in-listitem in $list/listitem/para[1]
                                      return $first-para-in-listitem
                                        //phrase[hub:is-identifier(.)][hub:same-scope(., $first-para-in-listitem)][1]
                                    ) eq 'other'
                                    and
                                    (
                                      every $first-para-in-listitem in $list/listitem/para[1] satisfies (
                                        hub:is-variable-list-listitem-with-phrase-identifier($first-para-in-listitem)
                                        and 
                                        not($first-para-in-listitem/@role = ('Note', $hub:equation-roles))
                                      )
                                    )
                                  or
                                  (
                                    every $first-para-in-listitem in $list/listitem/para[1] satisfies (
                                      hub:is-variable-list-listitem-without-phrase-identifier($first-para-in-listitem)
                                      and
                                      not($first-para-in-listitem/@role = ('Note', $hub:equation-roles))
                                    )
                                  )
                                )
                              )
                              or hub:is-variable-list-because-we-know-better($list)
                          ) then true() else false()"/>
  </xsl:function>

  <xsl:function name="hub:is-variable-list-because-we-know-better" as="xs:boolean">
    <xsl:param name="list" as="element(*)"/>
    <xsl:sequence select="false()"/>
  </xsl:function>
  
  <xsl:function name="hub:is-variable-list-listitem-with-phrase-identifier" as="xs:boolean">
    <xsl:param name="para" as="element(para)?"/>
    <xsl:sequence select="exists(
                            $para//tab[not(parent::tabs)][hub:same-scope(., $para)][1][
                              exists(
                                preceding::node()[self::phrase][hub:is-identifier(.)]
                                  [hub:same-scope(., $para)]
                              )
                            ]
                          )"/>
  </xsl:function>

  <xsl:function name="hub:is-variable-list-listitem-without-phrase-identifier" as="xs:boolean">
    <xsl:param name="para" as="element(para)?"/>
    <xsl:sequence select="not(
                            $para
                              //phrase[hub:is-identifier(.)][hub:same-scope(., $para)][1]
                          )
                          and exists(
                            ($para//tab[not(parent::tabs)][hub:same-scope(., $para)])[1]
                              /preceding::node()[. &gt;&gt; $para]
                          )"/>
  </xsl:function>

  <xsl:function name="hub:get-list-type-with-warning" as="xs:string">
    <xsl:param name="marks" as="node()*"/>
    <xsl:variable name="true-marks" select="for $x in $marks return replace($x,  $hub:orderedlist-mark-regex, '$1')" as="xs:string*"/>
    <xsl:variable name="mark" select="hub:get-list-type($marks)" as="xs:string" />
    <xsl:choose>
      <xsl:when test="$mark ne 'other'">
        <xsl:value-of select="$mark" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:message>
          Cannot determine type of ordered list. Markers (separator is ','): <xsl:value-of select="string-join($true-marks, ',')"/>
        </xsl:message>
        <xsl:sequence select="$mark" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:variable name="hub:known-ordered-list-types" as="xs:string*"
    select="('lowerroman', 'upperroman', 'loweralpha', 'upperalpha')"/>

  <xsl:function name="hub:get-list-type" as="xs:string">
    <xsl:param name="marks" as="node()*"/>
    <xsl:variable name="true-marks" as="xs:string*">
      <xsl:apply-templates select="$marks" mode="hub:list-true-marks"/>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="every $x in $true-marks satisfies matches($x, '^[ivx]+$')">lowerroman</xsl:when>
      <xsl:when test="every $x in $true-marks satisfies matches($x, '^[IVX]+$')">upperroman</xsl:when>
      <xsl:when test="every $x in $true-marks satisfies matches($x, '^[a-z]$')">loweralpha</xsl:when>
      <xsl:when test="every $x in $true-marks satisfies matches($x, '^[A-Z]$')">upperalpha</xsl:when>
      <xsl:when test="every $x in $true-marks satisfies matches($x, '^&#x2007;*[0-9]+$')">arabic</xsl:when>
      <xsl:when test="every $x in $true-marks satisfies matches($x, '^&#x2022;$')">bullet</xsl:when>
      <xsl:when test="every $x in $true-marks satisfies matches($x, '^&#xb7;$')">bullet</xsl:when>
      <xsl:when test="every $x in $true-marks satisfies matches($x, $hub:itemizedlist-mark-chars-regex)">
        <xsl:value-of select="$marks" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="'other'" />
      </xsl:otherwise>
    </xsl:choose>    
  </xsl:function>

  <xsl:template match="node()" mode="hub:list-true-marks" as="xs:string">
    <!-- If someone changed …|[a-z]|… to …|[a-z][.:\)]|… in $hub:orderedlist-mark-regex, we need the double replace
      because $1 then contains the punctuation. You might need to customize this template if you customized the regex further. -->
    <xsl:sequence select="replace(replace(normalize-space(.),  $hub:orderedlist-mark-regex, '$1'), '[.:\)\)]', '', 'i')"/>
  </xsl:template>

  <xsl:function name="hub:is-identifier" as="xs:boolean">
    <xsl:param name="phrase" as="element(phrase)" />
    <xsl:sequence select="$phrase/@role eq 'hub:identifier'
                          and
                          not($phrase/ancestor::footnote) 
                          and
                          not($phrase/ancestor::remark[@role eq 'endnote'])" />
  </xsl:function>


</xsl:stylesheet>