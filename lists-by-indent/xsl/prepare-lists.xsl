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
  xmlns:css="http://www.w3.org/1996/css"
  xmlns:hub="http://transpect.io/hub"
  xmlns="http://docbook.org/ns/docbook"
  version="2.0"
  xpath-default-namespace="http://docbook.org/ns/docbook"
  exclude-result-prefixes = "w o v wx xs dbk pkg r rel word200x exsl saxon fn tr">

  <!-- Pull sub list items into preceding list item. -->
  <xsl:template match="listitem[following-sibling::node()[1][self::listitem[orderedlist and count(node()) = count(orderedlist)]]]" mode="hub:prepare-lists">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:apply-templates mode="#current"/>
      <xsl:apply-templates select="following-sibling::node()[1]/orderedlist" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="listitem[preceding-sibling::node()[1][self::listitem] and orderedlist and count(node()) = count(orderedlist)]"
    mode="hub:prepare-lists">
  </xsl:template>

  <!-- Detect consecutive list paras and sort them into preceding listitem -->
  <xsl:template match="orderedlist[listitem/para[1][not(@margin-left) and @text-indent and @text-indent &gt; 0]
                                   and listitem[para[1][@margin-left]]]"
    mode="hub:prepare-lists">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:for-each-group select="node()" group-starting-with="listitem[para[1][@margin-left]]">
        <xsl:choose>
          <xsl:when test="current-group()[1][self::listitem[para[1][@margin-left]]]">
            <listitem>
              <xsl:apply-templates select="current-group()/node()" mode="#current"/>
              <!-- ist das nächste listitem eine Unterliste? -->
              <xsl:if test="current-group()[last()]/following-sibling::node()[1][self::listitem[count(node()) = 1 and orderedlist]]">
                <xsl:apply-templates select="following-sibling::node()[1]/orderedlist" mode="#current"/>
              </xsl:if>
            </listitem>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="current-group()" mode="#current"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>

  <!-- Pull equations out of lists 
  <xsl:template match="orderedlist[listitem[para[1]/@role = $hub:equation-roles]]" mode="hub:prepare-lists">
    <xsl:for-each-group select="node()" group-starting-with="listitem[para[1]/@role = $hub:equation-roles]">
      <xsl:choose>
        <xsl:when test="current-group()[1][self::listitem[para[1]/@role = $hub:equation-roles]]">
          <xsl:apply-templates select="current-group()[1]/node()" mode="#current"/>
          <xsl:if test="current-group()[position() &gt; 1]">
            <orderedlist>
              <xsl:apply-templates select="current-group()[position() &gt; 1]" mode="#current"/>
            </orderedlist>
          </xsl:if>
        </xsl:when>
        <xsl:otherwise>
          <orderedlist>
            <xsl:apply-templates select="current-group()" mode="#current"/>
          </orderedlist>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each-group>
  </xsl:template>
  -->

  <xsl:template match="listitem[para[1][not(@margin-left) and @text-indent and @text-indent &gt; 0]
                       and parent::orderedlist[listitem[1][para[1][@margin-left]]]]" mode="hub:prepare-lists">
    <!-- these are consecutive list paras set via tabs oder text-indent  -->
  </xsl:template>

  <!-- adjust @tab-stops of consecutive list paragraphs in listitem -->
  <xsl:template match="para[parent::listitem and not(@margin-left) and @text-indent]/@tab-stops
                       [tokenize(tokenize(., ' ')[1], ';')[1] = ../@text-indent]" mode="hub:prepare-lists">
    <xsl:variable name="new-tabs" select="string-join(tokenize(., ' ')[position() &gt; 1], ' ')"/>
    <xsl:if test="not($new-tabs = '')">
      <xsl:attribute name="tab-stops" select="$new-tabs"/>
    </xsl:if>
  </xsl:template>

  <!-- IDML, consecutive list paras in listitems -->
  <xsl:template match="orderedlist[listitem/para[1][not(descendant::phrase[@role = 'hub:identifier'])]
                       and listitem/para[1][descendant::phrase[@role = 'hub:identifier']]
                       and (every $x in listitem/para[1] satisfies exists($x/@margin-left))
                       and (every $x in listitem/para[1]/@margin-left satisfies $x = listitem[1]/para[1]/@margin-left)]" mode="hub:prepare-lists">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:for-each-group select="node()" group-starting-with="listitem[para[1][
                                                                 descendant::phrase[@role = 'hub:identifier']
                                                                 or
                                                                 hub:is-variable-list-listitem-without-phrase-identifier(.)
                                                               ]]">
        <xsl:choose>
          <xsl:when test="current-group()[1][self::listitem[para[1][
                            descendant::phrase[@role = 'hub:identifier']
                            or
                            hub:is-variable-list-listitem-without-phrase-identifier(.)
                          ]]]">
            <listitem>
              <xsl:apply-templates select="current-group()/node()" mode="#current"/>
            </listitem>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="current-group()" mode="#current"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>

	<xsl:key name="hub:list-styles" match="css:rule" use="@css:list-style-type"/>
	
  <!-- for IDML -->
  <xsl:template match="phrase[@role eq 'hub:identifier'][not(node())]" mode="hub:prepare-lists">
  	<xsl:variable name="context" select="." as="element()"/>
    <xsl:variable name="list-style-type" as="xs:string" 
      select="('', (key('hub:style-by-role', ../@role), ..)/@css:list-style-type)[last()]"/>
    <xsl:variable name="is-list-item" as="xs:boolean" 
      select="((key('hub:style-by-role', ../@role), ..)/@css:display)[last()] = 'list-item'"/>
  	 <xsl:variable name="all-list-styles" as="xs:string*"
      select="key('hub:list-styles', $list-style-type)[@hub:numbering-level = key('hub:style-by-role', current()/../@role)/@hub:numbering-level]/@name">
  	 	<!-- same style type and same level -->
  	 </xsl:variable>

  	<xsl:variable name="override" as="xs:integer?">
  		<xsl:for-each-group select="/*//orderedlist/listitem[some $p in para satisfies $p/@role = $all-list-styles]" group-starting-with=".[para[@role = $all-list-styles][@hub:numbering-continue[. = 'false'] or exists(key('hub:style-by-role', @role)[not(@hub:numbering-continue) or @hub:numbering-continue = 'false'])]]">
  		<xsl:if test="current-group()[some $elt in descendant::* satisfies $elt is $context]">
  			<xsl:sequence select="index-of(current-group()/*/@srcpath, $context/../@srcpath)"/>
  		</xsl:if>
  	</xsl:for-each-group>
  	</xsl:variable>
