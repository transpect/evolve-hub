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
  xmlns:css="http://www.w3.org/1996/css"
  xmlns="http://docbook.org/ns/docbook"
  version="2.0"
  xpath-default-namespace="http://docbook.org/ns/docbook"
  exclude-result-prefixes = "w o v wx xs dbk pkg r rel word200x exsl saxon fn tr">

  <xsl:include href="http://transpect.io/evolve-hub/xsl/hub-functions.xsl"/>
  <xsl:include href="http://transpect.io/xslt-util/num/xsl/num.xsl"/>

  <xsl:output
    name="debug"
    method="xml"
    indent="yes"
    encoding="utf-8"/>
  
  <xsl:key name="rule-by-name" match="css:rule" use="@name"/>
  
  <xsl:variable name="hub:list-hierarchy-role-regexes" 
                select="('^(List((Number|Continue|Bullet)|e(n(nummer|fortsetzung|absatz))?)?|Aufzhlungszeichen)[01]?$', 
                         '^(List((Number|Continue|Bullet)|e(n(nummer|fortsetzung|absatz))?)?|Aufzhlungszeichen)2$', 
                         '^(List((Number|Continue|Bullet)|e(n(nummer|fortsetzung|absatz))?)?|Aufzhlungszeichen)3$', 
                         '^(List((Number|Continue|Bullet)|e(n(nummer|fortsetzung|absatz))?)?|Aufzhlungszeichen)4$', 
                         '^(List((Number|Continue|Bullet)|e(n(nummer|fortsetzung|absatz))?)?|Aufzhlungszeichen)5$', 
                         '^(List((Number|Continue|Bullet)|e(n(nummer|fortsetzung|absatz))?)?|Aufzhlungszeichen)6$')" as="xs:string+"/>
  
  <xsl:variable name="hub:list-styles-regex" select="concat('(',string-join($hub:list-hierarchy-role-regexes,'|'),')')" as="xs:string"/>
  
  <xsl:variable name="hub:equation-roles" as="xs:string+" select="('Formula', 'Equation')" />
  
  <xsl:variable name="prepare-lists-by-role">
    <xsl:apply-templates select="/" mode="prepare-lists-by-role"/>
  </xsl:variable>
  
  <xsl:template name="main">
    <xsl:apply-templates select="$prepare-lists-by-role" mode="lists-by-role"/>
  </xsl:template>
  
  <xsl:template match="para[key('rule-by-name',@role)[@css:list-style-type]]/@role" mode="prepare-lists-by-role">
    <xsl:attribute name="orig-role" select="."/>
    <xsl:attribute name="role" select="concat('list-',replace(key('rule-by-name',.)/@css:list-style-type,'\-',''),'-',tokenize(replace(key('rule-by-name',.)/@css:content[matches(.,'lvl:')],'^.*?(lvl:[0-9]+).*?$','$1'),'lvl:')[last()])"/>
  </xsl:template>
  
  <xsl:template match="*[para[matches(@role,'^list\-')]]" mode="lists-by-role">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:sequence select="tr:hierarchize-lists(node(),1)"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:function name="tr:hierarchize-lists" as="node()+">
    <xsl:param name="context" as="node()+"/>
    <xsl:param name="level" as="xs:integer"/>
    
    <xsl:for-each-group select="$context[self::*]" group-adjacent="tr:is-level-element(.,$level)">
      <xsl:choose>
        <xsl:when test="current-grouping-key()">
          <xsl:for-each-group select="current-group()[self::*]" group-adjacent="tr:get-numeration-style-with-level(.,$level)">
            <xsl:variable name="key" select="current-grouping-key()"/>
            <xsl:variable name="true-marks" as="xs:string*">
              <xsl:apply-templates select="current-group()[self::*[matches(@role,'^list\-')]
                [tr:get-numeration-level(.)=$level]
                [tr:get-numeration-style(.)=$key]]/phrase[@role='hub:identifier']" mode="hub:list-true-marks"/>
            </xsl:variable>
            <xsl:choose>
              <xsl:when test="tr:get-list-type($key)='blockquote'">
                <xsl:element name="{tr:get-list-type($key)}">
                  <xsl:attribute name="role" select="'hub:identifier'"/>
                  <xsl:apply-templates select="current-group()" mode="lists-by-role"/>
                </xsl:element>
              </xsl:when>
              <xsl:when test="tr:get-list-type($key)='variablelist'">
                <xsl:element name="{tr:get-list-type($key)}">
                  <xsl:for-each-group select="current-group()" group-starting-with="*[matches(@role,'^list\-')]
                    [tr:get-numeration-level(.)=$level]
                    [tr:get-numeration-style(.)=$key]">
                    <xsl:element name="{tr:get-list-element-type($key)}">
                      <xsl:variable name="tabs" select="current-group()[1]//tab[not(@role) or @role='docx2hub:generated']
                                                                               [not(parent::tabs)]
                                                                               [hub:same-scope(., current())]"/>
                      <xsl:variable name="first-tab" select="$tabs[1]" as="element(tab)?"/>
                      <term>
                        <xsl:sequence select="if (empty($tabs)) then '' else hub:split-term-at-tab(current-group()[1],$first-tab)"/>
                      </term>
                      <listitem>
                        <xsl:choose>
                          <xsl:when test="empty($tabs)">
                            <xsl:apply-templates select="current-group()[1]" mode="lists-by-role"/>   
                          </xsl:when>
                          <xsl:otherwise>
                            <xsl:sequence select="hub:split-listitem-at-tab(current-group()[1],$first-tab)"/>    
                          </xsl:otherwise>
                        </xsl:choose>
                        <xsl:if test="count(current-group()) gt 1">
                          <xsl:sequence select="tr:hierarchize-lists(current-group()[position() gt 1],$level+1)"/>  
                        </xsl:if>
                      </listitem>
                    </xsl:element>
                  </xsl:for-each-group>
                </xsl:element>
              </xsl:when>
              <xsl:when test="tr:get-list-type($key)='itemizedlist' or 
                              (tr:get-list-type($key)='orderedlist' and hub:is-incrementing-identifier-sequence($true-marks))">
                <xsl:element name="{tr:get-list-type($key)}">
                  <xsl:for-each-group select="current-group()" group-starting-with="*[matches(@role,'^list\-')]
                    [tr:get-numeration-level(.)=$level]
                    [tr:get-numeration-style(.)=$key]">
                    <xsl:element name="{tr:get-list-element-type($key)}">
                      <xsl:apply-templates select="current-group()[1]" mode="lists-by-role"/>
                      <xsl:if test="count(current-group()) gt 1">
                        <xsl:sequence select="tr:hierarchize-lists(current-group()[position() gt 1],$level+1)"/>  
                      </xsl:if>
                    </xsl:element>
                  </xsl:for-each-group>
                </xsl:element>    
              </xsl:when>
              <xsl:otherwise>
                <xsl:apply-templates select="current-group()" mode="lists-by-role"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each-group>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="current-group()" mode="lists-by-role"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each-group>
  </xsl:function>
  
  <xsl:function name="tr:get-numeration-style-with-level" as="xs:string">
    <xsl:param name="elt" as="node()"/>
    <xsl:param name="level" as="xs:double"/>
    
    <xsl:choose>
      <xsl:when test="matches($elt/@role,'^list\-')">
        <xsl:choose>
          <xsl:when test="matches($elt/@role,'continue')">
            <xsl:sequence select="tr:get-numeration-style-with-level($elt/preceding-sibling::*[matches(@role,'^list\-')]
                                                                                              [not(matches(@role,'continue'))]
                                                                                              [tr:get-numeration-level(.)=tr:get-numeration-level($elt)]
                                                                                              [1],$level)"/>
          </xsl:when>
          <xsl:when test="tr:get-numeration-level($elt) gt $level">
            <xsl:sequence select="tr:get-numeration-style-with-level($elt/preceding-sibling::*[matches(@role,'^list\-')]
                                                                                              [not(matches(@role,'continue'))]
                                                                                              [tr:get-numeration-level(.)=$level]
                                                                                              [1],$level)"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:sequence select="tokenize($elt/@role,'\-')[2]"/>    
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="tr:get-numeration-style-with-level($elt/preceding-sibling::*[matches(@role,'^list\-')][1],$level)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:function name="tr:get-numeration-style" as="xs:string*">
    <xsl:param name="elt" as="element()"/>
    
    <xsl:sequence select="if (matches($elt/@role,'^list\-')) 
                          then tokenize($elt/@role,'\-')[2] 
                          else tr:get-numeration-style($elt/preceding-sibling::*[matches(@role,'^list\-')][1])"/>
  </xsl:function>
  
  <xsl:function name="tr:get-numeration-level" as="xs:double">
    <xsl:param name="elt" as="element()"/>
    
    <xsl:sequence select="if (matches($elt/@role,'^list\-')) 
                          then number(tokenize($elt/@role,'\-')[3]) 
                          else tr:get-numeration-level($elt/preceding-sibling::*[matches(@role,'^list\-')][1])"/>
  </xsl:function>
  
  <xsl:variable name="hub:ordered-list-styles-regex" select="'^((lower|upper)(alpha|roman)|arabic)$'"/>
  
  <xsl:function name="tr:get-list-type" as="xs:string">
    <xsl:param name="numeration"/>
    
    <xsl:variable name="list-type" as="xs:string">
      <xsl:choose>
        <xsl:when test="matches($numeration,$hub:ordered-list-styles-regex)">orderedlist</xsl:when>
        <xsl:when test="$numeration='simple'">blockquote</xsl:when>
        <xsl:when test="$numeration='definition'">variablelist</xsl:when>
        <xsl:otherwise>itemizedlist</xsl:otherwise>
      </xsl:choose>  
    </xsl:variable>
    
    <xsl:value-of select="$list-type"/>
  </xsl:function>
  
  <xsl:function name="tr:get-list-element-type" as="xs:string">
    <xsl:param name="numeration"/>
    <xsl:variable name="list-element" as="xs:string">
      <xsl:choose>
        <xsl:when test="$numeration='definition'">varlistentry</xsl:when>
        <xsl:otherwise>listitem</xsl:otherwise>
      </xsl:choose>  
    </xsl:variable>
    
    <xsl:value-of select="$list-element"/>
  </xsl:function>
  
  <xsl:function name="tr:is-level-element" as="xs:boolean">
    <xsl:param name="elt"/>
    <xsl:param name="level" as="xs:integer"/>
    <xsl:value-of select="$elt[self::table or self::figure or self::equation or self::informalfigure or self::informaltable or self::para[not(matches(@role,'^list\-'))][tr:is-level-element-para(.)]]
      [preceding-sibling::*[not(self::table or self::figure or self::equation or self::informalfigure or self::informaltable or self::para[not(matches(@role,'^list\-'))][tr:is-level-element-para(.)])]
                                                   [1]
                                                   [matches(@role,'^list\-') and tr:get-numeration-level(.) ge $level] or
                                                   following-sibling::*[not(self::table or self::figure or self::equation or self::informalfigure or self::informaltable or self::para[not(matches(@role,'^list\-'))][tr:is-level-element-para(.)])]
                                                   [1]
                                                   [matches(@role,'^list\-') and tr:get-numeration-level(.) ge $level]] or 
                          (matches($elt/@role,'^list\-') and tr:get-numeration-level($elt) ge $level)"/>
  </xsl:function>
  
  <xsl:function name="tr:is-level-element-para" as="xs:boolean">
    <xsl:param name="elt"/>
    
    <xsl:value-of select="if ($elt[every $n in child::node() 
                                   satisfies $n[self::equation or self::mediaobject or self::comment() or self::processing-instruction() or self::text()[matches(.,'^[\s&#160;]*$')]]] or hub:is-equation-para($elt)) 
                          then true() else false()"/>
  </xsl:function>
  
  <xsl:template match="node() | @*" mode="#all">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:function name="hub:is-equation-para" as="xs:boolean">
    <xsl:param name="para" as="element(*)"/>
    <xsl:sequence select="$para/@role = $hub:equation-roles or 
                          (count($para/node()) = 1 and ($para/inlineequation or $para/equation))"/>
  </xsl:function>

  <xsl:variable name="hub:orderedlist-mark-regex" as="xs:string"
    select="concat('^', $hub:orderedlist-mark-open-quote-regex, $hub:orderedlist-mark-chars-regex, '$')"/>
  <xsl:variable name="hub:orderedlist-mark-open-quote-regex" as="xs:string" select="'[‚„«‹›»“‘]?'"/>
  <xsl:variable name="hub:orderedlist-mark-chars-regex" as="xs:string"
    select="concat('[\(\[]?(([ivx]+|[IVX]+|', $hub:orderedlist-one-or-more-letter-chars-regex,'|\p{Zs}*[0-9]+)(\.\d+)*)[.:]?[\)\]]?')"/>
  <xsl:variable name="hub:orderedlist-one-or-more-letter-chars-regex" as="xs:string"  
    select="'[a-z]|[A-Z]'"/>
  
  <xsl:template match="node()" mode="hub:list-true-marks" as="xs:string" priority="10">
    <!-- If someone changed …|[a-z]|… to …|[a-z][.:\)]|… in $hub:orderedlist-mark-regex, we need the double replace
      because $1 then contains the punctuation. You might need to customize this template if you customized the regex further. -->
    <xsl:sequence select="replace(replace(normalize-space(.),  $hub:orderedlist-mark-regex, '$1'), '[.:\)\)]', '', 'i')"/>
  </xsl:template>
  
  <xsl:function name="hub:is-incrementing-identifier-sequence" as="xs:boolean">
    <xsl:param name="marks" as="xs:string*"/>
    <xsl:choose>
      <xsl:when test="count($marks) = 0">
        <xsl:sequence select="false()"/>
      </xsl:when>
      <xsl:when test="count($marks) = 1">
        <xsl:sequence select="true()"/>
      </xsl:when>
      <xsl:when test="every $mark in $marks satisfies (matches($mark,'^[ivxlcdm]+$') and (tr:roman-to-int(upper-case($mark)) gt -1))">
        <xsl:variable name="lowerroman" as="xs:boolean+">
          <xsl:for-each select="$marks[position() gt 1]">
            <xsl:variable name="pos" as="xs:integer" select="position()"/>
            <xsl:sequence select="tr:roman-to-int(upper-case(.)) = tr:roman-to-int(upper-case($marks[position() = $pos ])) + 1"/>
          </xsl:for-each>  
        </xsl:variable>
        <xsl:sequence select="every $b in $lowerroman satisfies $b"/>
      </xsl:when>
      <xsl:when test="every $mark in $marks satisfies (matches($mark,'^[IVXLCDM]+$') and (tr:roman-to-int($mark) gt -1))">
        <xsl:variable name="upperroman" as="xs:boolean+">
          <xsl:for-each select="$marks[position() gt 1]">
            <xsl:variable name="pos" as="xs:integer" select="position()"/>
            <xsl:sequence select="tr:roman-to-int(.) = tr:roman-to-int($marks[position() = $pos ]) + 1"/>
          </xsl:for-each>  
        </xsl:variable>
        <xsl:sequence select="every $b in $upperroman satisfies $b"/>
      </xsl:when>
      <xsl:when test="every $mark in $marks satisfies matches($mark,'^[a-zA-Z]+$')">
        <xsl:variable name="double-letters" as="xs:boolean+">
          <xsl:for-each select="$marks[position() gt 1]">
            <xsl:variable name="pos" as="xs:integer" select="position()"/>
            <xsl:sequence select="hub:letters-to-number(.) = hub:letters-to-number($marks[position() = $pos ]) + 1"/>
          </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="inc-letters" as="xs:boolean+">
          <xsl:for-each select="$marks[position() gt 1]">
            <xsl:variable name="pos" as="xs:integer" select="position()"/>
            <xsl:sequence select="hub:letters-to-number(.,2) = hub:letters-to-number($marks[position() = $pos ],2) + 1"/>
          </xsl:for-each>
        </xsl:variable>
        <xsl:sequence select="every $b in $double-letters satisfies $b or (every $b in $inc-letters satisfies $b)"/>    
      </xsl:when>
      <xsl:when test="every $mark in $marks satisfies matches($mark,'^[0-9]+$')">
        <xsl:variable name="arabic" as="xs:boolean+">
          <xsl:for-each select="$marks[position() gt 1]">
            <xsl:variable name="pos" as="xs:integer" select="position()"/>
            <xsl:sequence select="number(.) = number($marks[position() = $pos ]) + 1"/>
          </xsl:for-each>
        </xsl:variable>
        <xsl:sequence select="every $b in $arabic satisfies $b"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="false()"/>
      </xsl:otherwise>
    </xsl:choose>
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

</xsl:stylesheet>