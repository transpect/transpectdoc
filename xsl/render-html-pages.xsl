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
  <xsl:param name="project-name" select="replace($output-base-uri, '^.+/(.+?)/.+?(/|$)', '$1')"/>

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
    <xsl:sequence select="replace(replace($name, '[(\[\])]', ''), '[^-\w._]+', '_', 'i')"/>
  </xsl:function>

  <xsl:function name="transpect:page-name" as="xs:string">
    <xsl:param name="elt" as="element(*)"/>
    <xsl:param name="output-base-uri" as="xs:string?"/>
    <xsl:variable name="fragment" as="xs:string"
      select="if ($elt/name() = ('p:option', 'p:input', 'p:output'))
              then concat('#', local-name($elt), '_', $elt/@name)
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
          <title>
            <xsl:value-of select="string-join((@display-name, 'transpectdoc'), ' – ')"/>
          </title>
        </head>
        <body>
          <div id="nav" class="macroblock">
            <h1>
              <xsl:value-of select="$project-name"/>
            </h1>
            <xsl:call-template name="nav">
              <xsl:with-param name="page-name" tunnel="yes" select="$page-name"/>
            </xsl:call-template>
          </div>
          <div id="main" class="macroblock">
            <xsl:apply-templates select="." mode="main-html"/>  
          </div>
        </body>
      </html>
    </xsl:result-document>
  </xsl:template>

  <xsl:variable name="built-in-prefixes" select="('p', 'pxf', 'pos', 'ml', 'cxu', 'cxo', 'cx', 'cxf', 'c')" as="xs:string+"/>

  <xsl:key name="used-step" use="name()" 
    match="*[not(prefix-from-QName(node-name(.)) = $built-in-prefixes)]"/>
  <xsl:key name="step-declaration-by-type" use="@p:type" match="*[@p:type]"/>
  
  <xsl:template name="nav">
    <xsl:param name="page-name" tunnel="yes" as="xs:string"/>
    <h2>Frontend Pipelines</h2>
    <xsl:apply-templates select="//*[@front-end = 'true']" mode="links">
      <xsl:with-param name="current" select="."/>
      <xsl:with-param name="style" select="'type'"/>
    </xsl:apply-templates>
    <xsl:variable name="typed-steps" select="//*[@p:type]" as="element(*)*"/>
    <xsl:variable name="used-steps" select="$typed-steps[key('used-step', @p:type)]"/>
    <xsl:if test="exists($typed-steps)">
      <h2>Step Declarations</h2>
      <xsl:for-each-group select="$used-steps" group-by="@type-prefix">
        <xsl:sort select="current-grouping-key()"/>
        <h3>
          <xsl:value-of select="concat(current-grouping-key(), ':…')"/>
        </h3>
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
              <h4>
                <xsl:value-of select="current-grouping-key()"/>
              </h4>
              <xsl:apply-templates select="current-group()" mode="links">
                <xsl:with-param name="style" select="'type'"/>
              </xsl:apply-templates>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each-group>
      </xsl:for-each-group>
    </xsl:if>
  </xsl:template>

  <xsl:template match="*[@source-type = ('declare-step', 'pipeline', 'library')]" mode="main-html">
    <h2>
      <xsl:value-of select="replace(@display-name, concat('\s+', @name, '$'), '')"/>
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
      select="p:documentation[not(preceding-sibling::*[transpect:is-step(.)])]"/>
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
          <h3>Subpipeline</h3>
          <xsl:variable name="subpipeline" as="element(*)*" 
            select="*[transpect:is-step(.)] | p:documentation[preceding-sibling::*[transpect:is-step(.)]] "/>
          <xsl:choose>
            <xsl:when test="exists($subpipeline)">
              <xsl:call-template name="subpipeline-top">
                <xsl:with-param name="subpipeline" select="$subpipeline"/>
                <xsl:with-param name="depth" tunnel="yes" as="xs:integer" 
                  select="xs:integer(
                            max(for $s in descendant-or-self::*[transpect:is-step(.)] return count($s/ancestor::*))
                            - count(ancestor::*)
                          )" />
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <p class="none">none</p>
            </xsl:otherwise>
          </xsl:choose>
        </div>    
        <div class="use">
          <h3>Used by</h3>
          <xsl:for-each-group select="//*[@source-type = ('declare-step', 'pipeline')][.//*[name() = current()/@p:type]]"
            group-by="@display-name">
            <xsl:sort select="current-grouping-key()"/>
            <xsl:apply-templates select="." mode="links"/>  
          </xsl:for-each-group>
        </div>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="*" mode="links">
    <xsl:param name="style" as="xs:string?"/>
    <p class="nav">
      <xsl:if test="not($style)">
        <xsl:value-of select="@source-type"/>
        <xsl:text> </xsl:text>        
      </xsl:if>
      <a href="{transpect:page-name(., ())}">
        <xsl:value-of select="(@p:type[$style = 'type'], @display-name)[1]"/>
      </a>
    </p>
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
    <h3>Input Ports</h3>
    <xsl:call-template name="interface-items">
      <xsl:with-param name="items" select="p:input"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="output-declarations">
    <h3>Output Ports</h3>
    <xsl:call-template name="interface-items">
      <xsl:with-param name="items" select="p:output"/>
    </xsl:call-template>
  </xsl:template>
  
  <xsl:template name="option-declarations">
    <h3>Options</h3>
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
            <span class="flag primary">
              <xsl:value-of select="'Ⓟ'"/>
            </span>
          </xsl:if>
          <xsl:if test="@sequence = 'true'">
            <span class="flag sequence">
              <xsl:value-of select="'Ⓢ'"/>
            </span>
          </xsl:if>
        </p>
        <xsl:apply-templates select="../p:serialization[@port = current()/@port]" mode="#current"/>
      </td>
      <td>
        <xsl:apply-templates select="p:documentation" mode="#current"/>
      </td>
      <td><p>connections…</p></td>
    </tr>
  </xsl:template>
  
  <xsl:template match="p:option" mode="main-html">
    <tr>
      <td>
        <p class="option">
          <span class="name">
            <xsl:value-of select="@name"/>
          </span>
          <xsl:if test="@required = 'true'">
            <span class="flag required">
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
  
  <xsl:template match="p:documentation" mode="subpipeline">
    <xsl:apply-templates mode="#current"/>
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
    <dl>
      <dt>inline</dt>
      <dd>
        <pre>
          <xsl:apply-templates mode="verbose"/>
        </pre>
      </dd>
    </dl>
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
  
  <xsl:template match="p:choose | p:otherwise | p:for-each | p:try | p:catch | p:group" mode="subpipeline-environment">
    <xsl:value-of select="name()"/>
  </xsl:template>

  <xsl:template match="p:when" mode="subpipeline-environment">
    <xsl:value-of select="@test"/>
  </xsl:template>
  

  <xsl:template match="p:choose | p:when | p:otherwise" mode="subpipeline">
    <xsl:param name="depth" as="xs:integer" tunnel="yes"/>
    <xsl:variable name="process-children" as="element(html:tr)*">
      <xsl:apply-templates select="self::p:choose/(p:when | p:otherwise)
                                   | *[transpect:is-step(.)]" mode="#current">
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
        <p class="rotate">
          <xsl:apply-templates select="." mode="subpipeline-environment"/>
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
      <xsl:apply-templates select="*[transpect:is-step(.)]" mode="#current">
        <xsl:with-param name="depth" select="$depth - 1" tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:variable>
    <tr class="{replace(local-name(), '-', '')}">
      <td rowspan="{count($process-children) + 1}">
        <p class="rotate">
          <xsl:apply-templates select="." mode="subpipeline-environment"/>
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
  
  <xsl:template match="*" mode="verbose">
    <xsl:text>&lt;</xsl:text>
    <xsl:value-of select="name()"/>
    <xsl:apply-templates select="@*" mode="#current"/>
    <xsl:choose>
      <xsl:when test="node()[normalize-space()]">
        <xsl:text>&gt;</xsl:text>
        <xsl:apply-templates mode="#current"/>
        <xsl:text>&lt;/</xsl:text>
        <xsl:value-of select="name()"/>
        <xsl:apply-templates select="@*" mode="#current"/>
        <xsl:text>&gt;</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>/&gt;</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="@*" mode="verbose">
    <xsl:text> </xsl:text>
    <xsl:value-of select="name()"/>
    <xsl:text>="</xsl:text>
    <!-- &quot; escaping missing -->
    <xsl:value-of select="."/>
    <xsl:text>"</xsl:text>
  </xsl:template>

</xsl:stylesheet>