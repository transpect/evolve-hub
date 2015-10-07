<?xml version="1.0" encoding="utf-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c="http://www.w3.org/ns/xproc-step"  
  xmlns:cx="http://xmlcalabash.com/ns/extensions" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:tr="http://transpect.io"
  xmlns:hub="http://transpect.io/hub"
  version="1.0"
  name="evolve-hub"
  type="hub:evolve-hub">
  
  <p:documentation>
    evolve-hub deals with up-converting flat hub to hub documents with proper
    lists, hierarchies, etc. This is the up-conversion part where most knowledge
    about layout and style names (e.g., for headings or box types) comes into
    play. Therefore it is essential that everything is customizable per imprint,
    series, work, etc. 
    The basic evolve-hub.xsl library is an XSLT micropipeline. It uses some 
    meta-information from the hub input data to determine whether the document
    is already purportedly hierarchized or contains proper lists. But other than
    some branching according to these document properties and XSLT’s import 
    mechanism (that allows for clumsy reshuffling of the default pipeline),
    the pipeline is of a fixed, one-size-fits-all kind.
    Therefore we outsource the pipelining part to XProc here, and we allow
    evaluation of pipelines that are determined dynamically at runtime. 
    This front-end pipeline step loads dynamically evolve-hub/driver.xpl and 
    evolve-hub/driver.xsl from the first configuration directory where it can 
    find each file. The directories searched are, in that order, from higher to 
    lower specificity: work, series, publisher, common.
    driver.xsl imports the central evolve-hub.xsl and typically configures variables
    for the relevant modes. 
    driver.xpl is a custom pipeline that orchestrates some or all of the modes 
    available in evolve-hub. 
    Please note that every transformation in evolve-hub.xpl always uses the same
    XSLT, namely the most specific driver.xsl that could be found. 
    If templates are needed that aren’t included in evolve-hub or driver.xsl,
    they’d have to be imported by driver.xsl, too.
    Also note that driver.xsl and driver.xpl don’t need to reside in the same 
    configuration directory. You might perfectly well use the common pipeline 
    together with a series’ XSLT stylesheet. The transpect:load-cascaded mechanism will
    take care of loading the most specific available of each file type. 
    If some (not just one, not all) series would like to share a pipeline or an 
    XSLT stylesheet, they should create the corresponding files at some location
    (= for some series) and create stub pipelines/stylesheets in the other 
    locations. These stubs should simply import the master series’ files.
  </p:documentation>
  
  <p:option name="load" required="false" select="'evolve-hub/driver'"/>
  <p:option name="srcpaths" required="false" select="'no'"/>
  <p:option name="debug" required="false" select="'no'"/>
  <p:option name="debug-dir-uri" select="'debug'"/>
  <p:option name="status-dir-uri" select="'status'"/>
  <p:option name="fallback-xsl" select="'http://transpect.io/evolve-hub/xsl/evolve-hub.xsl'"/>
  <p:option name="fallback-xpl" select="'http://transpect.io/evolve-hub/xpl/fallback.xpl'"/>
  
  <p:input port="source" primary="true" sequence="true"/>
  <p:input port="paths" kind="parameter" primary="true"/>
  <p:output port="result" primary="true" sequence="true"/>
  
  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl" />
  <p:import href="http://transpect.io/cascade/xpl/dynamic-transformation-pipeline.xpl"/>
  <p:import href="http://transpect.io/xproc-util/simple-progress-msg/xpl/simple-progress-msg.xpl"/>
  
  <tr:simple-progress-msg name="start-msg" file="evolve-hub-start.txt">
    <p:input port="msgs">
      <p:inline>
        <c:messages>
          <c:message xml:lang="en">Starting upconversion of flat Hub XML (section hierarchies etc.)</c:message>
          <c:message xml:lang="de">Beginne Hochkonvertierung des flachen Hub XML (Überschriftenhierarchie etc.)</c:message>
        </c:messages>
      </p:inline>
    </p:input>
    <p:with-option name="status-dir-uri" select="$status-dir-uri"/>
  </tr:simple-progress-msg>
  
  <tr:dynamic-transformation-pipeline> 
    <p:with-option name="fallback-xpl" select="$fallback-xpl"/>
    <p:with-option name="fallback-xsl" select="$fallback-xsl"/>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:with-option name="load" select="$load"/>
    <p:input port="additional-inputs"><p:empty/></p:input>
    <p:input port="options"><p:empty/></p:input>
  </tr:dynamic-transformation-pipeline>

  <tr:simple-progress-msg name="success-msg" file="evolve-hub-success.txt">
    <p:input port="msgs">
      <p:inline>
        <c:messages>
          <c:message xml:lang="en">Successfully evolved Hub XML</c:message>
          <c:message xml:lang="de">Evolution des flachen Hub XML erfolgreich abgeschlossen</c:message>
        </c:messages>
      </p:inline>
    </p:input>
    <p:with-option name="status-dir-uri" select="$status-dir-uri"/>
  </tr:simple-progress-msg>

</p:declare-step>
