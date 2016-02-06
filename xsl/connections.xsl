<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:cx="http://xmlcalabash.com/ns/extensions"
  xmlns:p="http://www.w3.org/ns/xproc"
  xmlns:tr="http://transpect.io"
  exclude-result-prefixes="c cx xs tr"
  version="2.0">

  <xsl:import href="normalize-documentation.xsl"/>
  <xsl:include href="common.xsl"/>
  
  <xsl:template match="* | @*" mode="connect">
    <xsl:copy>
<!--      <xsl:attribute name="is-step" select="tr:is-step(self::*)"/>-->
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <!-- side effect: convert plain text p:documentation to HTML --> 
  <xsl:template match="p:documentation" mode="connect">
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
  <xsl:key name="primary-input-decl" match="p:input[@primary eq 'true' 
                                                    or 
                                                    (count(../p:input) eq 1 and not(@primary = 'false'))]
                                                   [../@p:type]" use="../@p:type"/>
  <xsl:key name="primary-output-decl" match="p:output[(@primary = 'true') or (count(../p:output) = 1)][../@p:type]" use="../@p:type"/>

  <!-- For steps in subpipelines, Make primary inputs and outputs explicit: --> 
  <xsl:template match="*[tr:is-step(.)][not(@source-type = ('declare-step', 'pipeline'))]" mode="connect">
    <xsl:copy>
      <xsl:attribute name="p:is-step" select="'true'"/>
      <xsl:variable name="keep" select="@name, @generated-name, @tr:name, @cx:*" as="attribute(*)*"/>
      <xsl:apply-templates select="$keep" mode="#current"/>
      <xsl:apply-templates select="@* except $keep" mode="make-with-option"/>
      <xsl:apply-templates select="." mode="make-primary-input-explicit"/>
      <xsl:apply-templates select="." mode="make-primary-output-explicit"/>
      <xsl:apply-templates mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="@*" mode="make-with-option">
    <p:with-option name="{name()}" select="'{.}'" tr:name="p:with-option"/>
  </xsl:template>

  <xsl:template match="text()" mode="make-primary-input-explicit make-primary-output-explicit"/>

  <!-- a step with a primary input port but without explicit connection to this input port -->
  <xsl:template match="*[tr:is-step(.) (: is a step (including step declarations) :)]
                        [not(@source-type = ('declare-step', 'pipeline')) (: is not the declaration; rather, a step in a (sub)pipeline :)]
                        [exists(key('primary-input-decl', tr:name(.))) (: the step’s declaration declares a primary source port :)]
                        [not(p:input/@port = key('primary-input-decl', tr:name(.))/@port)
                          (: the primary input port hasn’t already been connected explicitly :)]" 
                mode="make-primary-input-explicit">
    <p:input generated="true">
      <xsl:copy-of select="key('primary-input-decl', tr:name(.))/@port"/>
      <xsl:comment>a</xsl:comment><xsl:sequence select="tr:default-readable-port(.)"/><xsl:comment>b</xsl:comment>
    </p:input>
  </xsl:template>

  <!-- approximately the same for primary output ports (except that it’s much simpler 
    because you don’t specify connections for primary output ports): -->
  <xsl:template match="*[tr:is-step(.)]
                        [not(@source-type = ('declare-step', 'pipeline'))]
                        [exists(key('primary-output-decl', tr:name(.)))]
                        [count(key('primary-output-decl', tr:name(.))/../p:output) = 1
                         or 
                         not(p:output/@port = key('primary-output-decl', tr:name(.))/@port)
                        ]" 
                mode="make-primary-output-explicit">
    <p:output generated="true">
      <xsl:copy-of select="key('primary-output-decl', tr:name(.))/@port"/>
    </p:output>
  </xsl:template>
  
  <xsl:template match="*" mode="make-primary-output-explicit make-primary-input-explicit"/>
  
  <!-- the only output port declaration is primary by definition -->
  <xsl:template match="p:output[../@source-type = ('declare-step', 'pipeline')][count(../p:output) = 1]" mode="connect" priority="2">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:attribute name="primary" select="'true'"/>
      <xsl:copy-of select="*"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="p:for-each[not(p:iteration-source)]" mode="make-primary-input-explicit">
    <p:iteration-source generated="true">
      <xsl:sequence select="tr:default-readable-port(.)"/>
    </p:iteration-source>
  </xsl:template>

  <!-- For a given step in a subsequence, gives the p:pipe connection to
    the default readable port that is present here. It can be used in
    generated p:input elements. -->
  <xsl:function name="tr:default-readable-port" as="element(p:pipe)?">
    <xsl:param name="context" as="element(*)"/>
    <xsl:variable name="context-or-wrapper" as="element(*)">
      <xsl:choose>
        <xsl:when test="$context/preceding-sibling::*[tr:is-step(.)]">
          <xsl:sequence select="$context"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:choose>
            <xsl:when test="$context/../../(self::p:choose | self::p:try)">
              <xsl:sequence select="$context/../.."/>
            </xsl:when>
            <xsl:when test="$context/../self::p:group">
              <xsl:sequence select="$context/.."/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:sequence select="$context"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <!-- p:for-each, p:choose, p:group or atomic step in a subpipeline -->
    <xsl:variable name="preceding-step" as="element()?" select="$context-or-wrapper/preceding-sibling::*[tr:is-step(.)][1]"/>
    <xsl:variable name="preceding-steps-output-decl" as="element(p:output)*"
      select="if ($preceding-step) then 
              key('primary-output-decl', tr:name($preceding-step), root($context))
              else ()"/>
    <xsl:if test="count($preceding-steps-output-decl) gt 1">
