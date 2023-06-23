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
  xmlns:calstable="http://docs.oasis-open.org/ns/oasis-exchange/table"
  xmlns="http://docbook.org/ns/docbook"
  xpath-default-namespace="http://docbook.org/ns/docbook"
  exclude-result-prefixes="w o v wx xs dbk pkg r rel word200x exsl saxon fn tr hub css calstable"
  version="2.0">

  <xsl:import href="table-caption-vars.xsl"/>
  <xsl:import href="http://transpect.io/xslt-util/calstable/xsl/functions.xsl"/>

  <xsl:template match="*[*[hub:is-table-title(.)]]" mode="hub:table-captions">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:for-each-group select="* | processing-instruction() | comment()" group-starting-with="*[hub:is-table-title(.)]">
        <xsl:choose>
          <xsl:when test="$hub:table-graphic-creation-enabled 
                          and current-group()[1][hub:is-table-title(.)] 
                          and current-group()[2][self::para[not(.//text())][mediaobject]]">
            <table>
              <title>
                <xsl:apply-templates select="current-group()[1]/@*" mode="#current"/>
                <xsl:apply-templates select="current-group()[1]/node()" mode="#current"/>
              </title>
              <xsl:sequence select="current-group()[2]/mediaobject"/>
            </table>
            <xsl:apply-templates select="current-group()[position() &gt; 2]" mode="hub:process-informaltables"/>
          </xsl:when>
          <xsl:when test="current-group()[1][hub:is-table-title(.)] 
                          and current-group()[self::*[hub:is-table-not-in-table-env(.)]]">
            <xsl:variable name="table" select="(current-group()[self::*[hub:is-table-not-in-table-env(.)]])[1]"/>
            <xsl:variable name="note" select="current-group()[self::para[matches(@role, $hub:table-note-style-regex-x, 'x')]]" as="element(para)*"/>
            <xsl:variable name="copyright-statement" select="current-group()[self::para[matches(@role, $hub:table-copyright-style-regex-x, 'x')]]" as="element(para)*"/>
            <xsl:variable name="text" select="current-group()[position() &gt; 1 and . &lt;&lt; $table] 
                                              except $note" as="element(*)*"/><!-- usually para, but a sidebar has also been spotted -->
            <table>
              <xsl:attribute name="frame" select="if ($table/name()='informaltable') 
                                                  then hub:get-frame-attribute(
                                                    (
                                                      $table/@css:*[matches(name(.),'border\-.+\-style')],
                                                      hub:get-entry-outer-borders($table[@css:border-collapse = 'collapse']/tgroup)
                                                    )
                                                  ) 
                                                  else  hub:get-frame-attribute(
                                                    (
                                                      $table/informaltable/@css:*[matches(name(.),'border\-.+\-style')],
                                                      hub:get-entry-outer-borders($table[@css:border-collapse = 'collapse']/informaltable/tgroup)
                                                    )
                                                  )"/>
              <xsl:apply-templates select="$table/@*[not(some $i in (parent::*/descendant::*/@*) satisfies $i=.)] | ($table[self::para]/informaltable/@role, $table/@role)[1]" mode="#current"/>
              <xsl:apply-templates select="$table/self::informaltable/(@css:*)
                                           | $table/informaltable/(@css:*)" mode="#current"/>
              <title>
                <xsl:if test="current-group()[1][hub:is-table-title(.)][not(descendant::informaltable)]">
                  <xsl:apply-templates select="current-group()[1]/@*" mode="#current"/>
                  <xsl:apply-templates select="current-group()[1]/node()" mode="#current"/>
                </xsl:if>
                </title>
              <xsl:if test="$copyright-statement">
                <info>
                  <legalnotice role="copyright">
                    <xsl:apply-templates select="$copyright-statement" mode="#current">
                      <xsl:with-param name="process" select="true()" tunnel="yes"/>
                    </xsl:apply-templates>
                  </legalnotice>
                </info>
              </xsl:if>
              <xsl:if test="$text/node()">
                <textobject>
                  <xsl:apply-templates select="$text" mode="#current"/>
                </textobject>
              </xsl:if>
              <xsl:apply-templates select="if ($table/name() = 'informaltable') then $table/node() else $table/informaltable/node()" mode="#current"/>
              <xsl:if test="$note[node()]">
                <caption>
                    <xsl:apply-templates select="$note" mode="#current">
                      <xsl:with-param name="process" select="true()" tunnel="yes"/>
                    </xsl:apply-templates>
                </caption>
              </xsl:if>
              <!-- MP 6-2023: commented PI handling out as they might be duplicated in and out of table and even copy PIs that are located after foloowing tables -->
              <!--  <xsl:apply-templates select="$table/descendant-or-self::informaltable/following-sibling::processing-instruction()" />-->
            </table>
            <xsl:apply-templates select="current-group()[. &gt;&gt; $table] except ($note, $copyright-statement)" mode="hub:process-informaltables"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="current-group()" mode="hub:process-informaltables"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="informaltable[not(@annotations='generated')]" priority="-5" mode="hub:table-captions">
    <!-- https://redmine.le-tex.de/issues/14659 -->
    <xsl:variable name="note" as="element()*">
      <xsl:for-each-group select="following-sibling::*" group-ending-with="informaltable[not(@annotations='generated')]">
        <xsl:choose>
          <xsl:when test="current-group()[self::para[matches(@role, $hub:table-note-style-regex-x, 'x')]]">
            <xsl:sequence select="current-group()"/>
          </xsl:when>
        </xsl:choose>
      </xsl:for-each-group>
    </xsl:variable>
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:attribute name="frame"
        select="hub:get-frame-attribute((./@css:*[matches(name(.), 'border\-.+\-style')], hub:get-entry-outer-borders(tgroup[../@css:border-collapse = 'collapse'])))"/>
      <xsl:apply-templates mode="#current"/>
      <xsl:if test="$note[node()]">
        <caption>
          <xsl:apply-templates select="$note" mode="#current">
            <xsl:with-param name="process" select="true()" tunnel="yes"/>
          </xsl:apply-templates>
        </caption>
      </xsl:if>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="para[matches(@role, $hub:table-note-style-regex-x, 'x')]
                           [preceding-sibling::*[position() = (1,2)][self::informaltable[not(@annotations='generated')]]]
                           [preceding-sibling::*[1]
                                                [self::informaltable[not(@annotations='generated')]|self::para[matches(@role, $hub:table-title-role-regex-x, 'x')]]] | 
                       para[matches(@role, $hub:table-copyright-style-regex-x, 'x')]
                           [preceding-sibling::*[position() = (1,2,3)]
                                                [self::informaltable[not(@annotations='generated')]]
                           ]
                           [preceding-sibling::*[1]
                                                [self::informaltable[not(@annotations='generated')] | 
                                                 self::para[matches(@role, concat($hub:table-title-role-regex-x,'|',$hub:table-note-style-regex-x), 'x')]
                                                ]
                          ]" mode="hub:table-captions">
    <xsl:param name="process" tunnel="yes"/>
    <!-- discard table legends/notes and sources directly after tables when they were already processed-->
    <xsl:if test="$process">
      <xsl:copy>
        <xsl:apply-templates select="@*, node()" mode="#current"/>
      </xsl:copy>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="informaltable[not(@annotations='generated')]" mode="hub:process-informaltables">
    <xsl:variable name="context" as="element(informaltable)" select="."/>
    <xsl:copy>
      <xsl:variable name="note" as="element()*">
        <xsl:for-each-group select="following-sibling::*" group-adjacent="boolean(self::para[matches(@role, $hub:table-note-style-regex-x, 'x')])">
          <xsl:if test="    current-grouping-key() 
                        and current-group()[1]/preceding-sibling::informaltable[1][. is $context](:avoid next table's note to be duplicated:)">
            <xsl:sequence select="current-group()"/>
          </xsl:if>
        </xsl:for-each-group>
      </xsl:variable>
      <xsl:variable name="copyright-statement" as="element()*">
        <xsl:for-each-group select="following-sibling::*" group-adjacent="boolean(self::para[matches(@role, $hub:table-copyright-style-regex-x, 'x')])">
          <xsl:if test="    current-grouping-key() 
                        and current-group()[1]/preceding-sibling::informaltable[1][. is $context](:avoid next table's copyright to be duplicated:)">
            <xsl:sequence select="current-group()"/>
          </xsl:if>
        </xsl:for-each-group>
      </xsl:variable>
      <xsl:apply-templates select="@*" mode="hub:table-captions"/>
      <xsl:attribute name="frame"
        select="hub:get-frame-attribute((./@css:*[matches(name(.), 'border\-.+\-style')], hub:get-entry-outer-borders(tgroup[../@css:border-collapse = 'collapse'])))"
      />
      <xsl:apply-templates select="@role" mode="hub:table-captions"/>
      <xsl:if test="$copyright-statement">
        <info>
          <legalnotice role="copyright">
            <xsl:apply-templates select="$copyright-statement" mode="hub:table-captions">
            <xsl:with-param name="process" select="true()" tunnel="yes"/>
            </xsl:apply-templates>
          </legalnotice>
        </info>
      </xsl:if>
      <xsl:apply-templates mode="hub:table-captions"/>
      <xsl:if test="$note[node()]">
        <caption>
          <xsl:apply-templates select="$note" mode="hub:table-captions">
            <xsl:with-param name="process" select="true()" tunnel="yes"/>
          </xsl:apply-templates>
        </caption>
      </xsl:if>
    </xsl:copy>
  </xsl:template>
  
  <xsl:function name="hub:get-entry-outer-borders" as="attribute()*">
    <xsl:param name="group" as="element(tgroup)*"/>
    <xsl:sequence select="($group//row)[1]/entry/@css:border-top-style"/>
    <xsl:sequence
      select="$group//entry[ancestor::tgroup[1]/colspec[@colnum = 1]/@colname = (@colname, @namest)]/@css:border-left-style"/>
    <xsl:sequence
      select="$group//entry[ancestor::tgroup[1]/colspec[@colnum = max((ancestor::tgroup[1]/colspec/@colnum))]/@colname = (@colname, @nameend)]/@css:border-right-style"
    />
    <xsl:sequence select="
      for $c in $group/colspec/@colnum return (
      ($group//entry[calstable:is-col-in-span($c, (@namest, @colname), (@namest, @colname), ancestor::tgroup[1]/colspec)])[last()]/@css:border-bottom-style
      )"/>
  </xsl:function>
  
  <xsl:function name="hub:get-frame-attribute">
    <xsl:param name="border-style" as="attribute()*"/>
    <xsl:choose>
      <xsl:when test="$border-style[matches(local-name(),'left')][not(.=('nil','none'))] and $border-style[matches(local-name(),'right')][not(.=('nil','none'))] and $border-style[matches(local-name(),'top')][not(.=('nil','none'))] and $border-style[matches(local-name(),'bottom')][not(.=('nil','none'))]">all</xsl:when>
      <xsl:when test="$border-style[matches(local-name(),'left')][not(.=('nil','none'))] and $border-style[matches(local-name(),'right')][not(.=('nil','none'))]">sides</xsl:when>
      <xsl:when test="$border-style[matches(local-name(),'bottom')][not(.=('nil','none'))] and $border-style[matches(local-name(),'top')][not(.=('nil','none'))]">topbot</xsl:when>
      <xsl:when test="$border-style[matches(local-name(),'top')][not(.=('nil','none'))]">top</xsl:when>
      <xsl:when test="$border-style[matches(local-name(),'bottom')][not(.=('nil','none'))]">bottom</xsl:when>
      <xsl:otherwise>none</xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:template match="node()[not(self::informaltable)]" mode="hub:process-informaltables">
    <xsl:apply-templates select="." mode="hub:table-captions"/>
  </xsl:template>
  
  <xsl:variable name="row-keep-attributes" as="xs:string*"
                select="'role', 'css:color', 'css:background-color'"/>
  
  <xsl:template match="entry" mode="hub:table-captions">
    <xsl:element name="{name(.)}">
      <!--      <xsl:apply-templates select="ancestor::informaltable/@css:*[not(matches(local-name(), '^(margin|orientation)'))]" mode="#current"/>-->
      <!-- commented out 2018-03-05 to avoid inheriting border information. -->
      <xsl:apply-templates select="parent::row/@css:*[not(name() = $row-keep-attributes)], 
                                   @*, node()" 
                           mode="#current"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="row" mode="hub:table-captions">
    <xsl:element name="{name(.)}">
      <xsl:apply-templates select="@*[name() = $row-keep-attributes], node()" 
                           mode="#current"/>
    </xsl:element>
  </xsl:template>

  <!-- MODE: hub:table-captions-preprocess-merge -->
  <!-- Optional mode for preprocessing table captions where the number is in a paragraph on its own. -->
  <xsl:template match="para[matches(@role, $hub:table-title-role-regex-x, 'x')]
                           [preceding-sibling::*[1]/self::para[matches(@role, $hub:table-number-role-regex-x, 'x')]]" mode="hub:table-captions-preprocess-merge">
    <xsl:variable name="number-para" select="preceding-sibling::*[1]" as="element(para)"/>
    <xsl:copy>
      <xsl:sequence select="@*"/>
      <phrase>
        <xsl:sequence select="
          ( key('hub:style-by-role', $number-para/@role), $number-para )/@*[name() = ('srcpath', 'css:font-weight', 'css:font-family')], 
          $number-para/node()"/>
      </phrase>
      <xsl:text>&#x2002;</xsl:text>
      <xsl:sequence select="node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="para[matches(@role, $hub:table-number-role-regex-x, 'x')]
                           [following-sibling::*[1]/self::para[matches(@role, $hub:table-title-role-regex-x, 'x')]]" mode="hub:table-captions-preprocess-merge" />

</xsl:stylesheet>