<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:cx="http://xmlcalabash.com/ns/extensions" 
  xmlns:cat="urn:oasis:names:tc:entity:xmlns:xml:catalog"
  xmlns:p="http://www.w3.org/ns/xproc"
  xmlns:letex="http://www.le-tex.de/namespace"
  xmlns:transpect="http://www.le-tex.de/namespace/transpect"
  exclude-result-prefixes="c cx xs letex transpect"
  version="2.0">
  
  <xsl:include href="common.xsl"/>

  <xsl:param name="project-root-uri" as="xs:string?"/>

  <xsl:variable name="base-dir-uri-regex" as="xs:string?" 
    select="if ($project-root-uri)
            then replace($project-root-uri, '^file:/+', 'file:/+')
            else ()"/>

  <xsl:key name="by-href" match="*[@xml:id]" use="string-join((ancestor::*[transpect:is-step(.)][@href][1]/@href, @xml:id), '#')"/>

  <xsl:template name="crawl" as="element(c:files)">
    <xsl:variable name="raw-list" as="element(c:file)*">
      <xsl:call-template name="raw-list"/>    
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
  
  <xsl:template name="raw-list">
    <xsl:apply-templates select="collection()" mode="raw-list"/>
  </xsl:template>
  
  <xsl:template match="text()" mode="raw-list"/>
  
  <!-- The top-level file contents. We don’t use /* for the matching pattern
    because in interactive mode, they aren’t top-level elements -->
  <xsl:template match="p:library | p:declare-step[not(parent::p:library)] | p:pipeline[not(parent::p:library)]" 
    priority="4" mode="raw-list">
    <xsl:param name="pre-catalog-resolution-href" as="attribute(href)?" tunnel="yes"/>
    <c:file source-type="{local-name()}" href="{transpect:normalize-uri(base-uri())}">
      <xsl:variable name="project-relative-path" as="xs:string"
        select="if ($base-dir-uri-regex) 
                then replace(base-uri(), $base-dir-uri-regex, '')
                else base-uri()"/>
      <xsl:if test="$project-relative-path ne base-uri()">
        <xsl:attribute name="project-relative-path" select="$project-relative-path"/>
      </xsl:if>
      <xsl:if test="$pre-catalog-resolution-href">
        <xsl:attribute name="canonical-href" select="$pre-catalog-resolution-href"/>  
      </xsl:if>
      <xsl:call-template name="process-inner"/>
    </c:file>
    <xsl:apply-templates select="p:import" mode="raw-list">
      <xsl:with-param name="example-for" select="()" tunnel="yes"/>
    </xsl:apply-templates>
    <xsl:for-each select="descendant::*:examples/*:collection">
      <xsl:apply-templates select="transpect:find-in-dir(
                                     @dir-uri, 
                                     @file, 
                                     document('http://customers.le-tex.de/generic/book-conversion/xmlcatalog/catalog.xml')
                                   )" mode="raw-list">
        <xsl:with-param name="example-for" select="@file" tunnel="yes"/>
      </xsl:apply-templates>  
    </xsl:for-each>
  </xsl:template>

  <xsl:function name="transpect:find-in-dir" as="document-node(element(*))*">
    <xsl:param name="dir-uri" as="xs:string"/>
    <xsl:param name="file-name-with-local-dir" as="xs:string"/> 
    <xsl:param name="catalog" as="document-node(element(cat:catalog))?"/>
    <xsl:variable name="file-name" select="replace($file-name-with-local-dir, '^.+/', '')" as="xs:string"/>
    <xsl:variable name="collection-uri" select="concat(
                                                  if ($catalog) 
                                                  then letex:resolve-uri-by-catalog($dir-uri, $catalog) 
                                                  else $dir-uri,
                                                  '/?select=', $file-name, 
                                                  ';recurse=yes'
                                                )"/>
    <xsl:sequence select="collection($collection-uri)[contains(base-uri(), $file-name-with-local-dir)]"/>
  </xsl:function>

  <xsl:function name="transpect:basename" as="xs:string">
    <xsl:param name="href" as="xs:string"/>
    <xsl:sequence select="replace($href, '^.+/', '')"/>
  </xsl:function>
  
  <xsl:function name="transpect:normalize-uri" as="xs:string">
    <xsl:param name="uri" as="xs:string"/>
    <xsl:sequence select="replace($uri, '^file:///', 'file:/')"/>
  </xsl:function>

  <xsl:template name="process-inner">
    <xsl:param name="example-for" as="xs:string?" tunnel="yes"/>
    <xsl:copy-of select="@name"/>
    <xsl:apply-templates select="@type" mode="raw-list"/>
    <xsl:if test="not(@name) and transpect:is-step(.)">
      <xsl:attribute name="name" select="generate-id()"/>
      <xsl:attribute name="generated-name" select="'true'"/>
    </xsl:if>
    <xsl:if test="local-name() = ('declare-step', 'pipeline')
                  and
                  (base-uri() = transpect:initial-base-uris())">
      <xsl:attribute name="front-end" select="'true'"/>
    </xsl:if>
    <xsl:if test="$example-for">
      <xsl:attribute name="example-for" select="$example-for"/>
    </xsl:if>
    <xsl:attribute name="display-name">
      <xsl:choose>
        <xsl:when test="local-name() = ('declare-step', 'pipeline')">
          <xsl:value-of select="if (@type) 
                                then @type 
                                else concat(
                                  replace(($example-for, transpect:basename(base-uri()))[1], '\.[^.]+$', ''),
                                  ' Ⓐ',
                                  if ($example-for) then 'Ⓓ' else ''
                                )"/>
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
        <xsl:apply-templates select="p:declare-step | p:pipeline" mode="raw-list"/>
      </c:step-declarations>
    </xsl:if>
    <xsl:apply-templates select="* except (p:input | p:output | p:import | p:serialization
                                 | p:declare-step | p:pipeline )" mode="raw-list"/>
  </xsl:template>

  <xsl:template match="@*" mode="raw-list">
    <xsl:copy/>
  </xsl:template>

  <xsl:template match="*" mode="raw-list">
    <xsl:copy-of select="."/>
  </xsl:template>
  
  <xsl:template match="p:when | p:otherwise" mode="raw-list">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="*[transpect:is-step(.)]
                        [not(@name)]" mode="raw-list">
    <xsl:copy>
      <xsl:attribute name="name" select="generate-id()"/>
      <xsl:attribute name="generated-name" select="'true'"/>
      <xsl:apply-templates select="@*, node()" mode="raw-list"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="*[transpect:is-step(.)][@name]" mode="raw-list">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  

  <xsl:template match="@type" mode="raw-list">
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
  
  <xsl:template match="p:library/p:declare-step | p:library/p:pipeline" priority="2" mode="raw-list">
    <c:step-declaration source-type="{local-name()}">
      <xsl:call-template name="process-inner"/>
    </c:step-declaration>
  </xsl:template>
  
  <xsl:template match="p:import" mode="raw-list">
    <xsl:param name="catalog" as="document-node(element(cat:catalog))?" tunnel="yes"/>
    <xsl:apply-templates select="doc(
                                   if ($catalog)
                                   then letex:resolve-uri-by-catalog(@href, $catalog) 
                                   else resolve-uri(@href, base-uri())
                                 )" mode="#current">
      <xsl:with-param name="pre-catalog-resolution-href" select="@href" tunnel="yes"/>
    </xsl:apply-templates>
  </xsl:template>
  
</xsl:stylesheet>