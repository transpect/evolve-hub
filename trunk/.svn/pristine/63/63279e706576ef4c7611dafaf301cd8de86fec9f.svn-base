<?xml version="1.0" encoding="utf-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c="http://www.w3.org/ns/xproc-step"  
  xmlns:cx="http://xmlcalabash.com/ns/extensions" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"  
  xmlns:tr="http://transpect.io"
  xmlns:hub="http://transpect.io/hub"
  version="1.0"
  name="evolve-hub">

  <!-- fallback pipeline:
       just build sections, lists and figure/table environments
   -->
  
  <p:option name="debug" required="false" select="'no'"/>
  <p:option name="debug-dir-uri" />
  
  <p:input port="source" primary="true"/>
  <p:input port="parameters" kind="parameter" primary="true"/>
  <p:input port="stylesheet"/>
  <p:output port="result" primary="true"/>
  
  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl" />
  <p:import href="http://transpect.io/xproc-util/xslt-mode/xpl/xslt-mode.xpl"/>
  <p:import href="http://transpect.io/evolve-hub/xpl/evolve-hub_lists-by-indent.xpl"/>
  <p:import href="http://transpect.io/evolve-hub/xpl/evolve-hub_lists-by-role.xpl"/>
  
  <p:documentation xmlns="http://www.w3.org/1999/xhtml">
    <p>Here all modes shall be explained. <pre class="variable">Variables</pre>, <pre class="function">functions</pre> and <span class="dependency">dependent modes</span> are tagged like this.</p>
    
    <dt>hub:dissolve-sidebars-without-purpose</dt>    
    <dd>Dissolves sidebars that are a result from anchoring text frames in InDesign. The function <pre class="function">hub:is-in-sidebar-without-purpose</pre> determines which sideabrs are dissolved. Default is sidebars without @role, that were text frames or groups in InDesign. Also paragraphs that contain only anchors for those sideabrs are discarded.</dd>
    
    <dt>hub:preprocess-hierarchy</dt>    
  	<dd>Some minor preprocessing templates exist. This mode is mainly for your project's adaptations. Clean stuff to make <span class="dependency">hub:hierarchy</span> work properly.</dd>
    
    <dt>hub:hierarchy</dt>
  	<dd>Important mode to create the basic hierarchy of the document. Define the paragraph styles of document headings in the variable <pre class="variable">hub:hierarchy-role-regex</pre>. According to the depths of the headings. The document is partitioned to sections at these paragraphs.</dd>
    
  	<dt>hub:postprocess-hierarchy</dt>    
  	<dd>Discard page end anchors. This mode is mainly for your project's adaptations. Map the sections created in mode <span class="dependency">hub:hierarchy</span> to hub elements. E.g. section → chapter or section → appendix.</dd>
  	
    <dt>hub:tabular-float-caption-arrangements</dt>
    <dd>Optional mode for preprocessing single-row, two-column informaltables where a float is in one cell
      and the caption is in another cell. Also: single-column, two-row arrangement.</dd>
    <dd>Pulls the caption out of the table. Should run before <span class="dependency">hub:table-captions</span> and <span class="dependency">hub:figure:captions</span>. (Also before their preprocessing modes.)</dd>

    <dt>hub:join-tables_LATER</dt>
    <dd>submode/later</dd>

    <dt>hub:join-tables</dt>
  	<dd>This mode merges table cells. Its main purpose is to handle the case that a cell was splitted in InDesign to fit the the page. When that cell has to be merged again in conversion a special style appendix is expected on those cells. 
  		It can be defined in variable <pre class="variable">hub:split-style-regex"</pre>, its default value is 'SPLIT'.</dd>
  	<dd>The case that a paragraph in the splitted cell also was splitted is handled in this mode as well. Therefore the <pre class="variable">hub:split-style-regex"</pre> has to be added to the respective paragraphs and merges them.</dd>
 
    <dt>hub:simplify-complex-float-sidebars</dt>
    <dd>Resolve IDML-specific float anchorings especially dissolving sidebar in figure and table context to allow later the creation of those environments.</dd>
    <dd>Sidebars (InDesign textframes) with following role <pre class="variable">hub:exclude-sidebar-from-dissolving-if-image-contained-role-regex</pre> will not be dissolved.</dd>
    
    <dt>hub:resolve-sidebar-floats</dt>
    <dd>Resolve IDML-specific float anchorings</dd>
    <dd>After <span class="dependency">identifying tables and figures</span>, they may be moved out of their sidebars and the sidebars are dissolved.</dd>

    <dt>hub:collect-continued-floats</dt>
    <dd>Compares caption numbers of float objects and collects title and mediaobject into a figure or table element</dd>
    <dd class="todo">todo: implementation for tables (no data to test with, yet)</dd>

    <dt>hub:sort-figure-captions</dt>    
    <dd>If every figure caption is followed by a mediaobject, it may be assumed that the captions are consistently above the figures.
     In order to make <span class="dependency">hub:figure-captions</span> work properly, the captions are pulled down, below each mediaobject.</dd>
    <dt>hub:sort-table-captions</dt>    
    <dd>If every informaltable is followed by a caption, it may be assumed that the captions are consistently below the tables.
     In order to make <span class="dependency">hub:table-captions</span> work properly, the captions are pulled up, above each table.</dd>

    <dt>hub:join-phrases</dt>    
    <dd>Merge phrases/superscripts/subscripts when they have no varying attributes.</dd>
 
    <dt>hub:join-phrases-unwrap</dt>    
    <dd>submode</dd>

    <dt>hub:phrase-signature</dt>    
    <dd>submode</dd>
 
    <dt>hub:evolve-textreference-to-link</dt>    
    <dd></dd>
  	
    <dt>hub:figure-captions (figure-captions)</dt>
    <dd></dd>
    <dd>hub:figure-captions-preprocess-merge (figure-captions)</dd>
    <dd></dd>
  	
    <dt>hub:join-links</dt>    
    <dd></dd>

    <dt>hub:toc2</dt>    
    <dd></dd>
    <dt>hub:toc2-pagenum</dt>    
    <dd></dd>
 
    <dt>hub:special-paras</dt>    
    <dd></dd>
    <dt>hub:special-phrases</dt>    
    <dd></dd>

    <dt>hub:blockquotes</dt>    
    <dd>Creates blockquote elements around adjacent paragraphs with blockquote styles. They are defined in <pre class="variable">hub:blockquote-role-regex</pre>.</dd>
 
    <dt>hub:split-at-tab</dt>    
  	<dd>Optional mode that will split phrases and other elements within a para that contains tabs, such that the tabs become immediate children of the para.</dd>
  
    <dt>hub:upward-project-tab</dt>    
    <dd>submode</dd>

    <dt>hub:right-tab-to-tables</dt>    
    <dd>Optional mode that creates two-columns informaltables with the role hub:right-tab of 
      adjacent paras with right tabs. There is no preferred point in the pipeline when this 
      mode should run. Maybe run it before lists. Requires that <span class="dependency">hub:split-at-tab</span> has run before.</dd>

    <dd>You can set a regex variable <pre class="variable">hub:post-identifier-regex</pre> to override the table creation and create an identifier instead. In this case it will be labeled as phrase @role = 'hub:post-identifier'.</dd>

    <dt>hub:repair-hierarchy</dt>    
    <dd></dd>
  
    <dt>hub:identifiers</dt>    
    <dd></dd>
 
    <dt>hub:indexterms (relocate-indexterms)</dt>    
    <dd></dd>

    <dt>hub:insert-caption-num-to-text-separator</dt>    
    <dd></dd>

    <dt>hub:fix-floats-strip-num</dt>    
    <dd></dd>

    <dt>hub:table-captions (table-captions)</dt>
    <dd>This mode converts informaltables to real tables when a title can be determined. The paragraph style of the table has to set in <pre class="variable">hub:table-title-role-regex-x</pre>.</dd>
  	<dd>Different settings can be done, for example whether the caption has to start with text of a certain pattern (<pre class="variable">hub:table-caption-must-begin-with-table-caption-start-regex</pre>)</dd>
  	
    <dt>hub:table-captions-preprocess-merge (table-captions)</dt>
    <dd></dd>

    <dt>hub:table-merge (table-merge)</dt>
    <dd></dd>

    <dt>hub:twipsify-lengths</dt>    
    <dd></dd>

    <dt>hub:twipsify-lengths hub:expand-css-properties</dt>    
    <dd></dd>

    <dt>hub:no-floats</dt>    
    <dd></dd>

    <dt>hub:clean-hub</dt>    
    <dd>General postprocessing mode. Discard unwanted attributes or elements here.</dd>
  	<dd>By default phrases are dissolved that have the same formatting as their parents. You can change that behaviour by setting <pre class="variable">hub:dissolve-phrases-with-same-formatting-as-parent</pre> to false().</dd>

    <dt>hub:tabs-to-indent (lists-by-indent)</dt>    
    <dd>Converts tabs and negative indents/left margins to attributes: @indent and @margin-left.</dd>

    <dt>hub:handle-indent (lists-by-indent)</dt>    
    <dd>Creates ordered lists from paras whose @indent and @margin-left attributes match the list criteria and who have got an hub:identifier created in the mode <span class="dependency">hub:identifier</span>.</dd>
    <dd>You can overwrite the variable <pre class="variable">hub:list-by-indent-exception-role-regex</pre> to name paragraph style names that are excluded from the list generation.</dd>
    <dd>With the xs:boolean function <pre class="function">hub:condition-that-stops-indenting-apart-from-role-regex</pre> you can exlude further paras from this process. E.g. paras with tables inside, empty paras or using only list paras by list style.</dd>

    <dt>hub:prepare-lists (lists-by-indent)</dt>    
    <dd>Pulls sub list items into preceding list item. </dd>
    <dd>Detects consecutive list paras and sort them into preceding listitem </dd>

    <dt>hub:lists (lists-by-indent)</dt>    
    <dd>Creates ordered, itemized or variable lists from the temporarily created orderd lists in <span class="dependency">hub:handle-indent</span>.</dd>
    <dd>There are several variables that can be overridden to specify lists of marks that are used to determine whether something is an itemized or ordered list. For example <pre class="variable">hub:itemizedlist-mark-chars-regex</pre> or <pre class="variable">hub:orderedlist-mark-chars-regex</pre></dd>
    <dd>Indentations that are not recognized as lists are converted to blockquote with role hub:lists</dd>

    <dt>hub:postprocess-lists (lists-by-indent)</dt>    
    <dd>Sets back some variable lists to ordered/itemized lists or even paras.</dd>

    <dt>hub:ids</dt>    
    <dd></dd>

    <dt>hub:aux</dt>    
    <dd></dd>

    <dt>hub:aux-identifier</dt>    
    <dd>submode</dd>

    <dt>hub:cross-link</dt>    
    <dd></dd>

    <dt>hub:cross-link-resolve</dt>    
    <dd></dd>

    <dt>hub:reorder-marginal-notes</dt>    
  	<dd>In this mode sidebars are placed inside the paras they were originally anchored. This needed for correct list creation, blockquote creation etc. 
  		and before every mode whose results would be faulty if paragraphs are interrupted by sidebars. </dd>
  	<dd>Set <pre class="variable">sidenote-at-end-of-para-style-regex</pre> to define paras where the sidebar is pulled to the end. Otherwise thyey are included at the start of the paragraph. List paragraphs should be defined here.</dd>
  	<dd>Define title style names in <pre class="variable">sidenote-not-to-be-pulled-in-titles</pre>. For those paragraphs the sidebars are not pulled into, but after.</dd>
  	<dd>This should happen before the <span class="dependency">list modes</span> and after <span class="dependency">postprocess-hierarchy</span></dd>

    <dt>hub:split-at-br</dt>    
    <dd><pre class="variable">Split-at-br-elements</pre> [Paras and simparas] with a descendant br are split at br and are transformed to a verse-group. The sequences between the br elements are put into a verse-line element.</dd>
    <dd>The function <pre class="function">hub:specify-split-at-br-elements</pre> can constrain the <pre class="variable">Split-at-br-elements</pre> in your adaptions.</dd>
    <dd class="todo">The srcpath of the parent element is duplicated.</dd>
    <dd>Also elements without br elements and whose parent is not one of annotation', 'entry', 'blockquote', 'figure', 'footnote', 'listitem' or 'table' are turned to a verse-group/verse-line when their ancestor is a poem. 
     To determine the poem or other wanted context you should use the mode after <span cass="dependency">hub:postprocess-hierarchy</span> and override the function <pre class="function">hub:specify-split-at-br-context</pre> determine which elements are handled.</dd>

    <dt>hub:upward-project-br</dt>    
    <dd>submode</dd>

    <dt>hub:apres-split-at-br</dt>    
    <dd>submode</dd>

    <dt>hub:repair-float-ids</dt>
    <dd></dd>    
    
    <dt>hub:handle-phrase</dt>
    <dd>In this mode special phrase treatment should be realized. Currently whitespace phrases that only contain font size, style and weight information are removed.</dd>
  </p:documentation>
  
  
  <p:parameters name="consolidate-params">
    <p:input port="parameters">
      <p:pipe port="parameters" step="evolve-hub"/>
    </p:input>
  </p:parameters>

  <tr:xslt-mode msg="yes" hub-version="1.2" prefix="evolve-hub/00" mode="hub:split-at-tab">
    <p:input port="source"><p:pipe step="evolve-hub" port="source"/></p:input>
    <p:input port="stylesheet"><p:pipe step="evolve-hub" port="stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:xslt-mode>
  
  <tr:xslt-mode msg="yes" hub-version="1.2" prefix="evolve-hub/01" mode="hub:dissolve-sidebars-without-purpose">
    <p:input port="stylesheet"><p:pipe step="evolve-hub" port="stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:xslt-mode>
  
  <tr:xslt-mode msg="yes" hub-version="1.2" prefix="evolve-hub/02" mode="hub:preprocess-hierarchy">
    <p:input port="stylesheet"><p:pipe step="evolve-hub" port="stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:xslt-mode>
  
  <tr:xslt-mode msg="yes" hub-version="1.2" prefix="evolve-hub/03" mode="hub:hierarchy">
    <p:input port="stylesheet"><p:pipe step="evolve-hub" port="stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:xslt-mode>
  
  <tr:xslt-mode msg="yes" hub-version="1.2" prefix="evolve-hub/04" mode="hub:postprocess-hierarchy">
    <p:input port="stylesheet"><p:pipe step="evolve-hub" port="stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:xslt-mode>
  
  <tr:xslt-mode msg="yes" hub-version="1.2" prefix="evolve-hub/11" mode="hub:subfigure-captions">
    <p:input port="stylesheet"><p:pipe step="evolve-hub" port="stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:xslt-mode>

  <tr:xslt-mode msg="yes" hub-version="1.2" prefix="evolve-hub/12" mode="hub:figure-captions">
    <p:input port="stylesheet"><p:pipe step="evolve-hub" port="stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:xslt-mode>
  
  <tr:xslt-mode msg="yes" hub-version="1.2" prefix="evolve-hub/13" mode="hub:table-captions">
    <p:input port="stylesheet"><p:pipe step="evolve-hub" port="stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:xslt-mode>

  <tr:xslt-mode msg="yes" hub-version="1.2" prefix="evolve-hub/40" mode="hub:repair-hierarchy">
    <p:input port="stylesheet"><p:pipe step="evolve-hub" port="stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:xslt-mode>
  
  <tr:xslt-mode msg="yes" hub-version="1.2" prefix="evolve-hub/41" mode="hub:join-phrases">
    <p:input port="stylesheet"><p:pipe step="evolve-hub" port="stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:xslt-mode>
  
  <tr:xslt-mode msg="yes" hub-version="1.2" prefix="evolve-hub/42" mode="hub:twipsify-lengths">
    <p:input port="stylesheet"><p:pipe step="evolve-hub" port="stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:xslt-mode>
  
  <tr:xslt-mode msg="yes" hub-version="1.2" prefix="evolve-hub/44" mode="hub:identifiers">
    <p:input port="stylesheet"><p:pipe step="evolve-hub" port="stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:xslt-mode>
  
  <!--  parameter 'evolve-hub-list-processing' selects list hierarchizing by indent or by role (role|indent) -->
  <p:choose>
    <p:variable name="evolve-hub-list-processing" select="/*/c:param[@name='evolve-hub-list-processing']/@value">
      <p:pipe port="result" step="consolidate-params"/>
    </p:variable>
    <p:when test="$evolve-hub-list-processing='role'">
      <hub:evolve-hub_lists-by-role>
        <p:input port="stylesheet"><p:pipe step="evolve-hub" port="stylesheet"/></p:input>
        <p:input port="parameters"><p:pipe port="result" step="consolidate-params"/></p:input>
        <p:with-option name="debug" select="$debug"/>
        <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
      </hub:evolve-hub_lists-by-role>
    </p:when>
    <p:otherwise>
      <hub:evolve-hub_lists-by-indent>
        <p:input port="stylesheet"><p:pipe step="evolve-hub" port="stylesheet"/></p:input>
        <p:input port="parameters"><p:pipe port="result" step="consolidate-params"/></p:input>
        <p:with-option name="debug" select="$debug"/>
        <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
      </hub:evolve-hub_lists-by-indent>
    </p:otherwise>
  </p:choose>
  
  <tr:xslt-mode msg="yes" hub-version="1.2" prefix="evolve-hub/60" mode="hub:ids">
    <p:input port="stylesheet"><p:pipe step="evolve-hub" port="stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:xslt-mode>
  
  <tr:xslt-mode hub-version="1.2" msg="yes" prefix="evolve-hub/75" mode="hub:handle-phrase">
    <p:input port="stylesheet"><p:pipe port="stylesheet" step="evolve-hub"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:xslt-mode>
  
  <tr:xslt-mode msg="yes" hub-version="1.2" prefix="evolve-hub/90" mode="hub:clean-hub">
    <p:input port="stylesheet"><p:pipe step="evolve-hub" port="stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:xslt-mode>
  
</p:declare-step>