<!--   <xsl:message select="'####', $all-list-styles, $override"/>-->
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:if test="$is-list-item">
        <xsl:variable name="list-item-position" as="xs:integer"
          select="count(
                    ../../preceding-sibling::*[
                      (
                        node()[1]/@css:list-style-type, 
                        key('hub:style-by-role', node()[1]/@role)/@css:list-style-type
                      )[1] eq $list-style-type
                    ]
                  ) + 1"/>
        <xsl:number format="{hub:numbering-format($list-style-type)}" value="($override, $list-item-position)[1]"/>
      	    	<xsl:message>
    		 <xsl:number format="{hub:numbering-format($list-style-type)}" value="($override, $list-item-position)[1]"/>
    	</xsl:message>
      </xsl:if>

    </xsl:copy>
  </xsl:template>

  <xsl:function name="hub:numbering-format" as="xs:string">
    <xsl:param name="list-style-type" as="xs:string"/>
    <xsl:choose>
      <xsl:when test="$list-style-type = 'decimal'"><xsl:sequence select="'1'"/></xsl:when>
      <xsl:when test="$list-style-type = 'lower-roman'"><xsl:sequence select="'i'"/></xsl:when>
      <xsl:when test="$list-style-type = 'upper-roman'"><xsl:sequence select="'I'"/></xsl:when>
      <xsl:when test="$list-style-type = 'lower-alpha'"><xsl:sequence select="'a'"/></xsl:when>
      <xsl:when test="$list-style-type = 'upper-alpha'"><xsl:sequence select="'A'"/></xsl:when>
      <xsl:otherwise><xsl:sequence select="$list-style-type"/></xsl:otherwise>
    </xsl:choose>
  </xsl:function>
	
  <xsl:template match="css:rule" mode="hub:prepare-lists">
    <xsl:call-template name="css:move-to-attic">
      <xsl:with-param name="atts" select="@css:list-style-type, @css:display[. = 'list-item'], 
        @*[matches(name(), '^css:pseudo-marker_')],
        @css:margin-left[concat('-', .) = ../@css:text-indent]
        [not(matches(current()/@name, $hub:list-by-indent-exception-role-regex))],
        @css:text-indent[. = concat('-', ../@css:margin-left)]
        [not(matches(current()/@name, $hub:list-by-indent-exception-role-regex))],
        @css:text-indent[../@css:display = 'list-item']                
        "/>
      <!-- §§§ text-indent is removed "twice" for some common cases. We had a case where it wasn’t equal to 
        the negative margin-left. But it was in a list and had to be removed nevertheless. Otherwise, the
        paragraph’s text would move to close to the bullet. -->
      <!-- §§§ should have used a proper length comparison function for @css:margin-left an @css:text-indent --> 
    </xsl:call-template>
  </xsl:template>
</xsl:stylesheet>