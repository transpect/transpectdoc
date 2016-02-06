<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step 
  xmlns:p="http://www.w3.org/ns/xproc"
  xmlns:c="http://www.w3.org/ns/xproc-step" 
  xmlns:cx="http://xmlcalabash.com/ns/extensions"
  xmlns:cxf="http://xmlcalabash.com/ns/extensions/fileutils" 
  xmlns:pxf="http://exproc.org/proposed/steps/file"
  xmlns:tr="http://transpect.io"
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
    <pre><code>FRONTEND_PIPELINES = adaptions/common/xpl/idml2hobots.xpl adaptions/common/xpl/hobots2epub-frontend.xpl crossref/xpl/process-crossref-results.xpl crossref/xpl/jats-submit-crossref-query.xpl
transpectdoc: $(addprefix $(MAKEFILEDIR)/,$(FRONTEND_PIPELINES))
	$(CALABASH) $(foreach pipe,$^,$(addprefix -i source=,$(call uri,$(pipe)))) \
		$(call uri,transpectdoc/xpl/transpectdoc.xpl) \
		debug=$(DEBUG) debug-dir-uri=$(call uri,$(MAKEFILEDIR)/transpectdoc/debug)</code></pre>
    <p>Set the svn property <var>svn:mime-type</var> for the transpectdoc.css in your documentation 
    output directory to <kbd>text/css</kbd>, if you want to view the generated documentation online, not only locally.</p>
    <p>For customizing transpectdoc, there are three XSLT passes whose templates etc. may be overridden by specifying, e.g.:</p>
    <pre><code>		-i crawling-xslt=$(call uri,adaptions/common/transpectdoc/xsl/pubcoach-crawl.xsl) \
		-i connections-xslt=$(call uri,adaptions/common/transpectdoc/xsl/pubcoach-connections.xsl) \
		-i rendering-xslt=$(call uri,adaptions/common/transpectdoc/xsl/pubcoach-render-html-pages.xsl) \</code></pre>
    <p>within the calabash.sh invocation (provided the files reside there, of course).</p>
    <h4>Adding Examples for Dynamically Evaluated Pipelines</h4>
    <p>If your pipeline loads and executes pipelines at runtime, i.e., pipelines that are not known statically in advance,
    you may provide examples for these pipelines. Example:</p>
    <pre><code>&lt;tr:dynamic-transformation-pipeline load="hub2hobots/hub2hobots">
  …
  &lt;p:pipeinfo>
    &lt;examples xmlns="http://transpect.io"> 
      &lt;collection dir-uri="http://this.transpect.io/a9s/" file="hub2hobots/hub2hobots.xpl"/>
      &lt;generator-collection dir-uri="http://this.transpect.io/a9s/" file="hub2hobots/hub2hobots.xpl.xsl"/>
    &lt;/examples>
  &lt;/p:pipeinfo>
&lt;/tr:dynamic-transformation-pipeline</code></pre>
    <p>Please note that the <code>generator-collection</code> element is not implemted yet. It is meant for holding pointers to 
      XSLT stylesheets that generate the dynamically evaluated pipelines.</p>
    <p>There is an optional attribute <code>@for</code> on the <code>examples</code> element:</p>
    <pre>&lt;tr:evolve-hub name="evolve-hub-dyn" srcpaths="yes">
  …
  &lt;p:pipeinfo>
    &lt;examples xmlns="http://transpect.io" 
      for="http://transpect.io/cascade/xpl/dynamic-transformation-pipeline.xpl#eval-pipeline">
      &lt;collection dir-uri="http://this.transpect.io/a9s/" file="evolve-hub/driver.xpl"/>
      &lt;generator-collection dir-uri="http://this.transpect.io/a9s/" file="evolve-hub/driver.xpl.xsl"/>
    &lt;/examples>
  &lt;/p:pipeinfo>
