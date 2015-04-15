<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" 
  xmlns:saxon="http://saxon.sf.net/"
  xmlns:dbk="http://docbook.org/ns/docbook" 
  xmlns:tr="http://transpect.io"
  xmlns:idml2xml="http://transpect.io/idml2xml" 
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:css="http://www.w3.org/1996/css" 
  xmlns:hub="http://transpect.io/hub"
  xmlns="http://docbook.org/ns/docbook" 
  exclude-result-prefixes="xs saxon tr xlink hub dbk idml2xml"
  version="2.0">

  <xsl:import href="http://transpect.io/xslt-util/lengths/xsl/lengths.xsl"/>

  <xsl:template
    match="*[*[hub:is-continued-table(.)][preceding-sibling::*:table[not(hub:is-continued-table(.))]]]"
    mode="hub:table-merge">
    <xsl:call-template name="merge-tables">
      <xsl:with-param name="context" select="."/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="merge-tables">
    <xsl:param name="context" as="node()"/>

    <xsl:variable name="temp" as="node()">
      <xsl:element name="{$context/name()}">
        <xsl:copy-of select="$context/@*"/>
        <xsl:for-each-group select="$context/node()"
          group-starting-with="*:table[not(hub:is-continued-table(.))]">
          <xsl:choose>
            <xsl:when test="current-group()[1][self::*:table[not(hub:is-continued-table(.))]]">
              <xsl:for-each-group select="current-group()"
                group-ending-with="*[hub:is-continued-table(.)]">
                <xsl:choose>
                  <xsl:when
                    test="current-group()[1][self::*:table[not(hub:is-continued-table(.))]] and current-group()[last()][self::*[hub:is-continued-table(.)]]">
                    <xsl:for-each-group select="current-group()"
                      group-adjacent="if (
                      self::*[hub:is-continued-table(.)] or 
                      self::*:para[not(child::node()[not(self::*:anchor)])] or 
                      self::*:table[not(hub:is-continued-table(.))] or 
                      self::*:para[matches(.,'\(fortgesetzt\)')]
                      ) 
                      then true() 
                      else false()">
                      <xsl:choose>
                        <xsl:when
                          test="current-grouping-key() and current-group()[1][self::*:table[not(hub:is-continued-table(.))]] and current-group()[last()][self::*[hub:is-continued-table(.)]]">
                          <xsl:choose>
                            <xsl:when
                              test="string-join(current-group()[1]/*:title/*:phrase[@role='hub:caption-number']/*:phrase[@role='hub:identifier']/text(), '') = hub:get-continued-table-identifier(current-group()[last()])">
                              <table>
                                <xsl:apply-templates
                                  select="((current-group()[self::*[matches(name(),'table$')]]/*:title)[1] | current-group()[self::*[matches(name(),'table$')]]/*:titleabbrev), current-group()[self::*[matches(name(),'table$')]]/*:info, (current-group()[self::*[matches(name(),'table$')]]/*:alt | current-group()[self::*[matches(name(),'table$')]]/*:indexterm | current-group()[self::*[matches(name(),'table$')]]/*:textobject)"
                                  mode="#current"/>
                                <xsl:for-each-group
                                  select="current-group()[self::*[matches(name(),'table$')]]/*:mediaobject | current-group()[self::*[matches(name(),'table$')]]/*:tgroup"
                                  group-adjacent="name()">
                                  <xsl:choose>
                                    <xsl:when
                                      test="current-grouping-key()='tgroup' and count(current-group()) gt 1">
                                      <xsl:for-each-group select="current-group()"
                                        group-adjacent="@cols">
                                        <xsl:choose>
                                          <xsl:when test="count(current-group()) gt 1">
                                            <xsl:for-each-group select="current-group()"
                                              group-adjacent="if (*:thead) then *:thead else ''">
                                              <xsl:choose>
                                                <xsl:when test="count(current-group()) gt 1">
                                                  <tgroup>
                                                  <xsl:attribute name="cols"
                                                  select="current-group()[1]/@cols"/>
                                                  <xsl:variable name="colspecs"
                                                  select="current-group()/*:colspec" as="node()*"/>
                                                  <xsl:for-each
                                                  select="distinct-values($colspecs/@colname)">
                                                  <colspec>
                                                  <xsl:attribute name="colname" select="."/>
                                                  <xsl:attribute name="colnum"
                                                  select="$colspecs[@colname=current()][1]/@colnum"/>
                                                  <xsl:attribute name="colwidth"
                                                  select="hub:get-average-width($colspecs[@colname=current()]/@colwidth)"
                                                  />
                                                  </colspec>
                                                  </xsl:for-each>
                                                  <xsl:for-each
                                                  select="distinct-values(current-group()/*:spanspec/@spanname)">
                                                  <spanspec>
                                                  <xsl:attribute name="spanname" select="."/>
                                                  <xsl:attribute name="namest"
                                                  select="$colspecs[@spanname=current()][1]/@namest"/>
                                                  <xsl:attribute name="nameend"
                                                  select="$colspecs[@spanname=current()][1]/@nameend"
                                                  />
                                                  </spanspec>
                                                  </xsl:for-each>
                                                  <xsl:apply-templates
                                                  select="current-group()[1]/*:thead"
                                                  mode="#current">
                                                  <xsl:with-param name="merge" select="true()"/>
                                                  </xsl:apply-templates>
                                                  <xsl:if test="current-group()/*:tfoot">
                                                  <tfoot>
                                                  <xsl:apply-templates
                                                  select="current-group()/*:tfoot/*:row"
                                                  mode="#current"/>
                                                  </tfoot>
                                                  </xsl:if>
                                                  <tbody>
                                                  <xsl:apply-templates
                                                  select="current-group()/*:tbody/*:row[not(not(preceding-sibling::*:row) and  hub:continuation-marked-in-first-row(.))]"
                                                  mode="#current"/>
                                                  </tbody>
                                                  </tgroup>
                                                </xsl:when>
                                                <xsl:otherwise>
                                                  <xsl:element name="{current-group()[1]/name()}">
                                                  <xsl:copy-of select="current-group()/@*"/>
                                                  <xsl:apply-templates
                                                  select="current-group()/node()" mode="#current">
                                                  <xsl:with-param name="merge" select="true()"/>
                                                  </xsl:apply-templates>
                                                  </xsl:element>
                                                </xsl:otherwise>
                                              </xsl:choose>
                                            </xsl:for-each-group>
                                          </xsl:when>
                                          <xsl:otherwise>
                                            <xsl:element name="{current-group()[1]/name()}">
                                              <xsl:copy-of select="current-group()/@*"/>
                                              <xsl:apply-templates select="current-group()/node()"
                                                mode="#current">
                                                <xsl:with-param name="merge" select="true()"/>
                                              </xsl:apply-templates>
                                            </xsl:element>
                                          </xsl:otherwise>
                                        </xsl:choose>
                                      </xsl:for-each-group>
                                    </xsl:when>
                                    <xsl:otherwise>
                                      <xsl:copy-of select="current-group()"/>
                                    </xsl:otherwise>
                                  </xsl:choose>
                                </xsl:for-each-group>
                                <xsl:apply-templates
                                  select="current-group()[self::*[matches(name(),'table$')]]/*:caption"
                                  mode="#current"/>
                              </table>
                            </xsl:when>
                            <xsl:otherwise>
                              <xsl:apply-templates select="current-group()" mode="#current"/>
                            </xsl:otherwise>
                          </xsl:choose>
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:apply-templates select="current-group()" mode="#current"/>
                        </xsl:otherwise>
                      </xsl:choose>
                    </xsl:for-each-group>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:apply-templates select="current-group()" mode="#current"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:for-each-group>
            </xsl:when>
            <xsl:otherwise>
              <xsl:apply-templates select="current-group()" mode="#current"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each-group>
      </xsl:element>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="deep-equal($temp, $context)">
        <xsl:copy-of select="$temp"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="merge-tables">
          <xsl:with-param name="context" select="$temp"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:function name="hub:is-continued-table" as="xs:boolean">
    <xsl:param name="item" as="node()"/>

    <xsl:choose>
      <xsl:when
        test="$item[self::*:informaltable[*:tgroup[1]/(*:thead, *:tbody)[1]/*:row[1][hub:continuation-marked-in-first-row(.)]]]">
        <xsl:value-of select="true()"/>
      </xsl:when>
      <xsl:when
        test="$item[self::*:informaltable[preceding-sibling::*[1][self::*:para[matches(.,concat('^(',$hub:table-caption-start-regex,').*\(fortgesetzt\)'))]]]]">
        <xsl:value-of select="true()"/>
      </xsl:when>
      <xsl:when
        test="$item[self::*:table[*:title[matches(.,concat('^(',$hub:table-caption-start-regex,').*\(fortgesetzt\)'))]]]">
        <xsl:value-of select="true()"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="false()"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="hub:get-continued-table-identifier" as="xs:string">
    <xsl:param name="item" as="node()"/>

    <xsl:choose>
      <xsl:when
        test="$item[self::*:informaltable[*:tgroup[1]/(*:thead, *:tbody)[1]/*:row[1][hub:continuation-marked-in-first-row(.)]]]">
        <xsl:value-of
          select="replace(string-join($item/*:tgroup[1]/(*:thead, *:tbody)[1]/*:row[1]//text(),''),concat('^(',$hub:table-caption-start-regex,')[\s&#160;]+([A-Z0-9_\.-]+).*$'),'$2')"
        />
      </xsl:when>
      <xsl:when
        test="$item[self::*:informaltable[preceding-sibling::*[1][self::*:para[matches(.,concat('^(',$hub:table-caption-start-regex,').*\(fortgesetzt\)'))]]]]">
        <xsl:value-of
          select="replace(string-join($item/preceding-sibling::*[1][self::*:para]//text(),''),concat('^(',$hub:table-caption-start-regex,')[\s&#160;]+([A-Z0-9_\.-]+).*$'),'$2')"
        />
      </xsl:when>
      <xsl:when
        test="$item[self::*:table[*:title[matches(.,concat('^(',$hub:table-caption-start-regex,').*\(fortgesetzt\)'))]]]">
        <xsl:value-of
          select="replace(string-join($item/*:title//text(),''),concat('^(',$hub:table-caption-start-regex,')[\s&#160;]+([A-Z0-9_\.-]+).*$'),'$2')"
        />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="''"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="hub:get-average-width" as="xs:string">
    <xsl:param name="values" as="xs:string*"/>

    <xsl:value-of
      select="concat((sum(for $i in $values return tr:length-to-unitless-twip($i)) div count($values)) div 56.6929, 'mm')"
    />
  </xsl:function>

  <xsl:template match="*:thead | *:tbody" mode="hub:table-merge">
    <xsl:param name="merge" select="false()"/>

    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:variable name="row1" select="*:row[1]"/>
      <xsl:apply-templates select="node()[. &lt;&lt; $row1]" mode="#current"/>
      <xsl:choose>
        <xsl:when test="hub:continuation-marked-in-first-row(*:row[1]) and $merge"/>
        <xsl:otherwise>
          <xsl:apply-templates select="*:row[1]" mode="#current"/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="node()[. &gt;&gt; $row1]" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:function name="hub:continuation-marked-in-first-row" as="xs:boolean">
    <xsl:param name="item" as="node()"/>

    <xsl:choose>
      <xsl:when
        test="$item[count(*:entry[descendant::node()[self::text() or self::*:imageobject[not(matches(@role,'Equation'))]]])=1]
                           [matches(.,concat('^(',$hub:table-caption-start-regex,').*\(fortgesetzt\)'))]">
        <xsl:value-of select="true()"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="false()"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

</xsl:stylesheet>
