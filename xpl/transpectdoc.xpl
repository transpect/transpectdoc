<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step 
  xmlns:p="http://www.w3.org/ns/xproc"
  xmlns:c="http://www.w3.org/ns/xproc-step" 
  xmlns:cx="http://xmlcalabash.com/ns/extensions"
  xmlns:cxf="http://xmlcalabash.com/ns/extensions/fileutils" 
  xmlns:pxf="http://exproc.org/proposed/steps/file"
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
    <p>Sample invocation (from a Makefile):</p>
    <pre>FRONTEND_PIPELINES = adaptions/common/xpl/idml2hobots.xpl adaptions/common/xpl/hobots2epub-frontend.xpl crossref/xpl/process-crossref-results.xpl crossref/xpl/jats-submit-crossref-query.xpl
transpectdoc: $(addprefix $(MAKEFILEDIR)/,$(FRONTEND_PIPELINES))
	$(CALABASH) $(foreach pipe,$^,$(addprefix -i source=,$(call uri,$(pipe)))) \
		$(call uri,transpectdoc/xpl/transpectdoc.xpl) \
		debug=$(DEBUG) debug-dir-uri=$(call uri,$(MAKEFILEDIR)/transpectdoc/debug)
</pre>
    <p>For customizing transpectdoc, there are three XSLT passes whose templates etc. may be overridden by specifying, e.g.:</p>
    <pre>		-i crawling-xslt=$(call uri,adaptions/common/transpectdoc/xsl/pubcoach-crawl.xsl) \
		-i connections-xslt=$(call uri,adaptions/common/transpectdoc/xsl/pubcoach-connections.xsl) \
		-i rendering-xslt=$(call uri,adaptions/common/transpectdoc/xsl/pubcoach-render-html-pages.xsl) \</pre>
    <p>within the calabash.sh invocation (provided the files reside there, of course).</p>
  </p:documentation>
  
  <p:pipeinfo>
    <depends-on xmlns="http://www.le-tex.de/namespace/transpect">
      <module href="http://transpect.le-tex.de/xslt-util/xslt-based-catalog-resolver/" min-version="r1688"/>
      <module href="http://transpect.le-tex.de/xproc-util/store-debug/" min-version="r1183"/>
    </depends-on>
  </p:pipeinfo>
  
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
  
 <!-- <p:output port="info" >
    <p:pipe port="result" step="info"/>
  </p:output>
  <p:serialization port="info" omit-xml-declaration="false" indent="true"/>
-->
  <p:option name="debug" required="false" select="'yes'"/>
  <p:option name="debug-dir-uri" required="false" select="'debug'"/>
  <p:option name="output-base-uri" required="false" 
            select="replace(
                      static-base-uri(), 
                      'transpectdoc/xpl(/.*)?$', 
                      'doc'
                    )"/>
  <p:option name="project-name" required="false" select="''">
    <p:documentation>XSLT should generate title according to default rules if empty string is submitted</p:documentation>
  </p:option>
  <p:option name="project-root-uri" required="false" select="resolve-uri('../..', static-base-uri())"/>

  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
  <p:import href="http://transpect.le-tex.de/xproc-util/store-debug/store-debug.xpl"/>
  <p:import href="http://transpect.le-tex.de/calabash-extensions/ltx-lib.xpl" />
  
  <p:variable name="base-dir-system-path" 
              select="replace(
                        $output-base-uri,
                        '^file:/+(([a-z]:)/)?', 
                        '$2/', 
                        'i'
                      )">
    <p:empty/>
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <p>The operating system path for the output directory (with forward slashes). Whitespace is not supported.</p>
    </p:documentation>
  </p:variable>

  <p:xslt name="crawl" template-name="main">
    <p:input port="source">
      <p:pipe port="source" step="transpectdoc"/>
      <p:document href="lib/xproc-1.0.xpl"/>
    </p:input>
    <p:input port="parameters"><p:empty/></p:input>
    <p:with-param name="project-root-uri" select="$project-root-uri">
      <p:empty/>
    </p:with-param>
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
    <p:with-param name="output-base-uri" select="$output-base-uri"/>
    <p:with-param name="project-name" select="$project-name"/>
  </p:xslt>
  
  <p:sink/>
  
  <p:for-each>
    <p:iteration-source>
      <p:pipe port="secondary" step="render"/>
    </p:iteration-source>
    <p:store omit-xml-declaration="false" method="xhtml">
      <p:with-option name="href" select="base-uri()"/>
    </p:store>
  </p:for-each>
  
  <cxf:copy href="../css/transpectdoc.css">
    <p:with-option name="target" select="concat($output-base-uri, '/transpectdoc.css')"/>
  </cxf:copy>

  <cxf:copy href="../lib/jquery-2.1.1.min.js">
    <p:with-option name="target" select="concat($output-base-uri, '/jquery.js')"/>
  </cxf:copy>
  
  <letex:unzip name="unzip-highlight-js" overwrite="yes">
    <p:with-option name="zip" select="replace(
                                        resolve-uri('../lib/highlight.zip', static-base-uri()), 
                                        '^file:/+(([a-z]:)/)?', 
                                        '$2/', 
                                        'i'
                                      )">
      <p:documentation>Aaargh</p:documentation>
    </p:with-option>
    <p:with-option name="dest-dir" select="concat($base-dir-system-path, '/highlight')"/>
  </letex:unzip>

  <!--<cx:message>
    <p:with-option name="message" select="'HL: ', resolve-uri('../lib/highlight.zip', static-base-uri())"></p:with-option>
  </cx:message>-->
  
  <p:sink/>
  <!--
  <pxf:info name="info">
    <p:with-option name="href" select="resolve-uri('../lib/highlight.zip', static-base-uri())"></p:with-option>
  </pxf:info>

  <p:sink/>
  -->
</p:declare-step>