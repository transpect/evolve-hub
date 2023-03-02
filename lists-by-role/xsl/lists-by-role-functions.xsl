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
  
  <!-- gets @mark of an itemized list -->
  <xsl:function name="tr:get-itemized-type" as="xs:string">
    <xsl:param name="lvlText"/>
    <xsl:choose>
      <xsl:when test="matches($lvlText,'^[⏹■▪◼◾⬛⬝🞍🞌⯀￭𝅇]$')">
        <xsl:value-of select="'square'"/>
      </xsl:when>
      <xsl:when test="matches($lvlText,'^[º°○⭘◯⚪⚬oOοΟоОօՕₒⲟⲞＯ🞉🞇ｏ￮🞅🔾🔿❍]$')">
        <xsl:value-of select="'circle'"/>
      </xsl:when>
      <xsl:when test="matches($lvlText,'^[◻◽☐⌑□🞑🞒🞓⸋▫⬜⬞𝅆❏❐❑❒⧠]$')">
        <xsl:value-of select="'box'"/>
      </xsl:when>
      <xsl:when test="matches($lvlText,'^[✔✓🗸]$')">
        <xsl:value-of select="'check'"/>
      </xsl:when>
      <xsl:when test="matches($lvlText,'^[⬥⬩⯁◆🞘♦🞗]$')">
        <xsl:value-of select="'diamond'"/>
      </xsl:when>
      <xsl:when test="matches($lvlText,'^[&#x002d;&#x005f;&#x00af;&#x02d7;&#x0320;&#x2010;-&#x2015;&#x203e;&#x207b;&#x208b;&#x2212;&#x22c5;&#x23af;&#x2796;&#x2e3a;&#x2e3b;&#xfe58;&#xfe63;&#xff0d;&#xff3f;𝄖]$')">
        <xsl:value-of select="'dash'"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="'disc'"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <!-- gets type of subelements for the lists, varlistentry for variablelists, listitem all others  -->
  <xsl:function name="tr:get-list-element-type" as="xs:string">
    <xsl:param name="numeration" as="xs:string?"/>
    <xsl:variable name="list-element" as="xs:string">
      <xsl:choose>
        <xsl:when test="$numeration='definition'">varlistentry</xsl:when>
        <xsl:otherwise>listitem</xsl:otherwise>
      </xsl:choose>  
    </xsl:variable>
    
    <xsl:value-of select="$list-element"/>
  </xsl:function>
  
  <!-- gets type of list, possible result values: orderedlist, itemizedlist, variablelist, blockquote or nolist -->
  <xsl:function name="tr:get-list-type" as="xs:string">
    <xsl:param name="numeration"/>
    
    <xsl:variable name="list-type" as="xs:string">
      <xsl:choose>
        <xsl:when test="matches($numeration,$hub:ordered-list-styles-regex)">orderedlist</xsl:when>
        <xsl:when test="$numeration='simple'">blockquote</xsl:when>
        <xsl:when test="$numeration='definition'">variablelist</xsl:when>
        <xsl:when test="$numeration='continue'">nolist</xsl:when>
        <xsl:otherwise>itemizedlist</xsl:otherwise>
      </xsl:choose>  
    </xsl:variable>
    
    <xsl:value-of select="$list-type"/>
  </xsl:function>
  
  <xsl:function name="tr:format-list-style-type" as="xs:string">
    <xsl:param name="rule"/>
    <xsl:choose>
      <xsl:when test="$rule/@css:list-style-type='disc' and 
                      not(tr:get-non-list-type-new-role($rule/@name,$rule/@css:list-style-type)=$rule/@name)">
        <xsl:value-of select="tokenize(tr:get-non-list-type-new-role($rule/@name,$rule/@css:list-style-type),'\-')[2]"/>
      </xsl:when>
      <xsl:when test="$rule/@css:list-style-type='none'">
        <xsl:value-of select="'simple'"/>
      </xsl:when>
      <xsl:when test="$rule/@css:list-style-type='decimal'">
        <xsl:value-of select="'arabic'"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="replace($rule/@css:list-style-type,'\-','')"/>    
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <!-- deduce list type from @css:list-style-type for heuristic mapping -->
  <xsl:function name="tr:get-list-type-new-role" as="xs:string">
    <xsl:param name="rule"/>
    <xsl:variable name="role-lvl" select="if (tr:get-role-lvl($rule/@name)='na') 
                                          then ($rule/@numbering-level,'1')[1] 
                                          else tr:get-role-lvl($rule/@name)"/>
    <xsl:choose>
      <xsl:when test="matches($rule/@name,'^list\-') or 
                      (some $i in $hub:exclude-prepare-list-roles-regexes satisfies matches($rule/@name,$i))">
        <xsl:value-of select="$rule/@name"/>
      </xsl:when>
      <xsl:when test="$rule/@numbering-level ne $role-lvl and $rule/@numbering-multilevel-type='single' and $rule/@numbering-level='1'">
        <xsl:value-of select="concat('list-',tr:format-list-style-type($rule),'-',$role-lvl)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat('list-',tr:format-list-style-type($rule),'-',($rule/@numbering-level,$role-lvl)[1])"/>    
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <!-- deduce list type from hub:identifiers of all existing paras with that same role for style without @css:list-style-type for heuristic mapping -->
  <xsl:function name="tr:get-non-list-type-new-role" as="xs:string">
    <xsl:param name="old-role"/>
    <xsl:param name="list-style-type" as="xs:string?"/>
    <xsl:variable name="root" select="$old-role/ancestor::*[not(parent::*)]"/>
    <xsl:variable name="marks" as="xs:string*">
      <xsl:apply-templates select="$root//para[@role=$old-role]/phrase[@role='hub:identifier']" mode="hub:list-true-marks"/>
    </xsl:variable>
    <xsl:variable name="lvlText" as="xs:string*">
      <xsl:sequence select="distinct-values(for $id in $root//para[@role=$old-role]/phrase[@role='hub:identifier'] 
                                            return replace(string-join($id//text(),''),'[a-zA-Z0-9\s&#160;]',''))"/>
    </xsl:variable>
    <xsl:variable name="role-lvl" select="if (tr:get-role-lvl($old-role)='na') then '1' else tr:get-role-lvl($old-role)"/>
    <xsl:choose>
      <xsl:when test="matches($old-role,'^list\-') or 
                      (some $i in $hub:exclude-prepare-list-roles-regexes satisfies matches($old-role,$i))">
        <xsl:value-of select="$old-role"/>
      </xsl:when>
      <xsl:when test="not($list-style-type='disc') and
                      (every $p in $root//para[@role=$old-role] satisfies $p[phrase[@role='hub:identifier']]) and 
                      count($lvlText)=1 and
                      (every $mark in $marks satisfies (matches($mark,'^[ivxlcdm]+$')))">
        <xsl:value-of select="concat('list-lowerroman-',$role-lvl)"/>
      </xsl:when>
      <xsl:when test="not($list-style-type='disc') and
                      (every $p in $root//para[@role=$old-role] satisfies $p[phrase[@role='hub:identifier']]) and 
                      count($lvlText)=1 and 
                      (every $mark in $marks satisfies (matches($mark,'^[IVXLCDM]+$')))">
        <xsl:value-of select="concat('list-upperroman-',$role-lvl)"/>
      </xsl:when>
      <xsl:when test="not($list-style-type='disc') and
                      (every $p in $root//para[@role=$old-role] satisfies $p[phrase[@role='hub:identifier']]) and 
                      count($lvlText)=1 and 
                      (every $mark in $marks satisfies matches($mark,'^[a-z]+$'))">
        <xsl:value-of select="concat('list-loweralpha-',$role-lvl)"/>
      </xsl:when>
      <xsl:when test="not($list-style-type='disc') and
                      (every $p in $root//para[@role=$old-role] satisfies $p[phrase[@role='hub:identifier']]) and 
                      count($lvlText)=1 and 
                      (every $mark in $marks satisfies matches($mark,'^[A-Z]+$'))">
        <xsl:value-of select="concat('list-upperalpha-',$role-lvl)"/>
      </xsl:when>
      <xsl:when test="not($list-style-type='disc') and
                      (every $p in $root//para[@role=$old-role] satisfies $p[phrase[@role='hub:identifier']]) and 
                      count($lvlText)=1 and 
                      (every $mark in $marks satisfies matches($mark,'^[0-9]+$'))">
        <xsl:value-of select="concat('list-arabic-',$role-lvl)"/>
      </xsl:when>
      <xsl:when test="((every $p in $root//para[@role=$old-role] satisfies $p[phrase[@role='hub:identifier']]) or
                       $list-style-type='disc') and 
                      count($lvlText)=1 and 
                      string-length($lvlText)=1">
        <xsl:value-of select="concat('list-',tr:get-itemized-type($lvlText),'-',$role-lvl)"/>
      </xsl:when>
      <xsl:when test="not($list-style-type='disc') and
                      (every $p in $root//para[@role=$old-role] satisfies $p[phrase[@role='hub:identifer']]) and 
                      distinct-values(for $id in $root//para[@role=$old-role]/phrase[@role='hub:identifier'] 
                                      return replace(string-join($id//text(),''),'[\*†‡§\|∥#¶\s&#160;]','')) and 
                      (every $mark in $marks satisfies matches($mark,'^[\*†‡§\|∥#¶]+$'))">
        <xsl:value-of select="concat('list-chicago-',$role-lvl)"/>
      </xsl:when>
      <xsl:when test="not($list-style-type='disc') and (every $p in $root//para[@role=$old-role] satisfies $p[count(tab)=1])">
        <xsl:value-of select="concat('list-definition-',$role-lvl)"/>
      </xsl:when>
      <xsl:when test="not($list-style-type='disc') and
                      matches($old-role,$hub:list-continue-style-regex,'i') and 
                      (every $p in $root//para[@role=$old-role] satisfies $p[not(phrase[@role='hub:identifier'])])">
        <xsl:value-of select="concat('list-continue-',$role-lvl)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$old-role"/>        
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <!-- gets numeration level from own or preceding sibling mapped role -->
  <xsl:function name="tr:get-numeration-level" as="xs:integer">
    <xsl:param name="elt" as="element()"/>
    
    <xsl:sequence select="if (matches($elt/@role,'^list\-')) 
                          then xs:integer(tokenize($elt/@role,'\-')[3]) 
                          else tr:get-numeration-level($elt/preceding-sibling::*[matches(@role,'^list\-')][1])"/>
  </xsl:function>
  
  <!-- gets numeration style from own or preceding sibling mapped role -->
  <xsl:function name="tr:get-numeration-style" as="xs:string*">
    <xsl:param name="elt" as="element()"/>
    
    <xsl:sequence select="if (matches($elt/@role,'^list\-')) 
                          then tokenize($elt/@role,'\-')[2] 
                          else tr:get-numeration-style($elt/preceding-sibling::*[matches(@role,'^list\-')][1])"/>
  </xsl:function>
  
  <!-- gets numeration style considering numeration level -->
  <xsl:function name="tr:get-numeration-style-with-level" as="xs:string">
    <xsl:param name="elt" as="node()"/>
    <xsl:param name="level" as="xs:integer"/>
    
    <xsl:choose>
      <xsl:when test="matches($elt/@role,'^list\-')">
        <xsl:choose>
          <xsl:when test="matches($elt/@role,'continue') and exists($elt/preceding-sibling::*[matches(@role,'^list\-')]
            [not(matches(@role,'continue'))]
            [tr:get-numeration-level(.)=tr:get-numeration-level($elt)][. &gt;&gt; $elt/preceding-sibling::*[not(tr:is-level-element(.,$level))][1]])">
            <xsl:sequence select="tr:get-numeration-style-with-level($elt/preceding-sibling::*[matches(@role,'^list\-')]
                                                                                              [not(matches(@role,'continue'))]
                                                                                              [tr:get-numeration-level(.)=tr:get-numeration-level($elt)]
                                                                                              [. &gt;&gt; $elt/preceding-sibling::*[not(tr:is-level-element(.,$level))][1]]
                                                                                              [1],$level)"/>
          </xsl:when>
          <xsl:when test="tr:get-numeration-level($elt) gt $level and exists($elt/preceding-sibling::*[matches(@role,'^list\-')]
            [not(matches(@role,'continue'))]
            [tr:get-numeration-level(.)=$level])">
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
  
  <!-- get numeration level from original role  -->
  <xsl:function name="tr:get-role-lvl" as="xs:string">
    <xsl:param name="role"/>
    <xsl:sequence select="if (matches($role,'[1-9][0-9]*$')) 
                          then replace($role,'^.*?([1-9][0-9]*)$','$1') 
                          else if (matches($role,'sub','i')) 
                               then string(count(tokenize($role,'sub','i'))) 
                               else 'na'"/>
  </xsl:function>
  
  <!-- actual hierarchizing -->
  <xsl:function name="tr:hierarchize-lists" as="node()+">
    <xsl:param name="context" as="node()+"/>
    <xsl:param name="level" as="xs:integer"/>
    
    <xsl:for-each-group select="$context[self::*]" group-adjacent="tr:is-level-element(.,$level)">
      <xsl:choose>
        <xsl:when test="current-grouping-key()">
          <xsl:variable name="first-non-continue-element" select="if (tr:get-numeration-style(current-group()[1])='continue') 
                                                                  then current-group()[tr:get-numeration-style(.) ne 'continue'][1] 
                                                                  else ()"/>
          <xsl:for-each-group select="current-group()[self::*]" group-adjacent="if (empty($first-non-continue-element)) 
                                                                                then false() 
                                                                                else . &lt;&lt; $first-non-continue-element">
            <xsl:variable name="first-element-level" select="tr:get-numeration-level(current-group()[1])"/>
            <xsl:variable name="first-higher-level-element" 
                          select="current-group()[tr:get-numeration-level(.) lt $first-element-level][1]"/>
            <xsl:for-each-group select="current-group()[self::*]" group-adjacent="if (empty($first-higher-level-element)) 
                                                                                  then false() 
                                                                                  else . &lt;&lt; $first-higher-level-element">
              <xsl:variable name="actual-level" select="if (current-grouping-key()) 
                                                        then $first-element-level 
                                                        else if (not(empty($first-higher-level-element))) 
                                                             then tr:get-numeration-level($first-higher-level-element) 
                                                             else max(($level,$first-element-level))"/>
              <xsl:for-each-group select="current-group()[self::*]" 
                                  group-adjacent="tr:get-numeration-style-with-level(.,$actual-level)">
                <xsl:variable name="key" select="current-grouping-key()"/>
                <xsl:variable name="true-marks" as="xs:string*">
                  <xsl:apply-templates select="current-group()[self::*[matches(@role,'^list\-')]
                                                                      [tr:get-numeration-level(.)=$actual-level]
                                                                      [tr:get-numeration-style(.)=$key]]/phrase[@role='hub:identifier']" 
                                       mode="hub:list-true-marks"/>
                </xsl:variable>
                <xsl:choose>
                  <xsl:when test="tr:get-list-type($key)='blockquote'">
                    <xsl:element name="{tr:get-list-type($key)}">
                      <xsl:attribute name="role" select="'hub:lists'"/>
                      <xsl:apply-templates select="current-group()" mode="hub:lists-by-role"/>
                    </xsl:element>
                  </xsl:when>
                  <xsl:when test="tr:get-list-type($key)='variablelist'">
                    <xsl:element name="{tr:get-list-type($key)}">
                      <xsl:for-each-group select="current-group()" group-starting-with="*[matches(@role,'^list\-')]
                                                                                         [tr:get-numeration-level(.)=$actual-level]
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
                                <xsl:apply-templates select="current-group()[1]" mode="hub:lists-by-role"/>   
                              </xsl:when>
                              <xsl:otherwise>
                                <xsl:sequence select="hub:split-listitem-at-tab(current-group()[1],$first-tab)"/>    
                              </xsl:otherwise>
                            </xsl:choose>
                            <xsl:if test="count(current-group()) gt 1">
                              <xsl:sequence select="tr:hierarchize-lists(current-group()[position() gt 1],$actual-level+1)"/>  
                            </xsl:if>
                          </listitem>
                        </xsl:element>
                      </xsl:for-each-group>
                    </xsl:element>
                  </xsl:when>
                  <xsl:when test="tr:get-list-type($key)='itemizedlist' or 
                                  (tr:get-list-type($key)='orderedlist' and hub:is-incrementing-identifier-sequence($true-marks,$key))">
                    <xsl:element name="{tr:get-list-type($key)}">
                      <xsl:attribute name="{if (tr:get-list-type($key)='orderedlist') then 'numeration' else 'mark'}" select="$key"/>
                      <xsl:for-each-group select="current-group()" group-starting-with="*[matches(@role,'^list\-')]
                                                                                         [tr:get-numeration-level(.)=$actual-level]
                                                                                         [tr:get-numeration-style(.)=$key]">
                        <xsl:element name="{tr:get-list-element-type($key)}">
                          <xsl:apply-templates select="current-group()[1]" mode="hub:lists-by-role"/>
                          <xsl:if test="count(current-group()) gt 1">
                            <xsl:sequence select="tr:hierarchize-lists(current-group()[position() gt 1],$actual-level+1)"/>  
                          </xsl:if>
                        </xsl:element>
                      </xsl:for-each-group>
                    </xsl:element>    
                  </xsl:when>
                  <xsl:when test="tr:get-list-type($key)='orderedlist'">
                    <xsl:variable name="current-group" select="current-group()" as="node()*"/>
                    <xsl:for-each-group select="current-group()" 
                                        group-starting-with="*[matches(@role,'^list\-')]
                                                              [tr:get-numeration-level(.)=$actual-level]
                                                              [tr:get-numeration-style(.)=$key]
                                                              [phrase[@role='hub:identifier']]
                                                              [not(tr:is-successor(.,$actual-level,$key,$current-group))]">
                      <xsl:element name="{tr:get-list-type($key)}">
                        <xsl:attribute name="numeration" select="$key"/>
                        <xsl:for-each-group select="current-group()" 
                                            group-starting-with="*[matches(@role,'^list\-')]
                                                                  [tr:get-numeration-level(.)=$actual-level]
                                                                  [tr:get-numeration-style(.)=$key]">
                          <xsl:element name="{tr:get-list-element-type($key)}">
                            <xsl:apply-templates select="current-group()[1]" mode="hub:lists-by-role"/>
                            <xsl:if test="count(current-group()) gt 1">
                              <xsl:sequence select="tr:hierarchize-lists(current-group()[position() gt 1],$actual-level+1)"/>  
                            </xsl:if>
                          </xsl:element>
                        </xsl:for-each-group>
                      </xsl:element>
                    </xsl:for-each-group>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:apply-templates select="current-group()" mode="hub:lists-by-role"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:for-each-group>
            </xsl:for-each-group>
          </xsl:for-each-group>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="current-group()" mode="hub:lists-by-role"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each-group>
  </xsl:function>
  
  <xsl:function name="tr:is-successor" as="xs:boolean">
    <xsl:param name="context"/>
    <xsl:param name="actual-level"/>
    <xsl:param name="key"/>
    <xsl:param name="current-group"/>
    <xsl:variable name="mark" as="xs:string*">
      <xsl:apply-templates select="$context[matches(@role,'^list\-')]
                                           [tr:get-numeration-level(.)=$actual-level]
                                           [tr:get-numeration-style(.)=$key]/phrase[@role='hub:identifier']" 
        mode="hub:list-true-marks"/>
    </xsl:variable>
    <xsl:variable name="preceding-mark">
      <xsl:apply-templates select="$context/preceding-sibling::*[matches(@role,'^list\-')]
                                                                [tr:get-numeration-level(.)=$actual-level]
                                                                [tr:get-numeration-style(.)=$key]
                                                                [phrase[@role='hub:identifier']]
                                                                [1]
                                                                [generate-id()=(for $c in $current-group 
                                                                                return $c/generate-id())]/phrase[@role='hub:identifier']" 
        mode="hub:list-true-marks"/>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="not(empty($mark) or $mark='' or empty($preceding-mark) or $preceding-mark='') and 
                      hub:is-incrementing-identifier-sequence(($preceding-mark,$mark),$key)">
        <xsl:sequence select="true()"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="false()"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <!-- determines if a para is an equation or not -->
  <xsl:function name="tr:is-equation-para" as="xs:boolean">
    <xsl:param name="para" as="element(*)"/>
    <xsl:sequence select="$para/@role = $hub:equation-roles or 
                          (count($para/node()) = 1 and ($para/inlineequation or $para/equation))"/>
  </xsl:function>
  
  <!-- determines if a sequence of marks is incrementing considering numeration type -->
  <xsl:function name="hub:is-incrementing-identifier-sequence" as="xs:boolean">
    <xsl:param name="marks" as="xs:string*"/>
    <xsl:param name="key"/>
    <xsl:choose>
      <xsl:when test="count($marks) = 0">
        <xsl:sequence select="false()"/>
      </xsl:when>
      <xsl:when test="count($marks) = 1">
        <xsl:sequence select="true()"/>
      </xsl:when>
      <xsl:when test="every $mark in $marks satisfies (matches($mark,'^[ivxlcdm]+$') and (tr:roman-to-int(upper-case($mark)) gt -1)) and
                      $key='lowerroman'">
        <xsl:variable name="lowerroman" as="xs:boolean+">
          <xsl:for-each select="$marks[position() gt 1]">
            <xsl:variable name="pos" as="xs:integer" select="position()"/>
            <xsl:sequence select="tr:roman-to-int(upper-case(.)) = tr:roman-to-int(upper-case($marks[position() = $pos ])) + 1"/>
          </xsl:for-each>  
        </xsl:variable>
        <xsl:sequence select="every $b in $lowerroman satisfies $b"/>
      </xsl:when>
      <xsl:when test="every $mark in $marks satisfies (matches($mark,'^[IVXLCDM]+$') and (tr:roman-to-int($mark) gt -1)) and
                      $key='upperroman'">
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
      <xsl:when test="every $mark in $marks satisfies matches($mark,'^[\*†‡§\|∥#¶]+$')">
        <xsl:variable name="dagger-regex-sequence" select="('\*','\*\*','†','‡','§','[\|\||∥]','#','¶')" as="xs:string+"/>
        <xsl:variable name="daggers" as="xs:boolean+">
          <xsl:for-each select="$marks">
            <xsl:variable name="pos" as="xs:integer" select="position()"/>
            <xsl:sequence select="matches(.,concat('^',$dagger-regex-sequence[position()=$pos],'$'))"/>
          </xsl:for-each>
        </xsl:variable>
        <xsl:sequence select="every $b in $daggers satisfies $b"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="false()"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <!-- can this element be part of a list on the given level? -->
  <xsl:function name="tr:is-level-element" as="xs:boolean">
    <xsl:param name="elt"/>
    <xsl:param name="level" as="xs:integer"/>
    <xsl:sequence select="$elt[(local-name()=$hub:level-element-names) or 
                               self::para[not(matches(@role,'^list\-'))]
                                         [tr:is-level-element-para(.)]]
                                         [preceding-sibling::*[not((local-name()=$hub:level-element-names) or 
                                                        self::para[not(matches(@role,'^list\-'))]
                                                                  [tr:is-level-element-para(.)])]
                                                   [1]
                                                   [matches(@role,'^list\-') and tr:get-numeration-level(.) ge $level] and
                                          following-sibling::*[not((local-name()=$hub:level-element-names) or 
                                                        self::para[not(matches(@role,'^list\-'))]
                                                                  [tr:is-level-element-para(.)])]
                                                   [1]
                                                   [matches(@role,'^list\-') and tr:get-numeration-level(.) ge $level]] or 
                          (matches($elt/@role,'^list\-') and tr:get-numeration-level($elt) ge $level)"/>
  </xsl:function>
  
  <!-- is this para part of a list? -->
  <xsl:function name="tr:is-level-element-para" as="xs:boolean">
    <xsl:param name="elt" as="element(para)"/>
    
    <xsl:sequence select="if ($elt[every $n in child::node() 
                                   satisfies $n[self::equation or self::mediaobject or self::comment() or self::processing-instruction() or self::text()[matches(.,'^[\s&#160;]*$')]]] or 
                              tr:is-equation-para($elt) or 
                              $elt/@role=$hub:list-role-strings) 
                          then true() else false()"/>
  </xsl:function>
  
</xsl:stylesheet>