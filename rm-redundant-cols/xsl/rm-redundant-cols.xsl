<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:dbk="http://docbook.org/ns/docbook"
  xmlns:css="http://www.w3.org/1996/css"
  xmlns:hub="http://transpect.io/hub"
  xmlns="http://docbook.org/ns/docbook"
  xpath-default-namespace="http://docbook.org/ns/docbook"
  exclude-result-prefixes="xs hub dbk"
  version="2.0">
  
  <xsl:template match="*:tgroup" mode="hub:rm-redundant-cols">
    <xsl:variable name="rm-redundant-cols-colname">
      <xsl:apply-templates select="." mode="hub:rm-redundant-cols-colname"/>  
    </xsl:variable>
    <xsl:variable name="rm-redundant-cols-nameend">
      <xsl:apply-templates select="$rm-redundant-cols-colname" mode="hub:rm-redundant-cols-nameend"/>
    </xsl:variable>
    <xsl:apply-templates select="$rm-redundant-cols-nameend" mode="hub:rm-redundant-cols-namest"/>
  </xsl:template>
  
  <xsl:template match="*:tgroup[*:colspec[every $e in (parent::*:tgroup//*:entry/@colname,
                                                       parent::*:tgroup//*:entry/@namest) 
                                          satisfies not(@colname=$e)]
                                         [some $c in parent::*:tgroup//*/@nameend satisfies @colname=$c]]" mode="hub:rm-redundant-cols-nameend">
    <xsl:variable name="redundant-cols" select="*:colspec[every $e in (parent::*:tgroup//*:entry/@colname,
                                                                       parent::*:tgroup//*:entry/@namest) 
                                                          satisfies not(@colname=$e)]
                                                         [some $c in parent::*:tgroup//*/@nameend satisfies @colname=$c]/@colname" as="xs:string*"/>
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:attribute name="cols" select="number(@cols) - count($redundant-cols)"/>
      <xsl:apply-templates select="*:colspec[not(@colname=$redundant-cols)], * except *:colspec" mode="#current">
        <xsl:with-param name="redundant-cols" select="$redundant-cols" tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="*:tgroup[*:colspec[every $e in (parent::*:tgroup//*:entry/@colname,
                                                       parent::*:tgroup//*:entry/@nameend) 
                                          satisfies not(@colname=$e)]
                                         [some $c in parent::*:tgroup//*/@namest satisfies @colname=$c]]" mode="hub:rm-redundant-cols-namest">
    <xsl:variable name="redundant-cols" select="*:colspec[every $e in (parent::*:tgroup//*:entry/@colname,
                                                                       parent::*:tgroup//*:entry/@nameend) 
                                                          satisfies not(@colname=$e)]
                                                         [some $c in parent::*:tgroup//*/@namest satisfies @colname=$c]/@colname" as="xs:string*"/>
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:attribute name="cols" select="number(@cols) - count($redundant-cols)"/>
      <xsl:apply-templates select="*:colspec[not(@colname=$redundant-cols)], * except *:colspec" mode="#current">
        <xsl:with-param name="redundant-cols" select="$redundant-cols" tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="*:tgroup[*:colspec[every $e in (parent::*:tgroup//*:entry/@colname, 
                                                       parent::*:tgroup//*:entry/@namest, 
                                                       parent::*:tgroup//*:entry/@nameend) 
                                          satisfies not(@colname=$e)]]" mode="hub:rm-redundant-cols-colname">
    <xsl:variable name="redundant-cols" select="*:colspec[every $e in (parent::*:tgroup//*:entry/@colname, 
                                                                       parent::*:tgroup//*:entry/@namest, 
                                                                       parent::*:tgroup//*:entry/@nameend) 
                                                          satisfies not(@colname=$e)]/@colname" as="xs:string*"/>
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:attribute name="cols" select="number(@cols) - count($redundant-cols)"/>
      <xsl:apply-templates select="*:colspec[not(@colname=$redundant-cols)], * except *:colspec" mode="#current">
        <xsl:with-param name="redundant-cols" select="$redundant-cols" tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="*:entry" mode="hub:rm-redundant-cols-colname hub:rm-redundant-cols-namest">
    <xsl:param name="redundant-cols" tunnel="yes" as="xs:string*" select="()"/>
    <xsl:copy>
      <xsl:apply-templates select="@* except (@spanname, @namest, @nameend)[not(empty($redundant-cols))]" mode="#current"/>
      <xsl:if test="not(empty($redundant-cols))">
        <xsl:variable name="colname-corresponding-colspec" select="ancestor::*:tgroup[1]/*:colspec[@colname = current()/@colname]" as="element(colspec)?"/>
        <xsl:variable name="namest-corresponding-colspec" select="ancestor::*:tgroup[1]/*:colspec[@colname = current()/@namest]" as="element(colspec)?"/>
        <xsl:variable name="nameend-corresponding-colspec" select="ancestor::*:tgroup[1]/*:colspec[@colname = current()/@nameend]" as="element(colspec)?"/>
        <xsl:choose>
          <xsl:when test="@colname or 
                          ((number($nameend-corresponding-colspec/@colnum)-
                            count($nameend-corresponding-colspec/preceding-sibling::*:colspec[@colname=$redundant-cols]))-
                           (number($namest-corresponding-colspec/@colnum)-
                            count($namest-corresponding-colspec/preceding-sibling::*:colspec[@colname=$redundant-cols]))=0)">
            <xsl:variable name="nameend-colnum" select="if (@nameend) 
                                                        then (number($nameend-corresponding-colspec/@colnum)-
                                                              count($nameend-corresponding-colspec/preceding-sibling::*:colspec[@colname=$redundant-cols])) 
                                                        else ()"/>
            <xsl:variable name="colname-colnum" select="if (@colname)
                                                        then number($colname-corresponding-colspec/@colnum)-
                                                             count($colname-corresponding-colspec/preceding-sibling::*:colspec[@colname=$redundant-cols])
                                                        else ()"/>
            <xsl:attribute name="colname" select="(ancestor::*:tgroup[1]/*:colspec[@colnum=$colname-colnum]/@colname,
                                                   ancestor::*:tgroup[1]/*:colspec[@colnum=$nameend-colnum]/@colname)[1]"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="namest-colnum" select="number($namest-corresponding-colspec/@colnum)-
                                                       count($namest-corresponding-colspec/preceding-sibling::*:colspec[@colname=$redundant-cols])"/>
            <xsl:variable name="nameend-colnum" select="number($nameend-corresponding-colspec/@colnum)-
                                                        count($nameend-corresponding-colspec/preceding-sibling::*:colspec[@colname=$redundant-cols])"/>
            <xsl:attribute name="namest" select="ancestor::*:tgroup[1]/*:colspec[@colnum=$namest-colnum]/@colname"/>
            <xsl:attribute name="nameend" select="ancestor::*:tgroup[1]/*:colspec[@colnum=$nameend-colnum]/@colname"/>
            <xsl:apply-templates select="@spanname" mode="#current"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:if>
      <xsl:apply-templates mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="*:entry" mode="hub:rm-redundant-cols-nameend">
    <xsl:param name="redundant-cols" tunnel="yes" as="xs:string*" select="()"/>
    <xsl:copy>
      <xsl:apply-templates select="@* except (@spanname, @namest, @nameend)[not(empty($redundant-cols))]" mode="#current"/>
      <xsl:if test="not(empty($redundant-cols))">
        <xsl:variable name="colname-corresponding-colspec" select="ancestor::*:tgroup[1]/*:colspec[@colname = current()/@colname]" as="element(colspec)?"/>
        <xsl:variable name="namest-corresponding-colspec" select="ancestor::*:tgroup[1]/*:colspec[@colname = current()/@namest]" as="element(colspec)?"/>
        <xsl:variable name="nameend-corresponding-colspec" select="ancestor::*:tgroup[1]/*:colspec[@colname = current()/@nameend]" as="element(colspec)?"/>
        <xsl:choose>
          <xsl:when test="@colname or 
                          ((number($nameend-corresponding-colspec/@colnum)-
                            count($nameend-corresponding-colspec/preceding-sibling::*:colspec[@colname=$redundant-cols])-
                            count($nameend-corresponding-colspec/self::*:colspec[@colname=$redundant-cols]))-
                           (number($namest-corresponding-colspec/@colnum)-
                            count($namest-corresponding-colspec/preceding-sibling::*:colspec[@colname=$redundant-cols]))=0)">
            <xsl:variable name="nameend-colnum" select="if (@nameend) 
                                                        then (number($nameend-corresponding-colspec/@colnum)-
                                                              count($nameend-corresponding-colspec/preceding-sibling::*:colspec[@colname=$redundant-cols])-
                                                              count($nameend-corresponding-colspec/self::*:colspec[@colname=$redundant-cols])) 
                                                        else ()"/>
            <xsl:variable name="colname-colnum" select="if (@colname)
                                                        then number($colname-corresponding-colspec/@colnum)-
                                                             count($colname-corresponding-colspec/preceding-sibling::*:colspec[@colname=$redundant-cols])
                                                        else ()"/>
            <xsl:attribute name="colname" select="(ancestor::*:tgroup[1]/*:colspec[@colnum=$colname-colnum]/@colname,
                                                   ancestor::*:tgroup[1]/*:colspec[@colnum=$nameend-colnum]/@colname)[1]"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="namest-colnum" select="number($namest-corresponding-colspec/@colnum)-
                                                       count($namest-corresponding-colspec/preceding-sibling::*:colspec[@colname=$redundant-cols])"/>
            <xsl:variable name="nameend-colnum" select="number($nameend-corresponding-colspec/@colnum)-
                                                        count($nameend-corresponding-colspec/preceding-sibling::*:colspec[@colname=$redundant-cols])-
                                                        count($nameend-corresponding-colspec/self::*:colspec[@colname=$redundant-cols])"/>
            <xsl:attribute name="namest" select="ancestor::*:tgroup[1]/*:colspec[@colnum=$namest-colnum]/@colname"/>
            <xsl:attribute name="nameend" select="ancestor::*:tgroup[1]/*:colspec[@colnum=$nameend-colnum]/@colname"/>
            <xsl:apply-templates select="@spanname" mode="#current"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:if>
      <xsl:apply-templates mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="*:spanspec" mode="hub:rm-redundant-cols-colname hub:rm-redundant-cols-namest">
    <xsl:param name="redundant-cols" tunnel="yes" as="xs:string*" select="()"/>
    <xsl:variable name="namest-corresponding-colspec" select="ancestor::*:tgroup[1]/*:colspec[@colname = current()/@namest]" as="element(colspec)?"/>
    <xsl:variable name="nameend-corresponding-colspec" select="ancestor::*:tgroup[1]/*:colspec[@colname = current()/@nameend]" as="element(colspec)?"/>
    <xsl:if test="not(empty($redundant-cols)) and
                  not((number($nameend-corresponding-colspec/@colnum)-
                       count($nameend-corresponding-colspec/preceding-sibling::*:colspec[@colname=$redundant-cols]))-
                      (number($namest-corresponding-colspec/@colnum)-
                       count($namest-corresponding-colspec/preceding-sibling::*:colspec[@colname=$redundant-cols]))=0)">
      <xsl:copy>
        <xsl:apply-templates select="@*" mode="#current"/>
        <xsl:variable name="namest-colnum" select="number($namest-corresponding-colspec/@colnum)-
                                                   count($namest-corresponding-colspec/preceding-sibling::*:colspec[@colname=$redundant-cols])"/>
        <xsl:variable name="nameend-colnum" select="number($nameend-corresponding-colspec/@colnum)-
                                                    count($nameend-corresponding-colspec/preceding-sibling::*:colspec[@colname=$redundant-cols])"/>
        <xsl:attribute name="namest" select="ancestor::*:tgroup[1]/*:colspec[@colnum=$namest-colnum]/@colname"/>
        <xsl:attribute name="nameend" select="ancestor::*:tgroup[1]/*:colspec[@colnum=$nameend-colnum]/@colname"/>
        <xsl:apply-templates mode="#current"/>
      </xsl:copy>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="*:spanspec" mode="hub:rm-redundant-cols-nameend">
    <xsl:param name="redundant-cols" tunnel="yes" as="xs:string*" select="()"/>
    <xsl:variable name="namest-corresponding-colspec" select="ancestor::*:tgroup[1]/*:colspec[@colname = current()/@namest]" as="element(colspec)?"/>
    <xsl:variable name="nameend-corresponding-colspec" select="ancestor::*:tgroup[1]/*:colspec[@colname = current()/@nameend]" as="element(colspec)?"/>
    <xsl:if test="not(empty($redundant-cols)) and
                  not((number($nameend-corresponding-colspec/@colnum)-
                       count($nameend-corresponding-colspec/preceding-sibling::*:colspec[@colname=$redundant-cols])-
                       count($nameend-corresponding-colspec/self::*:colspec[@colname=$redundant-cols]))-
                      (number($namest-corresponding-colspec/@colnum)-
                       count($namest-corresponding-colspec/preceding-sibling::*:colspec[@colname=$redundant-cols]))=0)">
      <xsl:copy>
        <xsl:apply-templates select="@*" mode="#current"/>
        <xsl:variable name="namest-colnum" select="number($namest-corresponding-colspec/@colnum)-
                                                   count($namest-corresponding-colspec/preceding-sibling::*:colspec[@colname=$redundant-cols])"/>
        <xsl:variable name="nameend-colnum" select="number($nameend-corresponding-colspec/@colnum)-
                                                    count($nameend-corresponding-colspec/preceding-sibling::*:colspec[@colname=$redundant-cols])-
                                                    count($nameend-corresponding-colspec/self::*:colspec[@colname=$redundant-cols])"/>
        <xsl:attribute name="namest" select="ancestor::*:tgroup[1]/*:colspec[@colnum=$namest-colnum]/@colname"/>
        <xsl:attribute name="nameend" select="ancestor::*:tgroup[1]/*:colspec[@colnum=$nameend-colnum]/@colname"/>
        <xsl:apply-templates mode="#current"/>
      </xsl:copy>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="*:tgroup/*:colspec" mode="hub:rm-redundant-cols-colname hub:rm-redundant-cols-nameend">
    <xsl:param name="redundant-cols" tunnel="yes" as="xs:string*" select="()"/>
    
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:if test="not(empty($redundant-cols))">
        <xsl:variable name="colnum" select="number(@colnum)-count(preceding-sibling::*:colspec[@colname=$redundant-cols])"/>
        <xsl:attribute name="colnum" select="$colnum"/>
        <xsl:attribute name="colname" select="parent::*:tgroup/*:colspec[@colnum=$colnum]/@colname"/>
        <xsl:variable name="first" select="following-sibling::*:colspec[not(@colname=$redundant-cols)][1]"/>
        <xsl:attribute name="colwidth" select="concat(sum((number(replace(@colwidth,'^([0-9\.]+).*?$','$1')),
                                                          (for $post in (following-sibling::*:colspec[. &lt;&lt; $first]/@colwidth,
                                                                         following-sibling::*:colspec[empty($first)]/@colwidth) 
                                                           return number(replace($post,'^([0-9\.]+).*?$','$1'))))),
                                                      replace(@colwidth,'^[0-9\.]+(.*?)$','$1'))"/>        
      </xsl:if>
      <xsl:apply-templates mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="*:tgroup/*:colspec" mode="hub:rm-redundant-cols-namest">
    <xsl:param name="redundant-cols" tunnel="yes" as="xs:string*" select="()"/>
    
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:if test="not(empty($redundant-cols))">
        <xsl:variable name="colnum" select="number(@colnum)-count(preceding-sibling::*:colspec[@colname=$redundant-cols])"/>
        <xsl:attribute name="colnum" select="$colnum"/>
        <xsl:attribute name="colname" select="parent::*:tgroup/*:colspec[@colnum=$colnum]/@colname"/>
        <xsl:variable name="first" select="preceding-sibling::*:colspec[not(@colname=$redundant-cols)][1]"/>
        <xsl:attribute name="colwidth" select="concat(sum((number(replace(@colwidth,'^([0-9\.]+).*?$','$1')),
                                                          (for $pre in (preceding-sibling::*:colspec[. &gt;&gt; $first]/@colwidth,
                                                                        preceding-sibling::*:colspec[empty($first)]/@colwidth) 
                                                           return number(replace($pre,'^([0-9\.]+).*?$','$1'))))),
                                                      replace(@colwidth,'^[0-9\.]+(.*?)$','$1'))"/>        
      </xsl:if>
      <xsl:apply-templates mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
</xsl:stylesheet>