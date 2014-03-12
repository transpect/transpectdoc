<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step 
  xmlns:p="http://www.w3.org/ns/xproc"
  xmlns:c="http://www.w3.org/ns/xproc-step" 
  xmlns:letex="http://www.le-tex.de/namespace"
  exclude-inline-prefixes="#all"
  version="1.0"
  name="transpectdoc">
  
  <p:documentation xmlns="http://www.w3.org/1999/xhtml">
    <p>This pipeline documents all pipelines and library that are used in a project.</p>
    <p>The source documents are considered as the front-end pipelines. All other imported
    libraries and steps will be crawled.</p>
    <p>For each of the steps’ input and output ports, a linked list will be generated 
    that points to the ports in other pipelines that are connected to these ports.</p>
  </p:documentation>
  
  <p:input port="source" sequence="true" primary="true">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <p>The front-end pipelines of the transpect installation.</p>
    </p:documentation>
  </p:input>
  
  <p:input port="crawling-xslt">
    <p:document href="../xsl/crawl.xsl"/>
  </p:input>

  <p:input port="connections-xslt">
    <p:document href="../xsl/connections.xsl"/>
  </p:input>
  
  <p:output port="result" primary="true"/>
  <p:serialization port="result" omit-xml-declaration="false" indent="true"/>

  <p:option name="debug" required="false" select="'yes'"/>
  <p:option name="debug-dir-uri" required="false" select="'debug'"/>
  
  <p:import href="http://transpect.le-tex.de/xproc-util/store-debug/store-debug.xpl"/>
  
  <p:xslt name="crawl" template-name="main">
    <p:input port="source">
      <p:pipe port="source" step="transpectdoc"/>
      <p:document href="lib/xproc-1.0.xpl"/>
    </p:input>
    <p:input port="parameters"><p:empty/></p:input>
    <p:input port="stylesheet">
      <p:pipe port="crawling-xslt" step="transpectdoc"/>
    </p:input>
  </p:xslt>
  
  <letex:store-debug pipeline-step="transpectdoc/1.crawl">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </letex:store-debug>

  <p:xslt name="connections">
    <p:input port="parameters"><p:empty/></p:input>
    <p:input port="stylesheet">
      <p:pipe port="connections-xslt" step="transpectdoc"/>
    </p:input>
  </p:xslt>
  
  <letex:store-debug pipeline-step="transpectdoc/2.connect">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </letex:store-debug>

</p:declare-step>