<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:p="http://www.w3.org/ns/xproc"
  xmlns:transpect="http://www.le-tex.de/namespace/transpect"
  xmlns="http://www.w3.org/1999/xhtml"
  exclude-result-prefixes="c xs transpect"
  version="2.0">

  <xsl:include href="common.xsl"/>

  <xsl:param name="output-base-uri" select="'doc'"/>

  <xsl:template match="* | @*" mode="#default create-html">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="c:files | c:file[@source-type = library]">
    <!--<xsl:call-template name="page"/>-->
    <xsl:apply-templates select="c:file | c:step-declarations"/>
  </xsl:template>

  <xsl:template match="*[@source-type]" mode="create-html_">
    <p>
      <a href="{$output-base-uri}/{transpect:normalize-for-filename(@display-name)}.html">
        <xsl:value-of select="@display-name"/>
      </a>
    </p>
  </xsl:template>

  <xsl:template match="c:step-declarations">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:function name="transpect:normalize-for-filename" as="xs:string">
    <xsl:param name="name" as="xs:string"/>
    <xsl:sequence select="replace(replace($name, '[(\[\])]', ''), '[^-\w._]+', '_', 'i')"/>
  </xsl:function>

  <xsl:template match="c:file | c:step-declaration">
    <xsl:call-template name="page"/>
  </xsl:template>

  <xsl:template name="page">
    <xsl:result-document href="{$output-base-uri}/{transpect:normalize-for-filename(@display-name)}.html">
      <html>
        <head>
          <meta http-equiv="Content-type" content="text/html;charset=UTF-8"/>
          <title>
            <xsl:value-of select="string-join((@display-name, 'transpectdoc'), ' – ')"/>
          </title>
        </head>
        <body>
          <xsl:apply-templates select="." mode="create-html"/>
        </body>
      </html>
    </xsl:result-document>
  </xsl:template>

  <xsl:template match="*[@source-type = ('declare-step', 'pipeline')]" mode="create-html">
    <h2>
      <xsl:value-of select="@display-name"/>
    </h2>
    <xsl:call-template name="input-declarations"/>
    <xsl:call-template name="output-declarations"/>
    <xsl:call-template name="option-declarations"/>
    <!-- main documentation -->
    <xsl:apply-templates mode="#current"
      select="p:documentation[not(preceding-sibling::*[transpect:is-step(.)])]"/>
    <div class="subpipeline">
      <xsl:apply-templates mode="#current" 
        select="*[transpect:is-step(.)] | p:documentation[preceding-sibling::*[transpect:is-step(.)]] "/>
    </div>
  </xsl:template>

  <xsl:template name="input-declarations">
    <h3>Input Ports</h3>
    <xsl:if test="not(p:input)">
      <p class="none">none</p>
    </xsl:if>
    <xsl:apply-templates select="p:input" mode="#current"/>
  </xsl:template>

  <xsl:template name="output-declarations">
    <h3>Output Ports</h3>
    <xsl:if test="not(p:output)">
      <p class="none">none</p>
    </xsl:if>
    <xsl:apply-templates select="p:output" mode="#current"/>
  </xsl:template>
  
  <xsl:template name="option-declarations">
    <h3>Options</h3>
    <xsl:if test="not(p:option)">
      <p class="none">none</p>
    </xsl:if>
    <xsl:apply-templates select="p:option" mode="#current"/>
  </xsl:template>
  
  <xsl:template match="p:input | p:output" mode="create-html">
    <p class="port-declaration">
      <span class="name">
        <xsl:value-of select="@port"/>
      </span>
      <span class="flag">
        <xsl:if test="@primary = 'true'">
          <xsl:value-of select="'Ⓟ'"/>
        </xsl:if>
      </span>
      <span class="flag">
        <xsl:if test="@sequence = 'true'">
          <xsl:value-of select="'Ⓢ'"/>
        </xsl:if>
      </span>
    </p>
    <xsl:apply-templates select="p:documentation" mode="#current"/>
    <!-- applies to p:output only: -->
    <xsl:apply-templates select="../p:serialization[@port = current()/@port]" mode="#current"/>
  </xsl:template>
  
  <xsl:template match="p:documentation" mode="create-html">
    <div class="documentation">
      <xsl:apply-templates mode="#current"/>
    </div>
  </xsl:template>

</xsl:stylesheet>