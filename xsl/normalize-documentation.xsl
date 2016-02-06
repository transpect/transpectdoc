<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:p="http://www.w3.org/ns/xproc"
  xmlns:tr="http://transpect.io"
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns="http://www.w3.org/1999/xhtml"
  exclude-result-prefixes="c xs tr html"
  version="2.0">
  

  <xsl:template match="* | @*" mode="normalize-documentation">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  
  <xsl:template match="p:documentation/text()[normalize-space()]" mode="normalize-documentation">
    <xsl:variable name="with-br" as="node()+">
      <xsl:analyze-string select="." regex="([.:])[ \t]*[\n\r]+[ \t]*(\p{{Lu}})" flags="s">
        <xsl:matching-substring>
          <xsl:value-of select="regex-group(1)"/>
          <br/>
          <xsl:value-of select="regex-group(2)"/>
        </xsl:matching-substring>
        <xsl:non-matching-substring>
          <xsl:value-of select="."/>
        </xsl:non-matching-substring>
      </xsl:analyze-string>
    </xsl:variable>
    <xsl:for-each-group select="$with-br" group-starting-with="html:br">
      <p>
        <xsl:sequence select="current-group()[not(self::html:br)]"/>
      </p>
    </xsl:for-each-group>
  </xsl:template>

  <xsl:template match="html:*[starts-with(name(), 'html:')]" mode="normalize-documentation">
    <xsl:element name="{local-name(.)}" namespace="http://www.w3.org/1999/xhtml">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:element>
  </xsl:template>

</xsl:stylesheet>