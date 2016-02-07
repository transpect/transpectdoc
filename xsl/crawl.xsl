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
  
  <xsl:import href="../interactive/resolver/resolve-uri-by-catalog.xsl"/>

  <xsl:include href="common.xsl"/>

  <xsl:param name="project-root-uri" as="xs:string?"/>
  <xsl:param name="treat-use-when-as" as="xs:string?" select="'ignore'"/>

  <xsl:variable name="base-dir-uri-regex" as="xs:string?" 
    select="if ($project-root-uri)
            then replace($project-root-uri, '^file:/+', 'file:/+')
            else ()"/>

  <xsl:key name="by-href" match="*[@xml:id]" use="string-join((ancestor::*[tr:is-step(.)][@href][1]/@href, @xml:id), '#')"/>

  <xsl:template name="crawl" as="element(c:files)">
    <xsl:variable name="raw-list" as="element(c:file)*">
      <xsl:call-template name="raw-list"/>
    </xsl:variable>
    <xsl:variable name="consolidate-by-href" as="element(c:file)*">
      <xsl:for-each-group select="$raw-list" group-by="@href">
        <xsl:sequence select="."/>
      </xsl:for-each-group>
    </xsl:variable>
    <xsl:variable name="duplicate-types" as="element(c:group)*">
      <xsl:for-each-group select="$consolidate-by-href/descendant-or-self::*[@p:type]" group-by="@p:type">
        <xsl:if test="count(current-group()) gt 1">
          <c:group type="{current-grouping-key()}">
            <!-- These should only be redundant declarations of extension steps. Need to verify this and
              raise an error if not. For the time being, we select the declaration that is best documented… -->
            <xsl:variable name="maxdocs" as="xs:integer" 
              select="xs:integer(max(for $item in current-group() return count($item//p:documentation)))"/>
            <xsl:variable name="winner" as="element(*)" select="(current-group()[count(.//p:documentation) = $maxdocs])[1]"/>
            <xsl:for-each select="current-group()">
              <c:member href="{ancestor-or-self::*[@href][1]/@href}">
                <xsl:if test="not(. is $winner)">
                  <xsl:attribute name="sort-out" select="'true'"/>
                </xsl:if>
                <xsl:sequence select="."/>
              </c:member>
            </xsl:for-each>
          </c:group>  
        </xsl:if>
      </xsl:for-each-group>
    </xsl:variable>
    <c:files display-name="index">
      <xsl:apply-templates select="$consolidate-by-href" mode="remove-duplicate-declarations">
        <xsl:with-param name="duplicate-list" select="$duplicate-types" as="element(c:group)*" tunnel="yes"/>
      </xsl:apply-templates>
    </c:files>
  </xsl:template>
  
  <xsl:template match="* | @*" mode="remove-duplicate-declarations">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="*[@p:type]" mode="remove-duplicate-declarations">
    <xsl:param name="duplicate-list" as="element(c:group)*" tunnel="yes"/>
    <xsl:choose>
      <xsl:when test="$duplicate-list[@type = current()/@p:type]/c:member[@href = current()/ancestor-or-self::*[@href][1]/@href]/@sort-out"/>
      <xsl:otherwise>
        <xsl:next-match/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!--<xsl:template match="text()" mode="raw-list"/>-->
  
  <!-- The top-level file contents. We don’t use /* for the matching pattern
    because in interactive mode, they aren’t top-level elements -->
  <xsl:template match="p:library | p:declare-step[not(parent::p:library)] | p:pipeline[not(parent::p:library)]" 
    priority="4" mode="raw-list">
    <xsl:param name="catalog" as="document-node(element(cat:catalog))?" tunnel="yes"/>
    <xsl:param name="pre-catalog-resolution-href" as="xs:string?" tunnel="yes"/>
    <c:file source-type="{local-name()}" href="{tr:normalize-uri(base-uri(.))}">
      <xsl:variable name="project-relative-path" as="xs:string"
        select="if ($base-dir-uri-regex) 
                then replace(base-uri(/*), $base-dir-uri-regex, '')
                else base-uri(/*)"/>
      <xsl:if test="$project-relative-path ne base-uri(/*)">
        <xsl:attribute name="project-relative-path" select="$project-relative-path"/>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="$pre-catalog-resolution-href">
          <xsl:attribute name="canonical-href" select="resolve-uri($pre-catalog-resolution-href, tr:reverse-resolve-uri-by-catalog(base-uri(/*), $catalog))"/>
          <xsl:attribute name="canonical-href" select="$pre-catalog-resolution-href"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:attribute name="canonical-href" select="tr:reverse-resolve-uri-by-catalog(base-uri(/*), $catalog)"/>
          <xsl:attribute name="foo" select="tr:reverse-resolve-uri-by-catalog('file:/C:/cygwin/home/gerrit/Hogrefe/BookTagSet/transpect-git/a9s/common/xpl/idml2hobots.xpl', $catalog)"></xsl:attribute>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:call-template name="process-inner"/>
    </c:file>
    <xsl:apply-templates select="p:import" mode="#current">
      <xsl:with-param name="example-for" select="()" tunnel="yes"/>
    </xsl:apply-templates>
    <xsl:apply-templates select="(self::p:declare-step | self::p:pipeline)//tr:examples" mode="#current"/>
  </xsl:template>

  <xsl:template match="p:pipeinfo" mode="raw-list">
    <xsl:copy-of select="."/>
  </xsl:template>

  <xsl:template match="tr:examples" mode="raw-list">
    <xsl:param name="catalog" as="document-node(element(cat:catalog))?" tunnel="yes"/>
    <xsl:variable name="context" select="." as="element(tr:examples)"/>
    <xsl:variable name="files" as="document-node(element(*))*">
      <xsl:sequence select="for $f in tr:file 
                            return tr:doc(resolve-uri($f/@href, base-uri(.)), $catalog)"/>
      <xsl:sequence select="for $c in tr:collection 
                            return tr:find-in-dir(
                              $c/@dir-uri, 
                              $c/@file, 
                              $catalog
                            )" use-when="not(contains(system-property('xsl:product-name'), 'Saxon-CE'))"/>
    </xsl:variable>
    <!-- there may be duplicates -->
<!--    <xsl:message select="'FILES ', count($files), ' ', count(descendant::tr:collection), ' ', count(descendant::tr:file)"></xsl:message>-->
    <xsl:for-each-group select="$files" group-by="base-uri(/*)">
      <xsl:apply-templates select="." mode="#current">
        <xsl:with-param name="pre-catalog-resolution-href" tunnel="yes" as="xs:string"
          select="tr:reverse-resolve-uri-by-catalog(current-grouping-key(), $catalog)"/>
        <xsl:with-param name="example-for" select="$context/@option-value" tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:for-each-group>
  </xsl:template>

  <!-- Resolves the URI against a supplied catalog and process the document in a mode that will 
    add a tr:name attribute to prefixed names (if there is a tempplate for that – it should be
    in the interactive implementation).
    The latter is because browsers might mangle the prefix. 
    Please note that you might need to resolve-uri() relative hrefs prior to
    passing them to tr:doc() -->
  <xsl:function name="tr:doc" as="document-node(element(*))?">
    <xsl:param name="href" as="xs:string"/>
    <xsl:param name="catalog" as="document-node(element(cat:catalog))?"/>
    <xsl:choose>
      <xsl:when test="$catalog">
        <xsl:apply-templates select="doc(tr:resolve-uri-by-catalog($href, $catalog))" mode="tr:read-doc"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="doc($href)" mode="tr:read-doc"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:template match="/" mode="tr:read-doc">
    <xsl:document>
      <xsl:apply-templates mode="#current"/>
    </xsl:document>
  </xsl:template>

  <xsl:template match="/*" mode="tr:read-doc">
    <xsl:copy>
      <xsl:attribute name="xml:base" select="base-uri()"/>
      <xsl:apply-templates select="@*, *" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="* | @*" mode="tr:read-doc">
    <xsl:copy-of select="."/>
  </xsl:template>

  <xsl:function name="tr:find-in-dir" as="document-node(element(*))*">
    <xsl:param name="dir-uri" as="xs:string"/>
    <xsl:param name="file-name-with-local-dir" as="xs:string"/> 
    <xsl:param name="catalog" as="document-node(element(cat:catalog))?"/>
    <xsl:variable name="file-name" select="replace($file-name-with-local-dir, '^.+/', '')" as="xs:string"/>
    <xsl:variable name="collection-uri" select="concat(
                                                  if ($catalog) 
                                                  then tr:resolve-uri-by-catalog($dir-uri, $catalog) 
                                                  else $dir-uri,
                                                  '/?select=', $file-name, 
                                                  ';recurse=yes'
                                                )" as="xs:string"/>
    <xsl:sequence select="collection($collection-uri)[contains(base-uri(), $file-name-with-local-dir)]"/>
  </xsl:function>

  <xsl:function name="tr:basename" as="xs:string">
    <xsl:param name="href" as="xs:string"/>
    <xsl:sequence select="replace($href, '^.+/', '')"/>
  </xsl:function>
  
  <xsl:function name="tr:normalize-uri" as="xs:string">
    <xsl:param name="uri" as="xs:string"/>
    <xsl:sequence select="replace($uri, '^file:///', 'file:/')"/>
  </xsl:function>

  <xsl:template name="process-inner">
    <xsl:param name="example-for" as="xs:string?" tunnel="yes"/>
    <xsl:copy-of select="@name"/>
    <xsl:apply-templates select="@type" mode="raw-list"/>
    <xsl:if test="not(@name) and tr:is-step(.)">
      <xsl:attribute name="name" select="generate-id()"/>
      <xsl:attribute name="generated-name" select="'true'"/>
    </xsl:if>
    <xsl:if test="local-name() = ('declare-step', 'pipeline')
                  and
                  (base-uri() = tr:initial-base-uris())">
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
                                  replace(($example-for, tr:basename(base-uri()))[1], '\.[^.]+$', ''),
                                  ' Ⓐ',
                                  if ($example-for) then 'Ⓓ' else ''
                                )"/>
          <xsl:if test="parent::p:library">
            <xsl:text> (in library </xsl:text>
            <xsl:value-of select="tr:basename(base-uri())"/>
            <xsl:text>)</xsl:text>
          </xsl:if>
        </xsl:when>
        <xsl:when test="self::p:library">
          <xsl:value-of select="tr:basename(base-uri())"/>
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

  <xsl:template match="*[@use-when][$treat-use-when-as = 'ignore']" mode="raw-list" priority="2"/>

  <xsl:template match="*" mode="raw-list">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="p:when | p:otherwise" mode="raw-list">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="*[tr:is-step(.)]
                        [not(@name)]" mode="raw-list">
    <xsl:copy>
      <xsl:attribute name="name" select="generate-id()"/>
      <xsl:attribute name="generated-name" select="'true'"/>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="*[tr:is-step(.)][@name]" mode="raw-list">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  

  <xsl:template match="p:*/@type" mode="raw-list">
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
    <xsl:variable name="href" select="string(resolve-uri(@href, (ancestor::*[@xml:base][1]/@xml:base, base-uri())[1]))" as="xs:string"/>
<!--    <xsl:message select="'PIU: ', @href, ' ',$href, ' ', tr:resolve-uri-by-catalog($href, $catalog)"/>-->
    <xsl:apply-templates select="tr:doc($href, $catalog)" mode="#current">
      <xsl:with-param name="pre-catalog-resolution-href" select="@href" tunnel="yes" as="xs:string"/>
    </xsl:apply-templates>
  </xsl:template>
  
</xsl:stylesheet>