&lt;/tr:evolve-hub></pre>
    <p>Since the examples to the evolve-hub <code>tr:dynamic-transformation-pipeline</code> will vary from project to project,
    it is impractical to provide one single set of examples for this pipeline. Instead, you provide the examples at the <code>tr:evolve-hub</code>
    invocation in your project’s pipeline. In the <code>@for</code> attribute, you tell transpectdoc that the examples are for the input port called 'pipeline'
      of <code>tr:dynamic-transformation-pipeline</code> (provided that this port has an xml:id of 'eval-pipeline').</p>
  </p:documentation>
  
  <p:pipeinfo>
    <depends-on xmlns="http://transpect.io">
      <module href="http://transpect.io/xslt-util/xslt-based-catalog-resolver/" min-version="r1688"/>
      <module href="http://transpect.io/xproc-util/store-debug/" min-version="r1183"/>
    </depends-on>
  </p:pipeinfo>
  
  <p:input port="source" sequence="true" primary="true">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <p>The front-end pipelines of the transpect installation.</p>
    </p:documentation>
  </p:input>
  
  <p:input port="crawling-xslt">
    <p:document href="../xsl/crawl-xpl.xsl"/>
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
  <p:import href="http://transpect.io/xproc-util/store-debug/xpl/store-debug.xpl"/>
  <p:import href="http://transpect.io/calabash-extensions/transpect-lib.xpl" />
  
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

  <p:xslt name="crawl" template-name="crawl">
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
  
  <tr:store-debug pipeline-step="transpectdoc/1.crawl">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>

  <cx:message message="*** Connecting primary ports ..."/>

  <p:xslt name="connections" initial-mode="connect">
    <p:documentation>Makes implicit primary port connections explicit. 
      As an unrelated side effect, will normalize plain text and DocBook markup within 
    p:documentation elements to HTML.</p:documentation>
    <p:input port="parameters"><p:empty/></p:input>
    <p:input port="stylesheet">
      <p:pipe port="connections-xslt" step="transpectdoc"/>
    </p:input>
  </p:xslt>
  
  <tr:store-debug pipeline-step="transpectdoc/2.connect">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>

  <p:xslt name="render" initial-mode="render-transpectdoc">
    <p:input port="parameters"><p:empty/></p:input>
    <p:input port="stylesheet">
      <p:pipe port="rendering-xslt" step="transpectdoc"/>
    </p:input>
    <p:with-param name="output-base-uri" select="$output-base-uri"/>
    <p:with-param name="project-name" select="$project-name"/>
  </p:xslt>
  
  <cx:message message="*** Copying html, css and javascript files ..."/>

  <p:sink/>

  <p:for-each>
    <p:iteration-source>
      <p:pipe port="secondary" step="render"/>
    </p:iteration-source>
    <p:store omit-xml-declaration="false">
      <p:with-option name="method" 
        select="if(ends-with(base-uri(), 'json')) then 'text' else 'xhtml'"/>
      <p:with-option name="href" select="base-uri()"/>
    </p:store>
  </p:for-each>

  <cxf:mkdir>
    <p:documentation>Always create the output directory. 
      Otherwise (i.e. first time) a java.io.FileNotFoundException will raise.</p:documentation>
    <p:with-option name="href" select="$output-base-uri"/>
  </cxf:mkdir>

  <cxf:copy>
    <p:with-option name="href" select="resolve-uri('../css/transpectdoc.css', static-base-uri())"/>
    <p:with-option name="target" select="concat($output-base-uri, '/transpectdoc.css')"/>
  </cxf:copy>

  <cxf:copy>
    <p:with-option name="href" select="resolve-uri('../lib/jquery-2.1.1.min.js', static-base-uri())"/>
    <p:with-option name="target" select="concat($output-base-uri, '/jquery.js')"/>
  </cxf:copy>
  
  <cxf:copy>
    <p:with-option name="href" select="resolve-uri('../js/transpectdoc.js', static-base-uri())"/>
    <p:with-option name="target" select="concat($output-base-uri, '/transpectdoc.js')"/>
  </cxf:copy>

  <tr:unzip name="unzip-highlight-js" overwrite="yes">
    <p:with-option name="zip" select="replace(
                                        resolve-uri('../lib/highlight.zip', static-base-uri()), 
                                        '^file:/+(([a-z]:)/)?', 
                                        '$2/', 
                                        'i'
                                      )">
      <p:documentation>Aaargh</p:documentation>
    </p:with-option>
    <p:with-option name="dest-dir" select="concat($base-dir-system-path, '/highlight')"/>
  </tr:unzip>

  <p:sink/>
  
</p:declare-step>