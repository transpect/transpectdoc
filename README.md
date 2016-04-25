# transpectdoc

This pipeline documents all pipelines and library that are used in a project.

# Description

The source documents are considered as the front-end pipelines. All other imported libraries and steps will be crawled.

For each of the steps’ input and output ports, a linked list will be generated that points to the ports in other pipelines that are connected to these ports.

# Invocation

Sample invocation (from a Makefile):

FRONTEND_PIPELINES = adaptions/common/xpl/idml2hobots.xpl adaptions/common/xpl/hobots2epub-frontend.xpl crossref/xpl/process-crossref-results.xpl crossref/xpl/jats-submit-crossref-query.xpl
transpectdoc: $(addprefix $(MAKEFILEDIR)/,$(FRONTEND_PIPELINES))
	      $(CALABASH) $(foreach pipe,$^,$(addprefix -i source=,$(call uri,$(pipe)))) \
	      		  	    $(call uri,transpectdoc/xpl/transpectdoc.xpl) \
				    debug=$(DEBUG) debug-dir-uri=$(call uri,$(MAKEFILEDIR)/transpectdoc/debug)

Set the svn property `svn:mime-type` for the `transpectdoc.css` in your documentation output directory to text/css, if you want to view the generated documentation online, not only locally.

For customizing transpectdoc, there are three XSLT passes whose templates etc. may be overridden by specifying, e.g.:

```
-i crawling-xslt=$(call uri,adaptions/common/transpectdoc/xsl/pubcoach-crawl.xsl \
-i connections-xslt=$(call uri,adaptions/common/transpectdoc/xsl/pubcoach-connections.xsl \
-i rendering-xslt=$(call uri,adaptions/common/transpectdoc/xsl/pubcoach-render-html-pages.xsl 
```

within the calabash.sh invocation (provided the files reside there, of course).



# Adding Examples for Dynamically Evaluated Pipelines

If your pipeline loads and executes pipelines at runtime, i.e., pipelines that are not known statically in advance, you may provide examples for these pipelines. Examples:

```
<tr:dynamic-transformation-pipeline load=evolve-hub/driver" fallback-xpl="fallback.xpl">
    <p:pipeinfo>
      <examples xmlns="http://transpect.io">
        <file href="fallback.xpl"/>
      </examples>
    </p:pipeinfo>
    </tr:dynamic-transformation-pipeline>
<tr:dynamic-transformation-pipeline load="hub2hobots/hub2hobots">
  …
  <p:pipeinfo>
    <examples xmlns="http://transpect.io"> 
      <collection dir-uri="http://this.transpect.io/a9s/" file="hub2hobots/hub2hobots.xpl"/>
      <generator-collection dir-uri="http://this.transpect.io/a9s/" file="hub2hobots/hub2hobots.xpl.xsl"/>
    </examples>
  </p:pipeinfo>
</tr:dynamic-transformation-pipeline
```

Please note that the generator-collection element is not implemted yet. It is meant for holding pointers to XSLT stylesheets that generate the dynamically evaluated pipelines.

There is an optional attribute @for on the examples element:

```
<tr:evolve-hub name="evolve-hub-dyn" srcpaths="yes">
  …
  <p:pipeinfo>
    <examples xmlns="http://transpect.io" 
      for="http://transpect.io/cascade/xpl/dynamic-transformation-pipeline.xpl#eval-pipeline">
      <collection dir-uri="http://this.transpect.io/a9s/" file="evolve-hub/driver.xpl"/>
      <generator-collection dir-uri="http://this.transpect.io/a9s/" file="evolve-hub/driver.xpl.xsl"/>
    </examples>
  </p:pipeinfo>
</tr:evolve-hub>
```

Since the examples to the evolve-hub `tr:dynamic-transformation-pipeline` will vary from project to project, it is impractical to provide one single set of examples for this pipeline. Instead, you provide the examples at the `tr:evolve-hub` invocation in your project’s pipeline. In the @for attribute, you tell transpectdoc that the examples are for the input port called 'pipeline' of `tr:dynamic-transformation-pipeline` (provided that this port has an xml:id of 'eval-pipeline').

The front-end pipelines of the transpect installation.

XSLT should generate title according to default rules if empty string is submitted
The operating system path for the output directory (with forward slashes). Whitespace is not supported.

Makes implicit primary port connections explicit. As an unrelated side effect, will normalize plain text and DocBook markup within p:documentation elements to HTML. Always create the output directory. Otherwise (i.e. first time) a java.io.FileNotFoundException will raise. Aaargh