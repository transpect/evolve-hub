<?xml version="1.0" encoding="utf-8"?>
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
  xpath-default-namespace="http://docbook.org/ns/docbook"
  exclude-result-prefixes="xs saxon tr xlink hub dbk idml2xml"
  version="2.0">
 
  <!--  catch all must be first -->
  <xsl:import href="http://transpect.io/evolve-hub/catch-all/xsl/catch-all.xsl"/>

  <xsl:import href="http://transpect.io/evolve-hub/figure-captions/xsl/figure-captions.xsl"/>
  <xsl:import href="http://transpect.io/evolve-hub/figure-captions/xsl/subfigure-captions.xsl"/>
  <xsl:import href="http://transpect.io/evolve-hub/hierarchy-by-role/xsl/hierarchy-by-role.xsl"/>
  <xsl:import href="http://transpect.io/evolve-hub/lists-by-indent/xsl/lists-main.xsl"/>
  <xsl:import href="http://transpect.io/evolve-hub/table-captions/xsl/table-captions.xsl"/>
  <xsl:import href="http://transpect.io/evolve-hub/relocate-indexterms/xsl/relocate-indexterms.xsl"/>
  <xsl:import href="http://transpect.io/evolve-hub/table-merge/xsl/table-merge.xsl"/>

  <xsl:include href="http://transpect.io/evolve-hub/xsl/hub-functions.xsl"/>
  <xsl:include href="http://transpect.io/xslt-util/resolve-uri/xsl/resolve-uri.xsl"/>

  <xsl:output
    method="xml"
    indent="no"
    encoding="utf-8"
    />

  <xsl:output
    name="debug"
    method="xml"
    indent="yes"
    encoding="utf-8"
    saxon:suppress-indentation="para title simpara tocentry"
    />

  <!-- Params -->

  <xsl:param name="debug" select="'yes'"/>
  <xsl:param name="debug-path" select="concat($stylesheet-dir, 'debug')"/>
  <xsl:param name="set-debugging-info-origin" select="'no'"/>
  <xsl:param name="srcpaths" select="'no'"/>
  <xsl:param name="create-caption-numtext-separator" select="'no'"/>
  <xsl:param name="expand-css-properties" select="'yes'"/>
  <xsl:param name="remove-HyperlinkTextDestination-links" select="'no'"/>
  <xsl:param name="aux" select="'no'"/>
  <xsl:param name="evolve-textreference-to-link" select="'no'"/>
  <xsl:param name="move-floats" select="'yes'"/>
  <xsl:param name="remove-empty-paras" select="'no'"/>
  <xsl:param name="map-phrase-with-css-vertical-pos-to-super-or-subscript" select="'no'"/>
  <xsl:param name="collect-continued-floats" select="'no'"/>
  <xsl:param name="clean-hub_remove-attributes-with-paths" select="'no'"/>
  <xsl:param name="split-at-br-also-for-non-br-paras" select="'yes'"/>
  <xsl:param name="create-ulinks-from-text" select="'no'"/>
  <xsl:param name="equations-after-list-paras-belong-to-list" select="'yes'"/>

  <!-- Variables: evolve-hub -->
  <xsl:variable name="stylesheet-dir" select="replace(base-uri(document('')), '[^/]+$', '')" as="xs:string" />

  <xsl:variable name="basename" as="xs:string"
    select="(
              /*/dbk:info/dbk:keywordset[@role eq 'hub']/dbk:keyword[@role eq 'source-basename'],
              replace(base-uri(/*), '\.(xml|HUB|late\.xml)$', '')
    )[1]" />

  <xsl:variable name="basedir" as="xs:string"
    select="replace($basename, '^(.+/).+$', '$1')" />

  <xsl:variable name="hub:aux" as="document-node(element(hub:aux))">
    <xsl:document>
      <hub:aux>
        <xsl:if test="hub:boolean-param($aux)">
          <xsl:message select="'INFO: collecting all *.aux.xml files in directory', $basedir"/>
          <xsl:sequence select="collection(concat($basedir, '?select=*.aux.xml'))" />
        </xsl:if>
      </hub:aux>
    </xsl:document>
  </xsl:variable>

  <xsl:variable name="aux-file" select="concat($basename,'.aux.xml')"/>

  <xsl:variable name="hub:remove-empty-paras" as="xs:string"
    select="$remove-empty-paras" />

  <xsl:variable name="hub:empty-para-role-regex-x" as="xs:string"
    select="'^(tr|letex)_empty_para$'"/>

  <xsl:variable name="hub:base-style-regex" select="'^(No_paragraph_style|Standard)$'"/> 
  

  <xsl:variable name="hub:debug-lists-filename-prefix" as="xs:string" 
    select="'evolve.82.lists.'" />


  
  <xsl:variable name="hub:no-identifier-needed" select="'^(tr|letex)_no_id_style$'" as="xs:string"/>
  
  <xsl:template match="sidebar[hub:is-in-sidebar-without-purpose(.)]" mode="hub:dissolve-sidebars-without-purpose">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  
 <!-- if sidebars above are dissolved also paras whose only purpose is to reference such a sidebar can be discarded -->
  <xsl:template match="anchor[key('hub:linking-item-by-id', @xml:id)[hub:is-in-sidebar-without-purpose(.)]]" mode="hub:dissolve-sidebars-without-purpose"/>
  
  <xsl:template match="para[.//anchor[key('hub:linking-item-by-id', @xml:id)[hub:is-in-sidebar-without-purpose(.)]]
                                     [hub:same-scope(., current())]]
                                     [matches(hub:same-scope-text(.), '^\s*$')]
                                     [every $elt in * satisfies $elt[self::anchor[key('hub:linking-item-by-id', @xml:id)[hub:is-in-sidebar-without-purpose(.)]]] or 
                                      self::phrase[every $child in * satisfies $child[self::anchor[key('hub:linking-item-by-id', @xml:id)[hub:is-in-sidebar-without-purpose(.)]]]]
                                     ]" 
                mode="hub:dissolve-sidebars-without-purpose">
    <!-- this template discards page anchors etc.-->
  </xsl:template>
  
  <xsl:function name="hub:is-in-sidebar-without-purpose" as="xs:boolean">
    <xsl:param name="context" as="element(*)"/>
    <xsl:sequence select="if ($context/self::sidebar[not(@role)][@remap = ('TextFrame', 'Group')]) then true() else false()"/>
  </xsl:function>
  
  <!-- mode: preprocess-hierarchy -->

  <xsl:template match="/*" mode="hub:preprocess-hierarchy">
    <xsl:copy>
      <xsl:attribute name="xml:base" select="base-uri(.)" />
      <xsl:apply-templates select="@* | node()" mode="#current" />
    </xsl:copy>
  </xsl:template>

  <!-- for anchors in titles whose xml:id should be promoted to the object that contains the title --> 
  <xsl:template match="anchor" mode="hub:figure-captions hub:table-captions hub:hierarchy hub:identifiers hub:fix-floats-strip-num">
    <xsl:param name="suppress" as="element(anchor)*" tunnel="yes"/>
    <xsl:choose>
      <xsl:when test="exists($suppress) and (some $a in $suppress satisfies ($a is .))"/>
      <xsl:otherwise>
        <xsl:next-match/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Pull anchors out of links -->
  <xsl:template match="*:link[.//anchor]" mode="hub:hierarchy">
    <xsl:sequence select=".//*:anchor"/>
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:apply-templates select="node()" mode="#current">
        <xsl:with-param name="suppress" select=".//*:anchor" tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>
    
  <xsl:variable name="hub:non-empty-elements" as="xs:string+"
    select="('mediaobject','table','inlinemediaobject')" />

  <xsl:template 
      match="dbk:para[( 
                        hub:boolean-param($hub:remove-empty-paras) 
                        or 
                        matches(@role, $hub:empty-para-role-regex-x, 'x')
                      ) 
                      and
                      not(normalize-space(.)) 
                      and 
                      not(.//*[local-name() = $hub:non-empty-elements])
                      and
                      (: If you want to discard whitespace-only paras with underlines, redefine hub:underlined()
                      so that it always returns false() :)
                      not(hub:underlined(.))
                     ]" mode="hub:preprocess-hierarchy">
      <xsl:message select="'INFO: Removed empty para', 
                           if(@role ne '') then concat('with role ', xs:string(@role)) else '',
                           if(@srcpath ne '') then concat(' with srcpath ', xs:string(@srcpath)) else '',
                           if(*) then string-join(('; all descendant elements:', distinct-values(for $e in .//* return local-name($e))),' ') else ''"/>
  </xsl:template>
  
  <xsl:function name="hub:underlined" as="xs:boolean">
    <xsl:param name="elt" as="element(*)"/><!-- typically a para or a phrase -->
    <xsl:variable name="text-nodes" as="text()*" select="$elt//text()[hub:same-scope(., $elt)]"/>
    <xsl:variable name="underlines" as="attribute(css:text-decoration-line)*" 
      select="($text-nodes/ancestor::* intersect $elt/descendant-or-self::*)
                /(. | key('hub:style-by-role', @role))/@*[name() = 'css:text-decoration-line']
                                                         [. = 'underline']
                                                         [../@css:text-decoration-width[not(matches(., '^0(pt)?$'))]]"/>
    <xsl:sequence select="exists($underlines)"/>
  </xsl:function>
  
  <xsl:key name="natives" match="css:rule" use="@name"/> 
  
  <xsl:template match="css:rule[count(key('natives',current()/@name)) gt 1][not(@layout-type = ('table', 'cell'))][preceding-sibling::*[name() = 'css:rule'][@name = current()/@name]]" mode="hub:preprocess-hierarchy">
    <xsl:variable name="name">
      <xsl:value-of select="@name"/>
    </xsl:variable>
    <xsl:variable name="native-names" select="string-join(key('natives',current()/@name)/@native-name, ', ')"/>
    <xsl:message select="'❧❧❧❧❧❧ WARNING: CSS:RULE with identical name ', $name,' discarded. Native names were: ', $native-names"/>
  </xsl:template>
  
  <!-- Some authors set superscript or subscript manually with vertical-align. This template applies proper superscript or subscript tags 
       when such formatting is used. You have to set the param map-phrase-with-css-vertical-pos-to-super-or-subscript to 'yes' and use 
       the mode and apply your templates in this mode hub:hierarchy. -->
  
  <xsl:template match="phrase[@css:top and $map-phrase-with-css-vertical-pos-to-super-or-subscript eq 'yes']" mode="hub:hierarchy">
    <xsl:variable name="position" select="xs:decimal(replace(@css:top, '[a-zA-Z\s]', ''))" as="xs:decimal"/>
    <xsl:element name="{if($position gt 0) then 'subscript' else 'superscript'}">
      <xsl:apply-templates select="@* except (@css:top, @css:position), node()" mode="#current"/>
    </xsl:element>
  </xsl:template>
  
  <!-- MODE: hub:tabular-float-caption-arrangements -->
  
  <!-- Optional mode for preprocessing single-row, two-column informaltables where a float is in one cell
       and the caption is in another cell. Also: single-column, two-row arrangements -->
   
  <xsl:template match="informaltable[count(tgroup/tbody/row) = (1,2)]
                                    [xs:integer(tgroup/@cols) = 3 - count(tgroup/tbody/row)]
                                    [some $style in tgroup/tbody/row/entry/para/@role satisfies
                                     (
                                       matches($style, $hub:figure-title-role-regex-x, 'x')
                                       )]
                                    [exists(tgroup/tbody/row/entry//mediaobject)]
                                    (:para and mediaobject shouldn't exist in one entry (otherwise a table is useless) 
                                    because this destroys box tables containing a figure :)
                                    [tgroup/tbody/row/entry[.//mediaobject 
                                                             and 
                                                              not(some $style in para/@role satisfies
                                                                   (matches($style, $hub:figure-title-role-regex-x, 'x')
                                                             ))
                                                           ]
                                    ]"
                                    mode="hub:tabular-float-caption-arrangements">
    <xsl:apply-templates select="tgroup/tbody/row/entry[.//mediaobject]/node()" mode="#current"/>
    <xsl:apply-templates select="tgroup/tbody/row/entry[
                                   some $style in para/@role satisfies
                                   (
                                     matches($style, $hub:figure-title-role-regex-x, 'x')
                                   )
                                 ]/node()" mode="#current"/>
  </xsl:template>
  
  <!-- mode: join-tables -->

  <xsl:variable name="hub:split-style-regex" as="xs:string" select="'SPLIT'"/>
  
  <xsl:template match="*[informaltable[.//entry[matches(@role, $hub:split-style-regex)][hub:same-scope(.,
    current())]]]" mode="hub:join-tables_LATER">
    <xsl:next-match/>
  </xsl:template>
  
  <xsl:template name="hub:merge-srcpaths">
    <xsl:param name="srcpaths" as="attribute(srcpath)*"/>
    <xsl:variable name="distinct" as="xs:string*">
      <xsl:for-each-group select="$srcpaths" group-by="replace(., ';n=\d+$', '')">
        <xsl:sequence select="string(.)"/>
      </xsl:for-each-group>
    </xsl:variable>
    <xsl:if test="exists($distinct)">
      <xsl:attribute name="srcpath" select="$distinct" separator=" "/>
    </xsl:if>
  </xsl:template>
  
  <!-- joining sidebars (textboxes). Just the first one has to have a split on it-->
  <!-- first sidebar that will be merged -->
  <xsl:template match="*:sidebar[matches(@role, $hub:split-style-regex)][not(preceding-sibling::*[1][self::sidebar[matches(@role, $hub:split-style-regex)]])]" mode="hub:join-tables">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:apply-templates select="node()[not(matches(@role, $hub:split-style-regex))]" mode="#current"/>
      <xsl:if test="*[last()][matches(@role, $hub:split-style-regex)]">
       <xsl:call-template name="join-splitted-paras-in-sidebars"/>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="following-sibling::*[1][self::sidebar[matches(@role, $hub:split-style-regex)]]">
          <xsl:apply-templates select="following-sibling::*[1]" mode="#current">
            <xsl:with-param name="merged-sidebar" select="'yes'" as="xs:string"/>
          </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="if (*[last()][matches(@role, $hub:split-style-regex)]) then following-sibling::*[1]/node() except node()[1] else following-sibling::*[1]/node()" mode="#current"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>
  
  <!-- following mergeable sidebars -->
  <xsl:template match="*:sidebar[preceding-sibling::*[1][self::sidebar[matches(@role, $hub:split-style-regex)]]]" mode="hub:join-tables">
    <xsl:param name="merged-sidebar" as="xs:string?"/>
    <xsl:if test="$merged-sidebar = 'yes'">
      <xsl:apply-templates select="node()[not(matches(@role, $hub:split-style-regex))]" mode="#current"/>
      <xsl:if test="*[last()][matches(@role, $hub:split-style-regex)]">
        <xsl:call-template name="join-splitted-paras-in-sidebars"/>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="following-sibling::*[1][self::sidebar[matches(@role, $hub:split-style-regex)]]">
          <xsl:apply-templates select="following-sibling::*[1]" mode="#current">
            <xsl:with-param name="merged-sidebar" select="'yes'" as="xs:string"/>
          </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="if (*[last()][matches(@role, $hub:split-style-regex)]) then following-sibling::*[1]/node() except node()[1] else following-sibling::*[1]/node()" mode="#current"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>
  
  <!-- discard merged para -->
  <xsl:template match="para[parent::*[preceding-sibling::*[1]
                                                          [matches(@role, $hub:split-style-regex)]/*[position() = last()]
                                                                                                    [matches(@role, $hub:split-style-regex)]
                                                                                                    
                                     ]
                            ]
                            [../*[1] is .]" mode="hub:join-tables">
    <xsl:param name="merged-sidebar" as="xs:string?"/>
    <xsl:if test="not($merged-sidebar = 'yes')">
      <xsl:next-match/>
    </xsl:if>
  </xsl:template>
  
  <!-- joining splitted paras in sidebars-->
  <xsl:template name="join-splitted-paras-in-sidebars">
    <para>
      <xsl:call-template name="hub:merge-srcpaths">
        <xsl:with-param name="srcpaths" select="*[matches(@role, $hub:split-style-regex)]/@srcpath, following-sibling::*[1]/*/@srcpath"/>
      </xsl:call-template>
      <xsl:apply-templates select="*[matches(@role, $hub:split-style-regex)]/@* except (*[matches(@role, $hub:split-style-regex)]/@srcpath, following-sibling::*[1]/*[1]/@srcpath)" mode="#current"/>
      <xsl:apply-templates select="*[matches(@role, $hub:split-style-regex)]/node(), following-sibling::*[1]/*[1]/node()" mode="#current"/>
    </para>
  </xsl:template>
  
  <xsl:template match="tbody[row/entry[matches(@role, $hub:split-style-regex)]]" mode="hub:join-tables">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:for-each-group select="row" group-starting-with="*[self::row][entry[matches(@role, $hub:split-style-regex)][not(parent::*/preceding-sibling::*[1][entry[matches(@role, $hub:split-style-regex)]])]]">
         <xsl:for-each-group select="current-group()" group-adjacent="exists(entry[matches(@role, $hub:split-style-regex)] | entry[parent::*/preceding-sibling::*[1][self::row][entry[matches(@role, $hub:split-style-regex)]]])">
          <xsl:choose>
            <xsl:when test="current-grouping-key()">
              <xsl:copy>
                <xsl:apply-templates select="@*" mode="#current"/>
                <xsl:for-each select="entry">
                  <xsl:copy>
                    <xsl:variable name="pos" select="position()"/>
                    <xsl:apply-templates select="@* except @css:border-bottom-width, ((../following-sibling::row[entry[position() eq $pos][not(matches(@role, '_-_SPLIT'))]])[1]/entry[position() eq $pos]/@css:border-bottom-width, key('hub:style-by-role',(../following-sibling::row[entry[position() eq $pos][not(matches(@role, '_-_SPLIT'))]])[1]/entry[position() eq $pos]/@role)/@css:border-bottom-width)[1]" mode="#current"/>
                    <xsl:for-each-group select="current-group()/entry[position() eq $pos]/node()" group-starting-with="*[hub:split-start-para(., $pos)]">
                      <xsl:for-each-group select="current-group()" group-adjacent="hub:to-be-grouped-with-split(., $pos)">
                        <xsl:choose>
                          <xsl:when test="current-grouping-key()">
                            <xsl:copy>
                              <xsl:call-template name="hub:merge-srcpaths">
                                <xsl:with-param name="srcpaths" select="current-group()/@srcpath" as="attribute(srcpath)*"/>
                              </xsl:call-template>
                              <xsl:apply-templates select="@* except @srcpath, current-group()/node()" mode="#current"/>
                            </xsl:copy>
                          </xsl:when>
                          <xsl:otherwise>
                            <xsl:apply-templates select="current-group()" mode="#current"/>
                          </xsl:otherwise>
                        </xsl:choose>
                      </xsl:for-each-group>
                    </xsl:for-each-group>
                  </xsl:copy>
                </xsl:for-each>
              </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
              <xsl:apply-templates select="current-group()" mode="#current"/>
            </xsl:otherwise>
          </xsl:choose>
          </xsl:for-each-group>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>
  
  <xsl:function name="hub:split-start-para" as="xs:boolean">
    <xsl:param name="context" as="node()"/>
    <xsl:param name="pos" as="xs:integer"/>
    <xsl:choose>
      <xsl:when test="$context[self::para[matches(@role, $hub:split-style-regex)]]
                             [every $preceding in (preceding-sibling::*[1], parent::*[self::*:entry[parent::*[self::*:row[preceding-sibling::*[1]
                                                                                                                                              [self::*:row[*:entry[position() = $pos]
                                                                                                                                                          [matches(@role, $hub:split-style-regex)]]]]]]]/*:para[position() = last()])[1]
                              satisfies ($preceding[not(matches(@role,  $hub:split-style-regex))])]">
        <xsl:sequence select="true()"/>
      </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="false()"/>
        </xsl:otherwise>                                           
    </xsl:choose>
  </xsl:function>
  
  <xsl:function name="hub:to-be-grouped-with-split" as="xs:boolean">
    <xsl:param name="context" as="node()"/>
    <xsl:param name="pos" as="xs:integer"/>
    <xsl:choose>
      <xsl:when test="$context[self::para[matches(@role, $hub:split-style-regex)]]">
        <xsl:sequence select="true()"/>
      </xsl:when>
        <xsl:when test="$context[not(exists(preceding-sibling::*)) 
                                  and 
                                 parent::*[self::*:entry[parent::*[self::*:row[preceding-sibling::*[1][self::*:row[*:entry[position() = $pos]
                                                                                                                          [matches(@role, $hub:split-style-regex)]
                                                                                                                          [*:para[position() = last()]
                                                                                                                          [matches(@role, $hub:split-style-regex)]
                                                                                                                   ]
                                                                                                        ]
                                                                              ]
                                                                   ]
                                                        ]
                                              ]
                                           ]
                                           ]">
          <xsl:sequence select="true()"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="false()"/>
        </xsl:otherwise>                                           
    </xsl:choose>
  </xsl:function>
  
  
  <!-- mode: simplify-complex-float-sidebars
       Resolve IDML-specific float anchorings
       Note that idml2xml doesn't know whether there are floats in the text frames (all anchored frames become sidebars first).
       In order to be able to group tables and figures with their captions, we need to straighten out the nested structures,
       such as:
   <sidebar remap="Group" linkend="id_d1488e160">
      <para>
         <mediaobject>
            <imageobject>
               <imagedata fileref="…"/>
            </imageobject>
         </mediaobject>
      </para>
      <anchor xml:id="id_d1488e176"/>
   </sidebar>
   <sidebar remap="TextFrame" linkend="id_d1488e176">
      <para role="Figure_Legend">…</para>
   </sidebar>
       -->

  <xsl:template mode="hub:simplify-complex-float-sidebars"
    match="sidebar
             [
               anchor[
                 key('hub:linking-item-by-id', @*:id)
                   [para]
                   [count(node()) eq 1]
                   [
                     matches(para/@role, $hub:figure-title-role-regex-x, 'x')
                     or
                     matches(para/@role, $hub:table-title-role-regex-x, 'x')
                   ]
               ]
             ]
             [count(anchor) = (1, 2)]
             (: 'every $c …' also covers the case that there are only anchors in the sidebar :)
             [every $c in */node() satisfies ($c/self::informaltable or $c/self::mediaobject)]
           ">
    <xsl:variable name="caption-anchor" as="element(anchor)*"
      select="anchor[
                key('hub:linking-item-by-id', @*:id)[
                  para[
                    matches(@role, $hub:figure-title-role-regex-x, 'x')
                    or
                    matches(@role, $hub:table-title-role-regex-x, 'x')
                  ]
                ]
              ]" />
    <xsl:variable name="caption" as="element(para)*">
      <xsl:for-each select="$caption-anchor">
        <xsl:sequence select="key('hub:linking-item-by-id', ./@*:id)/para"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current" />
      <xsl:choose>
        <xsl:when test="every $i in ($caption) satisfies matches($i/@role, $hub:figure-title-role-regex-x, 'x')">
          <xsl:choose>
            <xsl:when test="count($caption-anchor) = count(para[mediaobject])">
              <xsl:apply-templates select="node() except (para[mediaobject],anchor)" mode="#current"/>
              <xsl:variable name="mediaobjects" select="para[mediaobject]" as="element(para)*"/>
              <xsl:for-each select="$caption-anchor">
                <xsl:variable name="pos" select="position()"/>
                <xsl:apply-templates select="$mediaobjects[position() eq $pos]" mode="#current" />
                <xsl:apply-templates select="$caption[position() eq $pos]" mode="#current" />
              </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
              <xsl:apply-templates select="node() except anchor (: empty if there are 2 anchors :), $caption[1],
                                           key('hub:linking-item-by-id', anchor[not(. is $caption-anchor[1])]/@*:id)/node()" 
                mode="#current" />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="$caption[1],
                                       node() except anchor (: empty if there are 2 anchors :),
                                       key('hub:linking-item-by-id', anchor[not(. is $caption-anchor[1])]/@*:id)/node()" 
            mode="#current" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>

  <xsl:variable name="hub:exclude-sidebar-from-dissolving-if-image-contained-role-regex" as="xs:string" select="'transpect_sidenote'">
    <!-- overwrite this in your adaptions if needed. Was needed to avoid sidenotes to be dissolved.-->
  </xsl:variable>
  
  <xsl:template mode="hub:simplify-complex-float-sidebars"
    match="sidebar
             [para]
             [not(matches(@role, $hub:exclude-sidebar-from-dissolving-if-image-contained-role-regex))]
             [count(node()) eq 1]
             [
               matches(para/@role, $hub:figure-title-role-regex-x, 'x')
               or
               matches(para/@role, $hub:table-title-role-regex-x, 'x')
							 or 
               para[mediaobject and . = '']
               or 
               informaltable[descendant::mediaobject]
             ]" priority="+1">
		<xsl:apply-templates mode="#current" />
	</xsl:template>

  <xsl:template mode="hub:simplify-complex-float-sidebars"
    match="sidebar
             [para]
             [count(node()) eq 1]
             [
               matches(para/@role, $hub:figure-title-role-regex-x, 'x')
               or
               matches(para/@role, $hub:table-title-role-regex-x, 'x')
             ]
             [
               key('hub:linking-item-by-linkend', @linkend)/..
                 [count(anchor) = (1, 2)]
                 [every $c in */node() satisfies ($c/self::informaltable or $c/self::mediaobject)]
             ] ">
		<xsl:if test="preceding-sibling::node()[1]/self::sidebar
             [
               para[
                 mediaobject and . = ''
               ] 
               or 
               informaltable[
                 descendant::mediaobject
               ]
             ]
             [count(node()) eq 1]
             [
               key('hub:linking-item-by-linkend', @linkend)/..
                 [count(anchor) = (1, 2)]
                 [every $c in */node() satisfies ($c/self::informaltable or $c/self::mediaobject)]
             ]">
			<xsl:apply-templates mode="#current" />
		</xsl:if>
	</xsl:template>

  <xsl:template mode="hub:simplify-complex-float-sidebars"
    match="sidebar
             [
               para[
                 mediaobject and . = ''
               ] 
               or 
               informaltable[
                 descendant::mediaobject
               ]
             ]
             [count(node()) eq 1]
             [
               key('hub:linking-item-by-linkend', @linkend)/..
                 [count(anchor) = (1, 2)]
                 [every $c in */node() satisfies ($c/self::informaltable or $c/self::mediaobject)]
             ] ">
		<xsl:if test="following-sibling::node()[1]/self::sidebar[para]
             [count(node()) eq 1]
             [
               matches(para/@role, $hub:figure-title-role-regex-x, 'x')
               or
               matches(para/@role, $hub:table-title-role-regex-x, 'x')
             ]
             [
               key('hub:linking-item-by-linkend', @linkend)/..
                 [count(anchor) = (1, 2)]
                 [every $c in */node() satisfies ($c/self::informaltable or $c/self::mediaobject)]
             ]">
			<xsl:apply-templates mode="#current" />
		</xsl:if>
	</xsl:template>

  <!-- Reformatted the code (which was introduced in r66 in order to understand it better but commented it out
       because I don't understand it and it does harm (removes 2nd table in Spektrum/Wachsmuth). 

  <xsl:variable name="hub:complex-sidebar-table-anchor-role-regex" select="'^(Table)$'"/>

  <xsl:template mode="hub:simplify-complex-float-sidebars"
    match="para[
             parent::sidebar 
             and
             matches(@role, $hub:complex-sidebar-table-anchor-role-regex)
             and anchor[
               key('hub:linking-item-by-id', @*:id)
               /self::sidebar[para and count(node()) eq 1]/para[informaltable and count(node()) eq 1]
             ]
             and (count(node()) eq 1)
           ]">
    <xsl:apply-templates select="key('hub:linking-item-by-id', anchor/@*:id)[1]/para/informaltable" mode="#current" />
  </xsl:template>

  <xsl:template mode="hub:simplify-complex-float-sidebars"
    match="sidebar[
             key('hub:linking-item-by-linkend', @linkend)
             /parent::para[
               matches(@role, $hub:complex-sidebar-table-anchor-role-regex)
               and count(node()) eq 1
             ]
             and (
               some $x in key('hub:linking-item-by-id', key('hub:linking-item-by-linkend', current()/@linkend)/@*:id)
               satisfies $x/self::sidebar[para and count(node()) eq 1]/para[informaltable and count(node()) eq 1]
             )
           ]" />

  -->

  <xsl:variable name="hub:marginalia-role-regex-x" select="'^marginpar$'" as="xs:string"/>

  <xsl:variable name="hub:keep-sidebar-para-role-regexes-x" select="$hub:marginalia-role-regex-x" as="xs:string+"/>

  <xsl:template mode="hub:simplify-complex-float-sidebars"
    match="sidebar[not(
                        some $para in para satisfies 
                        (
                          some $re in $hub:keep-sidebar-para-role-regexes-x satisfies (
                            matches($para/@role, $re, 'x')
                          )
                        )
                      )][
                        count(para union informaltable union table union mediaobject) eq count(node())
                        and @linkend eq following-sibling::*[1]/node()[1][self::anchor]/@xml:id
                      ]">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <xsl:template match="para[informaltable and parent::sidebar and count(node()) eq 1]" mode="hub:simplify-complex-float-sidebars">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <xsl:template match="para[informaltable and parent::sidebar and count(node()) eq 1]/informaltable" mode="hub:simplify-complex-float-sidebars">
    <xsl:copy>
      <!-- overwrite current @role with @role of parent element (para) -->
      <xsl:apply-templates select="@*, parent::*/@role, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>


  <!-- collateral (a rather fundamental one – can’t be done so well in the previous modes): -->
  <xsl:template match="/Body" mode="hub:simplify-complex-float-sidebars">
    <chapter>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </chapter>
  </xsl:template>
  

  <!-- mode: hub:resolve-sidebar-floats 
       Resolve IDML-specific float anchorings
       Note that idml2xml doesn't know whether there are floats in the text frames (all anchored frames become sidebars first).
       After identifying tables and figures, we may move them out of their sidebars and dissolve the sidebars. 
       -->

  <!-- for finding sidebar[@linkend] to a given anchor[@xml:id]: -->
  <xsl:key name="hub:linking-item-by-id" match="*[@linkend]" use="@linkend" />
  <!-- for finding anchor[@xml:id] to a given sidebar[@linkend]: -->
  <xsl:key name="hub:linking-item-by-linkend" match="*[@*:id]" use="@*:id" />

  <!-- For *anchored* groups, convey to the children that they are anchored.
       It is assumed that the anchored group is already close to the anchoring point.
       But we don’t check this here, nor do we make any efforts to place it close to
       its anchor. -->
  <xsl:template mode="hub:resolve-sidebar-floats"
    match="sidebar[@remap eq 'Group']">
    <xsl:apply-templates mode="#current">
      <xsl:with-param name="anchored" select="exists(@linkend)" tunnel="yes"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <!-- Remove the corresponding anchor: -->  
  <xsl:template match="anchor[key('hub:linking-item-by-id', @xml:id)/self::sidebar[@remap eq 'Group']]"
    mode="hub:resolve-sidebar-floats"/>
  
  <xsl:template mode="hub:resolve-sidebar-floats"
    match="sidebar
             [@linkend
              or ( (: A TextFrame that has already been moved to where it was anchored :)
                not(@linkend)
                and
                @remap = 'TextFrame'
              )
             ]
             [every $c in * satisfies ($c/self::table or $c/self::informaltable or $c/self::figure)]">
    <xsl:apply-templates mode="#current" />
  </xsl:template>

  <xsl:template mode="hub:resolve-sidebar-floats" priority="2"
    match="sidebar
             [exists(key('hub:linking-item-by-linkend', @linkend))
              or ( (: A TextFrame that has already been moved to where it was anchored :)
                not(@linkend)
                and
                @remap = 'TextFrame'
              )
             ]
             [every $c in * satisfies ($c/self::table or $c/self::informaltable or $c/self::figure)]
	       /*[self::figure or self::table]">
    <xsl:next-match>
      <xsl:with-param name="anchored" select="true()"/>
    </xsl:next-match>
  </xsl:template>

  <xsl:template mode="hub:resolve-sidebar-floats"
    match="*[self::figure or self::table]">
    <xsl:param name="anchored" as="xs:boolean?" tunnel="yes"/>
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:if test="$anchored">
        <xsl:attribute name="hub:anchored" select="'yes'"/>  
      </xsl:if>
      <xsl:apply-templates select="node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <!-- standard template for sidebar in mode resolve-sidebar-floats:
       check if parent element of linked anchor contains anchors only
       and has an non-empty @role attribute; copy @role, if so
       (i.e. <para role="Box"><anchor xml:id="id_d10929e232"/></para>) -->
  <xsl:template match="sidebar" mode="hub:resolve-sidebar-floats">
    <xsl:variable name="linking-item" select="key('hub:linking-item-by-linkend', @linkend)"/>
    <xsl:copy>
      <xsl:if test="exists($linking-item[parent::*[count(*) eq count(anchor)]/@role ne ''])">
	<xsl:attribute name="role" select="$linking-item[parent::*[count(*) eq count(anchor)]/@role ne '']/parent::*/@role"/>
      </xsl:if>
      <xsl:apply-templates select="@* except @linkend | node()" mode="#current" />
    </xsl:copy>
  </xsl:template>
 <!-- Wouldn't it be useful to discard the linkend then (I did that now – Maren)? It is already dissolved and needs an id which is discarded in next template -->

  <xsl:template mode="hub:resolve-sidebar-floats"
    match="para
             [ anchor ]
             [ every $c in node() satisfies ( $c/self::anchor[key('hub:linking-item-by-id', @*:id)] ) ]" />


  <!-- mode: hub:collect-continued-floats 
             compare caption numbers of float objects and collect title and mediaobject into one <figure> or <table>
  -->
  <!-- todo: implementation for tables (no data to test with, yet) -->

  <xsl:template mode="hub:collect-continued-floats"
    match="*[figure[following-sibling::node()[1][self::figure]]]">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:for-each-group select="node()" 
        group-adjacent="if(self::figure[title]) 
                        then replace(
                          replace(
                            title[1], 
                            concat($hub:caption-number-plus-sep-regex, '.*$'), 
                            '$1$2$3'),
                          '[^\d]',
                          '')
                        else false()">
        <xsl:choose>
          <xsl:when test="current-grouping-key() and self::figure and count(current-group()) gt 1">
            <xsl:message select="'INFO: Collecting continued figures to one figure environment [', current-grouping-key(), '], titles:', current-group()/title"/>
            <figure>
              <xsl:apply-templates select="current-group()[1]/@*" mode="#current" />
              <xsl:if test="current-group()[not(mediaobject)]">
                <title>
                  <xsl:apply-templates select="current-group()[not(mediaobject)][1]/title/node()" mode="#current" />
                  <xsl:variable name="first-title" select="string-join(current-group()[1]/title//text(), '')" as="xs:string"/>
                  <xsl:for-each select="current-group()[not(mediaobject)][position() gt 1]/title">
                    <xsl:if test="not(string-join(.//text(),'') eq $first-title)">
                      <phrase role="br"/>
                      <xsl:apply-templates select="current()/node()" mode="#current" />
                    </xsl:if>
                  </xsl:for-each>
                </title>
              </xsl:if>
              <xsl:for-each select="current-group()[mediaobject]">
                <mediaobject>
                  <xsl:apply-templates select="mediaobject/@*" mode="#current"/>
                  <xsl:apply-templates select="mediaobject/node()" mode="#current"/>
                  <xsl:if test="title">
                    <caption>
                      <xsl:apply-templates select="title/node()" mode="#current"/>
                    </caption>
                  </xsl:if>
                </mediaobject>
              </xsl:for-each>
              <xsl:if test="current-group()/*[not(self::title or self::mediaobject)]">
                <xsl:message select="' !!!!! WARNING !!!!! content not processed and lost:', current-group()/*[not(self::title or self::mediaobject)]" />
              </xsl:if>
            </figure>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="current-group()" mode="#current"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>

  
  <!-- mode: hub:sort-figure-captions -->

  <!-- If every figure caption is followed by a mediaobject, we may assume that the captions are consistently above the figures.
       In order to make hub:figure-captions work properly, we pull the captions down, below each mediaobject. -->
  <!-- There can be different variations of images with caption above and following images without caption. 
       Therefore check if figure caption is also preceded by a mediaobject, then don't change order. -->

  <xsl:template match="*[para[matches(@role, $hub:figure-title-role-regex-x, 'x')]]
                        [every $caption in para[matches(@role, $hub:figure-title-role-regex-x, 'x')] satisfies
                         ($caption/following-sibling::*[1][hub:is-figure(.)])
                        ]
                        [not(every $caption in para[matches(@role, $hub:figure-title-role-regex-x, 'x')] satisfies
                         ($caption/preceding-sibling::*[1][hub:is-figure(.)]))]" mode="hub:sort-figure-captions">
    <xsl:copy>
      <xsl:sequence select="@*" />
      <xsl:for-each-group select="*" group-starting-with="para[matches(@role, $hub:figure-title-role-regex-x, 'x')]">
        <xsl:variable name="mediaobjects" select="current-group() 
                                                  intersect
                                                  following-sibling::*[hub:is-figure(.)][hub:is-figure-title(preceding-sibling::*[1])]" />
        <!-- since figures can also be figures without titles, we may only resort those with a title here -->
        <xsl:choose>
          <xsl:when test="current-group()[1][self::para[matches(@role, $hub:figure-title-role-regex-x, 'x')]]">
            <xsl:sequence select="$mediaobjects" />
            <xsl:apply-templates select="current-group() except $mediaobjects" mode="#current"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="current-group()" mode="#current"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>

  <xsl:template 
    match="keywordset[@role eq 'hub']
                     (: The following match pattern should always the same as for the previous template :)
                     [//*[para[matches(@role, $hub:figure-title-role-regex-x, 'x')]]
                        [every $caption in para[matches(@role, $hub:figure-title-role-regex-x, 'x')] satisfies
                         ($caption/following-sibling::*[1][hub:is-figure(.)])
                        ]
                        [not(every $caption in para[matches(@role, $hub:figure-title-role-regex-x, 'x')] satisfies
                         ($caption/preceding-sibling::*[1][hub:is-figure(.)]))]
                     ]" 
    mode="hub:sort-figure-captions">
    <xsl:copy>
      <xsl:sequence select="@*" />
      <xsl:apply-templates select="keyword except keyword[@role eq 'figure-captions-moved-below-mediaobjects']" mode="#current" />
      <keyword role="figure-captions-moved-below-mediaobjects">true</keyword>
    </xsl:copy>
  </xsl:template>


  <!-- mode: hub:sort-table-captions -->

  <!-- If every informaltable is followed by a caption, we may assume that the captions are consistently below the tables.
       In order to make hub:table-captions work properly, we pull the captions up, above each informaltable. -->
  <!-- Consider tables without caption, followed by normal paragraph -->

  <xsl:template match="*[*[hub:is-table-not-in-table-env(.)]]
                         [every $table in (*[hub:is-table-not-in-table-env(.) 
                                             and 
                                             matches(following-sibling::para[1]/@role, $hub:table-title-role-regex-x,'x')
                                             or 
                                             matches(preceding-sibling::para[1]/@role, $hub:table-title-role-regex-x,'x')])
                         satisfies (matches($table/following-sibling::para[1]/@role, $hub:table-title-role-regex-x, 'x'))
                         ]" mode="hub:sort-table-captions">
    <xsl:copy>
      <xsl:sequence select="@*" />
      <xsl:for-each-group select="*" group-starting-with="*[hub:is-table-not-in-table-env(.)]">
        <xsl:variable name="captions" select="current-group() 
                                              intersect
                                              following-sibling::para[matches(@role, $hub:table-title-role-regex-x, 'x')]" />
        <xsl:choose>
          <xsl:when test="current-group()[1][self::*[hub:is-table-not-in-table-env(.)]]">
            <xsl:sequence select="$captions" />
            <xsl:sequence select="current-group() except $captions" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="current-group()" mode="#current"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>

  <xsl:template 
    match="keywordset[@role eq 'hub']
                     (: The following match pattern should always the same as for the previous template :)
                     [//*[*[hub:is-table-not-in-table-env(.)]]
                         [every $table in (*[hub:is-table-not-in-table-env(.)]) satisfies
                          (matches($table/following-sibling::para[1]/@role, $hub:table-title-role-regex-x, 'x'))
                         ]
                     ]" 
    mode="hub:sort-table-captions">
    <xsl:copy>
      <xsl:message select="'table-captions-moved-above-tables'"></xsl:message>
      <xsl:sequence select="@*" />
      <xsl:apply-templates select="keyword except keyword[@role eq 'table-captions-moved-above-tables']" mode="#current" />
      <keyword role="table-captions-moved-above-tables">true</keyword>
    </xsl:copy>
  </xsl:template>


  <!-- mode: hub:join-phrases -->

  <xsl:template match="@srcpath[not(hub:boolean-param($srcpaths))]" mode="hub:join-phrases" />

  <xsl:template match="*[phrase or superscript or subscript]" mode="hub:join-phrases">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current" />
      <xsl:for-each-group select="node()" group-adjacent="hub:phrase-signature(.)">
        <xsl:choose>
          <!-- dissolve if no interesting attributes -->
          <xsl:when test="exists(current-group()/@*) and 
                          (every $att in current-group()/@* satisfies ($att/name() = 'srcpath')) and
                          not(self::superscript or self::subscript)">
            <xsl:apply-templates select="current-group()" mode="hub:join-phrases-unwrap" />
          </xsl:when>
          <xsl:when test="self::phrase or self::superscript or self::subscript">
            <xsl:copy>
              <xsl:if test="hub:boolean-param($srcpaths) and (current-group()/@srcpath)[. ne ''][1]">
                <xsl:attribute name="srcpath" select="current-group()/@srcpath[. ne '']" separator=" "/>
              </xsl:if>
              <xsl:sequence select="@* except @srcpath" />
              <xsl:apply-templates select="current-group()" mode="hub:join-phrases-unwrap" />
            </xsl:copy>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="current-group()" mode="#current" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>

  <xsl:function name="hub:attr-hashes" as="xs:string*">
    <xsl:param name="elt" as="node()*" />
    <xsl:perform-sort>
      <xsl:sort/>
      <xsl:sequence select="for $a in ($elt/@*[not(name() = $hub:attr-hash-ignorables)]) return hub:attr-hash($a)" />
    </xsl:perform-sort>
  </xsl:function>
  
  <xsl:variable name="hub:attr-hash-ignorables" as="xs:string*" select="('xml:id', 'srcpath')"/>

  <xsl:function name="hub:attr-hash" as="xs:string">
    <xsl:param name="att" as="attribute(*)" />
    <xsl:sequence select="concat(name($att), '__=__', $att)" />
  </xsl:function>

  <xsl:function name="hub:attname" as="xs:string">
    <xsl:param name="hash" as="xs:string" />
    <xsl:value-of select="replace($hash, '__=__.+$', '')" />
  </xsl:function>

  <xsl:function name="hub:attval" as="xs:string">
    <xsl:param name="hash" as="xs:string" />
    <xsl:value-of select="replace($hash, '^.+__=__', '')" />
  </xsl:function>

  <xsl:function name="hub:signature" as="xs:string*">
    <xsl:param name="elt" as="element(*)?" />
    <xsl:sequence select="if (exists($elt)) 
                          then string-join((name($elt), hub:attr-hashes($elt)), '___')
                          else '' " />
  </xsl:function>

  <!-- If a span, return its hash. 
       If a whitespace text node in between two spans of same hash, return their hash.
       Otherwise, return the empty string. -->
  <xsl:function name="hub:phrase-signature" as="xs:string">
    <xsl:param name="node" as="node()" />
    <xsl:apply-templates select="$node" mode="hub:phrase-signature"/>
    <!--<xsl:sequence select="if ($node/self::phrase or $node/self::superscript or $node/self::subscript) 
                          then hub:signature($node)
                          else 
                            if ($node/self::*)
                            then ''
                            else
                              if ($node/self::text()
                                    [matches(., '^[\p{Zs}\s]+$')]
                                    [hub:signature($node/preceding-sibling::*[1]) eq hub:signature($node/following-sibling::*[1])]
                                 )
                              then hub:signature($node/preceding-sibling::*[1])
                              else ''
                          " />-->
  </xsl:function>
  
  <xsl:template match="phrase | superscript | subscript" mode="hub:phrase-signature" as="xs:string">
    <xsl:sequence select="hub:signature(.)"/>
  </xsl:template>

  <xsl:template match="node()" mode="hub:phrase-signature" as="xs:string">
    <xsl:sequence select="''"/>
  </xsl:template>
  
  <!-- overwrite this variable to join i.e. punctuation text nodes between phrase elements -->
  <xsl:variable name="hub:join-phrases-text-node-regex" as="xs:string"
    select="'^[\p{Zs}\s]+$'"/>
  
  <xsl:template match="text()[matches(., $hub:join-phrases-text-node-regex)]
                             [hub:signature(preceding-sibling::*[1]) = hub:signature(following-sibling::*[1])]" 
                mode="hub:phrase-signature" as="xs:string">
    <xsl:sequence select="hub:signature(preceding-sibling::*[1])"/>
  </xsl:template>
  
  <xsl:template match="anchor
                             [hub:signature(preceding-sibling::*[1]) = hub:signature(following-sibling::*[1])]" 
                mode="hub:phrase-signature" as="xs:string">
    <xsl:sequence select="hub:signature(preceding-sibling::*[1])"/>
  </xsl:template>


  <xsl:template match="phrase | superscript | subscript" mode="hub:join-phrases-unwrap">
    <xsl:apply-templates mode="hub:join-phrases" />
  </xsl:template>
  
  <xsl:template match="*" mode="hub:join-phrases-unwrap">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="hub:join-phrases" />  
    </xsl:copy>
  </xsl:template>


  <!-- mode: evolve-textreference-to-link -->

  <xsl:variable name="hub:reference-text-plus-number-regex" as="xs:string"
    select="concat('^(', $hub:figure-caption-start-regex, '|', $hub:table-caption-start-regex, '|', $hub:listing-caption-start-regex, ')(', $hub:caption-sep-regex, ')(A?[0-9]+(\.[0-9]+)*[&#x2009;&#x202F;]?[a-z,A-Z&#x2013;-]*\.?)')" />

  <!-- for figures and tables only, at the moment; ToDo: sections and other -->
  <xsl:template 
    match="text()[not(ancestor::link)]
             [not(ancestor::phrase[ @role eq 'hub:caption-number'])]
             [matches(., $hub:reference-text-plus-number-regex)]" 
    mode="hub:evolve-textreference-to-link">
    <xsl:variable name="root" as="document-node(element())">
      <xsl:document>
        <xsl:sequence select="root(.)/*"/>
      </xsl:document>
    </xsl:variable>
    <xsl:analyze-string select="." regex="{$hub:reference-text-plus-number-regex}">
      <xsl:matching-substring>
        <xsl:variable name="type" as="xs:string?" 
          select="hub:target-type(regex-group(1), regex-group(3))"/>
        <xsl:variable name="id" as="xs:string?" 
          select="regex-group(3)"/>
        <xsl:variable name="target" as="xs:string?" 
          select="hub:resolve-target($type, $id, $root)[1]"/>
        <link>
          <xsl:if test="$target">
            <xsl:attribute name="linkend" select="$target"/>
          </xsl:if>
          <xsl:value-of select="." />
        </link>
      </xsl:matching-substring>
      <xsl:non-matching-substring>
        <xsl:value-of select="." />
      </xsl:non-matching-substring>
    </xsl:analyze-string>
  </xsl:template>


  <!-- mode: join-links -->

  <xsl:function name="hub:link-signature" as="xs:string">
    <xsl:param name="node" as="node()" />
    <xsl:choose>
      <xsl:when test="$node/self::link/@role or $node/self::olink/@role">
        <xsl:sequence select="concat(local-name($node), $node/@role)" />
      </xsl:when>
      <xsl:when test="$node/self::link or $node/self::olink">
        <xsl:sequence select="'norole'" />
      </xsl:when>
      <xsl:when test="$node/self::anchor[preceding-sibling::node()[1]/(self::link | self::anchor | self::olink)]">
        <xsl:sequence select="hub:link-signature($node/preceding-sibling::node()[1])" />
      </xsl:when>
      <xsl:when test="$node/self::text()[matches(., '^[\p{Zs}]+$') and preceding-sibling::node()[1]/(self::link) and following-sibling::node()[1]/(self::link)]">
        <xsl:sequence select="hub:link-signature($node/preceding-sibling::node()[1])" />
      </xsl:when>
      <xsl:when test="$node/self::text()[matches(., '[\p{Zs}]+') and preceding-sibling::node()[1]/(self::olink) and following-sibling::node()[1]/(self::olink)]">
        <xsl:sequence select="hub:link-signature($node/preceding-sibling::node()[1])" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="'nolink'"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:template match="*[link or olink]" mode="hub:join-links">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:for-each-group select="node()" group-adjacent="hub:link-signature(.)">
        <xsl:choose>
          <xsl:when test="current-grouping-key() = ('nolink', 'norole')">
            <xsl:apply-templates select="current-group()" mode="#current"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:element name="{local-name(current-group()[1])}">
              <xsl:attribute name="role" select="current-grouping-key()"/>
              <xsl:apply-templates select="current-group()[1]/@*" />
              <xsl:apply-templates select="current-group()[self::link or self::olink]/node() | current-group()[self::text()]" mode="#current"/>
            </xsl:element>
            <xsl:apply-templates select="current-group()[self::anchor]" mode="#current"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>


  <!-- mode: hub:toc-chapter 
       
  <xsl:template match="/*[para[matches(@role, $hub:toc-entry-role-regex)]]" mode="hub:toc1_DISABLED">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:variable name="heading" select="hub:get-string-docprop(/, 'toc-title')" as="xs:string?"/>
      <xsl:for-each-group select="node()" group-adjacent="if (self::para[matches(@role, $hub:toc-entry-role-regex)]) then true() else false()">
        <xsl:choose>
          <xsl:when test="current-grouping-key()">
            <toc>
              <xsl:if test="$heading">
                <title>
                  <xsl:value-of select="$heading"/>
                </title>
              </xsl:if>
              <xsl:call-template name="hub:group-content">
                <xsl:with-param name="setup-node" select="document($hub:toc-structure-file)/*"/>
                <xsl:with-param name="nodes" select="current-group()"/>
              </xsl:call-template>
            </toc>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="current-group()" mode="#current"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template> -->

  <xsl:template match="tocdiv/para[following-sibling::tocdiv]" mode="hub:toc2" priority="2">
    <xsl:apply-templates select="." mode="hub:toc2-pagenum" />
    <title>
      <xsl:apply-templates select="@* | node()" mode="#current"/>
    </title>
  </xsl:template>

  <xsl:template match="tocdiv/para" mode="hub:toc2">
    <tocentry>
      <xsl:apply-templates select="." mode="hub:toc2-pagenum" />
      <xsl:apply-templates select="@* | node()" mode="#current"/>
    </tocentry>
  </xsl:template>

  <xsl:variable name="hub:tocentry-pagenum-sep-regex" as="xs:string"
    select="'[\p{Zs}\p{Pd}]+'" />

  <xsl:template match="tocdiv/para//text()[. is (ancestor::para[1]//text())[last()]]" mode="hub:toc2">
    <xsl:value-of select="replace(., concat($hub:tocentry-pagenum-sep-regex, '(\d+)$'), '')"/>
  </xsl:template>

  <xsl:template match="para" mode="hub:toc2-pagenum">
    <xsl:variable name="num" select="replace(., concat('^(.+?)(', $hub:tocentry-pagenum-sep-regex, '(\d+))?$'), '$3')" as="xs:string"/>
    <xsl:if test="$num ne ''">
      <xsl:attribute name="pagenum" select="$num" />
    </xsl:if>
  </xsl:template>

  <xsl:template match="tocdiv[count(*) eq 1]" mode="hub:toc2">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <!-- mode: hub:special-paras (@roles / formalparas) -->

  <xsl:variable name="hub:important-formalpara-heading-role-regex" as="xs:string"
    select="'^(Important_Headline)$'" />

  <xsl:variable name="hub:important-formalpara-para-role-regex" as="xs:string"
    select="'^(Important[-_\s]Text[-_\s][12]|Important[-_\s]Text[-_\s]1[-_\s]No_Headline)$'" />

  <xsl:variable name="hub:important-formalpara-list-role-regex" as="xs:string"
    select="'^(Important_Item_List_(Unordered|Numbered))$'" />

  <xsl:variable name="hub:warning-formalpara-heading-role-regex" as="xs:string"
    select="'^Cave[-_\s]Headline$'" />
  
  <xsl:variable name="hub:warning-formalpara-para-role-regex" as="xs:string"
    select="'^Cave[-_\s]Text-1$'" />

  <xsl:variable name="hub:warning-formalpara-list-role-regex" as="xs:string"
    select="'^Cave_Item_List_Unordered$'" />

  <xsl:variable name="hub:overview-formalpara-heading-role-regex" as="xs:string"
    select="'^Textbox-5_Headline(-2)?$'" />
  
  <xsl:variable name="hub:overview-formalpara-para-role-regex" as="xs:string"
    select="'^Textbox-5_(Text(-2)?|Figure|Table)$'" />

  <xsl:variable name="hub:overview-formalpara-list-role-regex" as="xs:string"
    select="'^Textbox-5_(Item|List_Unordered)$'" />

  <xsl:variable name="hub:definition-formalpara-heading-role-regex" as="xs:string"
    select="'^(Definition[-_\s]Headline|Textbox-2_Headline)$'" /><!--Headline[-_\s]Special-[23]([-_\s]Sub)?-->

  <xsl:variable name="hub:definition-formalpara-para-role-regex" as="xs:string"
    select="'^(Definition[-_\s]Text[-_\s][12]|Textbox-2_Text(-2)?|Textbox-2_(Figure|Table))$'" /><!--Bodytext[-_\s]1-->

  <xsl:variable name="hub:definition-formalpara-list-role-regex" as="xs:string"
    select="'^((Definition|Textbox-2)_(Item|Item_Sub|(Item_)?List_Unordered))$'" />
  
  <xsl:variable name="hub:trailer-formalpara-heading-role-regex" as="xs:string"
    select="'^Textbox-3_Headline$'" />

  <xsl:variable name="hub:trailer-formalpara-para-role-regex" as="xs:string"
    select="'^(Textbox-3_Text(-2)?)$'" />

  <xsl:variable name="hub:trailer-formalpara-list-role-regex" as="xs:string"
    select="'^(Textbox-3_TextItem_List_Unordered)$'" />

  <xsl:variable name="hub:answers-formalpara-heading-role-regex" as="xs:string"
    select="'^Answer_Headline$'" />

  <xsl:variable name="hub:answers-formalpara-para-role-regex" as="xs:string"
    select="'^(Answer_Text-1_No_Headline|Textbox-1_Text)$'" />

  <xsl:variable name="hub:answers-formalpara-list-role-regex" as="xs:string"
    select="'^Answer_Item_List_Numbered'" />

  <xsl:variable name="hub:formalpara-sep-regex" as="xs:string"
    select="'&#x2002;'" />

  <xsl:variable name="hub:example-formalpara-heading-role-regex" as="xs:string"
    select="'^Example_Headline$'" />

  <xsl:variable name="hub:example-formalpara-para-role-regex" as="xs:string"
    select="'^(Example_Text_[12]|Example_|Case[-_\s]Study)$'" />

  <xsl:variable name="hub:example-formalpara-list-role-regex" as="xs:string"
    select="'^Example_List_1$'" />

  <xsl:variable name="hub:backgroundinformation-formalpara-heading-role-regex" as="xs:string"
    select="'^(Backgroundinformation_Headline)$'" />

  <xsl:variable name="hub:backgroundinformation-formalpara-para-role-regex" as="xs:string"
    select="'^(Backgroundinformation|Backgroundinformation_Text_\d(_Space_Top)?)$'" />

  <xsl:variable name="hub:backgroundinformation-formalpara-list-role-regex" as="xs:string"
    select="'^(Backgroundinformation_Text_List(_Sub)*)$'" />

  <xsl:variable name="hub:procedure-formalpara-heading-role-regex" as="xs:string"
    select="'^Procedure[-_\s]Head[-_\s]*'" />

  <xsl:variable name="hub:procedure-formalpara-para-role-regex" as="xs:string"
    select="'^Procedure[-_\s]*'" />
  
  <xsl:variable name="hub:procedure-formalpara-list-role-regex" as="xs:string"
    select="'^Procedure_(Sub_)?(Sub)?([Ll]ist|item)_0\d-rows?'" />

  <xsl:variable name="hub:recipe-formalpara-heading-role-regex" as="xs:string"
    select="'^Recipe_Headline$'" />

  <xsl:variable name="hub:recipe-formalpara-para-role-regex" as="xs:string"
    select="'^(Recipe_Text-1_No_Headline|Textbox-4_Text)$'" />

  <xsl:variable name="hub:recipe-formalpara-list-role-regex" as="xs:string"
    select="'^Recipe_Item_List_(Numbered|Unordered)(_Sub)*$'" />

  <xsl:variable name="hub:motto-formalpara-para-role-regex" as="xs:string"
    select="'^Motto_Text-1$'" />

  <xsl:variable name="hub:learninggoals-formalpara-heading-role-regex" as="xs:string"
    select="'^LearningGoals_Headline$'" />

  <xsl:variable name="hub:learninggoals-formalpara-para-role-regex" as="xs:string"
    select="'^LearningGoals_Text_1$'" />

  <xsl:variable name="hub:learninggoals-formalpara-list-role-regex" as="xs:string"
    select="'^LearningGoals_Item$'" />

  <xsl:variable name="hub:legaltext-formalpara-heading-role-regex" as="xs:string"
    select="'^Legaltext_Headline$'" />

  <xsl:variable name="hub:legaltext-formalpara-para-role-regex" as="xs:string"
    select="'^Legaltext_Text_1$'" />

  <xsl:variable name="hub:legaltext-formalpara-list-role-regex" as="xs:string"
    select="'^Legaltext_Item$'" />

  <xsl:variable name="hub:question-formalpara-heading-role-regex" as="xs:string"
    select="'^Question_Headline$'" />

  <xsl:variable name="hub:question-formalpara-para-role-regex" as="xs:string"
    select="'^Question_Text-1$'" />

  <xsl:variable name="hub:question-formalpara-list-role-regex" as="xs:string"
    select="'^Question_Item_List_(Numbered|Unordered)$'" />
  
  <xsl:variable name="hub:questionnaire-formalpara-heading-role-regex" as="xs:string"
    select="'^Questionnaire_Headline$'" />
  
  <xsl:variable name="hub:questionnaire-formalpara-para-role-regex" as="xs:string"
    select="'^Questionnaire_(Text_\d|Line)$'" />
  
  <xsl:variable name="hub:questionnaire-formalpara-list-role-regex" as="xs:string"
    select="'^Questionnaire_Item$'" />

  <xsl:variable name="hub:programcode-formalpara-heading-role-regex" as="xs:string"
    select="'^ProgramCode_Headline-1$'" />

  <xsl:variable name="hub:programcode-formalpara-para-role-regex" as="xs:string"
    select="'^ProgramCode_Text-1$'" />

  <xsl:variable name="hub:tip-formalpara-heading-role-regex" as="xs:string"
    select="'^Tip_Headline$'" />

  <xsl:variable name="hub:tip-formalpara-para-role-regex" as="xs:string"
    select="'^Tip_Text_1$'" />

  <xsl:variable name="hub:tip-formalpara-list-role-regex" as="xs:string"
    select="'^Tip_List$'" />

  <xsl:variable name="hub:conclusion-formalpara-heading-role-regex" as="xs:string"
    select="'^Conclusion_Headline$'" />

  <xsl:variable name="hub:conclusion-formalpara-para-role-regex" as="xs:string"
    select="'^Conclusion_Text_1$'" />

  <xsl:variable name="hub:conclusion-formalpara-list-role-regex" as="xs:string"
    select="'^Conclusion_Item$'" />

  <xsl:variable name="hub:result-formalpara-heading-role-regex" as="xs:string"
    select="'^Result_Headline$'" />

  <xsl:variable name="hub:result-formalpara-para-role-regex" as="xs:string"
    select="'^Result_Text[-_]1$'" />

  <xsl:variable name="hub:result-formalpara-list-role-regex" as="xs:string"
    select="'^Result_List[-_]1$'" />

  <xsl:variable name="hub:eyecatcher-formalpara-heading-role-regex" as="xs:string"
    select="'^EyeCatcher_Headline$'" />

  <xsl:variable name="hub:eyecatcher-formalpara-para-role-regex" as="xs:string"
    select="'^EyeCatcher_Text_1$'" />

  <xsl:variable name="hub:eyecatcher-formalpara-list-role-regex" as="xs:string"
    select="'^EyeCatcher_Item$'" />
  
  <xsl:variable name="hub:casestudy-formalpara-heading-role-regex" as="xs:string"
    select="'^Case[-]?Study_Headline.*$'" />

  <xsl:variable name="hub:casestudy-formalpara-para-role-regex" as="xs:string"
    select="'^Case[-]?Study_Text.*$'" />

  <xsl:variable name="hub:casestudy-formalpara-list-role-regex" as="xs:string"
    select="'^Case[-]?Study_List.*$'" />


  <!-- regex-containers -->

  <xsl:variable name="hub:answers-role-regex-container" as="element(hub:regex-container)">
    <hub:regex-container>
      <hub:regex-map regex="{$hub:answers-formalpara-heading-role-regex}" role="Answers" heading="yes"/>
      <hub:regex-map regex="{$hub:answers-formalpara-para-role-regex}" role="Answers" heading="no"/>
      <hub:regex-map regex="{$hub:answers-formalpara-list-role-regex}" role="Answers" heading="no" list="yes"/>
    </hub:regex-container>
  </xsl:variable>

  <xsl:variable name="hub:definition-role-regex-container" as="element(hub:regex-container)">
    <hub:regex-container>
      <hub:regex-map regex="{$hub:definition-formalpara-heading-role-regex}" role="Definition" heading="yes"/>
      <hub:regex-map regex="{$hub:definition-formalpara-para-role-regex}" role="Definition" heading="no"/>
      <hub:regex-map regex="{$hub:definition-formalpara-list-role-regex}" role="Definition" heading="no" list="yes" />
    </hub:regex-container>
  </xsl:variable>

  <xsl:variable name="hub:important-role-regex-container" as="element(hub:regex-container)">
    <hub:regex-container>
      <hub:regex-map regex="{$hub:important-formalpara-heading-role-regex}" role="Important" heading="yes"/>
      <hub:regex-map regex="{$hub:important-formalpara-para-role-regex}" role="Important" heading="no"/>
      <hub:regex-map regex="{$hub:important-formalpara-list-role-regex}" role="Important" heading="no" list="yes" />
    </hub:regex-container>
  </xsl:variable>

  <xsl:variable name="hub:warning-role-regex-container" as="element(hub:regex-container)">
    <hub:regex-container>
      <hub:regex-map regex="{$hub:warning-formalpara-heading-role-regex}" role="Warning" heading="yes"/>
      <hub:regex-map regex="{$hub:warning-formalpara-para-role-regex}" role="Warning" heading="no"/>
      <hub:regex-map regex="{$hub:warning-formalpara-list-role-regex}" role="Warning" heading="no" list="yes"/>
    </hub:regex-container>
  </xsl:variable>

  <xsl:variable name="hub:overview-role-regex-container" as="element(hub:regex-container)">
    <hub:regex-container>
      <hub:regex-map regex="{$hub:overview-formalpara-heading-role-regex}" role="Overview" heading="yes"/>
      <hub:regex-map regex="{$hub:overview-formalpara-para-role-regex}" role="Overview" heading="no"/>
      <hub:regex-map regex="{$hub:overview-formalpara-list-role-regex}" role="Overview" heading="no" list="yes" />
    </hub:regex-container>
  </xsl:variable>

  <xsl:variable name="hub:recipe-role-regex-container" as="element(hub:regex-container)">
    <hub:regex-container>
      <hub:regex-map regex="{$hub:recipe-formalpara-heading-role-regex}" role="Recipe" heading="yes"/>
      <hub:regex-map regex="{$hub:recipe-formalpara-para-role-regex}" role="Recipe" heading="no"/>
      <hub:regex-map regex="{$hub:recipe-formalpara-list-role-regex}" role="Recipe" heading="no" list="yes"/>
    </hub:regex-container>
  </xsl:variable>

  <xsl:variable name="hub:trailer-role-regex-container" as="element(hub:regex-container)">
    <hub:regex-container>
      <hub:regex-map regex="{$hub:trailer-formalpara-heading-role-regex}" role="Trailer" heading="yes"/>
      <hub:regex-map regex="{$hub:trailer-formalpara-para-role-regex}" role="Trailer" heading="no"/>
      <hub:regex-map regex="{$hub:trailer-formalpara-list-role-regex}" role="Trailer" heading="no" list="yes" />
    </hub:regex-container>
  </xsl:variable>

  <xsl:variable name="hub:example-role-regex-container" as="element(hub:regex-container)">
    <hub:regex-container>
      <hub:regex-map regex="{$hub:example-formalpara-heading-role-regex}" role="Example" heading="yes"/>
      <hub:regex-map regex="{$hub:example-formalpara-para-role-regex}" role="Example" heading="no"/>
      <hub:regex-map regex="{$hub:example-formalpara-list-role-regex}" role="Example" heading="no" list="yes" />
    </hub:regex-container>
  </xsl:variable>

  <xsl:variable name="hub:motto-role-regex-container" as="element(hub:regex-container)">
    <hub:regex-container>
      <hub:regex-map regex="{$hub:motto-formalpara-para-role-regex}" role="Motto" heading="no"/>
    </hub:regex-container>
  </xsl:variable>

  <xsl:variable name="hub:learninggoals-role-regex-container" as="element(hub:regex-container)">
    <hub:regex-container>
      <hub:regex-map regex="{$hub:learninggoals-formalpara-heading-role-regex}" role="LearningGoals" heading="yes"/>
      <hub:regex-map regex="{$hub:learninggoals-formalpara-para-role-regex}" role="LearningGoals" heading="no"/>
      <hub:regex-map regex="{$hub:learninggoals-formalpara-list-role-regex}" role="LearningGoals" heading="no" list="yes"/>
    </hub:regex-container>
  </xsl:variable>
  
  <xsl:variable name="hub:legaltext-role-regex-container" as="element(hub:regex-container)">
    <hub:regex-container>
      <hub:regex-map regex="{$hub:legaltext-formalpara-heading-role-regex}" role="LegalText" heading="yes"/>
      <hub:regex-map regex="{$hub:legaltext-formalpara-para-role-regex}" role="LegalText" heading="no"/>
      <hub:regex-map regex="{$hub:legaltext-formalpara-list-role-regex}" role="LegalText" heading="no" list="yes"/>
    </hub:regex-container>
  </xsl:variable>

  <xsl:variable name="hub:question-role-regex-container" as="element(hub:regex-container)">
    <hub:regex-container>
      <hub:regex-map regex="{$hub:question-formalpara-heading-role-regex}" role="Questions" heading="yes"/>
      <hub:regex-map regex="{$hub:question-formalpara-para-role-regex}" role="Questions" heading="no"/>
      <hub:regex-map regex="{$hub:question-formalpara-list-role-regex}" role="Questions" heading="no" list="yes"/>
    </hub:regex-container>
  </xsl:variable>
  
  <xsl:variable name="hub:questionnaire-role-regex-container" as="element(hub:regex-container)">
    <hub:regex-container>
      <hub:regex-map regex="{$hub:questionnaire-formalpara-heading-role-regex}" role="Questionnaire" heading="yes"/>
      <hub:regex-map regex="{$hub:questionnaire-formalpara-para-role-regex}" role="Questionnaire" heading="no"/>
      <!--<hub:regex-map regex="{$hub:questionnaire-formalpara-list-role-regex}" role="Questionnaire" heading="no" list="yes"/>-->
    </hub:regex-container>
  </xsl:variable>

  <xsl:variable name="hub:backgroundinformation-role-regex-container" as="element(hub:regex-container)">
    <hub:regex-container>
      <hub:regex-map regex="{$hub:backgroundinformation-formalpara-heading-role-regex}" role="BackgroundInformation" heading="yes"/>
      <hub:regex-map regex="{$hub:backgroundinformation-formalpara-para-role-regex}" role="BackgroundInformation" heading="no"/>
      <hub:regex-map regex="{$hub:backgroundinformation-formalpara-list-role-regex}" role="BackgroundInformation" heading="no" list="yes"/>
    </hub:regex-container>
  </xsl:variable>

  <xsl:variable name="hub:procedure-role-regex-container" as="element(hub:regex-container)">
    <hub:regex-container>
      <hub:regex-map regex="{$hub:procedure-formalpara-heading-role-regex}" role="Procedure" heading="yes"/>
      <hub:regex-map regex="{$hub:procedure-formalpara-para-role-regex}" role="Procedure" heading="no"/>
      <hub:regex-map regex="{$hub:procedure-formalpara-list-role-regex}" role="Procedure" heading="no" list="yes" />
    </hub:regex-container>
  </xsl:variable>

  <xsl:variable name="hub:programcode-role-regex-container" as="element(hub:regex-container)">
    <hub:regex-container>
      <hub:regex-map regex="{$hub:programcode-formalpara-heading-role-regex}" role="Programcode" heading="yes" is-last-in-group="yes"/>
      <hub:regex-map regex="{$hub:programcode-formalpara-para-role-regex}" role="Programcode" heading="no"/>
    </hub:regex-container>
  </xsl:variable>

  <xsl:variable name="hub:tip-role-regex-container" as="element(hub:regex-container)">
    <hub:regex-container>
      <hub:regex-map regex="{$hub:tip-formalpara-heading-role-regex}" role="Tip" heading="yes"/>
      <hub:regex-map regex="{$hub:tip-formalpara-para-role-regex}" role="Tip" heading="no"/>
      <hub:regex-map regex="{$hub:tip-formalpara-list-role-regex}" role="Tip" heading="no" list="yes"/>
    </hub:regex-container>
  </xsl:variable>

  <xsl:variable name="hub:conclusion-role-regex-container" as="element(hub:regex-container)">
    <hub:regex-container>
      <hub:regex-map regex="{$hub:conclusion-formalpara-heading-role-regex}" role="Conclusion" heading="yes"/>
      <hub:regex-map regex="{$hub:conclusion-formalpara-para-role-regex}" role="Conclusion" heading="no"/>
      <hub:regex-map regex="{$hub:conclusion-formalpara-list-role-regex}" role="Conclusion" heading="no" list="yes"/>
    </hub:regex-container>
  </xsl:variable>

  <xsl:variable name="hub:result-role-regex-container" as="element(hub:regex-container)">
    <hub:regex-container>
      <hub:regex-map regex="{$hub:result-formalpara-heading-role-regex}" role="Results" heading="yes"/>
      <hub:regex-map regex="{$hub:result-formalpara-para-role-regex}" role="Results" heading="no"/>
      <hub:regex-map regex="{$hub:result-formalpara-list-role-regex}" role="Results" heading="no" list="yes"/>
    </hub:regex-container>
  </xsl:variable>
  
  <xsl:variable name="hub:casestudy-role-regex-container" as="element(hub:regex-container)">
    <hub:regex-container>
      <hub:regex-map regex="{$hub:casestudy-formalpara-heading-role-regex}" role="CaseStudy" heading="yes"/>
      <hub:regex-map regex="{$hub:casestudy-formalpara-para-role-regex}" role="CaseStudy" heading="no"/>
      <hub:regex-map regex="{$hub:casestudy-formalpara-list-role-regex}" role="CaseStudy" heading="no" list="yes"/>
    </hub:regex-container>
  </xsl:variable>

  <xsl:variable name="hub:eyecatcher-role-regex-container" as="element(hub:regex-container)">
    <hub:regex-container>
      <hub:regex-map regex="{$hub:eyecatcher-formalpara-heading-role-regex}" role="EyeCatcher" heading="yes"/>
      <hub:regex-map regex="{$hub:eyecatcher-formalpara-para-role-regex}" role="EyeCatcher" heading="no"/>
      <hub:regex-map regex="{$hub:eyecatcher-formalpara-list-role-regex}" role="EyeCatcher" heading="no" list="yes"/>
    </hub:regex-container>
  </xsl:variable>

  <xsl:variable name="special-regex-containers" as="element(*)*"
                select="($hub:answers-role-regex-container,
                         $hub:definition-role-regex-container,
                         $hub:important-role-regex-container,
                         $hub:warning-role-regex-container,
                         $hub:overview-role-regex-container,
                         $hub:recipe-role-regex-container,
                         $hub:trailer-role-regex-container,
                         $hub:example-role-regex-container,
                         $hub:motto-role-regex-container,
                         $hub:learninggoals-role-regex-container,
                         $hub:legaltext-role-regex-container,
                         $hub:question-role-regex-container,
                         $hub:backgroundinformation-role-regex-container,
                         $hub:procedure-role-regex-container,
                         $hub:programcode-role-regex-container,
                         $hub:tip-role-regex-container,
                         $hub:conclusion-role-regex-container,
                         $hub:result-role-regex-container,
                         $hub:eyecatcher-role-regex-container,
                         $hub:questionnaire-role-regex-container,
                         $hub:casestudy-role-regex-container
                        )"/>

  <xsl:template match="*[some $re in $special-regex-containers/* satisfies (some $e in * satisfies (matches($e/@role, $re/@regex)))][not(self::para)]" mode="hub:special-paras">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*" mode="#current" />
      <xsl:call-template name="hub:handle-special-paras">
        <xsl:with-param name="context" select="." />
        <xsl:with-param name="regex-container-pos" select="1" />
      </xsl:call-template>
    </xsl:copy>
  </xsl:template>

  <xsl:template name="hub:handle-special-paras">
    <xsl:param name="context" as="element(*)" />
    <xsl:param name="regex-container-pos" as="xs:integer" />
    <xsl:variable name="regex-container" select="$special-regex-containers[$regex-container-pos]" as="element(hub:regex-container)*" />
    <xsl:for-each-group select="$context/node()" group-adjacent="some $u in $regex-container/hub:regex-map/@regex satisfies matches(@role, $u)">
      <xsl:choose>
        <xsl:when test="current-grouping-key()  and 
                        current-group()
                          [last()]
                          [some $u 
                           in $regex-container/hub:regex-map[@heading='yes'][@is-last-in-group='yes']/@regex
                           satisfies matches(@role, $u)
                          ]  and  
                        count(current-group()) gt 1">
          <xsl:for-each-group select="current-group()" group-ending-with="*[some $u in $regex-container/hub:regex-map[@heading='yes']/@regex satisfies matches(@role, $u)]">
            <xsl:element name="{($regex-container/@container-elementname, 'formalpara')[1]}">
              <xsl:attribute name="role" select="$regex-container/*[1]/@role"/>
              <title>
                <xsl:apply-templates select="current-group()[last()]/@srcpath, node()" mode="#current" />
              </title>
              <xsl:apply-templates select="current-group()[position() lt last()]" mode="#current" />
            </xsl:element>
          </xsl:for-each-group>
        </xsl:when>
        <xsl:when test="current-grouping-key()  and  current-group()[1][some $u in $regex-container/hub:regex-map[@heading='yes']/@regex satisfies matches(@role, $u)]  and  count(current-group()) gt 1">
          <xsl:for-each-group select="current-group()" group-starting-with="*[some $u in $regex-container/hub:regex-map[@heading='yes']/@regex satisfies matches(@role, $u)]">
            <xsl:element name="{($regex-container/@container-elementname, 'formalpara')[1]}">
              <xsl:attribute name="role" select="$regex-container/*[1]/@role"/>
              <title>
                <xsl:apply-templates select="current-group()[1]/@srcpath, node()" mode="#current" />
              </title>
              <xsl:apply-templates select="current-group()[position() gt 1]" mode="#current" />
            </xsl:element>
          </xsl:for-each-group>
        </xsl:when>
        <xsl:when test="current-grouping-key()">
          <xsl:element name="{($regex-container/@container-elementname, 'formalpara')[1]}">
            <xsl:attribute name="role" select="$regex-container/*[1]/@role"/>
            <xsl:apply-templates select="current-group()" mode="#current" />
          </xsl:element>
        </xsl:when>
        <!-- no node in current-group conforms to the current hub:regex-container -->
        <xsl:otherwise>
          <xsl:choose>
            <!-- other hub:regex-container`s matching nodes in current-group -->
            <xsl:when test="some $re in $special-regex-containers[position() ge $regex-container-pos + 1]/* 
                            satisfies (
                              some $e in current-group()
                              satisfies matches($e/@role, $re/@regex)
                            )">
              <xsl:call-template name="hub:handle-special-paras">
                <xsl:with-param name="context" as="element(*)">
                  <tmp>
                    <xsl:sequence select="current-group()"/>
                  </tmp>
                </xsl:with-param>
                <xsl:with-param name="regex-container-pos" select="$regex-container-pos + 1" />
              </xsl:call-template>
            </xsl:when>
            <!-- leave template hub:handle-special-paras, just apply nodes in mode hub:specia-paras -->
            <xsl:otherwise>
              <xsl:apply-templates select="current-group()" mode="#current" />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each-group>
  </xsl:template>

  <xsl:template match="styles" mode="hub:special-paras" priority="10">
    <xsl:sequence select="."  />
  </xsl:template>
  
  <!-- If a paragraph contains only one inlineequation, then it should be a regular equation. -->
  <xsl:template match="para/inlineequation[position() eq 1 and position() eq last()]" mode="hub:special-paras">
    <equation>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </equation>
  </xsl:template>

  <xsl:template match="para[
                         matches(@role, $hub:definition-formalpara-heading-role-regex)
                         and not(
                           following-sibling::node()[1]/self::*[matches(@role, $hub:definition-formalpara-para-role-regex)]
                         )
                         and matches(., $hub:formalpara-sep-regex)
                       ]" mode="hub:special-paras">
    <xsl:variable name="with-sep" as="element(para)" select="hub:insert-sep(., $hub:formalpara-sep-regex)" />
    <xsl:variable name="leaves" select="$with-sep//node()[not(*)]" as="node()*" />
    <xsl:variable name="sep" select="$with-sep//hub:sep" as="element(hub:sep)+" />
    <formalpara role="definition-split">
      <xsl:apply-templates select="@* except @role" mode="#current"/>
      <title>
        <xsl:variable name="local-leaves" select="$leaves[. &lt;&lt; $sep[1]]" as="node()*" />
        <xsl:apply-templates select="$with-sep/node()" mode="hub:upward-project">
          <xsl:with-param name="restricted-to" select="$local-leaves/ancestor-or-self::node()" tunnel="yes" />
        </xsl:apply-templates>
      </title>
      <xsl:if test="$leaves[. &gt;&gt; $sep[1]][not(self::hub:sep)]">
        <xsl:copy>
          <xsl:apply-templates select="@* except (@role, @srcpath)" />
          <xsl:variable name="local-leaves" select="$leaves[. &gt;&gt; $sep[1]][not(self::hub:sep)]" as="node()*" />
          <xsl:apply-templates select="$with-sep/node()" mode="hub:upward-project">
            <xsl:with-param name="restricted-to" select="$local-leaves/ancestor-or-self::node()" tunnel="yes" />
          </xsl:apply-templates>
        </xsl:copy>
      </xsl:if>
    </formalpara>
  </xsl:template>

  <xsl:variable name="hub:remove-special-cstyle-role-regex" as="xs:string"
    select="'^EyeCatcher_Balken$'"/>

  <xsl:template match="phrase[matches(@role, $hub:remove-special-cstyle-role-regex)]" mode="hub:special-paras" />

  <xsl:variable name="hub:indexdiv-role-regex" as="xs:string"
    select="'^(Index-Head|Index_Head|Index Section Head)$'"/>

  <xsl:variable name="hub:primaryie-role-regex" as="xs:string"
    select="'^(Indexebene-1|Index[_-]1|Index\sLevel\s1)$'"/>
  
  <xsl:variable name="hub:secondaryie-role-regex" as="xs:string"
    select="'^(Indexebene-2|Index[_-]2|Index\sLevel\s2)$'"/>
  
  <xsl:variable name="hub:tertiaryie-role-regex" as="xs:string"
    select="'^Indexebene?-3|Index[_-]3$'"/>
  
  <xsl:variable name="hub:see-indexentry-text-regex" as="xs:string"
    select="'\s*(See|Siehe)\s*'"/>
  
  <xsl:template match="*[para[matches(@role, $hub:indexdiv-role-regex)]]" mode="hub:special-paras">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:for-each-group select="node()" group-starting-with="para[matches(@role, $hub:indexdiv-role-regex)]">
        <xsl:choose>
          <xsl:when test="self::para[matches(@role, $hub:indexdiv-role-regex)]">
            <indexdiv>
              <title>
                <xsl:apply-templates select="node()" mode="#current"/>
              </title>
              <xsl:apply-templates select="current-group()[position() gt 1]" mode="#current"/>
            </indexdiv>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="current-group()" mode="#current"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="para[matches(@role, $hub:primaryie-role-regex)]" mode="hub:special-paras">
    <primaryie>
      <xsl:apply-templates mode="#current"/>
    </primaryie>
  </xsl:template>

  <xsl:template match="para[matches(@role, $hub:secondaryie-role-regex)]" mode="hub:special-paras">
    <secondaryie>
      <xsl:apply-templates mode="#current"/>
    </secondaryie>
  </xsl:template>

  <xsl:template match="para[matches(@role, $hub:tertiaryie-role-regex)]" mode="hub:special-paras">
    <tertiaryie>
      <xsl:apply-templates mode="#current"/>
    </tertiaryie>
  </xsl:template>

  <xsl:template match="para[@role = 'Parttitle_Backmatter']" mode="hub:special-paras">
  </xsl:template>
  
  <!-- mode: hub:special-phrases -->

  <!-- ToDo: import Wingdings font map as external -->
  <xsl:variable name="hub:wingdings-phrase-role-regex" select="'Symbolphrase-to-evolve'" as="xs:string"/>
  <xsl:variable name="hub:wingdings-font-map" select="if (doc-available('http://transpect.io/evolve-hub/fontmaps/Wingdings.xml')) then document('http://transpect.io/evolve-hub/fontmaps/Wingdings.xml')/symbols/symbol else ()" as="node()*"/>
  
  <xsl:template match="phrase[matches(@role,$hub:wingdings-phrase-role-regex)]" mode="hub:special-phrases">
    <xsl:variable name="text" select="text()"/>
    <xsl:variable name="role" select="@role"/>
    <xsl:variable name="chars" as="xs:string *">
      <xsl:for-each select="1 to string-length($text)">
        <xsl:sequence select="substring($text,.,1)"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:for-each select="$chars">
      <xsl:choose>
        <xsl:when test="$hub:wingdings-font-map[@entity = current()]">
          <xsl:value-of select="translate(.,$hub:wingdings-font-map[@entity = current()]/@entity,$hub:wingdings-font-map[@entity = current()]/@char)"/>
        </xsl:when>
        <xsl:when test="matches(.,'[\s&#160;&#8194;&#8195;]')">
          <xsl:value-of select="."/>
        </xsl:when>
        <xsl:otherwise>
          <phrase>
            <xsl:attribute name="role" select="$role"/>
            <xsl:value-of select="."/>
          </phrase>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <!-- ToDo: import Symbol font map as external -->
  <xsl:variable name="hub:symbol-phrase-role-regex" select="'Symbolphrase-to-evolve'" as="xs:string"/>
  <xsl:variable name="hub:symbol-font-map" select="if (doc-available('http://transpect.io/evolve-hub/fontmaps/Symbol.xml')) then document('http://transpect.io/evolve-hub/fontmaps/Symbol.xml')/symbols/symbol else ()" as="node()*"/>
  <xsl:template match="phrase[matches(@role,$hub:symbol-phrase-role-regex)]" mode="hub:special-phrases">
    <xsl:variable name="text" select="text()"/>
    <xsl:variable name="role" select="@role"/>
    <xsl:variable name="chars" as="xs:string *">
      <xsl:for-each select="1 to string-length($text)">
        <xsl:sequence select="substring($text,.,1)"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:for-each select="$chars">
      <xsl:choose>
        <xsl:when test="$hub:symbol-font-map[@entity = current()]">
          <xsl:value-of select="translate(.,$hub:symbol-font-map[@entity = current()]/@entity,$hub:symbol-font-map[@entity = current()]/@char)"/>
        </xsl:when>
        <xsl:when test="matches(.,'[\s&#160;&#8194;&#8195;]')">
          <xsl:value-of select="."/>
        </xsl:when>
        <xsl:otherwise>
          <phrase>
            <xsl:attribute name="role" select="$role"/>
            <xsl:value-of select="."/>
          </phrase>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <!-- mode: hub:blockquotes -->

  <xsl:variable name="hub:blockquote-role-regex" as="xs:string"
    select="'^Bodytext[-_\s]Zitat'" />
  
  <xsl:variable name="hub:blockquote-heading-role-regex" as="xs:string"
    select="'^Headline[-_\s]Special-2$'" />
  
  <xsl:template match="*[not(self::blockquote)][para[matches(@role, $hub:blockquote-role-regex)]]" 
    name="build-blockquotes" mode="hub:blockquotes" xmlns="http://docbook.org/ns/docbook">
    <xsl:param name="wrapper-element-name" select="name()" as="xs:string" tunnel="no"/>
    <xsl:element name="{$wrapper-element-name}">
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:for-each-group select="node()" group-adjacent="exists(self::para[matches(@role, $hub:blockquote-role-regex)])">
        <xsl:choose>
          <xsl:when test="current-grouping-key()">
            <blockquote>
              <xsl:if test="current-group()[1]/preceding-sibling::node()[1]/self::para[matches(@role, $hub:blockquote-heading-role-regex)]">
                <title>
                  <xsl:apply-templates select="current-group()[1]/preceding-sibling::node()[1]/node()" mode="#current"/>
                </title>
              </xsl:if>
              <xsl:apply-templates select="current-group()" mode="#current"/>
            </blockquote>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="current-group()" mode="#current"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
    </xsl:element>
  </xsl:template>

  <xsl:template match="para[
                         matches(@role, $hub:blockquote-heading-role-regex)
                         and following-sibling::node()[1]/self::para[matches(@role, $hub:blockquote-role-regex)]
                       ]" mode="hub:blockquotes" />

  <xsl:template match="para[matches(@role, $hub:blockquote-role-regex)]
                       /@*[name() = ('role', 'css:margin-left', 'css:text-indent')]" mode="hub:blockquotes" />


  <!-- mode: hub:split-at-tab -->
	<!-- Optional mode that will split phrases and other elements within a para that contains
       tabs, such that the tabs become immediate children of the para. -->

  <xsl:variable name="hub:split-at-tab-element-names" as="xs:string+"
    select="('para', 'simpara', 'title')"/>

  <xsl:template match="*[local-name() = $hub:split-at-tab-element-names]
                        /*[not(local-name() = $hub:same-scope-element-names)][
                        .//tab[not(parent::tabs)][
                           hub:same-scope(., current())
                         ]
                       ]" mode="hub:split-at-tab">
    <xsl:variable name="context" select="." as="element(*)" />
  	<xsl:variable name="processed-content" as="document-node()">
  		<xsl:document>
		    <xsl:for-each-group
		      select="descendant::node()[
                                not(node())
                                or self::tab[not(parent::tabs)]
                                or local-name() = $hub:same-scope-element-names
                                or self::tabs 
                                ][hub:same-scope(., current()/..)]"
		      group-starting-with="tab">
		      <xsl:sequence select="current-group()/self::tab"/>
		      <xsl:variable name="upward-projected" as="element(*)">
		        <xsl:apply-templates select="$context" mode="hub:upward-project-tab">
		          <xsl:with-param name="restricted-to" select="current-group()/ancestor-or-self::node()[not(self::tab)]" tunnel="yes"/>
		        </xsl:apply-templates>
		      </xsl:variable>
		      <xsl:if test="$upward-projected/node()">
		        <xsl:sequence select="$upward-projected"/>
		      </xsl:if>
		    </xsl:for-each-group>
  		</xsl:document>
    </xsl:variable>
  	<xsl:apply-templates select="$processed-content/node()" mode="hub:postprocess-splitted-tabs">
  		<xsl:with-param name="elements-with-srcpaths" as="element(*)*" tunnel="yes" select="key('hub:element-by-srcpath', $processed-content//@srcpath, $processed-content)"/>
  	</xsl:apply-templates>
  </xsl:template>

	<xsl:key name="hub:element-by-srcpath" match="*" use="@srcpath"/>
	
	<xsl:template match="*[@srcpath]" mode="hub:postprocess-splitted-tabs">
		<xsl:param name="elements-with-srcpaths" as="element(*)*" tunnel="yes" />
			<xsl:copy>
				<xsl:sequence select="@* except @srcpath" />
				<xsl:attribute name="srcpath" select="if (count(for $elt in $elements-with-srcpaths return $elt[@srcpath = current()/@srcpath]) gt 1) then concat(@srcpath, ';n=', position()) else @srcpath"/>
				<xsl:apply-templates mode="#current" />
			</xsl:copy>
	</xsl:template>
	
  <xsl:template match="node()" mode="hub:upward-project-tab">
    <xsl:param name="restricted-to" as="node()+" tunnel="yes" />
    <xsl:if test="exists(. intersect $restricted-to)">
      <xsl:copy>
        <xsl:apply-templates select="@*" mode="hub:split-at-tab" />
        <xsl:apply-templates mode="#current" />
      </xsl:copy>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="*[local-name() = $hub:same-scope-element-names]" mode="hub:upward-project-tab">
    <xsl:param name="restricted-to" as="node()+" tunnel="yes" />
    <xsl:if test="exists(. intersect $restricted-to)">
      <xsl:apply-templates select="." mode="hub:split-at-tab" />
    </xsl:if>
  </xsl:template>

  <xsl:template match="tabs" mode="hub:upward-project-tab">
    <xsl:sequence select="."/>
  </xsl:template>
    
  <!-- mode: hub:right-tab-to-tables -->
  <!-- Optional mode that creates two-columns informaltables with the role hub:right-tab of 
       adjacent paras with right tabs. There is no preferred point in the pipeline when this 
       mode should run. Maybe run it before lists. Requires that hub:split-at-tab has run before. -->
  <xsl:template match="*[*[local-name() = $hub:split-at-tab-element-names][tab[@role = 'right'][not(preceding-sibling::*[local-name() = 'br'])]]]"
    mode="hub:right-tab-to-tables"  priority="3">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:for-each-group select="*" 
        group-adjacent="exists(self::*[local-name() = $hub:split-at-tab-element-names][tab[@role = 'right'][not(preceding-sibling::*[local-name() = 'br'])]])">
        <xsl:choose>
          <xsl:when test="current-grouping-key() and current-group()[every $tab in tab[@role = 'right']/following-sibling::node()[1] satisfies matches($tab, $hub:post-identifier-regex, 'x')]">
            <xsl:apply-templates select="current-group()" mode="#current">
              <xsl:with-param name="set-post-identifier" as="xs:boolean" tunnel="yes" select="true()"/>
            </xsl:apply-templates>
          </xsl:when>
          <xsl:when test="current-grouping-key()">
            <informaltable role="hub:right-tab">
              <tgroup cols="2">
                <colspec colname="c1"/>
                <colspec colname="c2"/>
                <tbody>
                  <xsl:apply-templates select="current-group()" mode="#current"/>
                </tbody>
              </tgroup>
            </informaltable>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="current-group()" mode="#current"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*[local-name() = $hub:split-at-tab-element-names][tab[@role = 'right'][not(preceding-sibling::*[local-name() = 'br'])]]"
    mode="hub:right-tab-to-tables" priority="3">
    <xsl:param name="set-post-identifier" as="xs:boolean?" tunnel="yes"/>
    <xsl:choose>
      <xsl:when test="$set-post-identifier">
        <xsl:copy copy-namespaces="no">
          <xsl:sequence select="@*"/>
          <xsl:apply-templates select="tab[@role = 'right'][last()]/preceding-sibling::node()" mode="#current"/>
        <xsl:element name="phrase">
            <xsl:attribute name="role" select="'hub:post-identifier'"/>
            <xsl:apply-templates select="tab[@role = 'right'][last()]/following-sibling::node()" mode="#current"/>
          </xsl:element>
        </xsl:copy>
      </xsl:when>
      <xsl:otherwise>
        <row>
          <entry colname="c1" >
            <simpara>
              <xsl:sequence select="@srcpath"/>
              <xsl:apply-templates select="tab[@role = 'right'][last()]/preceding-sibling::node()" mode="#current"/>
            </simpara>
          </entry>
        <entry colname="c2" role="right-align">
            <simpara>
              <xsl:apply-templates select="tab[@role = 'right'][last()]/following-sibling::node()" mode="#current"/>
            </simpara>
          </entry>
        </row>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:variable name="hub:post-identifier-regex" select="'^\p{Lu}\d+\.\d+$'" as="xs:string">
    <!-- This regex controls whether to create a table or only a phrase @role="hub:post-identifier". The above case covers string like F8.90 -->
  </xsl:variable>
  
  <!-- mode: hub:repair-hierarchy
       don't nest sidebars -->
  <xsl:template match="sidebar[not(@remap)][descendant::sidebar[not(@remap)]]"
    mode="hub:repair-hierarchy" priority="2">
    <xsl:variable name="bad-section" select="(descendant::sidebar[not(@remap)])[last()]"/>
    <xsl:if test="$bad-section/following-sibling::node()">
      <xsl:message>
        Cannot move nested sidebar up because it is not its parent element's last node.
        <xsl:sequence select="$bad-section"/>
      </xsl:message>
    </xsl:if>
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:apply-templates select="node()" mode="#current">
        <xsl:with-param name="ignore" select="$bad-section" tunnel="yes" />
      </xsl:apply-templates>
    </xsl:copy>
    <xsl:apply-templates select="$bad-section" mode="#current"/>
  </xsl:template>

  <xsl:template match="sidebar[not(@remap)]" mode="hub:repair-hierarchy">
    <xsl:param name="ignore" as="element(sidebar)?" tunnel="yes" />
    <xsl:if test="not(. is $ignore)">
      <xsl:copy>
        <xsl:apply-templates select="@*, node()" mode="#current"/>
      </xsl:copy>
    </xsl:if>
  </xsl:template>

  <!-- Hierarchiesprünge -->
  <xsl:template match="section[not(title) and (every $x in node() satisfies $x/self::section)]" mode="hub:repair-hierarchy">
    <xsl:param name="step-count" select="0" tunnel="yes"/>
    <xsl:apply-templates mode="#current">
      <xsl:with-param name="step-count" select="$step-count + 1" tunnel="yes"/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="section[title and parent::section[not(title) and (every $x in node() satisfies $x/self::section)]]" mode="hub:repair-hierarchy">
    <xsl:param name="step-count" select="0" tunnel="yes"/>
    <xsl:copy>
      <xsl:attribute name="renderas" select="$step-count"/>
      <xsl:apply-templates select="@* | node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:variable name="dont-repair-hierarchy-elements-regex" select="'^formalpara|sidebar|table|figure$'"/>
  
  <xsl:template match="title[not(parent::*[matches(local-name(),$dont-repair-hierarchy-elements-regex)]) and not(@role)][../@role]" mode="hub:repair-hierarchy">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current" />
      <xsl:sequence select="../@role"/>
      <xsl:apply-templates mode="#current" />
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*[not(self::*[matches(local-name(),$dont-repair-hierarchy-elements-regex)])][@role][title[not(@role)]]/@role" mode="hub:repair-hierarchy" />

  <!-- collateral: -->
  <xsl:variable name="hub:chapter-title-role-regex" as="xs:string"
    select="'^Chaptertitle([-_\s]\d[-_\s]row)?|Chapter[-_\s]Title|Chapter[-_\s]Title[-_\s]TOC|Chapter[-_\s]Title[-_\s]Backmatter|Chapter-Title[-_\s]Frontmatter|Chaptername[-_\s]Backmatter|Chapter-Title|Chapter-Title[-_\s]Text|Chaptername[-_\s]Contents$'" />
  <xsl:template match="chapter[
                         para[
                           matches(@role, $hub:chapter-title-role-regex)
                         ]
                       ]" mode="hub:repair-hierarchy">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current" />
      <xsl:apply-templates select="para[matches(@role, $hub:chapter-title-role-regex)],
                                   info, 
                                   toc,
                                   node()[
                                     not(self::toc) 
                                     and not(self::info) 
                                     and not(self::para[matches(@role, $hub:chapter-title-role-regex)])
                                   ]" mode="#current" />
    </xsl:copy>
  </xsl:template>

  <xsl:template match="para[
                         matches(@role, $hub:chapter-title-role-regex)
                       ]" mode="hub:repair-hierarchy">
    <title>
      <xsl:apply-templates select="@* except @role, node()" mode="#current"/>
    </title>
  </xsl:template>

  <!-- collateral -->
  <xsl:variable name="hub:no-cstyle-regex" as="xs:string"
    select="'^No[-_\s]character[-_\s]style$'" />
  
  <xsl:template match="phrase[matches(@role, $hub:no-cstyle-regex)][empty(@css:* | @xml:lang | @condition)]" mode="hub:preprocess-hierarchy">
    <xsl:apply-templates mode="#current" />
  </xsl:template>
  
  <!-- collateral: remove separators in footnotes if only identifier (or nothing) is before -->
  <xsl:template match="footnote/para/*[@role = 'hub:separator']
                                      [every $preceding in preceding-sibling::node() satisfies
                                       ($preceding/@role = 'hub:identifier')]"
                mode="hub:preprocess-hierarchy"/>
  
  <!-- Collateral: normalize @xml:lang, stripping the country or other suffixes -->
  <xsl:template match="@xml:lang[matches(., '^(\p{Ll}+).*$')]" mode="hub:group-environments hub:split-at-tab">
    <xsl:attribute name="{name()}" select="replace(., '^(\p{Ll}+).*$', '$1')"/>
  </xsl:template>

  <xsl:template match="emphasis[matches(., '^\d+$')][every $a in @* satisfies ($a/self::attribute(srcpath) or $a/self::attribute(xml:lang))]" mode="hub:hierarchy">
    <xsl:apply-templates mode="#current" />
  </xsl:template>
  
  <!-- thead (a bit collateral, too) -->
  <xsl:variable name="hub:thead-pstyle-regex" as="xs:string"
    select="'^Table[-_\s]Head'" />
  
  <xsl:variable name="hub:pstyle-regex" as="xs:string"
    select="'^Table[-_\s](Head|Body)'" />
  
  <xsl:template match="tgroup[tbody/row/entry/para[matches(@role, $hub:thead-pstyle-regex)]]" mode="hub:repair-hierarchy">
    <xsl:variable name="attribs" select="@*"/>
    <xsl:variable name="colspecs" select="colspec"/>
    <xsl:variable name="existing-thead" select="thead"/>
    <tgroup>
      <xsl:sequence select="$attribs"/>
      <xsl:sequence select="$colspecs"/>
      <xsl:for-each-group select="tbody/row" group-starting-with="row[hub:is-first-thead-row(.)]">
        <xsl:choose>
          <xsl:when test="self::row[hub:is-first-thead-row(.)]">
           
              <xsl:for-each-group select="current-group()" group-adjacent="exists(entry/para) 
                                                                           and (
                                                                             every $x in entry/para satisfies
                                                                               (matches($x/@role, $hub:thead-pstyle-regex))
                                                                           )">
                <xsl:choose>
                  <xsl:when test="current-grouping-key()">
                    <thead>
                      <!--<xsl:apply-templates select="$existing-thead/node()" mode="#current"/>-->
                      <xsl:apply-templates select="current-group()" mode="#current"/>
                    </thead>
                  </xsl:when>
                  <xsl:otherwise>
                    <tbody>
                      <xsl:apply-templates select="current-group()" mode="#current"/>
                    </tbody>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:for-each-group>
          </xsl:when>
          <xsl:otherwise>
             <xsl:apply-templates select="$existing-thead" mode="#current"/>
             <tbody>
               <xsl:apply-templates select="current-group()" mode="#current"/>
             </tbody>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
      <xsl:apply-templates select="tfoot" mode="#current"/>
    </tgroup>
  </xsl:template>

  <xsl:function name="hub:is-first-thead-row" as="xs:boolean">
    <xsl:param name="row" as="element(row)" />
    <xsl:sequence select="exists(
                            $row
                              [entry/para]
                              [every $x in entry/para satisfies
                                (matches($x/@role, $hub:thead-pstyle-regex))]
                              [empty(
                                preceding-sibling::row[1]
                                  [entry/para]
                                  [every $x in entry/para satisfies
                                    (matches($x/@role, $hub:thead-pstyle-regex))]
                              )]
                          )" />
  </xsl:function>

  <xsl:template match="entry/para/@role[matches(., $hub:pstyle-regex)]" mode="hub:repair-hierarchy"/>

  <xsl:template match="link[@remap = 'HyperlinkTextDestination']
                         [$remove-HyperlinkTextDestination-links eq 'yes']" mode="hub:repair-hierarchy">
    <xsl:choose>
      <xsl:when test="matches(.,concat('^',$hub:figure-caption-start-regex,'[\s&#160;]*[0-9.-]+[a-z,]*'))">
        <phrase>
          <xsl:attribute name="role" select="'ID_Querverweis_Figure'"/>
          <xsl:apply-templates mode="#current" />
        </phrase>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates mode="#current" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
<!--   <xsl:template match="link[@remap = 'HyperlinkTextDestination'] -->
<!--                          [$remove-HyperlinkTextDestination-links eq 'yes']" mode="hub:repair-hierarchy"> -->
<!--     <xsl:apply-templates mode="#current" /> -->
<!--   </xsl:template> -->

  <!-- do not use brackets '(', ')' or change templates using this regex -->
  <xsl:variable name="hub:figure-caption-start-regex" as="xs:string"
     select="'Bild|Abbildung|Abbildungen|Abb\.|Figuu?res?|Figs?\.?'"/>

  <!-- do not use brackets '(', ')' or change templates using this regex -->
  <xsl:variable name="hub:table-caption-start-regex" as="xs:string"
     select="'Tab\.|Tabellen?|Tabel|Tables?'"/>

  <!-- do not use brackets '(', ')' or change templates using this regex -->
  <xsl:variable name="hub:listing-caption-start-regex" as="xs:string"
     select="'Listing'"/>

  <!-- var hub:caption-sep-regex usage: 
       Separator between caption-start text (Fig, Table, ...) and caption-number. §§§.
       It´s not a sep between caption-num and caption-text (so, we should change the name?) -->
  <xsl:variable name="hub:caption-sep-regex" as="xs:string"
    select="'[&#x2002;&#xa0;&#x202F;\p{Zs}]+'"/>

  <xsl:variable name="hub:caption-number-regex" as="xs:string"
    select="'A?[0-9]+(\.[0-9]+)*[&#x2009;&#x202F;]?[a-z,A-Z&#x2011;&#x2013;&#x202F;-]*'" />

  <!-- §§§ 'without-sep-regex' using sep-regex: rename caption-sep-regex variable! -->
  <xsl:variable name="hub:caption-number-without-sep-regex" as="xs:string"
    select="concat(
              '^(', $hub:figure-caption-start-regex, '|', $hub:table-caption-start-regex, '|', $hub:listing-caption-start-regex, ')(', $hub:caption-sep-regex, ')(', $hub:caption-number-regex, ')'
            )" />

  <xsl:variable name="hub:caption-sep-among-caption-number-and-caption-text-regex_non-optional" as="xs:string"
    select="'[ .:&#xa0;&#x2002;&#8212;]'"/>

  <xsl:variable name="hub:caption-sep-among-caption-number-and-caption-text-regex" as="xs:string"
    select="concat($hub:caption-sep-among-caption-number-and-caption-text-regex_non-optional, '?')"/>

  <!-- §§§ to clarify: what is a 'sep' in captions? Isn`t <tab/> a separator? -->
  <xsl:variable name="hub:caption-number-plus-sep-regex" as="xs:string"
    select="concat( 
              $hub:caption-number-without-sep-regex, 
              $hub:caption-sep-among-caption-number-and-caption-text-regex
            )" />

  <xsl:template match="para[* and count(node()) eq count(formalpara)]" mode="hub:repair-hierarchy">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <xsl:template match="*[primaryie]" mode="hub:repair-hierarchy">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:for-each-group select="node()" group-starting-with="*[self::primaryie or self::indexdiv]">
        <xsl:choose>
          <xsl:when test="current-group()[1][self::primaryie]">
            <indexentry>
              <xsl:apply-templates select="current-group()" mode="#current"/>
            </indexentry>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="current-group()" mode="#current"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>

  <!-- first node in figure or table title is an indexterm: move the indexterm at end of title -->
  <xsl:template match="*[self::table or self::figure or self::section]
                         /title[node()[1][self::indexterm or self::anchor[not(@xml:id and matches(@xml:id, '^(cell)?page_'))]]]" mode="hub:repair-hierarchy" priority="1">
    <xsl:variable name="first-valid-node-in-title" select="node()[not(self::indexterm or self::anchor)][preceding-sibling::*[self::indexterm or self::anchor]][1]" as="node()?"/>
    <xsl:copy>
      <xsl:choose>
        <xsl:when test="empty($first-valid-node-in-title)">
          <xsl:message select="'EVOLVE WARNING:', local-name(), 'consists of critical element(s):', node()"/>
          <xsl:apply-templates select="@*, node()" mode="#current" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test="parent::section and not(@role) and ../@role">
            <xsl:attribute name="role" select="../@role"/>
          </xsl:if>
          <xsl:apply-templates select="@*, $first-valid-node-in-title, 
                                       node()[ . &gt;&gt; $first-valid-node-in-title], 
                                       node()[ . &lt;&lt; $first-valid-node-in-title]" mode="#current" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="preface/@renderas | bibliography/@renderas" mode="hub:repair-hierarchy"/>
  
  
  <!-- mode: hub:identifiers -->

  <xsl:variable name="hub:figure-caption-must-begin-with-figure-caption-start-regex"  as="xs:boolean"
    select="true()" />

  <xsl:template match="keywordset[@role eq 'hub']" mode="hub:identifiers">
    <xsl:copy>
      <xsl:sequence select="@*" />
      <xsl:apply-templates select="keyword except keyword[@role eq 'marked-identifiers']" mode="#current" />
      <keyword role="marked-identifiers">true</keyword>
    </xsl:copy>
  </xsl:template>

  <!-- there was a conflict with what is now in line 2239; arbitrarily decreasing this template’s priority --> 
  <xsl:template match="text()
                       [not(ancestor::*[matches(@role, $hub:no-identifier-needed)])]
		                   [not(ancestor::phrase[hub:same-scope(current(), .)][@role eq 'hub:identifier'])]
		                   [not(ancestor::*:math)]
		                   [
                         matches(., $hub:itemizedlist-mark-at-start-regex) 
                         and ancestor::para[xs:double(@margin-left) gt $hub:indent-epsilon]
                                           [(count(.//tab[hub:same-scope(., current()/ancestor::para[1])]/preceding-sibling::node()[self::text() or self::*][not(self::dbk:anchor)]) =1) 
                                            or (position()=1 and matches((.//text())[1],'\s+$'))
                                           ]
                         and . is (ancestor::para[1]//text())[1]
                       ]" mode="hub:identifiers" priority="0.4">
    <xsl:variable name="context" select="." as="text()" />
    <xsl:analyze-string select="." regex="{$hub:itemizedlist-mark-at-start-regex}" flags="s">
      <xsl:matching-substring>
        <phrase role="hub:identifier">
          <xsl:sequence select="hub:set-origin($set-debugging-info-origin, 'itemizedlistmark-and-ancer')"/>
          <xsl:value-of select="regex-group(1)" />
        </phrase>
        <xsl:if test="not($context/following-sibling::node()[1]/self::tab)">
          <tab>
            <xsl:text>&#9;</xsl:text>
          </tab>
        </xsl:if>
      </xsl:matching-substring>
      <xsl:non-matching-substring>
        <xsl:value-of select="." />
      </xsl:non-matching-substring>
    </xsl:analyze-string>
  </xsl:template>


  <!-- Example: <para><phrase>1.</phrase><tab/><phrase>Text</phrase></para>
       This is the result of hub:split-at-tab -->
  <xsl:template match="phrase[not(@role eq 'hub:identifier')]
                             [not(ancestor::phrase[@role eq 'hub:identifier'][hub:same-scope(current(), .)])]
                             [not(ancestor::*[matches(@role, $hub:no-identifier-needed)])]
                             [
                               (
                                 matches(., $hub:orderedlist-mark-regex)
                                 or
                                 matches(., $hub:itemizedlist-mark-regex)
                               )
                               and (
                                 ancestor::para[xs:double(@margin-left) gt $hub:indent-epsilon]
                                 or
                                 ancestor::tocentry
                               )
                               and (
                                 (. is (ancestor::*[self::para or self::tocentry][1]//node())[1]) 
                                 or (
                                (: preceding-sibling::node()[not(self::text()[matches(., '^\s+$')])][1]/self::anchor[. is ancestor::*[self::para or self::tocentry][1]//node()[not(self::text()[matches(., '^\s+$')])][1]] :) 
                                 every $item in preceding-sibling::node() satisfies ($item/self::text()[matches(., '^\s+$')] or $item[self::anchor or self::tabs])
                                 
                                 )
                               )
                               and following-sibling::node()[not(self::text()[matches(., '^\s+$')])][1]/self::tab
                             ]" mode="hub:identifiers">
    <xsl:choose>
      <xsl:when test="not(@*) or (every $a in @* satisfies $a/name() = ('srcpath', 'xml:lang'))">
        <phrase role="hub:identifier">
          <xsl:sequence select="hub:set-origin($set-debugging-info-origin, 'phrase-not-identif-yet-1')"/>
          <xsl:apply-templates select="@*" mode="#current"/>
          <xsl:sequence select="node()"/><!-- no apply-templates here because otherwise the following template will catch -->
        </phrase>
      </xsl:when>
      <xsl:otherwise>
        <phrase role="hub:identifier">
          <xsl:sequence select="hub:set-origin($set-debugging-info-origin, 'phrase-not-identif-yet-o')"/>
          <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:sequence select="node()"/><!-- no apply-templates here because otherwise the following template will catch -->
          </xsl:copy>
        </phrase>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="link[every $n in node() 
                            satisfies ($n
                                        [self::phrase[not(@role eq 'hub:identifier')]]
                                        [not(ancestor::phrase[@role eq 'hub:identifier'][hub:same-scope(current(), .)])]
                                        [not(ancestor::*[matches(@role, $hub:no-identifier-needed)])]
                                        [
                                          (
                                            matches(., $hub:orderedlist-mark-regex)
                                            or
                                            matches(., $hub:itemizedlist-mark-regex)
                                          )
                                          and (
                                            ancestor::para[xs:double(@margin-left) gt $hub:indent-epsilon]
                                            or
                                            ancestor::tocentry
                                          )
                                          and (
                                            (. is (ancestor::*[self::para or self::tocentry][1]//node())[1]) 
                                            or (
                                           (: preceding-sibling::node()[not(self::text()[matches(., '^\s+$')])][1]/self::anchor[. is ancestor::*[self::para or self::tocentry][1]//node()[not(self::text()[matches(., '^\s+$')])][1]] :) 
                                            every $item in preceding-sibling::node() satisfies ($item/self::text()[matches(., '^\s+$')] or $item[self::anchor or self::tabs])
                                            
                                            )
                                          )
                                       ]
                                    )
                          ]
                          [following-sibling::node()[not(self::text()[matches(., '^\s+$')])][1]/self::tab]" mode="hub:identifiers">
    <phrase role="hub:identifier">
      <xsl:copy>
      <xsl:sequence select="hub:set-origin($set-debugging-info-origin, 'phrase-not-identif-yet-with-link')"/>
        <xsl:apply-templates select="@*" mode="#current"/>
        <xsl:sequence select="node()"/><!-- no apply-templates here because otherwise the following template will catch -->
      </xsl:copy>
    </phrase>
  </xsl:template>


  <!-- Example(s): <para>1.<tab/>Text</para>
                   <para><phrase>1.<tab/></phrase>Text</para>
  -->
  <xsl:template match="text()
		                   [not(ancestor::phrase[@role eq 'hub:identifier'][hub:same-scope(current(), .)])]
		                   [not(ancestor::*[matches(@role, $hub:no-identifier-needed)])]
		                   [not(ancestor::*:math)]
		                   [
                         matches(., $hub:orderedlist-mark-at-start-regex)
                         and (
                           ancestor::para[xs:double(@margin-left) gt $hub:indent-epsilon][
                             count(tab/preceding-sibling::node()[self::text() or self::*]) = 1
                             or
                             (.//tab[not(ancestor::*[self::tabs])])[1][preceding-sibling::node()[1][. is current()]]
                           ]
                           or
                           ancestor::tocentry
                           or (:section titles are handled via a named template:)
                           ancestor::title[not(parent::section)]
                         )
                         and . is (ancestor::*[self::para or self::tocentry or self::title[not(parent::section)]][1]//text())[1]
                       ]" mode="hub:identifiers">
    <xsl:param name="hub:already-identified" as="xs:boolean?" tunnel="yes" select="false()"/>
    <xsl:variable name="context" select="." as="text()" />
    <xsl:variable name="no-identifier-but-simple-equation-starts" select="matches(., concat($hub:orderedlist-mark-at-start-regex, '[=\-\+÷]'))" as="xs:boolean"/>
    <xsl:variable name="parent" select="parent::*[1]" as="element()"/>
    <xsl:analyze-string select="." regex="{$hub:orderedlist-mark-at-start-regex}">
      <xsl:matching-substring>
        <xsl:choose>
          <xsl:when test="$context/following-sibling::node()[1]/self::tab 
                          and matches($context, concat($hub:orderedlist-mark-at-start-regex, '\p{L}'))
                          (: GI 2018-09-06: [A-Za-z] → \p{L} so that in 'o.ä.' 'o.' won’t be marked up as hub:identifier :)
                          or $hub:already-identified
                          or $no-identifier-but-simple-equation-starts">
            <xsl:value-of select="." />
          </xsl:when>
          <xsl:otherwise>
            <phrase role="hub:identifier">
              <xsl:sequence select="hub:set-origin($set-debugging-info-origin, 'orderlist-text1')"/>
              <xsl:value-of select="regex-group(1)" />
            </phrase>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="((
                         matches(regex-group(0), '[\s\p{Zs}]+$')
                         and
                         not($context/following::*[1]/self::tab)
                      )
                      or 
                      (
                        not($context/following::node()[1]/self::tab) and 
                        not(every $t in $parent/(* | text()) satisfies $t = $context)
                      ))
                      and not($hub:already-identified)">
          <tab>
            <xsl:text>&#9;</xsl:text>
          </tab>
        </xsl:if>
      </xsl:matching-substring>
      <xsl:non-matching-substring>
        <xsl:value-of select="." />
      </xsl:non-matching-substring>
    </xsl:analyze-string>
  </xsl:template>

  <xsl:variable name="hub:footnote-role-regex" as="xs:string"
    select="'Footnoteref'"/>

  <xsl:template match="link[phrase[matches(@role,$hub:footnote-role-regex)]]" mode="hub:identifiers">
    <footnoteref>
      <xsl:attribute name="linkend" select="phrase"/>
    </footnoteref>
  </xsl:template>

  <xsl:template match="section/title" mode="hub:identifiers">
    <xsl:call-template name="hub:section-title-identifier"/>
  </xsl:template>
  
  <xsl:template name="hub:section-title-identifier" as="element(title)">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:choose>
        <xsl:when test="phrase[@role eq 'hub:identifier']">
          <xsl:apply-templates mode="#current"/>
        </xsl:when>
        <xsl:when test="not(tab) and matches(normalize-space(.), $hub:orderedlist-mark-regex)">
          <xsl:apply-templates mode="#current">
            <xsl:with-param name="hub:already-identified" select="false()" tunnel="yes" as="xs:boolean"/>
          </xsl:apply-templates>
        </xsl:when>
        <xsl:when test="tab[following-sibling::node()[self::text() or self::phrase]] and not(phrase[@role eq 'hub:caption-number'])">
          <xsl:variable name="tab" select="tab[1]" as="element(tab)"/>
          <phrase role="hub:identifier">
            <xsl:sequence select="hub:set-origin($set-debugging-info-origin, 'section-title-identifier')"/>
            <xsl:apply-templates select="node()[ . &lt;&lt; $tab]" mode="#current">
              <xsl:with-param name="hub:already-identified" select="true()" tunnel="yes" as="xs:boolean"/>
            </xsl:apply-templates>
          </phrase>
          <xsl:apply-templates select="$tab | node()[ . &gt;&gt; $tab]" mode="#current"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates mode="#current">
            <xsl:with-param name="hub:already-identified" select="true()" tunnel="yes" as="xs:boolean"/>
          </xsl:apply-templates>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>

  <xsl:variable name="hub:caption-tagging-for-listings" as="xs:boolean"
    select="false()" />

  <xsl:variable name="hub:create-caption-numtext-separator" as="xs:boolean"
    select="if(hub:boolean-param($create-caption-numtext-separator)) then true() else false()" />

  <!-- This template has a name so that you can match another element (e.g., sidebar[@role = 'o_table']/title)
       in your importing stylesheet and treat it as a float title. -->
  <xsl:template match="  figure/title[not(matches(@role, $hub:no-identifier-needed))]
                       | table/title[not(matches(@role, $hub:no-identifier-needed))]
                       | mediaobject/caption
                       | formalpara[@role eq 'Programcode'][$hub:caption-tagging-for-listings]/title" 
    name="hub:float-title-identifier" 
    mode="hub:identifiers">

    <xsl:variable name="cleaned-text" as="xs:string?"
      select="string-join(.//text()[not(ancestor-or-self::indexterm)],'')"/>
    <xsl:copy>
      <xsl:apply-templates select="@*|processing-instruction()" mode="#current"/>
      <xsl:choose>

        <!-- example: <phrase>Table 4.1</phrase><tab/><phrase>…</phrase> 
             (scenario if hub:split-at-tab had already been invoked -->
        <xsl:when test="node()[1]/self::phrase[matches(., $hub:caption-number-without-sep-regex)]
                                              [not(phrase[@role = 'hub:identifier'])]
                        and 
                        node()[2]/self::tab and not(parent::*/@label)">
          <xsl:if test="node()[1][anchor]">
            <xsl:apply-templates select="node()[1]/anchor" mode="#current"/>
          </xsl:if>
          <phrase role="hub:caption-number">
            <xsl:analyze-string select="node()[1]" regex="{$hub:number-and-suffix-id-regex}">
              <xsl:matching-substring>
                <phrase role="hub:identifier">
                  <xsl:sequence select="hub:set-origin($set-debugging-info-origin, 'float-title-tab-identifier')"/>
                  <xsl:value-of select="."/>
                </phrase>
              </xsl:matching-substring>
              <xsl:non-matching-substring>
                <xsl:value-of select="."/>
              </xsl:non-matching-substring>
            </xsl:analyze-string>
          </phrase>
          <xsl:apply-templates select="node()[position() gt 1]" mode="#current"/>
        </xsl:when>

        <!-- same case as above + first nodes are anchors, for example <anchor xml:id="page_27"><anchor xml:id="id_HyperlinkTextDestination_Table_3" annotations="Table_3"/> -->
        <xsl:when test="( node()/self::phrase[matches(., $hub:caption-number-without-sep-regex)]
                                             [not(phrase[@role = 'hub:identifier'])]
                                             [every $n in preceding-sibling::node() satisfies ($n/self::anchor or $n/self::tabs)]
                                             [following-sibling::node()[1]/self::tab and not(parent::*/@label)]
                          )">
          <xsl:variable name="identifier" select="node()/self::phrase[matches(., $hub:caption-number-without-sep-regex)]
                                                                     [not(phrase[@role = 'hub:identifier'])]
                                                                     [every $n in preceding-sibling::node() satisfies ($n/self::anchor or $n/self::tabs)]
                                                                     [following-sibling::node()[1]/self::tab and not(parent::*/@label)]"/>
          <xsl:apply-templates select="node()[. &lt;&lt; $identifier]" mode="#current"/>
          <phrase role="hub:caption-number">
            <xsl:analyze-string select="$identifier" regex="{$hub:number-and-suffix-id-regex}">
              <xsl:matching-substring>
                <phrase role="hub:identifier">
                  <xsl:sequence select="hub:set-origin($set-debugging-info-origin, 'identifier-with-prec-anchors')"/>
                  <xsl:value-of select="."/>
                </phrase>
              </xsl:matching-substring>
              <xsl:non-matching-substring>
                <xsl:value-of select="."/>
              </xsl:non-matching-substring>
            </xsl:analyze-string>
          </phrase>
          <xsl:apply-templates select="node()[. &gt;&gt; $identifier]" mode="#current"/>
        </xsl:when>
        <!-- examples: ^Fig. 2$,  ^Table 4.1$,  ^Listing 1.3$ -->
        <xsl:when test="matches($cleaned-text, concat($hub:caption-number-without-sep-regex, '\s*$')) and not(parent::*/@label)">
          <xsl:for-each select=".//text()">
            <xsl:choose>
              <xsl:when test="ancestor::indexterm" />
              <xsl:otherwise>
                <phrase role="hub:caption-number">
                  <xsl:analyze-string select="." regex="{$hub:number-and-suffix-id-regex}">
                    <xsl:matching-substring>
                      <phrase role="hub:identifier">
                        <xsl:sequence select="hub:set-origin($set-debugging-info-origin, 'figtablist-identi')"/>
                        <xsl:value-of select="."/>
                      </phrase>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                      <xsl:value-of select="."/>
                    </xsl:non-matching-substring>
                  </xsl:analyze-string>
                </phrase>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each>
          <phrase role="hub:caption-text">
            <xsl:sequence select="hub:set-origin($set-debugging-info-origin, 'no-indexterm-no-palabel')"/>
            <xsl:apply-templates select=".//text()/ancestor::indexterm" mode="#current" />
          </phrase>
        </xsl:when>

        <!-- examples: ^Fig. 4.1: bla .*$, ^Tab. 3[&#x2002;]bla .*$, ^14.9$ -->
        <xsl:when test="matches($cleaned-text, $hub:caption-number-plus-sep-regex)
                        or (: figure title just starts with i.e. '23.7' :)
                        (
                          parent::figure
                          and not($hub:figure-caption-must-begin-with-figure-caption-start-regex)
                          and matches( $cleaned-text, concat( '^', $hub:caption-number-regex ) )
                        ) and not(parent::*/@label)">
              <xsl:call-template name="create-identifier-x">
                <xsl:with-param name="cleaned-text" as="xs:string" select="$cleaned-text"/>
              </xsl:call-template>
        </xsl:when>

        <xsl:when test="tab">
          <xsl:variable name="tab" select="tab[1]"/>
          <phrase role="hub:identifier">
            <xsl:sequence select="hub:set-origin($set-debugging-info-origin, 'tab-identifier')"/>
            <xsl:apply-templates select="node()[ . &lt;&lt; $tab]" mode="#current"/>
          </phrase>
          <xsl:apply-templates select="$tab | node()[ . &gt;&gt; $tab]" mode="#current"/>
        </xsl:when>

        <!-- input examples: ^Abb. A.1$, ^Table K.1. - .*$ -->
        <xsl:when test="matches(
                          $cleaned-text, 
                          concat('^(((', $hub:figure-caption-start-regex, ')|', $hub:table-caption-start-regex, ')', $hub:caption-sep-regex, '[A-Z]\.[0-9]+)\.?\p{Zs}.*')
                        ) 
                        and not(parent::*/@label)">
          <xsl:variable name="caption-number" 
            select="replace(
                      node()[not(self::tabs or self::info)][1], 
                      concat('^(((', $hub:figure-caption-start-regex, ')|', $hub:table-caption-start-regex, ')', $hub:caption-sep-regex, '[A-Z]\.[0-9]+)\.?\p{Zs}.*$'),
                      '$1'
                    )" as="xs:string" />
          <phrase role="hub:caption-number">
            <xsl:analyze-string select="$caption-number" regex="[A-Z]\.[0-9]+">
              <xsl:matching-substring>
                <phrase role="hub:identifier">
                  <xsl:sequence select="hub:set-origin($set-debugging-info-origin, 'float-cap-start-identifier')"/>
                  <xsl:value-of select="." />
                </phrase>
              </xsl:matching-substring>
              <xsl:non-matching-substring>
                <xsl:value-of select="." />
              </xsl:non-matching-substring>
            </xsl:analyze-string>
          </phrase>
          <phrase role="hub:caption-text">
            <xsl:sequence select="hub:set-origin($set-debugging-info-origin, 'no-indext-no-label')"/>
            <xsl:value-of select="replace(node()[1], hub:escape-for-regex($caption-number), '')" />
            <xsl:apply-templates select="node()[position() gt 1]" mode="#current" />
          </phrase>
        </xsl:when>

        <xsl:otherwise>
          <phrase role="hub:caption-text">
            <xsl:sequence select="hub:set-origin($set-debugging-info-origin, 'no-indext-no-label-otherw')"/>
            <xsl:apply-templates mode="#current"/>
          </phrase>
          <xsl:message>
            couldn't determine caption number in
            <xsl:sequence select="."/>
          </xsl:message>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>

  <xsl:template name="create-identifier-x">
    <xsl:param name="cleaned-text" as="xs:string?"/>
    <xsl:variable name="caption-number" as="xs:string">
      <xsl:choose>
        <!-- input examples: ^14.9$ -->
        <xsl:when test="parent::figure and 
          not($hub:figure-caption-must-begin-with-figure-caption-start-regex) and 
          matches( 
          $cleaned-text, 
          concat('^', $hub:caption-number-regex)
          )">
          <xsl:value-of 
            select="replace(
            $cleaned-text, 
            concat('(', $hub:caption-number-regex, ')(.+)$'), 
            '$1'
            )" />
          
        </xsl:when>
        <!-- input examples: ^Fig. 4.1: bla .*$, ^Tab. 3[&#x2002;]bla .*$-->
        <xsl:otherwise>
          <xsl:value-of 
                        select="replace(
                        $cleaned-text, 
                        concat($hub:caption-number-plus-sep-regex, '(.+)$'), 
                        '$1$2$3'
                        )" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:apply-templates select="descendant::*[self::anchor | self::indexterm][some $follower in following-sibling::node() satisfies (matches(string-join($follower, ''), $hub:caption-number-without-sep-regex))]" mode="#current"/>
    <phrase role="hub:caption-number">
      <xsl:analyze-string select="$caption-number" regex="{$hub:number-and-suffix-id-regex}">
        <xsl:matching-substring>
          <phrase role="hub:identifier">
            <xsl:sequence select="hub:set-origin($set-debugging-info-origin, 'identifier-in-capnum-without-sep')"/>
            <xsl:value-of select="."/>
          </phrase>
        </xsl:matching-substring>
        <xsl:non-matching-substring>
          <xsl:value-of select="."/>
        </xsl:non-matching-substring>
      </xsl:analyze-string>
    </phrase>
    <xsl:variable name="caption-number-with-tagged-separator" as="element(phrase)">
      <phrase role="hub:caption-text">
        <xsl:sequence select="hub:set-origin($set-debugging-info-origin, 'numbering-only')"/>
        <xsl:apply-templates mode="hub:insert-caption-num-to-text-separator">
          <xsl:with-param name="caption-number" select="$caption-number" tunnel="yes"/>
          <xsl:with-param name="parent" select="." tunnel="yes"/>
        </xsl:apply-templates>
      </phrase>
    </xsl:variable>
    <xsl:if test="$hub:create-caption-numtext-separator and 
      exists($caption-number-with-tagged-separator//hub:caption-separator/node())">
      <phrase role="hub:caption-numtext-separator">
        <xsl:sequence select="$caption-number-with-tagged-separator//hub:caption-separator/node()"/>
      </phrase>
    </xsl:if>
    <xsl:apply-templates select="$caption-number-with-tagged-separator" mode="hub:fix-floats-strip-num">
      <xsl:with-param name="insert-tab" tunnel="yes"
        select="if(contains($cleaned-text, '&#x9;') or $hub:create-caption-numtext-separator) 
        then false() else true()"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template match="*[self::anchor | self::indexterm]
                        [some $follower in following-sibling::node() satisfies (matches(string-join($follower, ''), $hub:caption-number-without-sep-regex))]" 
                        mode="hub:insert-caption-num-to-text-separator" priority="3">
    <!-- if anchor or indexterms are pulled before caption number, they shouldnt be processed again -->
  </xsl:template>
  
  <!-- insert separator element between caption-number and caption-text
  input example:
  <title role="FigureLegend">Fig. 1.5a<phrase css:font-family="Arial">–</phrase>h Arthroscopic diagnosis. <phrase css:font-weight="bold">a</phrase> biceps tendon anchor [...]</title>
  -->
  <xsl:template match="node()" mode="hub:insert-caption-num-to-text-separator">
    <xsl:param name="caption-number" as="xs:string" tunnel="yes"/>
    <xsl:param name="parent" as="element(*)" tunnel="yes"/>
    <xsl:variable name="context" select="." as="node()"/>
   
    <xsl:variable name="previous-text"
      select="replace(
                string-join(preceding::text()[not(ancestor::*[self::indexterm])][. &gt;&gt; $parent], ''),
                '&#x202f;+',
                '&#x202f;'
              )" as="xs:string"/>
    <xsl:choose>
      <!-- current node is an element and previous text is exactly the caption-number -->
      <!--<xsl:when test="self::* and $previous-text eq $caption-number and 
                      not(
                        matches(
                          following::node()[1], 
                          concat('^', $hub:caption-sep-among-caption-number-and-caption-text-regex_non-optional)
                      ))">
        <hub:caption-separator role="start" hub-origin="el-is-capnum"/>
      </xsl:when>-->
      
      <!-- tag all optional caption separator chars after caption-number -->
      <xsl:when test=". instance of text() and 
                      matches(
                        $previous-text, 
                        concat(
                          '^(',
                          $caption-number, 
                          $hub:caption-sep-among-caption-number-and-caption-text-regex,
                          ')$'
                        )
                      )">
        <xsl:analyze-string select="." regex="{concat('^(', $hub:caption-sep-among-caption-number-and-caption-text-regex_non-optional, ')')}">
          <xsl:matching-substring>
            <hub:caption-separator hub-origin="text-with-capnum-and-sep">
              <xsl:analyze-string select="." regex="&#x9;">
                <xsl:matching-substring>
                  <tab/>
                </xsl:matching-substring>
                <xsl:non-matching-substring>
                  <xsl:value-of select="."/>
                </xsl:non-matching-substring>
              </xsl:analyze-string>
            </hub:caption-separator>
          </xsl:matching-substring>
          <xsl:non-matching-substring>
            <xsl:value-of select="."/>
          </xsl:non-matching-substring>
        </xsl:analyze-string>
      </xsl:when>
      
      <!-- current node is text() and previous-text does not start with caption-number 
           (the current node is part of the caption-number and/or part of the caption-text) -->
      <xsl:when test=". instance of text() and not(starts-with($previous-text, $caption-number))">
        <xsl:variable name="current-text" select="." as="xs:string"/>
        <xsl:variable name="end-position" select="hub:get-endpos-of-string1-in-string2($caption-number, $previous-text, ., 1)" as="element(hub:pos)?"/>
        
        <xsl:choose>
          <xsl:when test="exists($end-position)">
            <xsl:analyze-string select="$current-text" 
              regex="{string-join(
                        (
                          '^', 
                          for $i in (1 to xs:integer($end-position/@val)) return '.', 
                          '(', $hub:caption-sep-among-caption-number-and-caption-text-regex, ')?'
                        ), 
                        '')}">
              <xsl:matching-substring>
                <hub:caption-separator hub-origin="text-is-part-of-capnum">
                  <xsl:value-of select="regex-group(1)"/>
                </hub:caption-separator>
              </xsl:matching-substring>
              <xsl:non-matching-substring>
                <xsl:value-of select="."/>
              </xsl:non-matching-substring>
            </xsl:analyze-string>            
          </xsl:when>
          <xsl:otherwise>
            <xsl:next-match/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:next-match/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- Remember to add this mode to the list of catch-all modes
       if specifying the modes explicitly -->
  
  <!-- current node is the, part of the caption-number or an element containing hub:caption-separator, 
       see mode hub:insert-caption-num-to-text-separator. There may be more than one hub:caption-separator! -->
  <xsl:template match="node()[not(self::hub:caption-separator)][ . &lt;&lt; (ancestor::*[last()]//hub:caption-separator)[1]]" mode="hub:fix-floats-strip-num" priority="1">
    <xsl:apply-templates select="hub:caption-separator" mode="#current"/>
  <xsl:apply-templates select="node()[not(self::hub:caption-separator)][preceding-sibling::hub:caption-separator]" mode="#current"/>
  </xsl:template>
  <xsl:template match="hub:caption-separator" mode="hub:fix-floats-strip-num">
    <xsl:param name="insert-tab" select="false()" tunnel="yes"/>
    <xsl:choose>
      <xsl:when test=". is (ancestor::*[last()]//hub:caption-separator)[1] and
                       not($hub:create-caption-numtext-separator) and 
                       $insert-tab and 
                       not(matches(string-join(following::hub:caption-separator, ''), '^\p{Zs}*[.:]'))">
       <tab>
         <xsl:text>&#9;</xsl:text>
       </tab>
      </xsl:when>
      <xsl:when test="not($hub:create-caption-numtext-separator)">
        <xsl:apply-templates mode="#current"/>
      </xsl:when>
      <!-- otherwise: do not output caption separator, already tagged in <phrase role="hub:caption-numtext-separator"> -->
      <xsl:otherwise/>
    </xsl:choose>
  </xsl:template>
  

  <xsl:template mode="hub:fix-floats-strip-num"
    match="node()[not(self::hub:caption-separator)][*][every $e in .//* satisfies $e/self::hub:caption-separator]">
    <xsl:choose>
      <xsl:when test="not($hub:create-caption-numtext-separator)">
        <xsl:next-match/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates mode="#current"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- mode: hub:twipsify-lengths -->

  <xsl:variable name="twipsify-lengths-attribute-names" as="xs:string+"
    select="('css:text-indent', 'css:margin-left')"/>

  <xsl:template match="@*[name() = $twipsify-lengths-attribute-names]" mode="hub:twipsify-lengths">
    <xsl:copy/>
    <xsl:if test="matches(xs:string(hub:to-twips(.)),'^[0-9\.-]+$')">
      <xsl:attribute name="{local-name()}" select="hub:to-twips(.)" />
    </xsl:if>
  </xsl:template>

  <!-- style is Hub 1.0, css:rule is Hub 1.1 or later -->
  <xsl:key name="hub:style-by-role" match="style | css:rule" use="(@role, @name)[1]" />

  <!-- override this if you don’t want to expand all properties 
  (i.e., leave out the apply templates instructions) -->
  <xsl:template match="@role" mode="hub:twipsify-lengths hub:expand-css-properties">
  	<xsl:copy />
    <xsl:apply-templates mode="#current"
      select="key('hub:style-by-role', .)
                /@*[name() = $twipsify-lengths-attribute-names]"/>
    <xsl:if test="hub:boolean-param($expand-css-properties)">
      <xsl:apply-templates mode="#current"
        select="key('hub:style-by-role', .)
                  /@css:*[not(name() = $twipsify-lengths-attribute-names)]" />
    </xsl:if>
  </xsl:template>

  <xsl:template mode="hub:twipsify-lengths hub:expand-css-properties"
    match="keywordset[@role eq 'hub'][hub:boolean-param($expand-css-properties)]" >
    <xsl:copy>
      <xsl:sequence select="@*" />
      <xsl:apply-templates select="keyword except keyword[@role eq 'formatting-deviations-only']" mode="#current" />
      <keyword role="formatting-deviations-only">false</keyword>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*" mode="hub:twipsify-lengths hub:expand-css-properties">
    <xsl:copy>
      <xsl:apply-templates select="@role, @* except @role, node()" mode="#current" />
    </xsl:copy>
  </xsl:template>

  <!-- This template could and probably should be imported from
       http://transpect.io/hub2html/xsl/css-atts2wrap.xsl
       It is redundantly included here in order to keep the number
       of external dependencies small. -->
  <xsl:template name="css:move-to-attic" as="element(css:rule)">
    <xsl:param name="atts" as="attribute(*)*"/>
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@* except $atts" mode="#current"/>
      <xsl:if test="exists($atts union css:attic/(@*, *))">
        <css:attic>
          <xsl:apply-templates select="$atts union css:attic/@*" mode="#current"/>
        </css:attic>
      </xsl:if>
      <xsl:apply-templates select="*" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <!-- collateral -->
  <xsl:variable name="hub:internalref-role" as="xs:string+" 
    select="('ID_Querverweis','ID_Querverweis_extern','ID_Querverweis_Semibold')"/>
  
  <!-- link (external) items: param aux has be set to 'yes' -->
  <xsl:variable name="hub:internalref-roles" as="xs:string+" 
    select="$hub:internalref-role" />
  <xsl:variable name="hub:internalref-table-role" as="xs:string+" 
    select="('ID_Querverweis_Table','ID_Querverweis_Table_extern','ID_Querverweis_Table_Element')" />
  <xsl:variable name="hub:internalref-figure-role" as="xs:string+" 
    select="('ID_Querverweis_Figure','Querverweis_Figure','ID_Querverweis_Figure_extern','ID_Querverweis_Figure_Element','ID_Querverweis_Figure_Element_extern')" />
  
  <xsl:variable name="hub:internalref-float-roles" as="xs:string+"
    select="($hub:internalref-table-role, $hub:internalref-figure-role)" />
  
  <xsl:variable name="hub:internalref-all-roles" as="xs:string+" 
    select="($hub:internalref-float-roles, $hub:internalref-roles)" />

  <!-- see also mode: hub:cross-link -->
  <xsl:template match="phrase[@role = $hub:internalref-all-roles]" mode="hub:twipsify-lengths">
    <xsl:value-of select="replace(
                            text()[
                              . is (
                                ancestor::phrase[@role = $hub:internalref-all-roles]//text()
                              )[1]
                            ],
                            '^(\s*).+$', 
                            '$1'
                          )"/>
    <link>
      <xsl:apply-templates select="@*[name() = ('role', 'srcpath')], node()" mode="#current"/>
    </link>
    <xsl:value-of select="replace(
                            text()[
                              . is (
                                ancestor::phrase[@role = $hub:internalref-all-roles]//text()
                              )[1]
                            ],
                            '^.+?(\s*)$', 
                            '$1'
                          )"/>
  </xsl:template>

  <xsl:template match="phrase[@role = $hub:internalref-all-roles]
                       //text()[
                         . is (
                           ancestor::phrase[@role = $hub:internalref-all-roles]//text()
                         )[1]
                       ]" mode="hub:twipsify-lengths">
    <xsl:value-of select="replace(., '^\s*(.+?)\s*$', '$1')"/>
  </xsl:template>

  <!-- mode: hub:no-floats -->
  <xsl:template match="*[self::figure | self::table]
                        [not(@hub:anchored eq 'yes')]" mode="hub:no-floats">
    <xsl:if test="@xml:id">
      <xsl:processing-instruction name="hub_removed-float-with-id" select="@xml:id"/>
    </xsl:if>
  </xsl:template>

  <xsl:key name="hub:linked-item-by-id" match="*[@xml:id]" use="@xml:id" />

  <!-- mode: hub:clean-hub -->

  <xsl:template name="hub_clean-hub">
    <xsl:apply-templates select="/" mode="hub:clean-hub"/>
  </xsl:template>

  <xsl:template match="*[matches(@conditon, 'Story(ID|Ref)')]" mode="hub:clean-hub">
    <xsl:message select="'StoryRef/StoryID element ', local-name(.), ' discarded'"/>
  </xsl:template>
  
 <xsl:template match="tabs/tab/@alignment-char[. = '']" mode="hub:clean-hub"/>

  <!-- set language attribute: project-specific? -->
  <xsl:template match="/*" mode="hub:clean-hub">
    <xsl:variable name="lang" as="xs:string"
      select="replace(
                (
                  @xml:lang, 
                  info/css:rules/css:rule[matches(@name, $hub:base-style-regex)]/@xml:lang,
                  info/css:rules/css:rule[@xml:lang][1]/@xml:lang,
                  'en'
                )[1],
                '^(\p{Ll}+)$',
                '$1'
              )"/>
    <xsl:copy>
      <xsl:if test="$lang ne ''">
        <xsl:attribute name="xml:lang" select="$lang"/>
      </xsl:if>
      <xsl:apply-templates select="@*, node()" mode="#current" />
    </xsl:copy>
  </xsl:template>

  <!-- remove attributes wearing source path values (useful option to diff conversion results) -->
  <xsl:template match="@xml:base[hub:boolean-param($clean-hub_remove-attributes-with-paths)]" mode="hub:clean-hub"/>
  <xsl:template match="keyword[matches(@role, 'uri')][hub:boolean-param($clean-hub_remove-attributes-with-paths)]" mode="hub:clean-hub"/>
  <xsl:template match="@idml2xml:layer | @*[matches(name(), 'color')][. = '?']" mode="hub:clean-hub"/>
	
  <xsl:template match="formalpara[title][every $c in * satisfies ($c/self::title)]" mode="hub:clean-hub">
    <para>
      <xsl:apply-templates select="@*, title/node()" mode="#current" />
    </para>
  </xsl:template>

  <xsl:template match="blockquote[parent::formalpara]" mode="hub:clean-hub">
    <para>
      <xsl:copy>
        <xsl:apply-templates select="@*, node()" mode="#current" />
      </xsl:copy>
    </para>
  </xsl:template>

  <xsl:template match="para[informaltable | table | figure]
                           [every $node in node() satisfies (exists($node/(self::informaltable | self::table | self::figure)))]
                           [every $att in @* satisfies (name($att) = ('srcpath', 'role'))]
                           [every $role in $special-regex-containers/descendant::*/@role satisfies not(matches($role, @role))]
                           [not(ancestor::*[self::epigraph])]
                           [not(parent::*[self::listitem])]" mode="hub:clean-hub">
        <xsl:apply-templates mode="#current" />
  </xsl:template>
  
  <xsl:function name="hub:style-props" as="attribute(*)*">
    <xsl:param name="elt" as="element(*)?"/>
    <xsl:if test="exists($elt)">
      <xsl:sequence select="$elt/@*[not(name() = ('xml:id', 'srcpath', 'role'))] 
                            union 
                            key('hub:style-by-role', $elt/@role, root($elt))/@*[not(name() = ('layout-type', 'name', 'native-name'))]" />
    </xsl:if>
  </xsl:function>

  <xsl:variable name="hub:clean-hub-ignored-generated-phrase-role-regex" as="xs:string+"
    select="'^hub:(identifier|caption-number|caption-text)$'"/>
  <xsl:variable name="hub:dissolve-phrases-with-same-formatting-as-parent" as="xs:boolean" select="true()"/>
  
  <!-- Dissolve phrases whose formatting is the same as their parents’. Will lose srcpath attributes though. 
  Solution: either devise a template with a similarly complex matching pattern for the ancestor element,
  in order to attache the dissolved phrases’ srcpath to it, or adapt the message rendering so that it uses 
  ancestor paths if it doesn’t find an immediate matching element. -->
  <!-- very dangerous template! semantic information like metadata tagging can be removed -->

  <xsl:template match="phrase[@role and not(matches(@role, $hub:clean-hub-ignored-generated-phrase-role-regex))]
                             [$hub:dissolve-phrases-with-same-formatting-as-parent]
                             [exists(
                                key('hub:style-by-role', @role)
                                  /@*[not(name() = ('layout-type', 'name', 'native-name'))]
                              )  and  (
                              every $prop in (key('hub:style-by-role', @role)
                                /@*[not(name() = ('layout-type', 'name', 'native-name'))] union current()/@*[not(name() = ('role', 'srcpath'))])
                              satisfies (exists(
                                hub:equiv-props(
                                  $prop,
                                  current(),
                                  hub:style-props(
                                    current()/ancestor::*[@role][hub:same-scope(., current())]
                                                         [hub:style-props(.)/name() = name($prop)][1]
                                  )
                                )
                              ))
                             )]" mode="hub:clean-hub">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <!-- Remove phrases that have been created by split-at-tab or that have lost their style -->
  <xsl:template match="phrase[not(@role)][every $att in @* satisfies ($att/self::attribute(srcpath))]" mode="hub:clean-hub">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <!-- move trailing whitespace outside of links. Changed template because it made problems with whitespaces inside links. Content was duplicated -->
  <xsl:template match="link[every $n in node() satisfies $n instance of text()]
                           [matches(., '[^\p{Zs}][\p{Zs}+]+$')]" mode="hub:clean-hub">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:value-of select="replace(., '^(.+?)([\p{Zs}]+)$', '$1')"/>
    </xsl:copy>
    <xsl:value-of select="replace(., '^(.+?)([\p{Zs}]+)$', '$2')"/>
  </xsl:template>

  <!-- In an importing stylesheet, you may overwrite this function and invoke 
       css:equiv-props (from http://transpect.io/hub2html/xsl/css-atts2wrap.xsl) 
       with the same arguments. It regards properties as equivalent that will resolve to
       the same markup. Because these rules are context dependent, we’ll accept context
       as an argument here, too. -->
  <xsl:function name="hub:equiv-props" as="attribute(*)*">
    <xsl:param name="prop" as="attribute(*)"/>
    <xsl:param name="context" as="element(*)?"/>
    <xsl:param name="props" as="attribute(*)*"/>
    <xsl:sequence select="$props[name() = name($prop) and . = $prop]"/>
  </xsl:function>

  <xsl:template match="@override[not(/*/@version = '5.1-variant le-tex_Hub-1.0')]">
    <xsl:copy/>
    <xsl:attribute name="css:pseudo-marker_content" select='concat("&apos;", ., "&apos;")'/>
  </xsl:template>

  <!-- mode: hub:ids -->

  <xsl:variable name="hub:section-sidebar-roles" select="('Excurse', 'Conclusion')" as="xs:string+" />

  <xsl:template match="section | sidebar[title/@role = $hub:section-sidebar-roles]" mode="hub:ids">
    <xsl:copy>
      <xsl:attribute name="xml:id" 
        select="concat(
                  'Sec', 
                  string(
                    count( 
                      (//section | //sidebar[title/@role = $hub:section-sidebar-roles] ) [. &lt;&lt; current()]
                    ) 
                    + 1 
                  )
                )"/>
      <xsl:apply-templates select="@* | node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="chapter" mode="hub:ids">
    <xsl:copy>
      <xsl:attribute name="xml:id" 
        select="concat(
                  'Chap', 
                  string(
                    count( 
                      ( //chapter ) [. &lt;&lt; current()]
                    ) 
                    + 1 
                  )
                )"/>
      <xsl:apply-templates select="@* | node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>


  <xsl:template match="figure" mode="hub:ids">
    <xsl:copy>
      <xsl:attribute name="xml:id" select="concat(
                                             'Fig', 
                                             string(
                                               count(
                                                 preceding::figure
                                               ) 
                                               + 1
                                             )
                                           )"/>
      <!-- sections with tables and/or figures only: set anchored to true, so this figure wont be moved to float variable  -->
      <xsl:if test="parent::section[count(*) eq count(title union table union figure)]">
        <xsl:attribute name="hub:anchored" select="'yes'"/>
      </xsl:if>
      <xsl:apply-templates select="@* | node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="table | informaltable" mode="hub:ids">
    <xsl:copy>
      <xsl:attribute name="xml:id" select="concat(
                                             'Tab', 
                                             string(
                                               count(
                                                 preceding::table union ancestor::table
                                                 union
                                                 preceding::informaltable union ancestor::informaltable
                                               ) 
                                               + 1
                                             )
                                           )"/>

      <!-- sections with tables and/or figures only: set anchored to true, so this table wont be moved to float variable  -->
      <xsl:if test="parent::section[count(*) eq count(title union table union figure)]">
        <xsl:attribute name="hub:anchored" select="'yes'"/>
      </xsl:if>
      <xsl:apply-templates select="@* | node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="index" mode="hub:ids">
    <xsl:copy>
      <xsl:attribute name="xml:id" 
        select="concat(
                  'Ind', 
                  string(
                    count( 
                      ( //index ) [. &lt;&lt; current()]
                    ) 
                    + 1 
                  )
                )"/>
      <xsl:apply-templates select="@* | node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="appendix" mode="hub:ids">
    <xsl:copy>
      <xsl:attribute name="xml:id" 
        select="concat(
                  'App', 
                  string(
                    count( 
                      ( //appendix ) [. &lt;&lt; current()]
                    ) 
                    + 1 
                  )
                )"/>
      <xsl:apply-templates select="@* | node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

	<xsl:template match="bibliography" mode="hub:ids">
		<xsl:copy>
			<xsl:attribute name="xml:id" 
				select="concat(
											'Bib', 
											string(
												count( 
												( //bibliography ) [. &lt;&lt; current()]
												) 
											+ 1 
											)
											)"/>
			<xsl:apply-templates select="@* | node()" mode="#current"/>
		</xsl:copy>
	</xsl:template>
	
  <xsl:template match="footnote" mode="hub:ids">
    <xsl:copy>
      <xsl:attribute name="xml:id" select="concat('Fn', count(preceding::footnote) + 1)"/>
      <xsl:apply-templates select="@* | node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <!-- collateral: poetry -->
  
  <xsl:variable name="hub:poetry-heading-regex-x" as="xs:string"
    select="'p_text_h_verse'"/>
  
  <xsl:template match="*[ para[matches(@role, $hub:poetry-heading-regex-x, 'x')] | linegroup][not(self::poetry or self::programlisting)]" mode="hub:ids">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:for-each-group select="*" 
        group-adjacent="boolean(self::para[matches(@role, $hub:poetry-heading-regex-x, 'x')] | self::linegroup)">
        <xsl:choose>
          <xsl:when test="current-grouping-key()">
            <poetry>
              <xsl:apply-templates select="current-group()" mode="#current"/>
            </poetry>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="current-group()" mode="#current"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="para[matches(@role, $hub:poetry-heading-regex-x, 'x')]" mode="hub:ids">
    <title>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </title>
  </xsl:template>

  <!-- mode: hub:aux -->

  <xsl:template match="node()" mode="hub:aux">
    <xsl:apply-templates mode="#current" />
  </xsl:template>

  <xsl:variable name="hub:target-filename" select="concat($basename, '.hub-e.xml')" />

  <xsl:template match="*[self::section or self::chapter or self::figure or self::table][@xml:id]" mode="hub:aux">
    <para xlink:href="{$hub:target-filename}#{@xml:id}" remap="{name()}">
      <phrase role="hub:identifier">
        <xsl:apply-templates select="." mode="hub:aux-identifier" />
      </phrase>
    </para>
    <xsl:apply-templates mode="#current" />
  </xsl:template>

  <xsl:template match="*" mode="hub:aux-identifier">
    <xsl:value-of select="title//phrase[@role eq 'hub:identifier']"/>
  </xsl:template>


  <!-- mode: hub:cross-link -->

  <xsl:variable name="hub:url-regex" as="xs:string"
    select="'(www\.[a-zA-Z][-a-zA-Z0-9.]+\.[-a-zA-Z0-9+&amp;@#/%?=~_|!:,.;]*[-a-zA-Z0-9+&amp;@#/%=~_|])|(doi\s?:\s*)?((https?|ftp|file|rtsp)://[-a-zA-Z0-9+&amp;@#/%?=~_|!:,.;\(\)]*[-a-zA-Z0-9+&amp;@#/%=~_|])'"/>

  <xsl:variable name="hub:doi-regex" as="xs:string"
    select="'(^|\s)(doi\s?:\s*)?(10\.\d\d\d\d(\.|\d+)*/[&quot;&amp;&lt;&gt;\S\(\)]+)(\s|$)'"/>

  <xsl:variable name="hub:doi-link-starting-string" as="xs:string?"
    select="'http://doi.org/'"/>

  <xsl:variable name="hub:remove-doi-text-prefix" as="xs:boolean"
    select="false()"/>
  
  <xsl:variable name="hub:cross-link-ulink-element-name" as="xs:string"
    select="'ulink'"/><!-- alternatives (i.e. DocBook 5.1): olink or link -->

  <xsl:variable name="hub:create-helper-attr-for-created-cross-links" as="xs:boolean"
    select="false()"/>
  
  <xsl:template match="para//text()[not(ancestor::*/name() = ('link', 'olink', 'ulink'))]" mode="hub:cross-link">
    <xsl:choose>
      <xsl:when test="$create-ulinks-from-text='yes'">
        <xsl:analyze-string select="." regex="{$hub:url-regex}([,.;]?)" flags="i">
          <xsl:matching-substring>
            <xsl:variable name="address" as="xs:string"
              select="replace(replace(., '^(doi\s?:\s*)', '', 'i'), '[,.;]$', '')"/>
            <xsl:if test="not($hub:remove-doi-text-prefix) and matches(., '^(doi\s?:\s*).+$')">
              <xsl:value-of select="replace(., '^(doi\s?:\s*).+$', '$1', 'i')"/>
            </xsl:if>
            <xsl:element name="{$hub:cross-link-ulink-element-name}">
              <xsl:attribute name="url" select="$address"/>
              <xsl:if test="$hub:create-helper-attr-for-created-cross-links">
                <xsl:attribute name="hub:created-by-evolve-hub" select="'yes'"/>
              </xsl:if>
              <xsl:value-of select="$address"/>
            </xsl:element>
            <xsl:if test="matches(., '[,.;]$')">
              <xsl:value-of select="replace(., '^(.+)([,.;])$', '$2')"/>
            </xsl:if>
          </xsl:matching-substring>
          <xsl:non-matching-substring>
            <xsl:analyze-string select="." regex="{$hub:doi-regex}" flags="i">
              <xsl:matching-substring>
                <xsl:variable name="address" as="xs:string"
                  select="replace(replace(regex-group(3), '^(doi\s?:\s*)', '', 'i'), '[,.;]$', '')"/>
                <xsl:value-of select="regex-group(1)"/>
                <xsl:if test="not($hub:remove-doi-text-prefix) and matches(regex-group(3), '^(doi\s?:\s*).+$')">
                  <xsl:value-of select="replace(regex-group(3), '^(doi\s?:\s*).+$', '$1', 'i')"/>
                </xsl:if>
                <link xlink:href="{concat($hub:doi-link-starting-string, $address)}">
                  <xsl:if test="$hub:create-helper-attr-for-created-cross-links">
                    <xsl:attribute name="hub:created-by-evolve-hub" select="'yes'"/>
                  </xsl:if>
                  <xsl:value-of select="$address"/>
                </link>
                <xsl:if test="matches(., '^.+([,.;])$')">
                  <xsl:value-of select="replace(regex-group(3), '^.+([,.;])$', '$1')"/>
                </xsl:if>
                <xsl:value-of select="regex-group(5)"/>
              </xsl:matching-substring>
              <xsl:non-matching-substring>
                <xsl:value-of select="."/>
              </xsl:non-matching-substring>
            </xsl:analyze-string>
          </xsl:non-matching-substring>
        </xsl:analyze-string>
      </xsl:when>
      <xsl:otherwise>
        <xsl:next-match/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- never mind the link's role if it looks like a URL: -->
  <xsl:template match="link[matches(., $hub:url-regex)]" mode="hub:cross-link" priority="2">
    <xsl:copy>
      <xsl:attribute name="xlink:href" select="if (exists(@xlink:href)) 
                                               then if (starts-with(@xlink:href, 'www'))
                                                    then concat('http://', @xlink:href)
                                                    else @xlink:href 
                                               else if (exists(@linkend)) 
                                                    then if (starts-with(@linkend, 'www'))
                                                         then concat('http://', @linkend)
                                                         else @linkend
                                                    else if (starts-with(., 'www'))
                                                         then concat('http://', .)
                                                         else ." />
      <xsl:apply-templates select="@srcpath, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <!-- This template has a name so that it can be called by this name if your adaptions have templates
    that match other patterns but should do the same things -->
  <xsl:template match="link[@role = $hub:internalref-all-roles]" name="hub:cross-link" mode="hub:cross-link">
    <xsl:if test="*">
      <xsl:message>Link <xsl:sequence select="."/> contains markup. The markup will be discarded.
      </xsl:message>
    </xsl:if>
    <xsl:variable name="context" select="." as="element(link)" />
    <xsl:variable name="prelim" as="document-node(element(link-group))">
      <xsl:document>
        <link-group>
          <xsl:analyze-string select="." regex="{$hub:internalref-regex-x}" flags="x">
            <xsl:matching-substring>
              <link>
                <xsl:apply-templates select="$context/@*" mode="#current" />
                <!-- If you define a regex with a different bracketing, you'd need to redefine this template
                     b/c of the numbered regex-group() references -->
                <xsl:variable name="id" as="xs:string?" select="regex-group(5)" />
                <xsl:variable name="type" as="xs:string?" select="hub:target-type(regex-group(2), $id)" />
                <xsl:if test="$type">
                  <xsl:attribute name="target-type" select="$type" />
                </xsl:if>
                <xsl:if test="$id">
                  <xsl:attribute name="target-id" select="$id" />
                </xsl:if>
                <xsl:value-of select="."/>
              </link>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
              <link>
                <xsl:apply-templates select="$context/@srcpath" mode="#current"/>
                <xsl:value-of select="."/>
              </link>
            </xsl:non-matching-substring>
          </xsl:analyze-string>
        </link-group>
      </xsl:document>
    </xsl:variable>
    <!--
    <xsl:message>PRELIM:
    <xsl:sequence select="$prelim" />
    </xsl:message>
    -->
    <xsl:apply-templates select="$prelim/link-group/node()" mode="hub:cross-link-resolve">
      <xsl:with-param name="root" tunnel="yes">
        <xsl:document>
          <xsl:sequence select="root(.)/*"/>
        </xsl:document>
      </xsl:with-param>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:variable name="hub:internalref-type-regex-x" as="xs:string" 
    select="concat('
              (
                (', $hub:figure-caption-start-regex, '|', $hub:table-caption-start-regex, '|', $hub:listing-caption-start-regex, '|Abschn\.|Kap\.|Chap\.|Chapter|Chaps\.)
                ([\p{Zs}]+)
              )'
            )" />

  <xsl:variable name="hub:internalref-number-suffix-regex" as="xs:string" 
    select="'[a-z,&#x2013;&#x202f;]+'" />

  <xsl:variable name="hub:internalref-number-regex-x" as="xs:string" 
    select="concat('(
                     (\d+(\.\d+)*)',
                     '(', $hub:internalref-number-suffix-regex, ')?',
                   ')')" />

  <xsl:variable name="hub:internalref-regex-x" as="xs:string" 
    select="concat(
              $hub:internalref-type-regex-x,
              '?',
              $hub:internalref-number-regex-x
            )" />


  <xsl:variable name="hub:figure-name-regex" as="xs:string" 
    select="concat('^(', $hub:figure-caption-start-regex, ')$')" />
  <xsl:variable name="hub:number-and-suffix-id-regex" as="xs:string"
    select="'\d+(\.\d+(\p{L}([,&#x2013;&#x202f;-]\p{L})?)*)?'" />
  <xsl:variable name="hub:figure-id-regex" as="xs:string" select="$hub:number-and-suffix-id-regex" />
  <xsl:variable name="hub:table-name-regex" as="xs:string" select="'^Tab(\.|ellen?|les?)$'" />
  <xsl:variable name="hub:table-id-regex" as="xs:string" select="$hub:number-and-suffix-id-regex" />
  <xsl:variable name="hub:section-name-regex" as="xs:string" select="'^(Abschn(\.|itt(e?s|en?)?)|Kap(\.|itel[ns]?))$'" />
  <xsl:variable name="hub:section-id-regex" as="xs:string" select="'\d+\.\d+(\.\d+)*'" />
  <xsl:variable name="hub:chapter-name-regex" as="xs:string" select="'^(Kap(\.|itel[ns]?)|Chap(\.|ters?|s\.?))$'" />
  <xsl:variable name="hub:chapter-id-regex" as="xs:string" select="'\d+'" />
  <xsl:variable name="hub:part-name-regex" as="xs:string" select="'^Teil(s|en?)?$'" />
  <xsl:variable name="hub:part-id-regex" as="xs:string" select="'.+'" />
  <xsl:variable name="hub:appendix-name-regex" as="xs:string" select="'^(Anhangs?|AnhÃÂ¤ngen?)$'" />
  <xsl:variable name="hub:appendix-id-regex" as="xs:string" select="'.+'" />

  <xsl:function name="hub:target-type" as="xs:string?">
    <xsl:param name="matched-string" as="xs:string?" />
    <xsl:param name="matched-id" as="xs:string?" />
    <xsl:choose>
      <xsl:when test="matches($matched-string, $hub:figure-name-regex)
                      and matches($matched-id, $hub:figure-id-regex)">figure</xsl:when>
      <xsl:when test="matches($matched-string, $hub:table-name-regex)
                      and matches($matched-id, $hub:table-id-regex)">table</xsl:when>
      <xsl:when test="matches($matched-string, $hub:section-name-regex)
                      and matches($matched-id, $hub:section-id-regex)">section</xsl:when>
      <xsl:when test="matches($matched-string, $hub:chapter-name-regex)
                      and matches($matched-id, $hub:chapter-id-regex)">chapter</xsl:when>
      <xsl:when test="matches($matched-string, $hub:part-name-regex)
                      and matches($matched-id, $hub:part-id-regex)">part</xsl:when>
      <xsl:when test="matches($matched-string, $hub:appendix-name-regex)
                      and matches($matched-id, $hub:appendix-id-regex)">appendix</xsl:when>
    </xsl:choose>
  </xsl:function>

  <xsl:key name="hub:element-by-identifier-text" match="*[title//phrase[@role eq 'hub:identifier']]" 
    use="concat(local-name(.[1]), '_', (title//phrase[@role eq 'hub:identifier'])[1])" />

  <xsl:key 
    name="hub:element-by-identifier-text-without-suffix" 
    match="*[title//phrase[@role eq 'hub:identifier']]" 
    use="concat(
           local-name(.[1]), 
           '_', 
           replace(
             title//phrase[@role eq 'hub:identifier'][1],
             $hub:internalref-number-suffix-regex,
             ''
           )
         )"
    />

  <xsl:key name="hub:aux-element-by-identifier-text" match="para" 
    use="concat(@remap, '_', phrase[@role eq 'hub:identifier'])" />

  <xsl:function name="hub:resolve-target" as="xs:string*">
    <xsl:param name="type" as="xs:string?" />
    <xsl:param name="identifier-string" as="xs:string" />
    <xsl:param name="root" as="document-node(element(*))" />
    <xsl:if test="$type">
      <xsl:variable name="local-resolution" as="element(*)*"
        select="key('hub:element-by-identifier-text', concat($type, '_', $identifier-string), $root)" />
      <xsl:variable name="local-resolution-without-suffix" as="element(*)*"
        select="key('hub:element-by-identifier-text-without-suffix', 
                    concat( 
                      $type, 
                      '_', 
                      replace( 
                        $identifier-string,
                        $hub:internalref-number-suffix-regex,
                        ''
                      )
                    ),
                    $root)" />
      <xsl:choose>
        <xsl:when test="exists($local-resolution)">
          <xsl:if test="count($local-resolution) gt 1">
            <xsl:message>More than one link resolution target for <xsl:value-of select="$type"/>_<xsl:value-of select="$identifier-string"/>: <xsl:value-of select="$local-resolution/@xml:id"/>
            </xsl:message>
          </xsl:if>
          <xsl:sequence select="$local-resolution/@xml:id" />
        </xsl:when>
        <xsl:when test="not(exists($local-resolution)) and count($local-resolution-without-suffix) eq 1">
          <xsl:sequence select="$local-resolution-without-suffix/@xml:id" />
        </xsl:when>
        <xsl:when test="hub:boolean-param($aux) and $identifier-string ne ''">
          <xsl:sequence select="key('hub:aux-element-by-identifier-text', concat($type, '_', $identifier-string), $hub:aux)/@xlink:href" />
        </xsl:when>
      </xsl:choose>
    </xsl:if>
  </xsl:function>

  <xsl:template match="tocdiv | tocentry" mode="hub:cross-link">
    <xsl:copy>
      <!-- §§ hard-coded 'section'; needs to be generalized: -->
      <xsl:variable name="resolution" as="xs:string*"
        select="hub:resolve-target('section', ( (title, self::tocentry)//phrase[@role eq 'hub:identifier'], '')[1], root(.))" />
      <xsl:choose>
        <xsl:when test="count($resolution) eq 0">
          <xsl:message>No link resolution for <xsl:sequence select="." />
          </xsl:message>
        </xsl:when>
        <xsl:when test="count($resolution) gt 1">
          <xsl:message>Ambiguous link resolution for <xsl:sequence select="." />
          </xsl:message>
        </xsl:when>
        <xsl:otherwise>
          <xsl:attribute name="linkend" select="$resolution" />
        </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="@*, node()" mode="#current" />
    </xsl:copy>
  </xsl:template>

  <!-- if you explicitly enumerate identity template modes, don't forget this one: -->
  <xsl:template match="link[@target-id]" mode="hub:cross-link-resolve">
    <xsl:param name="root" as="document-node(element(*))" tunnel="yes" />
    <xsl:variable name="type" as="xs:string?"
      select="(
                preceding-sibling::link/@target-type,
                @target-type
              )[last()]
              " />
    <xsl:variable name="resolved" select="hub:resolve-target($type, @target-id, $root)" as="xs:string*"/>
    <xsl:choose>
      <xsl:when test="exists($type) and exists($resolved)">
        <xsl:copy>
          <xsl:choose>
            <xsl:when test="matches($resolved[1], '^file:')">
              <xsl:attribute name="xlink:href" select="$resolved[1]" />
              <xsl:attribute name="role" select="'same-work-external'" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:attribute name="linkend" select="$resolved" />
              <xsl:attribute name="role" select="'same-work-internal'" />
            </xsl:otherwise>
          </xsl:choose>
          <xsl:apply-templates select="@srcpath, node()" mode="#current"/>
        </xsl:copy>
      </xsl:when>
      <xsl:when test="exists($type)">
        <xsl:copy>
          <xsl:attribute name="xlink:href" select="concat('urn:X-hub:unresolved-same-work-externalref?id=', $type, '_', @target-id)" />
          <xsl:apply-templates select="@srcpath, node()" mode="#current"/>
        </xsl:copy>
      </xsl:when>
      <xsl:otherwise>
        <xsl:processing-instruction name="hub">cross-link-02 Could not resolve internal link with unknown type and id [<xsl:value-of select="@target-id"/>]; removed: [<xsl:value-of select="hub:normalize-for-message(.)"/>]</xsl:processing-instruction>
        <xsl:message>Could not resolve internal link with unknown type and id [<xsl:value-of select="@target-id"/>]; removed: <xsl:value-of select="."/>
        </xsl:message>
        <xsl:apply-templates mode="#current"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="link[not(@target-id)]" mode="hub:cross-link-resolve">
    <xsl:processing-instruction name="hub">cross-link-01 No id for internal link; removed: [<xsl:value-of select="hub:normalize-for-message(.)"/>]</xsl:processing-instruction>
    <xsl:message>No id for internal link; removed: <xsl:value-of select="."/>
    </xsl:message>
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <xsl:template match="link[not(@*)]" mode="hub:cross-link">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  
	<xsl:template match="anchor[matches(@xml:id, '^pageend')]" mode="hub:postprocess-hierarchy"/>
	
  <!-- mode: hub:reorder-marginal-notes-->
  <!-- In this mode sidebars are placed inside the paras they were originally anchored. 
  This should happen before the list modes and after postprocess-hierarchy-->
  <xsl:variable name="sidenote-not-to-be-pulled-in-titles" as="xs:string" select="concat($hub:table-title-role-regex-x, '|', $hub:table-number-role-regex-x, '|', $hub:figure-title-role-regex-x, '|', $hub:figure-number-role-regex-x)"/>
  <xsl:variable name="sidenote-at-end-of-para-style-regex" as="xs:string" select="'transpect_list_para'"/>
  
  <xsl:template match="*[not(self::title)]
                        [not(self::para[matches(@role, $sidenote-not-to-be-pulled-in-titles)])]
                        [.//anchor[key('hub:linking-item-by-id', @xml:id)/self::sidebar[hub:is-marginal-note(.)]]]" mode="hub:reorder-marginal-notes">
    <xsl:variable name="sidenote-anchor" as="element(anchor)+" select=".//anchor[key('hub:linking-item-by-id', @xml:id)/self::sidebar[hub:is-marginal-note(.)]]"/>
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*"/>
      <!-- the out commented code pulls the sidebars to the start or end of the para. It is more useful to do that later, depending on the displaying of the marginal note -->
     <!-- <xsl:apply-templates select="$sidenote-anchor[(string-length(normalize-space(string-join(preceding-sibling::node()//text(), ''))) + string-length(normalize-space(string-join(parent::phrase/preceding-sibling::node()//text(), '')))) lt
        (string-length(normalize-space(string-join(following-sibling::node()//text(), ''))) + string-length(normalize-space(string-join(parent::phrase/following-sibling::node()//text(), ''))))]/key('hub:linking-item-by-id', @xml:id)" mode="hub:reorder-marginal-notes">
            <xsl:with-param name=keep-sidebar" as="xs:boolean" select="true()" tunnel="yes"/>
          </xsl:apply-templates>
          <xsl:apply-templates select="node()" mode="#current"/>
      <xsl:apply-templates select=" $sidenote-anchor[(string-length(normalize-space(string-join(preceding-sibling::node()//text(), ''))) + string-length(normalize-space(string-join(parent::phrase/preceding-sibling::node()//text(), '')))) ge
        (string-length(normalize-space(string-join(following-sibling::node()//text(), ''))) + string-length(normalize-space(string-join(parent::phrase/following-sibling::node()//text(), ''))))]/key('hub:linking-item-by-id', @xml:id)" mode="hub:reorder-marginal-notes">
        <xsl:with-param name="keep-sidebar" as="xs:boolean" select="true()" tunnel="yes"/>
      </xsl:apply-templates>-->
      <xsl:choose>
        <xsl:when test="not(matches(@role, $sidenote-at-end-of-para-style-regex))">
          <xsl:apply-templates select="node()" mode="#current">
            <xsl:with-param name="insert-sidebars" as="xs:boolean" select="true()" tunnel="yes"/>
          </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
          <!-- For example in lists sidenotes shouldn't be at the beginning to avoid them being put into the term -->
          <xsl:apply-templates select="node()" mode="#current">
            <xsl:with-param name="insert-sidebars" as="xs:boolean" select="false()" tunnel="yes"/>
            <xsl:with-param name="discard-anchor" as="element(anchor)*" select="$sidenote-anchor" tunnel="yes"/>
          </xsl:apply-templates>
          <xsl:apply-templates select=".//anchor[key('hub:linking-item-by-id', @xml:id)/self::sidebar[hub:is-marginal-note(.)]]" mode="#current">
          <xsl:with-param name="insert-sidebars" as="xs:boolean" select="true()" tunnel="yes"/>
          </xsl:apply-templates>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="phrase[anchor[key('hub:linking-item-by-id', @xml:id)/self::sidebar[hub:is-marginal-note(.)]]]" mode="hub:reorder-marginal-notes" priority="3">
    <xsl:param name="insert-sidebars" tunnel="yes" as="xs:boolean?"/>
    <xsl:variable name="context" select="." as="element(*)" />
    <xsl:choose>
      <xsl:when test="$insert-sidebars">
        <xsl:for-each-group
          select="descendant::node()" group-starting-with="anchor[key('hub:linking-item-by-id', @xml:id)/self::sidebar[hub:is-marginal-note(.)]]">
              <xsl:apply-templates select="current-group()/self::anchor[key('hub:linking-item-by-id', @xml:id)/self::sidebar[hub:is-marginal-note(.)]]" mode="#current">
                <xsl:with-param name="insert-sidebars" as="xs:boolean" select="true()" tunnel="yes"/>
              </xsl:apply-templates>
              <xsl:variable name="upward-projected" as="element(*)">
                <xsl:apply-templates select="$context" mode="hub:upward-project-tab">
                  <xsl:with-param name="restricted-to" select="current-group()/ancestor-or-self::node()[not(self::anchor[key('hub:linking-item-by-id', @xml:id)/self::sidebar[hub:is-marginal-note(.)]])]" tunnel="yes"/>
                </xsl:apply-templates>
              </xsl:variable>
              <xsl:if test="$upward-projected/node()">
                  <xsl:sequence select="$upward-projected"/>  
              </xsl:if>
        </xsl:for-each-group>
      </xsl:when>
      <xsl:otherwise>
        <!-- do not pull sidebar up, for example phrases in titles with an anchor-->  
      <xsl:copy copy-namespaces="no">
          <xsl:apply-templates select="@*, node()" mode="#current">
            <xsl:with-param name="insert-sidebars" as="xs:boolean" select="false()" tunnel="yes"/>
          </xsl:apply-templates>
        </xsl:copy>
      </xsl:otherwise>
      </xsl:choose>
  </xsl:template>
  
   <!-- pull sidebars before titles (table and figure titles as well) --> 

   <xsl:template match="*[self::title[not(parent::title)] or self::para[matches(@role, $sidenote-not-to-be-pulled-in-titles)]]
                         [.//anchor[key('hub:linking-item-by-id', @xml:id)/self::sidebar[hub:is-marginal-note(.)]]]" mode="hub:reorder-marginal-notes">
    <xsl:variable name="sidenote" as="element(sidebar)*" select=".//anchor/key('hub:linking-item-by-id', @xml:id)[self::sidebar[hub:is-marginal-note(.)]]"/>
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*, node()" mode="#current">
        <xsl:with-param name="insert-sidebars" as="xs:boolean" select="false()" tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:copy>
    <xsl:apply-templates select="$sidenote" mode="#current">
      <xsl:with-param name="keep-sidebar" as="xs:boolean" select="true()" tunnel="yes"/>
    </xsl:apply-templates>
</xsl:template>
  

  
  <xsl:template match="*:anchor" mode="hub:reorder-marginal-notes" priority="2">
    <xsl:param name="insert-sidebars" tunnel="yes" as="xs:boolean?"/>
    <xsl:param name="discard-anchor" as="element(anchor)*" tunnel="yes"/>
    <xsl:if test="not(@xml:id = $discard-anchor/@xml:id)">
      <xsl:copy copy-namespaces="no">
        <xsl:apply-templates select="@*, node()" mode="#current"/>
      </xsl:copy>
      <xsl:if test="$insert-sidebars and key('hub:linking-item-by-id', @xml:id)/self::sidebar[hub:is-marginal-note(.)]">
        <xsl:apply-templates select="key('hub:linking-item-by-id', @xml:id)" mode="#current">
          <xsl:with-param name="keep-sidebar" as="xs:boolean" select="true()" tunnel="yes"/>
        </xsl:apply-templates>
      </xsl:if>
    </xsl:if>
  </xsl:template>
    
  <xsl:template match="sidebar[key('hub:linking-item-by-linkend', @linkend)][hub:is-marginal-note(.)]" mode="hub:reorder-marginal-notes">
    <xsl:param name="keep-sidebar" tunnel="yes"/>
    <xsl:choose>
      <xsl:when test="$keep-sidebar">
        <xsl:copy copy-namespaces="no">
          <xsl:apply-templates select="@*, node()" mode="#current"/>
        </xsl:copy>
      </xsl:when>
      <xsl:otherwise/>
    </xsl:choose>
  </xsl:template>
  
  <!-- Override these in your adaptions-->
  <xsl:variable name="hub:marginal-note-container-style-regex" as="xs:string" select="'^(le-tex|tr)_margin-box'"/>
  <xsl:variable name="hub:marginal-note-para-style-regex" as="xs:string" select="'^(le-tex|tr)_p_margin'"/>
  
  
  <xsl:function name="hub:is-marginal-note" as="xs:boolean">
    <xsl:param name="sidebar" as="element(sidebar)?"/>
    <xsl:choose>
      <xsl:when test="matches($sidebar[@role]/@role, $hub:marginal-note-container-style-regex)">
        <xsl:sequence select="true()"/>
      </xsl:when>
      <xsl:when test="some $para in $sidebar/*:para satisfies (matches($para/@role, $hub:marginal-note-para-style-regex))">
        <xsl:sequence select="true()"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="false()"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
 
  <!-- collateral clean-up -->
  <xsl:template match="emphasis[every $attr in @* satisfies (matches(name($attr), '^(css:.+|text-indent|margin-left)$'))]" mode="hub:cross-link">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <xsl:template match="symbol" mode="hub:cross-link">
    <phrase role="hub:unmapped-char">
      <xsl:apply-templates select="@srcpath, node()" mode="#current">
        <xsl:with-param name="text" select="concat(@css:font-family, '/', .)" tunnel="yes"/>
      </xsl:apply-templates>
    </phrase>
  </xsl:template>

  <xsl:template match="text()[ancestor::symbol]" mode="hub:cross-link">
    <xsl:param name="text" tunnel="yes" as="xs:string"/>
    <xsl:value-of select="$text"/>
  </xsl:template>

  <!-- mode: hub:split-at-br -->

  <xsl:variable name="hub:split-at-br-element-names" as="xs:string+"
    select="('para', 'simpara')"/>
  
  <xsl:template match="*[local-name() = $hub:split-at-br-element-names][
                         .//br[
                           hub:same-scope(., current())
                         ]
                       ]
                       [hub:specify-split-at-br-elements(.)]" mode="hub:split-at-br">
    <xsl:variable name="context" select="." as="element(*)" />
    <xsl:variable name="prelim" as="element(*)+">
      <linegroup remap="{name()}">
        <xsl:apply-templates select="@* except @remap" mode="#current"/>
        <xsl:for-each-group select="descendant::node()[
                                      not(node())
                                      or local-name() = $hub:same-scope-element-names
                                  ][hub:same-scope(., current())]" group-starting-with="br">
          <xsl:apply-templates select="$context" mode="hub:upward-project-br">
          <xsl:with-param name="restricted-to" select="current-group()/ancestor-or-self::node()" tunnel="yes" />
        </xsl:apply-templates>
      </xsl:for-each-group>
      </linegroup>
    </xsl:variable>
    <xsl:apply-templates select="$prelim" mode="hub:apres-split-at-br" />
  </xsl:template>

  <xsl:function name="hub:specify-split-at-br-elements" as="xs:boolean">
    <xsl:param name="context" as="element(*)"/>
    <!-- you may override this funtion in your adaptions to handle only paras with a certain role for instance -->
    <xsl:sequence select="true()"/>
  </xsl:function>
  
  <xsl:variable name="hub:split-at-br-also-for-non-br-paras" as="xs:boolean" select="$split-at-br-also-for-non-br-paras = 'yes'"/>
  
  <xsl:template match="*[$hub:split-at-br-also-for-non-br-paras]
                        [local-name() = $hub:split-at-br-element-names]
                        [not(../local-name() = $hub:same-scope-element-names)][
                         not(.//br[
                           hub:same-scope(., current())
                         ])
                       ]
                       [hub:specify-split-at-br-context(.)]" mode="hub:split-at-br">
    <linegroup remap="{name()}">
      <line>
        <xsl:apply-templates select="@*, node()" mode="#current"/>
      </line>
    </linegroup>
  </xsl:template>

  <xsl:function name="hub:specify-split-at-br-context" as="xs:boolean">
    <xsl:param name="context" as="element(*)"/>
    <xsl:choose>
      <xsl:when test="$context[parent::dbk:poetry]">
      <!-- you may override this funtion in your adaptions to handle only paras with a certain role for instance or look for the parent elements -->
        <xsl:sequence select="true()"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="false()"/>
      </xsl:otherwise>
    </xsl:choose>
      
   
  </xsl:function>
  
  <xsl:template match="node()" mode="hub:upward-project-br">
    <xsl:param name="restricted-to" as="node()+" tunnel="yes" />
    <xsl:if test="exists(. intersect $restricted-to)">
      <xsl:copy>
        <xsl:sequence select="@*" />
        <xsl:apply-templates mode="#current" />
      </xsl:copy>
    </xsl:if>
  </xsl:template>

  <xsl:template match="*[local-name() = $hub:same-scope-element-names]" mode="hub:upward-project-br">
    <xsl:param name="restricted-to" as="node()+" tunnel="yes" />
    <xsl:if test="exists(. intersect $restricted-to)">
      <xsl:apply-templates select="." mode="hub:split-at-br" />
    </xsl:if>
  </xsl:template>

  <!-- list paragraphs without marker: -->
  <xsl:template match="*[local-name() = $hub:split-at-br-element-names][.//br[
                           hub:same-scope(., current()/..)
                         ]]/@*:text-indent[starts-with(., '-')]" mode="hub:apres-split-at-br">
    <xsl:attribute name="{name()}" select="'0'" />
  </xsl:template>

  <!--<xsl:template match="*[local-name() = $hub:split-at-br-element-names][.//br[
                           hub:same-scope(., current())
                         ]]" mode="hub:apres-split-at-br">
    <xsl:copy>
      <!-\-<xsl:attribute name="hub:split" select="'at-br'" />-\->
      <xsl:apply-templates select="@*, node()" mode="#current" />
    </xsl:copy>
  </xsl:template>-->

  <xsl:template match="linegroup/*[local-name() = $hub:split-at-br-element-names]" mode="hub:apres-split-at-br">
    <line>
      <!-- @* are on linegroup already and make problems, e.g. margins of whole para are given to each line. If some attributes are needed a call-template might be useful -->
      <xsl:apply-templates select="node()" mode="#current" />
    </line>
  </xsl:template>
  
  <xsl:template match="br" mode="hub:apres-split-at-br" />


  <!-- mode hub:repair-float-ids
       recount ids after moving floats -->

  <xsl:template match="figure/@xml:id" mode="hub:repair-float-ids">
    <xsl:attribute name="xml:id" select="concat('Fig', count(preceding::figure) + 1)"/>
  </xsl:template>

  <xsl:template match="table/@xml:id | informaltable/@xml:id" mode="hub:repair-float-ids">
    <xsl:attribute 
      name="xml:id" 
      select="concat('Tab', 
                     count(preceding::table union ancestor::table union
                           preceding::informaltable union ancestor::informaltable)
                     )"/>
  </xsl:template>

  <xsl:template match="link/@linkend[matches(., '^Fig')]" mode="hub:repair-float-ids">
    <xsl:attribute name="linkend"
      select="concat('Fig', count(ancestor::*[last()]//figure[@xml:id = current()]/preceding::figure) + 1)"/>
  </xsl:template>

  <xsl:template match="link/@linkend[matches(., '^Tab')]" mode="hub:repair-float-ids">
    <xsl:attribute name="linkend"
      select="concat('Tab', count(ancestor::*[last()]//*[name() = ('table', 'informaltable') and @xml:id = current()]/preceding::*[name() = ('table', 'informaltable')]) + 1)"/>
  </xsl:template>

  <xsl:template match="link[@linkend = ancestor::*[local-name() = ('figure', 'table')][1]/@xml:id]" mode="hub:repair-float-ids">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <!-- <xsl:template match="para[not(following::para)]" mode="hub:repair-float-ids"> -->
  <!--   <xsl:copy> -->
  <!--     <xsl:apply-templates select="@*, node()" mode="#current"/> -->
  <!--   </xsl:copy> -->
  <!--   <xsl:apply-templates select="$hub:missing-floats-after-placement/floats/*[self::table]" mode="hub:repair-float-ids"/> -->
  <!--   <xsl:apply-templates select="$hub:missing-floats-after-placement/floats/*[self::figure]" mode="hub:repair-float-ids"/> -->
  <!-- </xsl:template> -->

  <!-- mode: remove-hub-attributes -->

  <xsl:template match="/*/info/styles | /*/info/css:rules" mode="hub:remove-hub-attribs"/>
  
  <xsl:template match="tabs" mode="hub:remove-hub-attribs"/>
  
  <xsl:template match="@css:*" mode="hub:remove-hub-attribs"/>
  
  <xsl:template match="@hub:split" mode="hub:remove-hub-attribs"/>

  <xsl:template match="@hub-origin" mode="hub:remove-hub-attribs"/>

  <xsl:template match="processing-instruction('hub-origin')" mode="hub:remove-hub-attribs"/>
  
  <!-- mode: remove-debugging-info-origin -->

  <xsl:template match="@hub-origin" mode="hub:remove-debugging-info-origin"/>

  <xsl:template match="processing-instruction('hub-origin')" mode="hub:remove-debugging-info-origin"/>

</xsl:stylesheet>
