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
  xmlns="http://docbook.org/ns/docbook"
  version="2.0"
  xpath-default-namespace="http://docbook.org/ns/docbook"
  exclude-result-prefixes = "w o v wx xs dbk pkg r rel word200x exsl saxon fn tr hub">



  <!-- Toleranz bei Einzügen (1 entspricht 1/20 pt)  -->
  <xsl:variable name="hub:indent-epsilon" select="30" as="xs:integer"/>

  <xsl:variable name="hub:list-by-indent-exception-role-regex" select="'^TOC'" as="xs:string"/>
  
  <!-- For some people it might be useful if paras with tables inside are not indented. Or empty paras. Those can be given here. 
    Also a possibility to define that only certain paras (with a list style format for instance) are processed. 
    The result should be false(), if its input should not be indented. -->
  <xsl:function name="hub:condition-that-stops-indenting-apart-from-role-regex" as="xs:boolean">
    <xsl:param name="input" as="element(*)*"/>
    <!-- to allow other conversions to stay unaffected. Override in adaptions -->
    <xsl:sequence select="true()"/>
  </xsl:function>
  
  <xsl:function name="hub:lists-permitted-here" as="xs:boolean">
    <xsl:param name="input" as="element(*)"/>
    <!-- had to be refactorized. In some cases lists in bibliodivs are needed for example-->
    <xsl:sequence select="exists(
                            $input[    
                                  not(self::footnote) 
                              and not(ancestor-or-self::toc) 
                              and not(ancestor-or-self::bibliography) 
                              and not(ancestor-or-self::info[
                                not($input/local-name() = ('abstract', 'formalpara', 'legalnotice', 'printhistory'))
                              ])
                             and not(self::remark[@role = 'endnote'])
                          ])"/>
  </xsl:function>
  
  <!-- phrase/@role='hub:identifier' have been marked in mode hub:identifiers -->
  <xsl:template match="*[
                         *[
                           @margin-left &gt; $hub:indent-epsilon 
                           and not(matches(@role, $hub:list-by-indent-exception-role-regex))
                          ]
                       ]" mode="hub:handle-indent">
    <xsl:choose>
      <xsl:when test="hub:lists-permitted-here(.)">
        <xsl:copy>
          <xsl:apply-templates select="@*" mode="#current"/>
          <xsl:for-each-group select="node()" 
            group-adjacent="(
                              (
                                @margin-left 
                                and @margin-left &gt; $hub:indent-epsilon
                              )
                              (: why should a positive text-indent indicate that there is a list?
                              or 
                              (
                                @text-indent
                                and @text-indent &gt; $hub:indent-epsilon
                              )
                              :)
                            )
                            (: cf. discussion in https://letexml.slack.com/archives/hub2app/p1426695436000042
                              and not(
                              exists(@text-indent) 
                              and exists(@margin-left)
                              and @text-indent + @margin-left = 0
                              and not(.//tab)
                            ):)
                            and not(matches(@role, $hub:list-by-indent-exception-role-regex))
                            and not(self::*[local-name() = ('title', 'subtitle', 'titleabbrev', 'bridgehead', 'entry')])
                            and not(self::para[(@role = $hub:equation-roles) or starts-with(@role, 'heading')])
                            and hub:condition-that-stops-indenting-apart-from-role-regex(.)
                            and not(self::biblioentry[count(child::*)=1 and bibliomisc[not(child::node())]])">
            <xsl:choose>
              <xsl:when test="current-grouping-key()">
                <xsl:call-template name="create-list">
                  <xsl:with-param name="nodes" select="current-group()"/>
                </xsl:call-template>
              </xsl:when>
              <xsl:otherwise>
                <xsl:apply-templates select="current-group()" mode="#current"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each-group>
        </xsl:copy>
      </xsl:when>
      <xsl:otherwise>
        <xsl:next-match/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="create-list">
    <xsl:param name="nodes" as="node()+"/>
    <xsl:param name="count" select="1" as="xs:integer"/>
    <!-- looping auf Ebene 20 abbrechen -->
    <xsl:if test="$count gt 20">
      <xsl:message terminate="yes">Terminated at list nesting depth 20. This list detection stylesheet is probably looping.</xsl:message>
    </xsl:if>
    <!--<xsl:variable name="indent" select="($nodes[1]/@margin-left, 0)[1] + ($nodes[1]/@text-indent, 0)[1]"/>-->
<xsl:variable name="indent" select="min( for $n in $nodes 
                                             return (($n/@margin-left, 0)[1] + ($n/@text-indent, 0)[1])
                                           )"/>
<xsl:variable name="temporary-list" as="node()*">
        <xsl:for-each-group select="$nodes"
          group-adjacent="abs($indent - (@margin-left, 0)[1] - (@text-indent, 0)[1]) &lt;= $hub:indent-epsilon">
          <xsl:choose>
            <xsl:when test="current-grouping-key()">
              <xsl:for-each select="current-group()">
                <listitem>
                  <xsl:apply-templates select="." mode="#current"/>
                </listitem>
              </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
              <xsl:choose>
                <xsl:when test="not($nodes[1]/@margin-left) and exists($nodes[1]/@text-indent) and ($nodes[1]/@text-indent = $indent)">
                  <xsl:for-each select="current-group()">
                    <listitem>
                      <xsl:apply-templates select="." mode="#current"/>
                    </listitem>
                  </xsl:for-each>
                </xsl:when>
                <xsl:when test="$indent - (@margin-left, 0)[1] - (@text-indent, 0)[1] &gt; $hub:indent-epsilon">
                  <xsl:call-template name="create-list">
                    <xsl:with-param name="nodes" select="current-group()"/>
                    <xsl:with-param name="count" select="$count + 1"/>
                  </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                  <listitem>
                    <xsl:call-template name="create-list">
                      <xsl:with-param name="nodes" select="current-group()"/>
                      <xsl:with-param name="count" select="$count + 1"/>
                    </xsl:call-template>
                  </listitem>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each-group>
    </xsl:variable>
<xsl:for-each-group select="$temporary-list" group-adjacent="local-name()">
      <xsl:choose>
        <xsl:when test="current-group()[1][self::listitem]">
          <orderedlist>
            <xsl:sequence select="current-group()"/>
          </orderedlist>
        </xsl:when>
        <xsl:when test="current-group()[1][self::orderedlist]">
          <xsl:sequence select="current-group()"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:message terminate="yes">
            Falsches Element in create-list!
          </xsl:message>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each-group>
  </xsl:template>
  
  
</xsl:stylesheet>
