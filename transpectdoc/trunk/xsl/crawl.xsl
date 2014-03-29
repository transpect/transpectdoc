<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:p="http://www.w3.org/ns/xproc"
  xmlns:transpect="http://www.le-tex.de/namespace/transpect"
  exclude-result-prefixes="c xs transpect"
  version="2.0">
  
  <xsl:include href="common.xsl"/>

  <xsl:param name="base-dir-uri-regex" as="xs:string"/>

  <xsl:template name="main">
    <xsl:variable name="raw-list" as="element(c:file)*">
      <xsl:apply-templates select="collection()"/>
    </xsl:variable>
    <xsl:variable name="consolidate-by-href" as="element(c:file)*">
      <xsl:for-each-group select="$raw-list" group-by="@href">
        <xsl:sequence select="."/>
      </xsl:for-each-group>
    </xsl:variable>
    <c:files display-name="index">
      <xsl:copy-of select="$consolidate-by-href" copy-namespaces="no"/>
    </c:files>
  </xsl:template>
  
  <xsl:template match="text()"/>
  
  <xsl:template match="/*" priority="2">
    <xsl:param name="pre-catalog-resolution-href" as="attribute(href)?" tunnel="yes"/>
    <c:file source-type="{local-name()}" href="{base-uri()}">
      <xsl:variable name="project-relative-path" as="xs:string"
        select="replace(base-uri(), $base-dir-uri-regex, '')"/>
      <xsl:if test="$project-relative-path ne base-uri()">
        <xsl:attribute name="project-relative-path" select="$project-relative-path"/>
      </xsl:if>
      <xsl:if test="$pre-catalog-resolution-href">
        <xsl:attribute name="canonical-href" select="$pre-catalog-resolution-href"/>  
      </xsl:if>
      <xsl:call-template name="process-inner"/>
    </c:file>
    <xsl:apply-templates select="p:import"/>
  </xsl:template>

  <xsl:function name="transpect:basename" as="xs:string">
    <xsl:param name="href" as="xs:string"/>
    <xsl:sequence select="replace($href, '^.+/', '')"/>
  </xsl:function>

  <xsl:template name="process-inner">
    <xsl:copy-of select="@name"/>
    <xsl:apply-templates select="@type"/>
    <xsl:if test="not(@name) and transpect:is-step(.)">
      <xsl:attribute name="name" select="generate-id()"/>
      <xsl:attribute name="generated-name" select="'true'"/>
    </xsl:if>
    <xsl:attribute name="display-name">
      <xsl:choose>
        <xsl:when test="local-name() = ('declare-step', 'pipeline')">
          <xsl:value-of select="if (@type) 
                                then @type 
                                else concat('[anonymous] ', replace(transpect:basename(base-uri()), '\.[^.]+$', ''))"/>
          <xsl:if test="parent::p:library">
            <xsl:text> (in library </xsl:text>
            <xsl:value-of select="transpect:basename(base-uri())"/>
            <xsl:text>)</xsl:text>
          </xsl:if>
        </xsl:when>
        <xsl:when test="self::p:library">
          <xsl:value-of select="transpect:basename(base-uri())"/>
          <xsl:text> (library)</xsl:text>
        </xsl:when>
      </xsl:choose>
    </xsl:attribute>
    <xsl:copy-of select="p:input | p:output | p:import | p:serialization"/>
    <xsl:if test="local-name() = 'library'">
      <c:step-declarations>
        <xsl:apply-templates select="p:declare-step | p:pipeline"/>
      </c:step-declarations>
    </xsl:if>
    <xsl:apply-templates select="* except (p:input | p:output | p:import | p:serialization
                                           | p:declare-step | p:pipeline )"/>
  </xsl:template>

  <!--<xsl:template match="* | @*">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()"/>
    </xsl:copy>
  </xsl:template>-->

  <xsl:template match="*">
    <xsl:copy-of select="."/>
  </xsl:template>

  <xsl:template match="*[transpect:is-step(.)]
                        [not(@name)]">
    <xsl:copy>
      <xsl:attribute name="name" select="generate-id()"/>
      <xsl:attribute name="generated-name" select="'true'"/>
      <xsl:copy-of select="@*, node()"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="*[transpect:is-step(.)][@name]">
    <xsl:copy>
      <xsl:copy-of select="@*, node()"/>
    </xsl:copy>
  </xsl:template>
  

  <xsl:template match="@type">
    <xsl:variable name="context" select=".." as="element()"/>
    <xsl:analyze-string select="." regex="^(.+):(.+)$">
      <xsl:matching-substring>
        <xsl:attribute name="type-namespace" select="namespace-uri-for-prefix(regex-group(1), $context)"/>    
        <xsl:attribute name="type-prefix" select="regex-group(1)"/>
        <xsl:attribute name="type-local-name" select="regex-group(2)"/>
        <xsl:attribute name="p:type" select="."/>
      </xsl:matching-substring>
      <xsl:non-matching-substring>
        <xsl:message terminate="yes">@type must be a QName with a namespace prefix. Found: <xsl:value-of select="."/></xsl:message>
      </xsl:non-matching-substring>
    </xsl:analyze-string>
  </xsl:template>
  
  <xsl:template match="p:library/p:declare-step | p:library/p:pipeline" priority="2">
    <c:step-declaration source-type="{local-name()}">
      <xsl:call-template name="process-inner"/>
    </c:step-declaration>
  </xsl:template>
  
  <xsl:template match="p:import">
    <xsl:apply-templates select="doc(@href)">
      <xsl:with-param name="pre-catalog-resolution-href" select="@href" tunnel="yes"/>
    </xsl:apply-templates>
  </xsl:template>
  
</xsl:stylesheet>