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
  
  <xsl:import href="http://transpect.le-tex.de/xslt-util/xslt-based-catalog-resolver/resolve-uri-by-catalog.xsl"/>
  
  <xsl:include href="common.xsl"/>

  <xsl:param name="project-root-uri" as="xs:string"/>

  <xsl:variable name="base-dir-uri-regex" as="xs:string" select="replace($project-root-uri, '^file:/+', 'file:/+')"/>

  <xsl:variable name="initial-base-uris" as="xs:string+" select="collection()/base-uri()[not(ends-with(., 'lib/xproc-1.0.xpl'))]"/>

  <xsl:key name="by-href" match="*[@xml:id]" use="string-join((ancestor::*[transpect:is-step(.)][@href][1]/@href, @xml:id), '#')"/>

  <xsl:template name="main">
    <xsl:variable name="raw-list" as="element(c:file)*">
      <xsl:apply-templates select="collection()"/>    
    </xsl:variable>
    <!--<xsl:variable name="plus-examples" as="element(c:file)*">
      <xsl:sequence select="$raw-list/c:files/c:file"/>
      <xsl:variable name="dynamic-pipelines" as="element(p:input)*" select="for $for in $raw-list/descendant::p:pipeinfo/transpect:examples/@for 
        return key('by-href', letex:resolve-uri-by-catalog($for, document('http://customers.le-tex.de/generic/book-conversion/xmlcatalog/catalog.xml')), $raw-list)"/>
      <xsl:message select="count($dynamic-pipelines), for $for in $raw-list/descendant::p:pipeinfo/transpect:examples/@for 
        return letex:resolve-uri-by-catalog($for, document('http://customers.le-tex.de/generic/book-conversion/xmlcatalog/catalog.xml'))"></xsl:message>
      <xsl:apply-templates select="$dynamic-pipelines"/>
      <xsl:message select="for $k in $raw-list//*[@xml:id] return $k/ancestor::*[transpect:is-step(.)]"></xsl:message>
    </xsl:variable>-->
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
    <c:file source-type="{local-name()}" href="{transpect:normalize-uri(base-uri())}">
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
    <xsl:apply-templates select="p:import">
      <xsl:with-param name="example-for" select="()" tunnel="yes"/>
    </xsl:apply-templates>
    <!--<xsl:apply-templates select="for $coll in descendant::transpect:examples/transpect:collection 
      return collection(letex:resolve-uri-by-catalog($coll/@uri, document('http://customers.le-tex.de/generic/book-conversion/xmlcatalog/catalog.xml')))"/>-->
    <xsl:for-each select="descendant::*:examples/*:collection">
      <xsl:apply-templates select="transpect:find-in-dir(
                                     @dir-uri, 
                                     @file, 
                                     document('http://customers.le-tex.de/generic/book-conversion/xmlcatalog/catalog.xml')
                                   )">
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
    <xsl:apply-templates select="@type"/>
    <xsl:if test="not(@name) and transpect:is-step(.)">
      <xsl:attribute name="name" select="generate-id()"/>
      <xsl:attribute name="generated-name" select="'true'"/>
    </xsl:if>
    <xsl:if test="local-name() = ('declare-step', 'pipeline')
                  and
                  (base-uri() = $initial-base-uris)">
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
        <xsl:apply-templates select="p:declare-step | p:pipeline"/>
      </c:step-declarations>
    </xsl:if>
    <xsl:apply-templates select="* except (p:input | p:output | p:import | p:serialization
                                           | p:declare-step | p:pipeline )"/>
  </xsl:template>

  <xsl:template match="@*">
    <xsl:copy/>
  </xsl:template>

  <xsl:template match="*">
    <xsl:copy-of select="."/>
  </xsl:template>
  
  <xsl:template match="*[transpect:is-step(.)]
                        [not(@name)]">
    <xsl:copy>
      <xsl:attribute name="name" select="generate-id()"/>
      <xsl:attribute name="generated-name" select="'true'"/>
      <xsl:apply-templates select="@*, node()"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="*[transpect:is-step(.)][@name]">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()"/>
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
    <xsl:apply-templates select="doc(resolve-uri(@href, base-uri()))">
      <xsl:with-param name="pre-catalog-resolution-href" select="@href" tunnel="yes"/>
    </xsl:apply-templates>
  </xsl:template>
  
</xsl:stylesheet>