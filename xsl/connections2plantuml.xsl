<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:p="http://www.w3.org/ns/xproc"
  xmlns:tr="http://transpect.io"
  exclude-result-prefixes="xs tr p c"
  version="2.0">

  <xsl:template match="c:files" mode="plantuml">
    <plantuml-wrapper>
      <xsl:apply-templates select="c:file" mode="#current"/>
    </plantuml-wrapper>
  </xsl:template>

  <xsl:template match="c:file[@source-type = library]" mode="plantuml">
    <xsl:apply-templates select="c:step-declarations" mode="#current"/>
  </xsl:template>

  <xsl:template match="c:step-declarations" mode="plantuml">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <xsl:template match="c:file | c:step-declaration" mode="plantuml">
    <xsl:call-template name="page"/>
    <xsl:apply-templates select="c:step-declarations" mode="#current"/>
  </xsl:template>

  <!-- Important notice:
       If the Graphviz software ist not installed, only sequence 
       and the new activity plantuml constructs are applicable.
  -->

  <xsl:template name="page">
    <plantuml xml:id="svg_{ancestor-or-self::*[@tr:filename][1]/@tr:filename}">
    <xsl:variable name="component" as="xs:string"
      select="concat('[&lt;b>', (@p:type, @tr:filename)[1], '&lt;/b>\n(', count(p:option), ' options)]')"/>
@startuml
<xsl:for-each select="p:input">
  <xsl:value-of select="concat(
                          $component, ' &lt;-up- ', 
                          replace(@port, '-', '_'),
                          '&#xa;'
                        )"/>
</xsl:for-each>
<xsl:for-each select="p:output">
  <xsl:value-of select="concat(
                          $component, ' -down-> ', 
                          replace(@port, '-', '_'),
                          '&#xa;'
                        )"/>
</xsl:for-each><!--
<xsl:text>note right of </xsl:text>
<xsl:value-of select="$component, '&#xa;'"/>
<xsl:text>Options: </xsl:text><xsl:value-of select="count(p:option)"/>
<xsl:text>&#xa;end note</xsl:text>-->
@enduml
    </plantuml>
  </xsl:template>

</xsl:stylesheet>