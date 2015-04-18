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
  
  <tr:xslt-mode msg="yes" hub-version="1.1" prefix="evolve-hub/00" mode="hub:split-at-tab">
    <p:input port="stylesheet"><p:pipe step="evolve-hub" port="stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:xslt-mode>
  
  
  <tr:xslt-mode msg="yes" hub-version="1.1" prefix="evolve-hub/01" mode="hub:dissolve-sidebars-without-purpose">
    <p:input port="stylesheet"><p:pipe step="evolve-hub" port="stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:xslt-mode>
  
  <tr:xslt-mode msg="yes" hub-version="1.1" prefix="evolve-hub/02" mode="hub:preprocess-hierarchy">
    <p:input port="stylesheet"><p:pipe step="evolve-hub" port="stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:xslt-mode>
  
  <tr:xslt-mode msg="yes" hub-version="1.1" prefix="evolve-hub/03" mode="hub:hierarchy">
    <p:input port="stylesheet"><p:pipe step="evolve-hub" port="stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:xslt-mode>
  
  <tr:xslt-mode msg="yes" hub-version="1.1" prefix="evolve-hub/04" mode="hub:postprocess-hierarchy">
    <p:input port="stylesheet"><p:pipe step="evolve-hub" port="stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:xslt-mode>

  <tr:xslt-mode msg="yes" hub-version="1.1" prefix="evolve-hub/12" mode="hub:figure-captions">
    <p:input port="stylesheet"><p:pipe step="evolve-hub" port="stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:xslt-mode>
  
  <tr:xslt-mode msg="yes" hub-version="1.1" prefix="evolve-hub/13" mode="hub:table-captions">
    <p:input port="stylesheet"><p:pipe step="evolve-hub" port="stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:xslt-mode>

  <tr:xslt-mode msg="yes" hub-version="1.1" prefix="evolve-hub/40" mode="hub:repair-hierarchy">
    <p:input port="stylesheet"><p:pipe step="evolve-hub" port="stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:xslt-mode>
  
  <tr:xslt-mode msg="yes" hub-version="1.1" prefix="evolve-hub/41" mode="hub:join-phrases">
    <p:input port="stylesheet"><p:pipe step="evolve-hub" port="stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:xslt-mode>
  
  <tr:xslt-mode msg="yes" hub-version="1.1" prefix="evolve-hub/42" mode="hub:twipsify-lengths">
    <p:input port="stylesheet"><p:pipe step="evolve-hub" port="stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:xslt-mode>
  
  <tr:xslt-mode msg="yes" hub-version="1.1" prefix="evolve-hub/44" mode="hub:identifiers">
    <p:input port="stylesheet"><p:pipe step="evolve-hub" port="stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:xslt-mode>
  
  <hub:evolve-hub_lists-by-indent>
    <p:input port="stylesheet"><p:pipe step="evolve-hub" port="stylesheet"/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </hub:evolve-hub_lists-by-indent>
  
  <tr:xslt-mode msg="yes" hub-version="1.1" prefix="evolve-hub/60" mode="hub:ids">
    <p:input port="stylesheet"><p:pipe step="evolve-hub" port="stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:xslt-mode>
  
  <tr:xslt-mode msg="yes" hub-version="1.1" prefix="evolve-hub/90" mode="hub:clean-hub">
    <p:input port="stylesheet"><p:pipe step="evolve-hub" port="stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:xslt-mode>
  
</p:declare-step>