<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:cat="urn:oasis:names:tc:entity:xmlns:xml:catalog"
  xmlns:letex="http://www.le-tex.de/namespace"
  xmlns:style="http://saxonica.com/ns/html-style-property"
  xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
  xmlns:prop="http://saxonica.com/ns/html-property"
  xmlns:transpect="http://www.le-tex.de/namespace/transpect"
  exclude-result-prefixes="xs cat letex transpect"
  extension-element-prefixes="ixsl"
  version="2.0">

  <xsl:import href="resolver/resolve-uri-by-catalog.xsl"/>
  <xsl:import href="../xsl/crawl.xsl"/>
  
  <xsl:template match="/">
    <xsl:result-document href="#catalog" method="ixsl:replace-content">
      <xsl:variable name="lib-cat" as="document-node(element(cat:catalog))">
        <xsl:document>
          <catalog xmlns="urn:oasis:names:tc:entity:xmlns:xml:catalog">
            <uri name="http://xmlcalabash.com/extension/steps/library-1.0.xpl" uri="../xpl/lib/library-1.0.xpl"/>
            <rewriteURI uriStartString="http://transpect.le-tex.de/calabash-extensions/" rewritePrefix="../xpl/lib/"/>
          </catalog>
        </xsl:document>
      </xsl:variable>
      <xsl:sequence select="letex:expand-nextCatalog((/, $lib-cat))"/>
    </xsl:result-document>
    <xsl:for-each select="ixsl:page()//*[@class = 'loading']">
      <ixsl:set-attribute name="style:display" select="'none'"/>
    </xsl:for-each>
    <xsl:for-each select="ixsl:page()//*:button[@id = 'add']">
      <ixsl:set-attribute name="style:visibility" select="'visible'"/>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="*[@id = ('abstract2repo', 'repo2abstract')]" mode="ixsl:onclick">
    <xsl:variable name="source" as="xs:string" select="replace(@id, '^(.+)2.+$', '$1')"/>
    <xsl:variable name="target" as="xs:string" select="replace(@id, '^.+2(.+)$', '$1')"/>
    <xsl:variable name="uri" select="//*[@id = $source]/@prop:value" as="xs:string*"/>
    <xsl:variable name="catalog" as="document-node(element(cat:catalog))">
      <xsl:document>
        <xsl:sequence select="//*[@id = 'catalog']/*"/>
      </xsl:document>
    </xsl:variable>
    <xsl:for-each select="//*[@id = $target]">
      <!-- There’s a catch. Don’t manipulate value. Use prop:value instead. 
        Otherwise the text in the input element might not update. -->
      <xsl:choose>
        <xsl:when test="$source = 'repo'">
          <ixsl:set-attribute name="prop:value" select="letex:reverse-resolve-uri-by-catalog($uri, $catalog)"/>    
        </xsl:when>
        <xsl:otherwise>
          <ixsl:set-attribute name="prop:value" select="letex:resolve-uri-by-catalog($uri, $catalog)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <xsl:function name="cat:resolve" as="xs:string">
    <!-- resolve against the expanded catalog that has been stored in this HTML file -->
    <xsl:param name="uri" as="xs:string"/>
    <xsl:variable name="catalog" as="document-node(element(cat:catalog))">
      <xsl:document>
        <xsl:sequence select="ixsl:page()//*[@id = 'catalog']/*"/>
      </xsl:document>
    </xsl:variable>
    <xsl:sequence select="letex:resolve-uri-by-catalog($uri, $catalog)"/>
  </xsl:function>

  <!-- Interactivity -->

  <xsl:template match="*[@id = ('add')]" mode="ixsl:onclick">
    <xsl:result-document href="#pipelines" method="ixsl:append-content">
      <xsl:apply-templates select="doc(cat:resolve(//*[@id = 'xpl']/@prop:value))" mode="add-base-uri"/>
      <!-- If there are no pipelines yet, add the standard library and Calabash’s extension step library -->
      <xsl:if test="not(ixsl:page()//*[@id = 'xpl']/*)">
        <xsl:apply-templates select="for $l in ('library-1.0.xpl', 'xproc-1.0.xpl') return doc(concat('../xpl/lib/', $l))" mode="add-base-uri"/>
      </xsl:if>
    </xsl:result-document>
    <xsl:result-document href="#initial-base-uris" method="ixsl:append-content">
      <li>
        <xsl:sequence select="cat:resolve(//*[@id = 'xpl']/@prop:value)"/>
      </li>
    </xsl:result-document>
    <xsl:for-each select="ixsl:page()//*:button[@id = 'process']">
      <ixsl:set-attribute name="style:visibility" select="'visible'"/>
    </xsl:for-each>
  </xsl:template>
  
  <xsl:template match="*[@id = ('process')]" mode="ixsl:onclick">
    <xsl:result-document href="#pipelines" method="ixsl:replace-content">
      <xsl:call-template name="raw-list"/>
    </xsl:result-document>
  </xsl:template>
  
  <xsl:template match="/*" mode="add-base-uri">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:attribute name="xml:base" select="base-uri()"/>
      <xsl:copy-of select="node()"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- Crawl -->
  
  <xsl:template name="raw-list">
    <xsl:apply-templates select="ixsl:page()//*:div[@id = 'pipelines']/*" mode="raw-list">
      <xsl:with-param name="catalog" tunnel="yes">
        <xsl:document>
          <xsl:sequence select="ixsl:page()//*[@id = 'catalog']/*"/>
        </xsl:document>
      </xsl:with-param>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:function name="transpect:initial-base-uris" as="xs:string+">
    <xsl:sequence select="for $i in ixsl:page()//*:ul[@id = 'initial-base-uris']/*:li return string($i)"/>
  </xsl:function>
  
</xsl:stylesheet>