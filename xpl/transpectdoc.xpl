<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step 
  xmlns:p="http://www.w3.org/ns/xproc"
  xmlns:c="http://www.w3.org/ns/xproc-step" 
  xmlns:cx="http://xmlcalabash.com/ns/extensions" 
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

  <p:input port="rendering-xslt">
    <p:document href="../xsl/render-html-pages.xsl"/>
  </p:input>
  
<!--  <p:output port="result" primary="true"/>
  <p:serialization port="result" omit-xml-declaration="false" indent="true"/>
-->
  <p:option name="debug" required="false" select="'yes'"/>
  <p:option name="debug-dir-uri" required="false" select="'debug'"/>
  
  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
  <p:import href="http://transpect.le-tex.de/xproc-util/store-debug/store-debug.xpl"/>

  <p:variable name="base-dir-uri-regex" 
    select="replace(
              replace(
                static-base-uri(), 
                'transpectdoc/xpl(/.*)?$', 
                ''
              ),
              '^file:/+',
              '^file:/+'
            )">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <p><a href="https://twitter.com/westmaaan/status/447696882442043392/photo/1">Assumption</a>: 
        no regex reserved chars such as brackets or curly braces in static-base-uri()</p>
    </p:documentation>
  </p:variable>

  <p:xslt name="crawl" template-name="main">
    <p:input port="source">
      <p:pipe port="source" step="transpectdoc"/>
      <p:document href="lib/xproc-1.0.xpl"/>
    </p:input>
    <p:input port="parameters"><p:empty/></p:input>
    <p:with-param name="base-dir-uri-regex" select="$base-dir-uri-regex"/>
    <p:input port="stylesheet">
      <p:pipe port="crawling-xslt" step="transpectdoc"/>
    </p:input>
  </p:xslt>
  
  <letex:store-debug pipeline-step="transpectdoc/1.crawl">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </letex:store-debug>

  <p:xslt name="connections">
    <p:documentation>Makes implicit primary port connections explicit. 
      As an unrelated side effect, will normalize plain text and DocBook markup within 
    p:documentation elements to HTML.</p:documentation>
    <p:input port="parameters"><p:empty/></p:input>
    <p:input port="stylesheet">
      <p:pipe port="connections-xslt" step="transpectdoc"/>
    </p:input>
  </p:xslt>
  
  <letex:store-debug pipeline-step="transpectdoc/2.connect">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </letex:store-debug>
  
  <p:xslt name="render">
    <p:input port="parameters"><p:empty/></p:input>
    <p:input port="stylesheet">
      <p:pipe port="rendering-xslt" step="transpectdoc"/>
    </p:input>
  </p:xslt>
  
  <p:sink/>
  
  <p:for-each>
    <p:iteration-source>
      <p:pipe port="secondary" step="render"/>
    </p:iteration-source>
    <p:store omit-xml-declaration="false">
      <p:with-option name="href" select="base-uri()"/>
    </p:store>
  </p:for-each>
  
</p:declare-step>