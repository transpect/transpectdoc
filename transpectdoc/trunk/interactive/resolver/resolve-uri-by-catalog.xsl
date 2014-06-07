<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:cat="urn:oasis:names:tc:entity:xmlns:xml:catalog"
  xmlns:letex="http://www.le-tex.de/namespace"
  exclude-result-prefixes="xs cat letex"
  version="2.0">

  <!-- This is only for testing -->
  <xsl:param name="test-uri" as="xs:string?"/>
  <xsl:param name="debug" select="'no'" as="xs:string"/>
  
  <xsl:output method="text"/>
  
  <xsl:template name="test">
    <xsl:variable name="transpect-modules-catalog" as="document-node(element(cat:catalog))"
      select="letex:expand-nextCatalog(/)"/>
    <xsl:message select="'forward: ', letex:resolve-uri-by-catalog($test-uri, $transpect-modules-catalog)"/>
    <!-- you might also supply the unexpanded catalog -->
    <xsl:message select="'reverse: ', letex:reverse-resolve-uri-by-catalog($test-uri, $transpect-modules-catalog)"/>
    <xsl:if test="$debug = 'yes'">
      <xsl:result-document href="expanded-catalog.xml" method="xml">
        <xsl:sequence select="$transpect-modules-catalog"/>
      </xsl:result-document>
    </xsl:if>
  </xsl:template>

  <!-- maybe some input normalization is missing yet -->
  <xsl:key name="cat:uri-by-name" match="cat:uri" use="@name"/>
  <xsl:key name="cat:uri-by-uri" match="cat:uri" use="@uri"/>
  
  <!-- You might want to call this once for a catalog and then pass the expanded catalog 
    to the resolution functions. Otherwise the processor might read the nextCatalogs over 
    and over again. -->
  <xsl:function name="letex:expand-nextCatalog" as="document-node(element(cat:catalog))">
    <xsl:param name="cat" as="document-node(element(cat:catalog))+"/>
    <xsl:document>
      <xsl:apply-templates select="$cat[1]" mode="cat:expand-nextCatalog">
        <xsl:with-param name="additional-catalogs" select="$cat[position() gt 1]"/>
      </xsl:apply-templates>
    </xsl:document>
  </xsl:function>
  
  <xsl:function name="letex:resolve-uri-by-catalog" as="xs:string?">
    <xsl:param name="uri-in" as="xs:string?"/>
    <xsl:param name="catalog" as="document-node(element(cat:catalog))"/>
    <xsl:if test="$uri-in">
      <xsl:variable name="expand-nextCatalog" as="document-node(element(cat:catalog))">
        <xsl:sequence select="if ($catalog/cat:catalog/@expanded = 'yes')
                              then $catalog
                              else letex:expand-nextCatalog($catalog)"/>
      </xsl:variable>
      <xsl:variable name="matching-uri" select="key('cat:uri-by-name', $uri-in, $expand-nextCatalog)" as="element(cat:uri)*"/>
      <xsl:choose>
        <xsl:when test="$matching-uri">
          <xsl:sequence select="string($matching-uri/@uri)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="candidates" as="element(cat:rewriteURI)*"
                        select="$expand-nextCatalog//cat:rewriteURI[starts-with($uri-in, @uriStartString)]"/>
          <xsl:variable name="max" select="max(for $c in $candidates return string-length($c/@uriStartString))" as="xs:double?"/>
          <xsl:variable name="longest-match" as="element(cat:rewriteURI)?"
                        select="($candidates[string-length(@uriStartString) = $max])[1]"/>
          <xsl:choose>
            <xsl:when test="$longest-match">
              <xsl:sequence select="concat($longest-match/@rewritePrefix, substring($uri-in, $max + 1))"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:sequence select="$uri-in"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:function>
  
  <xsl:function name="letex:reverse-resolve-uri-by-catalog" as="xs:string?">
    <xsl:param name="uri-in" as="xs:string?"/>
    <xsl:param name="catalog" as="document-node(element(cat:catalog))"/>
    <xsl:if test="$uri-in">
      <xsl:variable name="expand-nextCatalog" as="document-node(element(cat:catalog))"
                    select="if ($catalog/cat:catalog/@expanded = 'yes')
                            then $catalog
                            else letex:expand-nextCatalog($catalog)"/>
      <xsl:variable name="matching-uri" select="key('cat:uri-by-uri', $uri-in, $expand-nextCatalog)" as="element(cat:uri)*"/>
      <xsl:choose>
        <xsl:when test="$matching-uri">
          <xsl:sequence select="string($matching-uri[1]/@name)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="candidates" as="element(cat:rewriteURI)*"
                        select="$expand-nextCatalog//cat:rewriteURI[starts-with($uri-in, @rewritePrefix)]"/>
          <xsl:variable name="max" as="xs:double?"
                        select="max(for $c in $candidates return string-length($c/@rewritePrefix))"/>
          <xsl:variable name="longest-match" as="element(cat:rewriteURI)?" 
                        select="($candidates[string-length(@rewritePrefix) = $max])[1]"/>
          <xsl:choose>
            <xsl:when test="$longest-match">
              <xsl:sequence select="concat($longest-match/@uriStartString, substring($uri-in, $max + 1))"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:sequence select="$uri-in"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:function>
  
  <xsl:template match="* | @*" mode="cat:expand-nextCatalog">
    <xsl:copy>
      <xsl:attribute name="xml:base" select="base-uri()"/>
      <xsl:apply-templates select="@* | node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="/*" mode="cat:expand-nextCatalog">
    <xsl:param name="additional-catalogs" as="document-node(element(cat:catalog))*"/>
    <xsl:copy>
      <xsl:attribute name="xml:base" select="base-uri()"/>
      <xsl:attribute name="expanded" select="'yes'"/>
      <xsl:apply-templates select="@*, node(), $additional-catalogs/cat:catalog/node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="@rewritePrefix" mode="cat:expand-nextCatalog">
    <xsl:attribute name="{name()}" select="resolve-uri(., base-uri())"/>
  </xsl:template>
  
  <xsl:template match="cat:nextCatalog" mode="cat:expand-nextCatalog">
    <xsl:choose>
      <xsl:when test="doc-available(resolve-uri(@catalog, base-uri()))">
        <xsl:apply-templates select="document(resolve-uri(@catalog, base-uri()))/cat:catalog/*" mode="#current"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message select="'Cannot retrieve ', string(@catalog), ' (from ', base-uri(), ')'"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
</xsl:stylesheet>