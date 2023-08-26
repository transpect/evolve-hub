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


  <!-- 
    There are situations when you don’t want to select the
    text nodes of an embedded footnote when selecting the text
    nodes of a paragraph.
    A footnote, for example, constitutes a so called “scope.”
    Other scope-establishing elements are table cells that
    may contain paragraphs, or figures/tables whose captions 
    may contain paragraphs. But also indexterms, elements that 
    do not contain paragraphs, may establish a new scope. 
    This concept allows you to select only the main narrative 
    text of a given paragraph (or phrase, …), excluding any 
    content of embedded notes, figures, list items, or index 
    terms.
    Example:
<para><emphasis>Outer</emphasis> para text<footnote><para>Footnote text</para></footnote>.</para>
    Typical invocation (context: outer para):
    .//text()[hub:same-scope(., current())]
    Result: The three text nodes with string content
    'Outer', ' para text', and '.'
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
             'indexterm',
             'listitem', 
             'table',
             'sidebar')"/>

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
  
  <xsl:template match="@* | indexterm | para | alt | info" mode="discard-index-terms-and-paras"/>
  
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
        <xsl:sequence select="@*" />
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
      <xsl:when test="$caption-number-plus-current-and-previous-string-in-current-text eq normalize-space($string2)">
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
  
  <xsl:function name="hub:is-valid-attr-name" as="xs:boolean">
    <xsl:param name="attr-name" as="xs:string?"/>
    <xsl:variable name="attribute-start-char-regex" as="xs:string"
      select="'[:A-Z_a-z&#x00C0;-&#x00D6;&#x00D8;-&#x00F6;&#x00F8;-&#x02FF;&#x0370;-&#x037D;&#x037F;-&#x1FFF;&#x200C;-&#x200D;&#x2070;-&#x218F;&#x2C00;-&#x2FEF;&#x3001;-&#xD7FF;&#xF900;-&#xFDCF;&#xFDF0;-&#xFFFD;&#x10000;-&#xEFFFF;]'"/>
    <xsl:sequence select="matches($attr-name, concat(
                            '^', 
                            $attribute-start-char-regex, 
                            '([-\.0-9&#x00B7;&#x0300;-&#x036F;&#x203F;-&#x2040;]|', 
                            $attribute-start-char-regex, 
                            ')+$'
                          ))"/>
  </xsl:function>
  
  <xsl:function name="hub:letters-to-number" as="xs:integer">
  <!--wrapper for 1-parameter-call; default: type=1-->
    <xsl:param name="string" as="xs:string"/>
    <xsl:sequence select="hub:letters-to-number($string,1)"/>
  </xsl:function>
  
  <xsl:function name="hub:letters-to-number" as="xs:integer">
    <!-- a, b, c, …, aa, ab, … to 1, 2, 3, …, 27, 28, …
      Maybe this function should also deal with a, b, c, …, aa, bb, cc, … -->
    
    <xsl:param name="string" as="xs:string"/>
    <xsl:param name="type"/>
    <!--possible values: 1: normal: a..z, aa, ab..az, ba, bb
                         2: double digits: a..z, aa, bb..zz-->
    
    <xsl:variable name="offset" as="xs:integer">
      <xsl:choose>
        <xsl:when test="matches($string, '^[a-z][a-z]*$')">
          <xsl:sequence select="96"/>
        </xsl:when>
        <xsl:when test="matches($string, '^[A-Z][A-Z]*$')">
          <xsl:sequence select="64"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="-1"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$type = 2">
        <!-- length ordered letter groups aa,bb -->
        <xsl:choose>
          <xsl:when test="$offset = -1">
            <xsl:sequence select="0"/><!-- or throw an error? -->
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="nums" as="xs:integer+">
              <xsl:for-each select="string-to-codepoints($string)">
                <xsl:sequence select="."/>
              </xsl:for-each>
            </xsl:variable>
            <xsl:variable name="length" as="xs:integer" select="count($nums)"/>
            <xsl:sequence select="xs:integer((sum($nums) div $length) + (26 * ($length - 1)) - $offset)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <!-- lexicographic ordered letters aa,ab -->
        <xsl:choose>
          <xsl:when test="$offset = -1">
            <xsl:sequence select="0"/><!-- or throw an error? -->
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="nums" as="xs:integer+">
              <xsl:for-each select="reverse(string-to-codepoints($string))">
                <xsl:sequence select="(. - $offset) * hub:pow(26, position() - 1)"/>
              </xsl:for-each>
            </xsl:variable>
            <xsl:sequence select="xs:integer(sum($nums))"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:function name="hub:pow" as="xs:integer">
    <xsl:param name="base" as="xs:integer"/>
    <xsl:param name="power" as="xs:integer"/>
    <xsl:choose>
      <xsl:when test="$power eq 0">
        <xsl:sequence select="1"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="$base * hub:pow($base, $power - 1)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
    
  <xsl:function name="hub:is-incrementing-alpha-sequence" as="xs:boolean">
    <xsl:param name="marks" as="xs:string*"/>
    <xsl:choose>
      <xsl:when test="count($marks) = 0">
        <xsl:sequence select="false()"/>
      </xsl:when>
      <xsl:when test="count($marks) = 1">
        <xsl:sequence select="true()"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="tmp" as="xs:boolean+">
          <xsl:for-each select="$marks[position() gt 1]">
            <xsl:variable name="pos" as="xs:integer" select="position()"/>
            <xsl:sequence select="hub:letters-to-number(.) = hub:letters-to-number($marks[position() = $pos ]) + 1"/>
          </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="tmp2" as="xs:boolean+">
          <xsl:for-each select="$marks[position() gt 1]">
            <xsl:variable name="pos" as="xs:integer" select="position()"/>
            <xsl:sequence select="hub:letters-to-number(.,2) = hub:letters-to-number($marks[position() = $pos ],2) + 1"/>
          </xsl:for-each>
        </xsl:variable>
        <xsl:sequence select="every $b in $tmp satisfies $b or (every $b in $tmp2 satisfies $b)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="hub:normalize-text" as="xs:string">
    <xsl:param name="nodes" as="node()*"/>
    <xsl:param name="type" as="xs:string?"/>
    <xsl:choose>
      <xsl:when test="$type = '+annot'">
        <xsl:sequence select="normalize-space(string-join($nodes, ''))"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="normalize-space(string-join($nodes/descendant::text()[not(ancestor::annotation)], ''))"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="hub:normalize-text" as="xs:string">
    <xsl:param name="nodes" as="node()*"/>
    <xsl:sequence select="hub:normalize-text($nodes, '')"/>
  </xsl:function>

  <!-- function hub:very-first-text-node-in-context 
       will return the first 'valid' content (can be also an element) -->
  <xsl:function name="hub:very-first-text-node-in-context" as="node()?">
    <xsl:param name="context" as="node()"/>
    <xsl:sequence select="(
                            $context/descendant::node()[not(local-name() = ('anchor', 'info', 'tabs'))]
                                                       [hub:same-scope(., $context)][. != '']
                          )[1]"/>
  </xsl:function>
  
  <!-- converts filerefs starting with 'container:' to URIs -->
  
  <xsl:function name="hub:container-path-to-uri" as="xs:string">
    <xsl:param name="path" as="xs:string"/>
    <xsl:param name="source-dir-uri" as="xs:string"/>
    <xsl:variable name="fixed-win-path" select="replace($path, '\\+', '/')" as="xs:string"/>
    <xsl:value-of select="resolve-uri(replace($fixed-win-path, '^container:', ''), 
                                      $source-dir-uri)"/>
  </xsl:function>

</xsl:stylesheet>
