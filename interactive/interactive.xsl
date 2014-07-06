<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:cx="http://xmlcalabash.com/ns/extensions" 
  xmlns:cxf="http://xmlcalabash.com/ns/extensions/fileutils"
  xmlns:p="http://www.w3.org/ns/xproc"
  xmlns:cat="urn:oasis:names:tc:entity:xmlns:xml:catalog"
  xmlns:letex="http://www.le-tex.de/namespace"
  xmlns:style="http://saxonica.com/ns/html-style-property"
  xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
  xmlns:prop="http://saxonica.com/ns/html-property"
  xmlns:transpect="http://www.le-tex.de/namespace/transpect"
  exclude-result-prefixes="xs cat letex transpect"
  extension-element-prefixes="ixsl"
  version="2.0">

  <xsl:import href="../xsl/crawl.xsl"/>
  <xsl:import href="../xsl/connections.xsl"/>
  <xsl:import href="../xsl/render-html-pages.xsl"/>
  
  <xsl:template match="/">
    <xsl:result-document href="#catalog" method="ixsl:replace-content">
      <xsl:variable name="lib-cat" as="document-node(element(cat:catalog))">
        <xsl:document>
          <catalog xmlns="urn:oasis:names:tc:entity:xmlns:xml:catalog">
            <uri name="http://xmlcalabash.com/extension/steps/library-1.0.xpl" uri="../xpl/lib/library-1.0.xpl"/>
            <!-- Only resolves if calabash and transpectdoc are on sibling directories: -->
            <rewriteURI uriStartString="http://transpect.le-tex.de/calabash-extensions/" rewritePrefix="../../calabash/lib/ltx/"/>
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
      <xsl:variable name="href" select="//*[@id = 'xpl']/@prop:value" as="xs:string"/>
      <xsl:apply-templates select="doc(cat:resolve($href))" mode="transpect:read-doc"/>
      <!-- If there are no pipelines yet, add the standard library and Calabash’s extension step library -->
      <xsl:if test="not(ixsl:page()//*[@id = 'pipelines']/*)">
        <xsl:apply-templates select="for $l in ('library-1.0.xpl', 'xproc-1.0.xpl', 'ltx-lib.xpl') return doc(concat('../xpl/lib/', $l))" mode="transpect:read-doc"/>
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
    <xsl:variable name="crawl" as="document-node(element(c:files))">
      <xsl:document>
        <xsl:call-template name="crawl"/>
      </xsl:document>
    </xsl:variable>
    <xsl:message select="'CRWL: ', $crawl/*/name()"></xsl:message>
    <xsl:result-document href="#pipelines" method="ixsl:replace-content">
      <xsl:apply-templates select="$crawl" mode="connect"/>
<!--      <xsl:sequence select="$crawl"></xsl:sequence>-->
    </xsl:result-document>
    <!--<ixsl:schedule-action wait="1">
      <xsl:call-template name="render-for-interactive">
        <xsl:with-param name="page-name" select="'index'"/>
      </xsl:call-template>
    </ixsl:schedule-action>-->
  </xsl:template>
  
  <xsl:template match="/*" mode="transpect:read-doc" priority="2">
    <xsl:copy>
      <xsl:attribute name="xml:base" select="base-uri()"/>
      <xsl:attribute name="transpect:name" select="name()"/>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- Crawl -->

  <xsl:template match="*" mode="transpect:read-doc">
    <xsl:copy>
      <xsl:if test=" prefix-from-QName(node-name(.))">
        <xsl:attribute name="transpect:name" select="name()"/>  
      </xsl:if>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
    
  <xsl:template name="raw-list" as="element(c:file)+">
    <xsl:apply-templates select="ixsl:page()//*:div[@id = 'pipelines']/*" mode="raw-list">
      <xsl:with-param name="catalog" tunnel="yes">
        <xsl:document>
          <xsl:sequence select="ixsl:page()//*[@id = 'catalog']/*"/>
        </xsl:document>
      </xsl:with-param>
    </xsl:apply-templates>
  </xsl:template>
  
  <!-- Saxon CE cannot create head elements in the DOM, no matter in what namespace they are -->
  <xsl:template match="*:head" mode="raw-list">
    <xsl:element name="_head" namespace="{namespace-uri(.)}">
      <xsl:attribute name="letex:name" select="name()"/>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:function name="transpect:initial-base-uris" as="xs:string+">
    <xsl:sequence select="for $i in ixsl:page()//*:ul[@id = 'initial-base-uris']/*:li return string($i)"/>
  </xsl:function>
  
  <!-- Render -->
  
  <xsl:template name="render-for-interactive">
    <xsl:param name="page-name" as="xs:string"/>
    <xsl:for-each select="ixsl:page()//*:button[@id = 'process']">
      <ixsl:set-attribute name="style:display" select="'none'"/>
    </xsl:for-each>
    <xsl:for-each select="ixsl:page()//*[@id = 'wait']">
      <ixsl:set-attribute name="style:visibility" select="'visible'"/>
    </xsl:for-each>
    <xsl:variable name="representation" as="document-node(element(c:files))">
      <xsl:document>
        <xsl:sequence select="ixsl:page()//*:div[@id = 'pipelines']/*" />
      </xsl:document>
    </xsl:variable>
    <xsl:result-document href="#transpectdoc" method="ixsl:replace-content">
      <xsl:apply-templates select="$representation//*[@transpect:filename = $page-name]" mode="render-transpectdoc">
        <xsl:with-param name="docroot" select="$representation" tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:result-document>
  </xsl:template>
  
  <xsl:template match="*:a[@href]" mode="ixsl:onclick" ixsl:prevent-default="yes">
    <ixsl:schedule-action wait="1">
      <xsl:call-template name="render-for-interactive">
        <xsl:with-param name="page-name" select="replace(@href, '\.html', '')"/>
      </xsl:call-template>
    </ixsl:schedule-action>
  </xsl:template>
  
  <xsl:template name="update-nav">
    <xsl:sequence select="ixsl:call(ixsl:window(), 'update_nav')"/>
  </xsl:template>
  
  <xsl:template name="page">
    <div id="{@transpect:filename}" class="id-container">
      <xsl:call-template name="transpect:nav">
        <xsl:with-param name="page-name" select="'temp'"/>
      </xsl:call-template>
      <xsl:call-template name="transpect:main"/>
    </div>
    <ixsl:schedule-action wait="1">
      <xsl:call-template name="update-nav"/>
    </ixsl:schedule-action>
  </xsl:template>
  
  <xsl:template match="c:files" mode="render-transpectdoc">
    <xsl:call-template name="page"/>
  </xsl:template>
</xsl:stylesheet>