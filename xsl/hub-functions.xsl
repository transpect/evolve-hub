<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:saxon="http://saxon.sf.net/"
  xmlns:dbk="http://docbook.org/ns/docbook"
  xmlns:hub="http://transpect.io/hub"
  xmlns:tr="http://transpect.io"
  xmlns:idml2xml="http://transpect.io/idml2xml"
  xpath-default-namespace="http://docbook.org/ns/docbook"
  xmlns="http://docbook.org/ns/docbook"
  exclude-result-prefixes="xs saxon tr hub dbk idml2xml"
  version="2.0">

  <xsl:function name="hub:boolean-param" as="xs:boolean">
    <xsl:param name="input" as="xs:string" />
    <xsl:sequence select="$input = ('yes', '1', 'true')" />
  </xsl:function>

  <xsl:function name="hub:get-boolean-docprop" as="xs:boolean">
    <xsl:param name="root" as="document-node()" />
    <xsl:param name="propname" as="xs:string" />
    <xsl:sequence select="$root/*/info/keywordset[@role eq 'hub']/keyword[@role eq $propname] = 'true'" />
  </xsl:function>

  <xsl:function name="hub:get-string-docprop" as="xs:string?">
    <xsl:param name="root" as="document-node(element(*))" />
    <xsl:param name="propname" as="xs:string" />
    <xsl:sequence select="$root/*/info/keywordset[@role eq 'hub']/keyword[@role eq $propname]" />
  </xsl:function>


  <!-- Tests whether $elt is immediately contained in $ancestor-elt 
       (that is, in the same Story, in the same Cell, etc.). 
       Or phrased differently: whether $elt is in a paragraph
       where $ancestor-elt's ParagraphStyleRange is still in force.
       This function works with IDML input and with extracted XML,
       provided that @aid:table and @idml2xml:story are conserved 
       in the extracted XML.
       -->
  <xsl:function name="hub:same-scope" as="xs:boolean">
    <xsl:param name="node" as="node()" />
    <xsl:param name="ancestor-elt" as="element(*)*" />
    <xsl:sequence select="not($node/ancestor::*[local-name() = $hub:same-scope-element-names]
                                               [some $a in ancestor::* satisfies (some $b in $ancestor-elt satisfies ($a is $b))])" />
  </xsl:function>

  <xsl:variable name="hub:same-scope-element-names" as="xs:string*"
    select="('annotation', 
             'entry', 
             'blockquote', 
             'figure', 
             'footnote', 
             'listitem', 
             'table')"/>

  <xsl:function name="hub:escape-for-regex" as="xs:string">
    <xsl:param name="input" as="xs:string"/>
    <xsl:sequence select="replace($input, '([\[{()}\].])', '\\$1')"/>
  </xsl:function>

  <xsl:function name="hub:to-twips" as="xs:double">
    <xsl:param name="css-length" as="xs:string"/>
    <xsl:choose>
      <xsl:when test="ends-with($css-length, 'pt')">
        <xsl:sequence select="xs:double(replace($css-length, 'pt$', '')) * 20" />
      </xsl:when>
      <xsl:otherwise>
        <!-- provisional: -->
        <xsl:sequence select="number($css-length)" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="hub:same-scope-text" as="xs:string">
    <xsl:param name="elt" as="element(*)"/>
    <xsl:variable name="cleaned-elt" as="element(*)">
      <xsl:element name="{local-name($elt)}">
        <xsl:apply-templates select="$elt/node()" mode="discard-index-terms-and-paras"/>
      </xsl:element>
    </xsl:variable>
    <xsl:sequence select="string-join($cleaned-elt/descendant-or-self::text()[hub:same-scope(., $elt)], '')"/>
  </xsl:function>

  <xsl:template match="node()" mode="discard-index-terms-and-paras">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="@* | indexterm | para | alt" mode="discard-index-terms-and-paras"/>
  
  <xsl:function name="hub:insert-sep" as="element(*)">
    <xsl:param name="elt" as="element(*)" />
    <xsl:param name="sep-regex" as="xs:string" />
    <xsl:apply-templates select="$elt" mode="hub:insert-sep">
      <xsl:with-param name="sep-regex" select="$sep-regex" tunnel="yes" />
    </xsl:apply-templates>
  </xsl:function>

  <xsl:template match="text()" mode="hub:insert-sep">
    <xsl:param name="sep-regex" as="xs:string" tunnel="yes" />
    <xsl:analyze-string select="." regex="{$sep-regex}" flags="s">
      <xsl:matching-substring>
        <hub:sep/>
      </xsl:matching-substring>
      <xsl:non-matching-substring>
        <xsl:value-of select="."/>
      </xsl:non-matching-substring>
    </xsl:analyze-string>
  </xsl:template>


  <xsl:template match="node()" mode="hub:upward-project">
    <xsl:param name="restricted-to" as="node()+" tunnel="yes" />
    <xsl:if test="exists(. intersect $restricted-to)">
      <xsl:copy>
        <xsl:copy-of select="@*" />
        <xsl:apply-templates mode="#current" />
      </xsl:copy>
    </xsl:if>
  </xsl:template>


  <xsl:function name="hub:normalize-caption-number" as="xs:string?">
    <xsl:param name="input" as="xs:string?"/>
    <xsl:sequence select="if ($input) 
                          then 
                            replace(
                              replace($input, '&#xa0;', '&#x20;'), 
                                '^(.+?)[a-z,]*$',
                                '$1'
                            )
                          else ()" />
  </xsl:function>


  <xsl:function name="hub:normalize-for-message" as="xs:string">
    <xsl:param name="input" as="xs:string" />
    <xsl:sequence select="replace(
                            replace(
                              $input,
                              '\p{Pd}',
                              '-'
                            ),
                            '\p{Zs}',
                            ' '
                          )" />
  </xsl:function>

  <xsl:function name="hub:debug-uri" as="xs:string">
    <xsl:param name="dir" as="xs:string"/>
    <xsl:param name="basename" as="xs:string"/>
    <xsl:param name="extension" as="xs:string"/>
    <xsl:sequence select="xs:string(resolve-uri(concat($dir, '/', $basename, '.', $extension)))"/>
  </xsl:function>

  <!-- debugging function hub:set-origin just adds an attribute or PI 
       to find out which template has created an element.
       string switch: enable or disable this function
       string origin-val: value inserted in attribute or procesing-instruction
       string insert-type: insert $origin-val as attribute ('attr') 
                           or PI ('pi') when attributes can't be created on context node
  -->
  <xsl:function name="hub:set-origin" as="node()?">
    <xsl:param name="switch" as="xs:string"/>
    <xsl:param name="origin-val" as="xs:string"/>
    <xsl:param name="insert-type" as="xs:string"/>
    <xsl:if test="hub:boolean-param($switch)">
      <xsl:choose>
        <xsl:when test="$insert-type eq 'pi'">
          <xsl:sequence select="hub:set-origin-pi($origin-val)"/>
        </xsl:when>
        <xsl:when test="$insert-type eq 'attr'">
          <xsl:sequence select="hub:set-origin-attr($origin-val)"/>
        </xsl:when>
        <!-- (otherwise, create origin attribute, defaultly) -->
        <xsl:otherwise>
          <xsl:sequence select="hub:set-origin-attr($origin-val)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:function>

  <!-- default usage of func set-origin: insert an origin attribute -->
  <xsl:function name="hub:set-origin" as="node()?">
    <xsl:param name="switch" as="xs:string"/>
    <xsl:param name="origin-val" as="xs:string"/>
    <xsl:sequence select="hub:set-origin($switch, $origin-val, 'attr')"/>
  </xsl:function>

  <xsl:function name="hub:set-origin-pi" as="processing-instruction(hub-origin)">
    <xsl:param name="origin-val" as="xs:string"/>
    <xsl:processing-instruction name="hub-origin" select="$origin-val"/>
  </xsl:function>

  <xsl:function name="hub:set-origin-attr" as="attribute(hub-origin)">
    <xsl:param name="origin-val" as="xs:string"/>
    <xsl:attribute name="hub-origin" select="$origin-val"/>
  </xsl:function>

  <!-- function hub:get-endpos-of-string1-in-string2
       Returns the position in string1, where string2 ends in text-before-string1 plus string1. Function works recursively.
       Input/Params:
          - 'string2': a string with its last character in string1
          - 'text-before-string1': text added in front of string1 before string1 and string2 will be compared, optionally (leave blank)
          - 'string1': a string where string2 will (function returns <hub:pos>) or will not end (no <hub:pos element)
          - 'current-pos': character position in string1. set to '1' on first function call!
       Example 1 Call: hub:get-endpos-of-string1-in-string2("Abb. 1.1", "", "Abb. 1.1", 1)
       Example 1 Output: <hub:pos num="8"/>
       Example 2 Call: hub:get-endpos-of-string1-in-string2("Fig. 25.14a,b", "Fig. 25.14a", ",b Ankle arthrodesis", 1)
       Example 2 Output: <hub:pos num="2"/>
  -->
  <xsl:function name="hub:get-endpos-of-string1-in-string2" as="element(hub:pos)?">
    <xsl:param name="string2" as="xs:string"/>
    <xsl:param name="text-before-string1" as="xs:string"/>
    <xsl:param name="string1" as="xs:string"/>
    <xsl:param name="current-pos" as="xs:integer"/>
    
    <xsl:variable name="caption-number-plus-current-and-previous-string-in-current-text" as="xs:string"
      select="string-join(($text-before-string1, substring($string1, 1, $current-pos)), '')"/>
    
    <xsl:choose>
      <xsl:when test="$current-pos gt string-length($string1)"/>
      <xsl:when test="$caption-number-plus-current-and-previous-string-in-current-text eq $string2">
        <hub:pos val="{$current-pos}"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="hub:get-endpos-of-string1-in-string2($string2, $text-before-string1, $string1, $current-pos + 1)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

<xsl:function name="hub:contains-tokens" as="xs:boolean">
    <xsl:param name="string" as="xs:string?"/>
    <xsl:param name="tokens" as="xs:string*"/>
    <xsl:sequence select="tokenize($string, '\s+') = $tokens"/>
  </xsl:function>
  
  <xsl:function name="hub:contains-token" as="xs:boolean">
    <xsl:param name="string" as="xs:string?"/>
    <xsl:param name="token" as="xs:string"/>
    <xsl:sequence select="tokenize($string, '\s+') = $token"/>
  </xsl:function>

</xsl:stylesheet>
