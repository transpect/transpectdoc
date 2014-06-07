<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:p="http://www.w3.org/ns/xproc"
  xmlns:transpect="http://www.le-tex.de/namespace/transpect"
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns="http://www.w3.org/1999/xhtml"
  exclude-result-prefixes="c xs transpect"
  version="2.0">

  <xsl:include href="common.xsl"/>

  <xsl:param name="output-base-uri" select="'doc'"/>
  <xsl:param name="project-name" as="xs:string?" />

  <xsl:key name="transpect:step" match="*[@p:is-step = 'true']" use="name()"/>

  <xsl:variable name="title" select="if (not($project-name) or $project-name = '') 
                                     then tokenize($output-base-uri, '/')[not(. = ('doc', 'trunk', 'repo'))][last()]
                                     else $project-name" as="xs:string"/>

  <xsl:template match="* | @*" mode="#default main-html">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="c:files | c:file[@source-type = library]">
    <!--<xsl:call-template name="page"/>-->
    <xsl:apply-templates select="c:file | c:step-declarations"/>
  </xsl:template>

  <xsl:template match="*[@source-type]" mode="main-html_">
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
    <xsl:sequence select="replace(replace($name, ':', '_'), '(\s+\(.+\)|[^-0-9a-z_]+)', '', 'i')"/>
  </xsl:function>

  <xsl:function name="transpect:page-name" as="xs:string">
    <xsl:param name="elt" as="element(*)"/>
    <xsl:param name="output-base-uri" as="xs:string?"/>
    <xsl:variable name="fragment" as="xs:string"
      select="if ($elt/@name and not($elt/@source-type))
              then concat('#', if($elt/@p:is-step = 'true') then 'step' else local-name($elt), '_', $elt/@name)
              else ''"/>
    <xsl:sequence select="concat(if ($output-base-uri)
                                 then concat($output-base-uri, '/')
                                 else '', 
                                 transpect:normalize-for-filename($elt/ancestor-or-self::*[@display-name][1]/@display-name), 
                                 '.html',
                                 $fragment
                                )"/>
  </xsl:function>
  
  <xsl:template match="c:file | c:step-declaration">
    <xsl:call-template name="page"/>
    <xsl:apply-templates select="c:step-declarations"/>
  </xsl:template>

  <xsl:template name="page">
    <xsl:variable name="page-name" select="transpect:page-name(., $output-base-uri)" as="xs:string"/>
    <xsl:result-document href="{$page-name}">
      <html>
        <head>
          <meta http-equiv="Content-type" content="text/html;charset=UTF-8"/>
          <link rel="stylesheet" type="text/css" href="transpectdoc.css"/>
          <link rel="stylesheet" type="text/css" href="highlight/styles/default.css"/>
          <script src="jquery.js"></script>
          <script src="highlight/highlight.pack.js"></script>
          <script>hljs.initHighlightingOnLoad();</script>
          <script type="text/javascript" src="transpectdoc.js"></script>
          <title>
            <xsl:value-of select="string-join((@display-name, 'transpectdoc'), ' – ')"/>
          </title>
        </head>
        <body id="{transpect:normalize-for-filename(@display-name)}" >
          <xsl:call-template name="transpect:nav">
            <xsl:with-param name="page-name" select="$page-name"/>
          </xsl:call-template>
          <xsl:call-template name="transpect:main"/>
        </body>
      </html>
    </xsl:result-document>
  </xsl:template>

  <xsl:template name="transpect:nav">
    <xsl:param name="page-name" as="xs:string"/>
    <div id="nav" class="macroblock">
      <h1>
        <xsl:value-of select="$title"/>
      </h1>
      <xsl:call-template name="nav">
        <xsl:with-param name="page-name" tunnel="yes" select="$page-name"/>
      </xsl:call-template>
    </div>
  </xsl:template>

  <xsl:template name="transpect:main">
    <div id="main" class="macroblock">
      <xsl:apply-templates select="." mode="main-html"/>  
    </div>
  </xsl:template>
  
  <xsl:variable name="built-in-prefixes" select="('p', 'pxf', 'pos', 'ml', 'cxu', 'cxo', 'cx', 'cxf', 'c')" as="xs:string+"/>

  <xsl:key name="used-step" use="name()" 
    match="*"/><!-- filter it? [not(prefix-from-QName(node-name(.)) = $built-in-prefixes)] -->
  <xsl:key name="step-declaration-by-type" use="@p:type" match="*[@p:type]"/>
  
  <xsl:template name="nav">
    <xsl:param name="page-name" tunnel="yes" as="xs:string"/>
    <ul class="nav">
      <li>
        <p class="toggle level1" id="nav_frontend"><a class="fold pointer">Frontend Pipelines</a>
          <xsl:text>&#x2003;</xsl:text>
          <span class="count">(<xsl:value-of select="count(//*[@front-end = 'true'])"/>)</span></p>
        <ul>
          <xsl:apply-templates select="//*[@front-end = 'true']" mode="links">
            <xsl:with-param name="current" select="."/>
            <xsl:with-param name="style" select="'type'"/>
          </xsl:apply-templates>
        </ul>
      </li>
      <xsl:variable name="typed-steps" select="//*[@p:type]" as="element(*)*"/>
      <xsl:variable name="used-steps" select="$typed-steps[key('used-step', @p:type)]"/>
      <xsl:if test="exists($typed-steps)">
        <li>
          <p class="toggle level1" id="nav_typedSteps">
            <a class="fold pointer">Step Declarations</a>
            <xsl:text>&#x2003;</xsl:text>
            <span class="count">(<xsl:value-of select="count(distinct-values($used-steps/@p:type))"/>)</span>
          </p>
          <ul>
            <xsl:for-each-group select="$used-steps" group-by="@type-prefix">
              <xsl:sort select="current-grouping-key()"/>
              <li>
                <p class="toggle level2" id="nav_namespaceSteps_{current-grouping-key()}">
                  <a class="fold pointer">
                    <xsl:value-of select="concat(current-grouping-key(), ':…')"/>
                  </a>
                  <xsl:text>&#x2003;</xsl:text>
                  <span class="count">(<xsl:value-of select="count(current-group())"/>)</span>
                </p>
                <ul>
                  <xsl:for-each-group select="current-group()"
                    group-by="(ancestor::c:file[@source-type = 'library']/@display-name, '')[1]">
                    <xsl:sort select="current-grouping-key()"/>
                    <xsl:choose>
                      <xsl:when test="current-grouping-key() = ''">
                        <xsl:apply-templates select="current-group()" mode="links">
                          <xsl:with-param name="style" select="'type'"/>
                        </xsl:apply-templates>
                      </xsl:when>
                      <xsl:otherwise>
                        <li>
                          <p class="toggle level3">
                            <a class="fold pointer">
                              <xsl:value-of select="current-grouping-key()"/>
                            </a>
                            <xsl:text>&#x2003;</xsl:text>
                            <span class="count">(<xsl:value-of select="count(current-group())"/>)</span>
                          </p>
                          <ul>
                            <xsl:apply-templates select="current-group()" mode="links">
                              <xsl:with-param name="style" select="'type'"/>
                            </xsl:apply-templates>
                          </ul>
                        </li>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:for-each-group>
                </ul>
              </li>
            </xsl:for-each-group>
          </ul>
        </li>
      </xsl:if>

      <xsl:variable name="examples" select="//*[@example-for]"/>
      <xsl:if test="exists($examples)">
        <li>
          <p class="toggle level1"><a class="fold pointer">Dynamic Evaluation Candidates</a>
            <xsl:text>&#x2003;</xsl:text>
            <span class="count">(<xsl:value-of select="count(distinct-values($examples/@project-relative-path))"/>)</span></p>
          <ul>
            <xsl:for-each-group select="$examples" group-by="@project-relative-path">
              <xsl:sort select="current-grouping-key()"/>
              <xsl:apply-templates select="." mode="links">
                <xsl:with-param name="style" select="'type'"/>
              </xsl:apply-templates>
            </xsl:for-each-group>
          </ul>
        </li>
      </xsl:if>
    </ul>
  </xsl:template>

  <xsl:function name="transpect:render-display-name" as="node()*">
    <xsl:param name="input" as="xs:string"/>
    <xsl:analyze-string select="$input" regex="[ⒶⒹⓅⓇⓈ]">
      <xsl:matching-substring>
        <span>
          <xsl:attribute name="title">
            <xsl:choose>
              <xsl:when test=". = 'Ⓐ'">
                <xsl:sequence select="'anonymous – this step has no type'"/>
              </xsl:when>
              <xsl:when test=". = 'Ⓓ'">
                <xsl:sequence select="'dynamic – this is an example for a dynamically loaded or generated pipeline'"/>
              </xsl:when>
              <xsl:when test=". = 'Ⓟ'">
                <xsl:sequence select="'primary port'"/>
              </xsl:when>
              <xsl:when test=". = 'Ⓡ'">
                <xsl:sequence select="'required option'"/>
              </xsl:when>
              <xsl:when test=". = 'Ⓢ'">
                <xsl:sequence select="'sequence – zero to many documents are allowed on this port'"/>
              </xsl:when>
            </xsl:choose>
          </xsl:attribute>
          <xsl:value-of select="."/>
        </span>
      </xsl:matching-substring>
      <xsl:non-matching-substring>
        <xsl:value-of select="."/>
      </xsl:non-matching-substring>
    </xsl:analyze-string>
  </xsl:function>

  <xsl:template match="*[@source-type = ('declare-step', 'pipeline', 'library')]" mode="main-html">
    <h2>
      <xsl:sequence select="transpect:render-display-name(replace(@display-name, concat('\s+', @name, '$'), ''))"/>
      <xsl:if test="@name">
        <xsl:text xml:space="preserve"> </xsl:text>
        <span class="name{if (@generated-name = 'true') then ' generated' else ''}" id="step_{@name}">
          <xsl:value-of select="@name"/>
        </span>
      </xsl:if>
    </h2>
    <xsl:call-template name="file-paths"/>
    <!-- main documentation -->
    <xsl:apply-templates mode="#current"
      select="p:documentation[not(preceding-sibling::*[@p:is-step = 'true'])]"/>
    <xsl:choose>
      <xsl:when test="@source-type = 'library'">
        <xsl:apply-templates select="c:step-declarations/c:step-declaration" mode="links"/>
      </xsl:when>
      <xsl:otherwise>
        <div class="interface block input">
          <xsl:call-template name="input-declarations"/>  
        </div>
        <div class="interface block output">
          <xsl:call-template name="output-declarations"/>
        </div>
        <div class="interface block option">
          <xsl:call-template name="option-declarations"/>
        </div>
        <div class="subpipeline block">
          <h3 class="toggle"><a class="pointer">Subpipeline</a></h3>
          <xsl:variable name="subpipeline" as="element(*)*" 
            select="*[@p:is-step = 'true'] | p:variable | p:documentation[preceding-sibling::*[@p:is-step = 'true']] "/>
          <xsl:choose>
            <xsl:when test="exists($subpipeline)">
              <xsl:call-template name="subpipeline-top">
                <xsl:with-param name="subpipeline" select="$subpipeline"/>
                <xsl:with-param name="depth" tunnel="yes" as="xs:integer" 
                  select="xs:integer(
                            max(for $s in descendant-or-self::*[@p:is-step = 'true'] return count($s/ancestor::*))
                            - count(ancestor::*)
                          )" />
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <p class="none">none</p>
            </xsl:otherwise>
          </xsl:choose>
        </div>
        <xsl:if test="//*[@source-type = ('declare-step', 'pipeline')][.//*[name() = current()/@p:type]]">
          <div class="interface block use">
            <h3 class="toggle"><a class="pointer">Used by</a></h3>
            <xsl:variable name="using-steps" as="element(*)*">
              <xsl:for-each-group select="//*[@source-type = ('declare-step', 'pipeline')][.//*[name() = current()/@p:type]]"
                group-by="@display-name">
                <xsl:sort select="current-grouping-key()"/>
                <xsl:apply-templates select="." mode="links"/>  
              </xsl:for-each-group>
            </xsl:variable>
            <xsl:choose>
              <xsl:when test="exists($using-steps)">
                <ul>
                  <xsl:sequence select="$using-steps"/>
                </ul>
              </xsl:when>
              <xsl:otherwise>
                <p class="none">none</p>                
              </xsl:otherwise>
            </xsl:choose>
          </div>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="*" mode="links">
    <xsl:param name="style" as="xs:string?"/>
    <li>
      <p class="nav" id="nav_{transpect:normalize-for-filename(@display-name)}">
        <xsl:if test="not($style)">
          <xsl:value-of select="@source-type"/>
          <xsl:text> </xsl:text>
        </xsl:if>
        <a href="{transpect:page-name(., ())}">
          <xsl:sequence select="transpect:render-display-name((@p:type[$style = 'type'], @display-name)[1])"/>
        </a>
      </p>
    </li>
  </xsl:template>

  <xsl:template name="file-paths">
    <div class="file-path block">
      <p class="file-path">
        <xsl:value-of select="(@project-relative-path, @href)[1]"/>
      </p>
      <xsl:if test="@canonical-href">
        <p class="file-path"> Canonical URI: <xsl:value-of select="@canonical-href"/>
        </p>
      </xsl:if>
    </div>
  </xsl:template>

  <xsl:template name="input-declarations">
    <h3 class="toggle"><a class="pointer">Input Ports</a></h3>
    <xsl:call-template name="interface-items">
      <xsl:with-param name="items" select="p:input"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="output-declarations">
    <h3 class="toggle"><a class="pointer">Output Ports</a></h3>
    <xsl:call-template name="interface-items">
      <xsl:with-param name="items" select="p:output"/>
    </xsl:call-template>
  </xsl:template>
  
  <xsl:template name="option-declarations">
    <h3 class="toggle"><a class="pointer">Options</a></h3>
    <xsl:call-template name="interface-items">
      <xsl:with-param name="items" select="p:option"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="interface-items">
    <xsl:param name="items" as="element(*)*"/>
    <xsl:choose>
      <xsl:when test="exists($items)">
        <table>
          <colgroup>
            <col class="name"/>
            <col class="doc"/>
            <col class="connect"/>
          </colgroup>
          <tr>
            <th>Name</th>
            <th>Documentation</th>
            <th>
              <xsl:value-of select="if ($items/self::p:option)
                                    then 'Default'
                                    else 'Connections'"/>
            </th>
          </tr>
          <xsl:apply-templates select="$items" mode="#current"/>
        </table>
      </xsl:when>
      <xsl:otherwise>
        <p class="none">none</p>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="p:input | p:output" mode="main-html">
    <tr>
      <td>
        <p class="port-declaration">
          <span class="name">
            <xsl:value-of select="@port"/>
          </span>
          <xsl:if test="@primary = 'true'">
            <span class="flag primary" title="Primary port">
              <xsl:value-of select="'Ⓟ'"/>
            </span>
          </xsl:if>
          <xsl:if test="@sequence = 'true'">
            <span class="flag sequence" title="Accepts a sequence of documents">
              <xsl:value-of select="'Ⓢ'"/>
            </span>
          </xsl:if>
        </p>
        <xsl:apply-templates select="../p:serialization[@port = current()/@port]" mode="#current"/>
      </td>
      <td>
        <xsl:apply-templates select="p:documentation" mode="#current"/>
      </td>
      <td>
        <xsl:apply-templates select="." mode="connections"/>
      </td>
    </tr>
  </xsl:template>
  
  <xsl:template match="p:input" mode="connections">
    <!-- context: p:input in a step declaration -->
    <xsl:variable name="pipes" as="element(p:pipe)*"
      select="key('transpect:step', current()/../@p:type)/p:input[@port = current()/@port]/p:pipe"/>
    <xsl:variable name="connection-list-items" as="element(html:li)*">
      <xsl:apply-templates mode="#current" select="$pipes"/>
    </xsl:variable>
    <xsl:if test="exists($connection-list-items)">
      <ul class="connections">
        <xsl:sequence select="$connection-list-items"/>
      </ul>
    </xsl:if>
  </xsl:template>

  <xsl:template match="p:input/p:pipe" mode="connections">
    <!-- p:input in a connection --> 
    <xsl:variable name="connected-to" as="element(*)" 
      select="ancestor::*[@source-type = 'declare-step']
                /descendant-or-self::*[not(name() = ('p:option', 'p:param', 'p:with-option', 'p:with-param'))]
                                      [@name = current()/@step]"/>
    <li>
      <a href="{transpect:page-name($connected-to, $output-base-uri)}">
        <xsl:value-of select="transpect:render-display-name(ancestor::*[@source-type = 'declare-step']/@display-name)"/>
        <xsl:text>/</xsl:text>
        <xsl:value-of select="$connected-to/name()"/>
        <xsl:text> </xsl:text>
        <span class="name">
          <xsl:value-of select="$connected-to/@name"/>
        </span>
        <xsl:text> </xsl:text>
        <xsl:value-of select="@port"/>
      </a>
    </li>
  </xsl:template>

  <xsl:template match="p:option" mode="main-html">
    <tr>
      <td>
        <p class="option">
          <span class="name">
            <xsl:value-of select="@name"/>
          </span>
          <xsl:if test="@required = 'true'">
            <span class="flag required" title="Required">
              <xsl:value-of select="'&#x24c7;'"/>
            </span>
          </xsl:if>
          
        </p>
        <xsl:apply-templates select="../p:serialization[@port = current()/@port]" mode="#current"/>
      </td>
      <td>
        <xsl:apply-templates select="p:documentation" mode="#current"/>
      </td>
      <td>
        <p>
          <xsl:if test="@select">
            <span class="default">
              <xsl:value-of select="@select"/>
            </span>
          </xsl:if>
        </p>
      </td>
    </tr>
  </xsl:template>
  
  <xsl:template match="p:documentation" mode="main-html">
    <div class="documentation">
      <xsl:apply-templates mode="#current"/>
    </div>
  </xsl:template>

  <xsl:template name="subpipeline-top">
    <xsl:param name="depth" as="xs:integer" tunnel="yes"/>
    <xsl:param name="subpipeline" as="element(*)+"/>
    <table>
      <colgroup>
        <xsl:for-each select="(2 to $depth)">
          <col/>
        </xsl:for-each>
        <col class="name"/>
        <col class="inputs"/>
        <col class="outputs"/>
        <col class="options"/>
      </colgroup>
      <tr>
        <th colspan="{$depth}">Step</th>
        <th>Inputs</th>
        <th>Outputs</th>
        <th>Options</th>
      </tr>
      <xsl:apply-templates select="$subpipeline" mode="subpipeline"/>
    </table>
  </xsl:template>

  <xsl:template match="*" mode="subpipeline">
    <xsl:param name="depth" as="xs:integer" tunnel="yes"/>
    <tr>
      <xsl:if test="@p:is-step = 'true' and not(p:output)">
        <xsl:attribute name="class" select="'local-end'"/>        
      </xsl:if>
      <td colspan="{$depth}">
        <p class="names">
          <span class="type">
            <xsl:value-of select="name()"/>
          </span>
          <xsl:if test="@name">
            <xsl:text xml:space="preserve"> </xsl:text>
            <span class="name{if (@generated-name = 'true') then ' generated' else ''}" id="step_{@name}">
              <xsl:value-of select="@name"/>
            </span>
          </xsl:if>
        </p>
        <xsl:apply-templates select="p:documentation" mode="#current"/>
      </td>
      <td>
        <xsl:if test="p:input">
          <dl>
            <xsl:apply-templates select="p:input" mode="#current"/>    
          </dl>
        </xsl:if>
      </td>
      <td>        
        <!--<xsl:if test="../@name">
          <xsl:attribute name="id" select="concat('step_', ../@name, '_port_', @port)"/>
        </xsl:if>-->
        <xsl:apply-templates select="p:output" mode="#current"/>
      </td>
      <td>
        <xsl:apply-templates select="p:with-option" mode="#current"/>
      </td>
    </tr>
  </xsl:template>
  
  <xsl:template match="p:variable" mode="subpipeline">
    <xsl:param name="depth" as="xs:integer" tunnel="yes"/>
    <tr>
      <td colspan="{$depth}">
        <p class="names">
          <span class="type">
            <xsl:value-of select="name()"/>
          </span>
          <xsl:text xml:space="preserve"> </xsl:text>
          <span class="name" id="var_{@name}">
            <xsl:value-of select="@name"/>
          </span>
        </p>
        <xsl:apply-templates select="p:documentation" mode="#current"/>
      </td>
      <td>
        <xsl:apply-templates select="p:pipe" mode="#current"/>    
      </td>
      <td>        
      </td>
      <td>
        <xsl:apply-templates select="@select" mode="#current"/>
      </td>
    </tr>
  </xsl:template>
  <xsl:template match="p:documentation" mode="subpipeline" priority="2">
    <xsl:sequence select="node()"/>
  </xsl:template>
  
  <xsl:template match="p:input" mode="subpipeline">
    <dt>
      <xsl:value-of select="@port"/>
    </dt>
    <dd>
      <xsl:apply-templates mode="#current"/>  
    </dd>
  </xsl:template>
  
  <xsl:template match="p:output" mode="subpipeline">
    <p>
      <xsl:if test="../@name">
        <xsl:attribute name="id" select="concat('step_', ../@name, '_port_', @port)"/>
      </xsl:if>
      <xsl:value-of select="@port"/>
    </p>
  </xsl:template>
  
  <xsl:template match="p:inline" mode="subpipeline">
    <pre><code><xsl:sequence select="transpect:code(node(), true())"/></code></pre>
  </xsl:template>

  <xsl:template match="p:viewport-source | p:iteration-source" mode="subpipeline">
    <xsl:attribute name="id" select="concat('step_', ../@name, '_port_current')"/>
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <xsl:template match="p:pipe" mode="subpipeline">
    <p>
      <a href="#{string-join(('step', @step, 'port', @port), '_')}">
        <xsl:value-of select="@port"/>
      </a>
      <xsl:text> on </xsl:text>
      <a href="#{string-join(('step', @step), '_')}">
        <xsl:value-of select="@step"/>
      </a>
    </p>
  </xsl:template>

  <xsl:template match="p:empty" mode="subpipeline">
    <p>
      <xsl:value-of select="name()"/>
    </p>
  </xsl:template>
  
  <xsl:template match="p:input/p:document" mode="subpipeline">
    <p>
      <xsl:value-of select="name()"/>
      <a href="{@href}">
        <xsl:value-of select="@href"/>
      </a>
    </p>
  </xsl:template>

  <xsl:template match="p:with-option" mode="subpipeline">
    <xsl:variable name="declaration" select="key('step-declaration-by-type', ../name())/p:option[@name = current()/@name]" as="element(*)?"/>
    <p>
      <xsl:choose>
        <xsl:when test="exists($declaration)">
          <a href="{transpect:page-name($declaration, ())}">
            <xsl:value-of select="@name"/>
          </a>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="@name"/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:text>&#x2009;=&#x2009;</xsl:text>
      <xsl:value-of select="@select"/>
    </p>
  </xsl:template>
  
  <xsl:template match="p:choose | p:otherwise | p:for-each | p:try | p:catch | p:group | p:viewport" mode="subpipeline-environment">
    <xsl:value-of select="name()"/>
  </xsl:template>

  <xsl:template match="p:when" mode="subpipeline-environment">
    <xsl:value-of select="@test"/>
  </xsl:template>
  

  <xsl:template match="p:choose | p:when | p:otherwise" mode="subpipeline">
    <xsl:param name="depth" as="xs:integer" tunnel="yes"/>
    <xsl:variable name="process-children" as="element(html:tr)*">
      <xsl:apply-templates select="self::p:choose/(p:when | p:otherwise)
                                   | *[@p:is-step = 'true']" mode="#current">
        <xsl:with-param name="depth" select="$depth - 1" tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:variable>
    <tr>
      <xsl:choose>
        <xsl:when test="self::p:choose">
          <xsl:attribute name="class" select="'cases'"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:choose>
            <xsl:when test="position() mod 2 = 0">
              <xsl:attribute name="class" select="'even cond'"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:attribute name="class" select="'odd cond'"/>
            </xsl:otherwise>
          </xsl:choose>          
        </xsl:otherwise>
      </xsl:choose>
      <td rowspan="{count($process-children) + 1}">
        <xsl:variable name="subpipeline-environment" as="xs:string+">
          <xsl:apply-templates select="." mode="subpipeline-environment"/>
        </xsl:variable>
        <p class="rotate" title="{$subpipeline-environment}">
          <xsl:sequence select="$subpipeline-environment"/>
          <xsl:if test="@name">
            <xsl:text xml:space="preserve"> </xsl:text>
            <span class="name{if (@generated-name = 'true') then ' generated' else ''}" id="step_{@name}">
              <xsl:value-of select="@name"/>
            </span>
          </xsl:if>
        </p>
      </td>
      <!-- §§§ -->
      <td colspan="{$depth - 1}">
        <xsl:apply-templates select="p:documentation" mode="#current"/>
      </td>
      <td>
        <!-- render p:xpath-context here? -->
      </td>
      <td> 
        <!-- create some kind of common description for p:output here? -->
      </td>
      <td>
        <!-- no connections? Or mention default readable port here? -->
      </td>
    </tr>
    <xsl:sequence select="$process-children"/>
  </xsl:template>

  <xsl:template match="p:for-each | p:group | p:viewport | p:try | p:catch" mode="subpipeline">
    <xsl:param name="depth" as="xs:integer" tunnel="yes"/>
    <xsl:variable name="process-children" as="element(html:tr)*">
      <xsl:apply-templates select="*[@p:is-step = 'true'] | p:variable " mode="#current">
        <xsl:with-param name="depth" select="$depth - 1" tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:variable>
    <tr class="{replace(local-name(), '-', '')}">
      <td rowspan="{count($process-children) + 1}">
        <xsl:variable name="subpipeline-environment" as="xs:string+">
          <xsl:apply-templates select="." mode="subpipeline-environment"/>
        </xsl:variable>
        <p class="rotate" title="{$subpipeline-environment}">
          <xsl:sequence select="$subpipeline-environment"/>
          <xsl:if test="@name">
            <xsl:text xml:space="preserve"> </xsl:text>
            <span class="name{if (@generated-name = 'true') then ' generated' else ''}" id="step_{@name}">
              <xsl:value-of select="@name"/>
            </span>
          </xsl:if>
        </p>
      </td>
      <!-- §§§ -->
      <td colspan="{$depth - 1}">
        <xsl:apply-templates select="p:documentation" mode="#current"/>
      </td>
      <td>
        <xsl:apply-templates select="p:iteration-source | p:viewport-source" mode="#current"/>
        <xsl:if test="self::p:catch">
          <p>
            <xsl:attribute name="id" select="concat('step_', @name, '_port_error')"/>
            <xsl:text>error</xsl:text>
          </p>
        </xsl:if>
      </td>
      <td> 
        <!-- create some kind of common description for p:output here? -->
      </td>
      <td>
        <!-- no connections? Or mention default readable port here? -->
      </td>
    </tr>
    <xsl:sequence select="$process-children"/>
  </xsl:template>
  
  <xsl:function name="transpect:code" as="text()*">
    <xsl:param name="input" as="node()*"/>
    <xsl:param name="clip-leading-spaces" as="xs:boolean"/>
    <xsl:variable name="prelim" as="text()*">
      <xsl:apply-templates select="$input" mode="verbose"/>
    </xsl:variable>
    <xsl:variable name="prelim-string" as="xs:string" select="string-join($prelim, '')"/>
    <xsl:variable name="lines" as="element(html:line)*">
      <xsl:for-each select="tokenize($prelim-string, '\n')">
        <line>
          <xsl:analyze-string select="." regex="^\s+">
            <xsl:matching-substring>
              <space length="{string-length(.)}">
                <xsl:sequence select="."/>
              </space>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
              <xsl:sequence select="."/>
            </xsl:non-matching-substring>
          </xsl:analyze-string>
        </line>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="min-leading-spaces" as="xs:double">
      <xsl:choose>
        <xsl:when test="not(every $line in $lines[normalize-space()] satisfies ($line/html:space))">
          <xsl:sequence select="0"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="min($lines/html:space/@length)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:apply-templates select="$lines" mode="render-verbose">
      <xsl:with-param name="min" select="xs:integer($min-leading-spaces)" as="xs:integer" tunnel="yes"/>
    </xsl:apply-templates>
  </xsl:function>

  <xsl:template match="html:line" mode="render-verbose" priority="2">
    <xsl:next-match/>
    <xsl:text>&#xa;</xsl:text>
  </xsl:template>
  
  <xsl:template match="html:line[html:space]" mode="render-verbose">
    <xsl:param name="min" as="xs:integer?" tunnel="yes"/>
<!--    <xsl:message select="'length ', html:space/@length, ' min ', $min"></xsl:message>-->
    <xsl:value-of select="substring(html:space, 1, xs:integer(html:space/@length) - $min - 1)"/>
    <xsl:value-of select="text()"/>
  </xsl:template>
  
  <xsl:template match="*" mode="verbose" as="text()+">
    <xsl:text>&lt;</xsl:text>
    <xsl:value-of select="name()"/>
    <xsl:apply-templates select="@*" mode="#current"/>
    <xsl:choose>
      <xsl:when test="node()">
        <xsl:text>&gt;</xsl:text>
        <xsl:apply-templates mode="#current"/>
        <xsl:text>&lt;/</xsl:text>
        <xsl:value-of select="name()"/>
        <xsl:text>&gt;</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>/&gt;</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="@*" mode="verbose" as="text()+">
    <xsl:text> </xsl:text>
    <xsl:value-of select="name()"/>
    <xsl:text>="</xsl:text>
    <!-- &quot; escaping missing -->
    <xsl:value-of select="."/>
    <xsl:text>"</xsl:text>
  </xsl:template>

</xsl:stylesheet>