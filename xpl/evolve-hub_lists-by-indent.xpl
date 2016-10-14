<?xml version="1.0" encoding="utf-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c="http://www.w3.org/ns/xproc-step"  
  xmlns:cx="http://xmlcalabash.com/ns/extensions" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:hub="http://transpect.io/hub"  
  xmlns:tr="http://transpect.io"
  version="1.0"
  name="lists-by-indent"
  type="hub:evolve-hub_lists-by-indent">
  
  <p:option name="debug" required="false" select="'no'"/>
  <p:option name="debug-dir-uri" select="'debug-dir-uri'"/>
  <p:option name="status-dir-uri" select="'status-dir-uri'"/>
  <p:option name="fail-on-error" select="'no'"/>
  <p:option name="prefix" required="false" select="'evolve-hub/5'"/>
  
  <p:input port="source" primary="true"/>
  <p:input port="parameters" kind="parameter" primary="true"/>
  <p:input port="stylesheet"/>
  <p:output port="result" primary="true"/>
  <p:output port="report" sequence="true">
    <p:pipe port="report" step="tabs-to-indent"/>
    <p:pipe port="report" step="handle-indent"/>
    <p:pipe port="report" step="prepare-lists"/>
    <p:pipe port="report" step="lists"/>
    <p:pipe port="report" step="postprocess-lists"/>
  </p:output>
  
  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl" />
  <p:import href="http://transpect.io/xproc-util/xslt-mode/xpl/xslt-mode.xpl"/>

  <tr:xslt-mode msg="yes" hub-version="1.2" mode="hub:tabs-to-indent" name="tabs-to-indent">
    <p:input port="source">
      <p:pipe step="lists-by-indent" port="source"/>
    </p:input>
    <p:input port="stylesheet"><p:pipe step="lists-by-indent" port="stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:with-option name="status-dir-uri" select="$status-dir-uri"/>
    <p:with-option name="prefix" select="concat($prefix, '0')"/>
  </tr:xslt-mode>
  
  <tr:xslt-mode msg="yes" hub-version="1.2" mode="hub:handle-indent" name="handle-indent">
    <p:input port="stylesheet"><p:pipe step="lists-by-indent" port="stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:with-option name="status-dir-uri" select="$status-dir-uri"/>
    <p:with-option name="prefix" select="concat($prefix, '1')"/>
  </tr:xslt-mode>
  
  <tr:xslt-mode msg="yes" hub-version="1.2" mode="hub:prepare-lists" name="prepare-lists">
    <p:input port="stylesheet"><p:pipe step="lists-by-indent" port="stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:with-option name="status-dir-uri" select="$status-dir-uri"/>
    <p:with-option name="prefix" select="concat($prefix, '2')"/>
  </tr:xslt-mode>
  
  <tr:xslt-mode msg="yes" hub-version="1.2" mode="hub:lists" name="lists">
    <p:input port="stylesheet"><p:pipe step="lists-by-indent" port="stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:with-option name="status-dir-uri" select="$status-dir-uri"/>
    <p:with-option name="prefix" select="concat($prefix, '3')"/>
  </tr:xslt-mode>
  
  <tr:xslt-mode msg="yes" hub-version="1.2" mode="hub:postprocess-lists" name="postprocess-lists">
    <p:input port="stylesheet"><p:pipe step="lists-by-indent" port="stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:with-option name="status-dir-uri" select="$status-dir-uri"/>
    <p:with-option name="prefix" select="concat($prefix, '4')"/>
  </tr:xslt-mode>
    
</p:declare-step>