<!--      <xsl:message select="'More than one primary output declaration in ', $preceding-steps-output-decl/.., ' ', base-uri($context), ': ', $preceding-steps-output-decl"/>-->
<!--      <xsl:message select="'More than one primary output declaration in ', base-uri($context), ': ', $preceding-steps-output-decl"></xsl:message>-->
    </xsl:if>
    <xsl:choose>
      <xsl:when test="$preceding-steps-output-decl">
        <p:pipe step="{$preceding-step/@name}" port="{$preceding-steps-output-decl/@port}"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="parent-step-with-primary-input-decl" as="element(*)?"
          select="$context-or-wrapper/ancestor::*[p:input[@primary eq 'true']][1]"/>
        <xsl:choose>
          <!-- there is a preceding step but it doesn't have a primary output: -->
          <xsl:when test="$preceding-step"/>
          <xsl:when test="$context/parent::p:for-each">
            <p:pipe step="{$context/../@name}" port="current"/>
          </xsl:when>
          <xsl:when test="$parent-step-with-primary-input-decl">
            <p:pipe step="{$parent-step-with-primary-input-decl/@name}" 
              port="{$parent-step-with-primary-input-decl/p:input[@primary = 'true']/@port}"/>
          </xsl:when>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="tr:primary-output-port" as="element(p:output)">
    <xsl:param name="step" as="element(*)"/>
    <xsl:variable name="own-decl" as="element(p:output)" select="key('primary-output-decl', tr:name($step), root($step))"/>
    <xsl:choose>
      <xsl:when test="exists($own-decl)">
        <xsl:sequence select="$own-decl"/>
      </xsl:when>
      <xsl:when test="exists($step/*[tr:is-step(.)])">
        <xsl:sequence select="tr:primary-output-port(($step/*[tr:is-step(.)])[last()])"/>
      </xsl:when>
    </xsl:choose>
  </xsl:function>

  <!-- Collateral; convenience attribute: --> 

  <xsl:function name="tr:normalize-for-filename" as="xs:string">
    <xsl:param name="name" as="xs:string"/>
    <xsl:sequence select="replace(replace($name, ':', '_'), '(\s+\(.+\)|[^0-9a-z_-]+)', '', 'i')"/>
  </xsl:function>
  
  <!--<xsl:function name="tr:normalize-for-filename" as="xs:string">
    <xsl:param name="name" as="xs:string"/>
    <xsl:sequence select="$name"/>
  </xsl:function>-->
  
  <xsl:template match="@display-name" mode="connect">
    <xsl:copy/>
    <xsl:attribute name="tr:filename" select="tr:normalize-for-filename(.)"/>
  </xsl:template>
  
</xsl:stylesheet>