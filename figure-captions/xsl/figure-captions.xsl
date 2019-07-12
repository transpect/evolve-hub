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
  xmlns:tr="http://transpect.io"
  xmlns:hub="http://transpect.io/hub"
  xmlns:css="http://www.w3.org/1996/css"
  xmlns="http://docbook.org/ns/docbook"
  xpath-default-namespace="http://docbook.org/ns/docbook"
  exclude-result-prefixes="w o v wx xs dbk pkg r rel word200x exsl fn tr hub css"
  version="2.0">

  <xsl:import href="figure-caption-vars.xsl"/>

  <xsl:template match="*[
                          ( some $element in * satisfies hub:is-figure($element) )
                            and 
                          ( some $element in * satisfies hub:is-figure-title($element) )
                        ]
                        [not($hub:handle-several-images-per-caption)]" mode="hub:figure-captions">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:for-each-group select="*" group-starting-with="*[hub:is-figure(.)]">
        <xsl:choose>
          <xsl:when test="current-group()[1][hub:is-figure(.)]
                          and current-group()[2][hub:is-figure-title(.)]">
            <xsl:variable name="title" select="current-group()[2]" as="element(para)"/>
            <xsl:variable name="note-me-maybe" as="node()*">
              <xsl:for-each-group select="current-group()[. &gt;&gt; $title]"
                group-adjacent="(
                                  for $r in (@role, 'NONE')[1]
                                  return ($hub:figure-note-role-regex, $hub:figure-copyright-statement-role-regex)[matches($r, .)],
                                  ''
                                )[1]">
                <xsl:choose>
                  <xsl:when test="current-grouping-key() = $hub:figure-note-role-regex">
                    <notes>
                      <xsl:call-template name="hub:figure-notes"/>
                    </notes>
                  </xsl:when>
                  <xsl:when test="current-grouping-key() = $hub:figure-copyright-statement-role-regex">
                    <copyrights>
                      <xsl:call-template name="hub:figure-copyrights"/>
                    </copyrights>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:sequence select="current-group()"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:for-each-group>
            </xsl:variable>
            <figure>
              <xsl:variable name="anchor" as="element(anchor)?" 
                select="if($hub:use-title-child-anchor-id-for-figure-id) 
                then ($title//anchor[@xml:id][not(matches(@xml:id, '^(cell)?page'))][not(key('hub:linking-item-by-id', @xml:id)[self::sidebar])][hub:same-scope(., $title)], $title//anchor[@xml:id][hub:same-scope(., $title)])[1] 
                        else ()"/>
              <xsl:sequence select="$anchor/@xml:id | current-group()[1]//@css:orientation"/>
              <xsl:if test="current-group()[1]/@srcpath | $note-me-maybe/@srcpath">
                <xsl:attribute name="srcpath" select="string-join((current-group()[1]/@srcpath, $note-me-maybe/@srcpath),' ')"/>  
              </xsl:if>
              <title>
                <xsl:apply-templates select="$title/@*" mode="#current"/>
                <xsl:apply-templates select="$title/node()" mode="#current">
                  <xsl:with-param name="suppress" select="$anchor" tunnel="yes"/>
                </xsl:apply-templates>
              </title>
              <xsl:sequence select="$note-me-maybe/self::copyrights/node()"/>
              <xsl:apply-templates select="current-group()[1]" mode="#current"/>
              <xsl:sequence select="$note-me-maybe/self::notes/node()"/>
            </figure>
            <xsl:apply-templates select="$note-me-maybe[not(self::notes | self::copyrights)]" mode="#current"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="current-group()" mode="#current"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*[local-name() = ('mediaobject', 'inlinemediaobject')]/@*[name() = ('css:width', 'css:height')][. = '']" mode="hub:figure-captions"/>
  <xsl:template match="imagedata/@*[name() = ('css:width', 'css:height')][. = ('px', 'pt', 'mm', 'cm', 'm')]" mode="hub:figure-captions"/>
  
  <!-- if there’s more than one note or copyright statement, you’ll have to apply some more grouping -->
  
  <xsl:template name="hub:figure-notes">
    <xsl:apply-templates select="current-group()" mode="#current"/>
  </xsl:template>

  <xsl:template name="hub:figure-copyrights">
    <xsl:apply-templates select="current-group()" mode="#current"/>
  </xsl:template>
  
  <xsl:template name="hub:figure-further-paras">
    <xsl:apply-templates select="current-group()" mode="#current"/>
  </xsl:template>

  <xsl:variable name="hub:create-note-element-for-figure-note-in-figure-note" as="xs:boolean"
    select="false()"/>

  <xsl:template match="para[matches(@role, $hub:figure-note-role-regex)]" mode="hub:figure-captions">
    <xsl:choose>
      <!-- case: note paragraphs in a table (wrapped in another para with figure-note-role-regex) -->
      <xsl:when test="ancestor::para[matches(@role, $hub:figure-note-role-regex)]
                      and $hub:create-note-element-for-figure-note-in-figure-note = false()">
        <xsl:next-match/>
      </xsl:when>
      <xsl:otherwise>
        <note>
          <xsl:next-match/>
        </note>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="para[matches(@role, $hub:figure-copyright-statement-role-regex)]" mode="hub:figure-captions">
    <info>
      <!-- legalnotice because copyright requires a tagged year -->
      <legalnotice role="copyright">
        <xsl:next-match/>
      </legalnotice>
    </info>
  </xsl:template>
  
  <!-- This is another figure caption template to handle figures with more than one actual image in figure. Split figures for example or really several images with just one caption.
       Still has to be tested thoroughly if used. Use it while setting the parameter hub:handle-several-images-per-caption (in caption vars) in your adaptions to true() -->
  <xsl:template match="*[
                          ( some $element in * satisfies hub:is-figure($element) )
                          and 
                          ( some $element in * satisfies hub:is-figure-title($element) )
                          ]
                        [$hub:handle-several-images-per-caption]" mode="hub:figure-captions" priority="2">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:for-each-group select="node()" group-starting-with="*[hub:is-figure(.) and not(preceding-sibling::*[1][hub:is-figure(.)])]">
     
        <xsl:choose>
          <xsl:when test="current-group()[1][hub:is-figure(.)]
            and  (some $a in current-group() satisfies (hub:is-figure-title($a) and ($a/preceding-sibling::*[1][hub:is-figure(.)] or $a[hub:is-figure(.)])))">
            <xsl:variable name="title" select="(current-group()[hub:is-figure-title(.)])[1]" as="element(*)"/>
            <xsl:variable name="note-me-maybe" as="node()*">
              <xsl:for-each-group select="current-group()[. &gt;&gt; $title]"
                group-adjacent="(
                for $r in (@role, 'NONE')[1]
                return ($hub:figure-note-role-regex, $hub:figure-copyright-statement-role-regex)[matches($r, .)],
                ''
                )[1]">
                <xsl:choose>
                  <xsl:when test="matches(current-grouping-key(), $hub:figure-note-role-regex)">
                    <notes>
                      <xsl:call-template name="hub:figure-notes"/>
                    </notes>
                  </xsl:when>
                  <xsl:when test="matches(current-grouping-key(), $hub:figure-copyright-statement-role-regex)">
                    <copyrights>
                      <xsl:call-template name="hub:figure-copyrights"/>
                    </copyrights>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:sequence select="current-group()"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:for-each-group>
            </xsl:variable>
            <figure>
              <xsl:variable name="anchor" as="element(anchor)?" 
                          select="if($hub:use-title-child-anchor-id-for-figure-id) 
                          then ($title//anchor[@xml:id][not(matches(@xml:id, '^(cell)?page'))][not(key('hub:linking-item-by-id', @xml:id)[self::sidebar])][hub:same-scope(., $title)])[1] 
                                  else ()"/>
              <xsl:sequence select="$anchor/@xml:id"/>
              <xsl:if test="$note-me-maybe/@srcpath | current-group()[*][hub:is-figure(.) and . &lt;&lt; $title]/@srcpath">
                <xsl:attribute name="srcpath" select="string-join(($note-me-maybe/@srcpath, current-group()[*][hub:is-figure(.) and . &lt;&lt; $title]/@srcpath),' ')"/>  
              </xsl:if>
              <title>
                <xsl:if test="$title[not(hub:is-figure(.))]">
                  <xsl:apply-templates select="$title/@*" mode="#current"/>
                  <xsl:apply-templates select="$title/node()" mode="#current">
                    <xsl:with-param name="suppress" select="$anchor" tunnel="yes"/>
                  </xsl:apply-templates>
                </xsl:if>
              </title>
              <xsl:sequence select="$note-me-maybe/self::copyrights/node()"/>
              <xsl:apply-templates select="current-group()[*][hub:is-figure(.) and . &lt;&lt; $title] | $title[hub:is-figure(.)]" mode="#current"/>
              <xsl:sequence select="$note-me-maybe/self::notes/node()"/>
            </figure>
            <xsl:apply-templates select="$note-me-maybe[not(self::notes | self::copyrights)]" mode="#current"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="current-group()" mode="#current"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="para
                        [hub:is-figure(.)]
                        [mediaobject]" mode="hub:figure-captions">
    <xsl:choose>
      <xsl:when test=" $hub:handle-several-images-per-caption and ($hub:remove-para-wrapper-for-mediaobject and (hub:is-figure-title(following-sibling::*[1]) or hub:is-figure(following-sibling::*[1]) or hub:is-figure(preceding-sibling::*[1])))">
        <xsl:apply-templates select="node() except *[local-name() = ('tabs', 'tab')]" mode="#current"/>
        <!-- inserted this branch because otherwise only the last image in a figure with several images is unwrapped -->
      </xsl:when>
      <xsl:when test="$hub:remove-para-wrapper-for-mediaobject and hub:is-figure-title(following-sibling::*[1])">
        <xsl:apply-templates select="node() except *[local-name() = ('tabs', 'tab')]" mode="#current"/>
      </xsl:when>
      <xsl:when test="$hub:remove-para-wrapper-for-mediaobject and hub:is-figure-title(.)">
        <xsl:apply-templates select="node() except *[local-name() = ('tabs', 'tab')]" mode="#current"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:next-match/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- MODE: hub:figure-captions-preprocess-merge -->
  <!-- Optional mode for preprocessing figure captions where the number is in a paragraph on its own. -->
  <xsl:template match="para[matches(@role, $hub:figure-title-role-regex-x, 'x')]
                           [preceding-sibling::*[1]/self::para[matches(@role, $hub:figure-number-role-regex-x, 'x')]]" mode="hub:figure-captions-preprocess-merge">
    <xsl:param name="discard-image" tunnel="yes" as="xs:boolean?"/>
    <xsl:variable name="number-para" select="preceding-sibling::*[1]" as="element(para)"/>
    <xsl:copy>
      <xsl:sequence select="@*"/>
      <phrase>
        <xsl:sequence select="
          ( key('hub:style-by-role', $number-para/@role), $number-para )/@*[name() = ('srcpath', 'css:font-weight', 'css:font-family')], 
          $number-para/node()"/>
      </phrase>
      <xsl:text>&#x2002;</xsl:text>
      <xsl:apply-templates select="node()" mode="#current">
        <xsl:with-param name="discard-image" select="true()" tunnel="yes" as="xs:boolean"/>
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="para[matches(@role, $hub:figure-number-role-regex-x, 'x')]
                           [following-sibling::*[1]/self::para[matches(@role, $hub:figure-title-role-regex-x, 'x')]]" mode="hub:figure-captions-preprocess-merge" />
  
  <!-- If figure and caption are in one para. Often happens if figures are anchored -->
  <xsl:template match="para[matches(@role, $hub:figure-title-role-regex-x, 'x')]
                           [inlinemediaobject]
                           [some $text in descendant::node()[self::text()] satisfies matches($text, '\S')]
                           (:[not(preceding-sibling::*[1][hub:is-figure(.)])]:)" mode="hub:figure-captions-preprocess-merge" priority="2">
    <xsl:for-each select="inlinemediaobject">
     <mediaobject>
       <xsl:apply-templates select="./@*" mode="#current"/>
       <xsl:apply-templates select="./node()" mode="#current"/>
     </mediaobject>
    </xsl:for-each>
    <xsl:next-match>
      <xsl:with-param name="discard-image" select="true()" tunnel="yes" as="xs:boolean"/>
    </xsl:next-match>
  </xsl:template>
  
  <xsl:template match="inlinemediaobject" mode="hub:figure-captions-preprocess-merge">
    <xsl:param name="discard-image" tunnel="yes" as="xs:boolean?"/>
    <xsl:if test="not($discard-image)">
      <xsl:next-match/>
    </xsl:if>
  </xsl:template>
  
  <!-- merge several caption paras in one, separate by <br/> -->
  <xsl:template match="*[dbk:para[hub:is-figure-title(.)]
                                 [following-sibling::*[1][matches(@role, $hub:figure-title-further-paras-role-regex-x)]]
                        ]
                        [$hub:merge-several-caption-paras]" mode="hub:figure-captions-preprocess-merge">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:for-each-group select="node()" group-starting-with="*[hub:is-figure(.)]">
        <xsl:choose>
          <xsl:when test="current-group()[1][hub:is-figure(.)]
                      and current-group()[2][hub:is-figure-title(.)]">
            <xsl:variable name="title" select="current-group()[2]" as="element(dbk:para)"/>
            <xsl:variable name="further-caption-paras" as="node()*">
              <xsl:for-each-group select="current-group()[. &gt;&gt; $title]" group-adjacent="(
                                                                                                for $r in (@role, 'NONE')[1]
                                                                                                return ($hub:figure-title-further-paras-role-regex-x)[matches($r, .)],
                                                                                                ''
                                                                                              )[1]">
                <xsl:choose>
                  <xsl:when test="current-grouping-key() = $hub:figure-title-further-paras-role-regex-x">
                    <title>
                      <xsl:call-template name="hub:figure-further-paras"/>
                    </title>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:sequence select="current-group()"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:for-each-group>
            </xsl:variable>
            <xsl:apply-templates select="current-group()[1]" mode="#current"/>
            <para>
              <xsl:apply-templates select="$title/@*, $title/node()" mode="#current"/>
              <xsl:for-each select="$further-caption-paras/self::title/node()">
                <br/>
                <xsl:apply-templates select="current()/node()" mode="#current"/>
              </xsl:for-each>
            </para>
            <xsl:apply-templates select="$further-caption-paras[not(self::title)]" mode="#current"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="current-group()" mode="#current"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>
  
</xsl:stylesheet>