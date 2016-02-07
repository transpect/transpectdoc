<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:cx="http://xmlcalabash.com/ns/extensions" 
  xmlns:cat="urn:oasis:names:tc:entity:xmlns:xml:catalog"
  xmlns:p="http://www.w3.org/ns/xproc"
  xmlns:tr="http://transpect.io"
  exclude-result-prefixes="c cx xs tr"
  version="2.0">
  
  <xsl:import href="http://transpect.io/xslt-util/xslt-based-catalog-resolver/xsl/resolve-uri-by-catalog.xsl"/>
  <xsl:import href="crawl.xsl"/>

  <xsl:param name="catalog-uri" as="xs:string?" select="'http://this.transpect.io/xmlcatalog/catalog.xml'"/>

  <xsl:variable name="base-dir-uri-regex" as="xs:string" select="replace($project-root-uri, '^file:/+', 'file:/+')"/>

  <xsl:variable name="initial-base-uris" as="xs:string+" select="collection()/base-uri()[not(ends-with(., 'lib/xproc-1.0.xpl'))]"/>

  <xsl:template name="raw-list">
    <xsl:apply-templates select="collection()" mode="raw-list">
      <xsl:with-param name="catalog" tunnel="yes">
        <xsl:sequence select="if ($catalog-uri) then tr:expand-nextCatalog(doc($catalog-uri)) else ()"/>
      </xsl:with-param>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:function name="tr:initial-base-uris" as="xs:string+">
    <xsl:sequence select="collection()/base-uri()[not(ends-with(., 'lib/xproc-1.0.xpl'))]"/>
  </xsl:function>

</xsl:stylesheet>