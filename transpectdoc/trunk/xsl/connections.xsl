<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:p="http://www.w3.org/ns/xproc"
  xmlns:transpect="http://www.le-tex.de/namespace/transpect"
  exclude-result-prefixes="c xs transpect"
  version="2.0">

  <xsl:import href="normalize-documentation.xsl"/>
  <xsl:include href="common.xsl"/>
  
  <xsl:template match="* | @*">
    <xsl:copy>
<!--      <xsl:attribute name="is-step" select="transpect:is-step(self::*)"/>-->
      <xsl:apply-templates select="@*, node()"/>
    </xsl:copy>
  </xsl:template>

  <!-- side effect: convert plain text p:documentation to HTML --> 
  <xsl:template match="p:documentation">
    <xsl:apply-templates select="." mode="normalize-documentation"/>
  </xsl:template>

  <!-- these keys return the primary input/output port declarations from the step declarations.
    They will typically be used for a step that is found in a subpipeline, e.g.
    your step declaration:
    
    <p:declare-step type="my:step">
      <p:input port="source" primary="true"/>
      …
    </p:declare-step>
    
    Your subpipeline uses my:step with an implicit connection of its source port:
    
    <my:step/> 
    
    Then you supply its name to the key() lookup:
    
    <my:step/> -> name() -> 'my:step'
    key('primary-input-decl', 'my:step') -> <p:input port="source" primary="true"/>
    
    and receive the declaration of my:step’s primary input port. 
    
    One use case is: does my current subpipeline step have a primary input port, i.e.,
    does the key() function return a non-empty sequence?
    -->
  <xsl:key name="primary-input-decl" match="p:input[@primary eq 'true'][../@p:type]" use="../@p:type"/>
  <xsl:key name="primary-output-decl" match="p:output[@primary eq 'true'][../@p:type]" use="../@p:type"/>

  <!-- For steps in subpipelines, Make primary inputs and outputs explicit: --> 
  <xsl:template match="*[transpect:is-step(.)][not(@source-type = ('declare-step', 'pipeline'))]">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates select="." mode="make-primary-input-explicit"/>
      <xsl:apply-templates select="." mode="make-primary-output-explicit"/>
      <xsl:copy-of select="node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="text()[not(normalize-space())]" mode="make-primary-input-explicit make-primary-output-explicit"/>

  <!-- a step with a primary input port but without explicit connection to this input port -->
  <xsl:template match="*[transpect:is-step(.) (: is a step (including step declarations) :)]
                        [not(@source-type = ('declare-step', 'pipeline')) (: is not the declaration; rather, a step in a (sub)pipeline :)]
                        [exists(key('primary-input-decl', name())) (: the step’s declaration declares a primary source port :)]
                        [not(p:input/@port = key('primary-input-decl', name())/@port)
                          (: the primary input port hasn’t already been connected explicitly :)]" 
                mode="make-primary-input-explicit">
    <p:input generated="true">
      <xsl:copy-of select="key('primary-input-decl', name())/@port"/>
      <xsl:variable name="preceding-step" as="element()?"
        select="preceding-sibling::*[transpect:is-step(.)][1]"/>
      <xsl:variable name="preceding-steps-output-decl" as="element(p:output)?"
        select="key('primary-output-decl', $preceding-step/name())"/>
      <xsl:variable name="parent-steps-input-decl" as="element(p:input)?"
        select="../p:input[@primary eq 'true']"/>
      <xsl:variable name="connection" as="element()?"
        select="(
                  if ($preceding-steps-output-decl)
                  then $preceding-step
                  else 
                    if (not($preceding-step) and $parent-steps-input-decl)
                    then ..
                    else ()
                )"/>
      <xsl:if test="$connection">
        <p:pipe step="{$connection/@name}" port="{($preceding-steps-output-decl, $parent-steps-input-decl)[1]/@port}"/>
      </xsl:if>
    </p:input>
  </xsl:template>

  <!-- approximately the same for primary output ports (except that it’s much simpler 
    because you don’t specify connections for primary output ports): -->
  <xsl:template match="*[transpect:is-step(.)]
                        [not(@source-type = ('declare-step', 'pipeline'))]
                        [exists(key('primary-output-decl', name()))]
                        [not(p:output/@port = key('primary-output-decl', name())/@port)]" 
                mode="make-primary-output-explicit">
    <p:output generated="true">
      <xsl:copy-of select="key('primary-output-decl', name())/@port"/>
    </p:output>
  </xsl:template>
  

</xsl:stylesheet>