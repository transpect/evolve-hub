<?xml version="1.0" encoding="utf-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c="http://www.w3.org/ns/xproc-step"  
  xmlns:cx="http://xmlcalabash.com/ns/extensions" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:hub="http://transpect.io/hub"  
  xmlns:tr="http://transpect.io"
  version="1.0"
  name="evolve-hub_lists-by-role"
  type="hub:evolve-hub_lists-by-role">
  
  <p:option name="debug" required="false" select="'no'"/>
  <p:option name="debug-dir-uri" select="'debug-dir-uri'"/>
  <p:option name="debug-indent" select="'true'">
    <p:documentation>Whether debug files should be indented.</p:documentation>
  </p:option>
  <p:option name="status-dir-uri" select="'status-dir-uri'"/>
  <p:option name="fail-on-error" select="'no'"/>
  <p:option name="prefix" required="false" select="'evolve-hub/5'"/>
  <p:option name="hub-version" required="false" select="'1.2'"/>
  
  <p:input port="source" primary="true"/>
  <p:input port="parameters" kind="parameter" primary="true" sequence="true"/>
  <p:input port="stylesheet">
    <p:document href="../xsl/evolve-hub.xsl"/>
  </p:input>
  <p:output port="result" primary="true"/>
  <p:output port="report" sequence="true">
    <p:pipe port="report" step="prepare-lists-by-role"/>
    <p:pipe port="report" step="lists-by-role"/>
    <p:pipe port="report" step="postprocess-lists-by-role"/>
    <p:pipe port="report" step="restore-roles"/>
  </p:output>
  
  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl" />
  <p:import href="http://transpect.io/xproc-util/xslt-mode/xpl/xslt-mode.xpl"/>
  <p:import href="http://transpect.io/xproc-util/store-debug/xpl/store-debug.xpl"/>

  <p:parameters name="consolidate-params">
    <p:input port="parameters">
      <p:pipe port="parameters" step="evolve-hub_lists-by-role"/>
    </p:input>
  </p:parameters>
  
  <tr:xslt-mode msg="yes" mode="hub:tabs-to-indent" name="tabs-to-indent">
    <p:input port="source">
      <p:pipe step="evolve-hub_lists-by-role" port="source"/>
    </p:input>
    <p:input port="stylesheet"><p:pipe step="evolve-hub_lists-by-role" port="stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:input port="parameters"><p:pipe port="result" step="consolidate-params"/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-indent" select="$debug-indent"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:with-option name="status-dir-uri" select="$status-dir-uri"/>
    <p:with-option name="prefix" select="concat($prefix, '0')"/>
    <p:with-option name="hub-version" select="$hub-version"/>
  </tr:xslt-mode>

  <tr:xslt-mode msg="yes" mode="hub:prepare-lists-by-role" name="prepare-lists-by-role">
     <!--<p:input port="source">
      <p:pipe step="evolve-hub_lists-by-role" port="source"/>
    </p:input>-->
    <p:input port="stylesheet"><p:pipe step="evolve-hub_lists-by-role" port="stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:input port="parameters"><p:pipe port="result" step="consolidate-params"/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-indent" select="$debug-indent"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:with-option name="status-dir-uri" select="$status-dir-uri"/>
    <p:with-option name="prefix" select="concat($prefix, '0')"/>
    <p:with-option name="hub-version" select="$hub-version"/>
    <p:with-param name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:xslt-mode>
  
  <tr:xslt-mode msg="yes" mode="hub:lists-by-role" name="lists-by-role">
    <p:input port="stylesheet"><p:pipe step="evolve-hub_lists-by-role" port="stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:input port="parameters"><p:pipe port="result" step="consolidate-params"/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-indent" select="$debug-indent"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:with-option name="status-dir-uri" select="$status-dir-uri"/>
    <p:with-option name="prefix" select="concat($prefix, '2')"/>
    <p:with-option name="hub-version" select="$hub-version"/>
  </tr:xslt-mode>
  
  <tr:xslt-mode msg="yes" mode="hub:postprocess-lists-by-role" name="postprocess-lists-by-role">
    <p:input port="stylesheet"><p:pipe step="evolve-hub_lists-by-role" port="stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:input port="parameters"><p:pipe port="result" step="consolidate-params"/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-indent" select="$debug-indent"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:with-option name="status-dir-uri" select="$status-dir-uri"/>
    <p:with-option name="prefix" select="concat($prefix, '4')"/>
    <p:with-option name="hub-version" select="$hub-version"/>
  </tr:xslt-mode>
  
  <tr:xslt-mode msg="yes" mode="hub:restore-roles" name="restore-roles">
    <p:input port="stylesheet"><p:pipe step="evolve-hub_lists-by-role" port="stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:input port="parameters"><p:pipe port="result" step="consolidate-params"/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-indent" select="$debug-indent"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:with-option name="status-dir-uri" select="$status-dir-uri"/>
    <p:with-option name="prefix" select="concat($prefix, '6')"/>
    <p:with-option name="hub-version" select="$hub-version"/>
  </tr:xslt-mode>
    
</p:declare-step>
