<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:p="http://www.w3.org/ns/xproc"
  xmlns:transpect="http://www.le-tex.de/namespace/transpect"
  exclude-result-prefixes="c xs transpect"
  version="2.0">
  
  <xsl:function name="transpect:is-step" as="xs:boolean">
    <!-- this function returns true if the element may carry a name attribute -->
    <xsl:param name="elt" as="element()"/>
    <xsl:choose>
      <xsl:when test="$elt/name() = ('p:option',
                                     'p:import',
                                     'p:serialization',
                                     'p:input', 
                                     'p:output',
                                     'p:documentation')
                      ">
        <xsl:sequence select="false()"/>
      </xsl:when>
      <!-- pipeline declarations itself and their children (except for the list above)
        qualify as 'steps' for the purpose of this function -->
      <xsl:when test="($elt/../local-name(), $elt/../@source-type) = ('pipeline', 'declare-step', 'step-declaration')">
        <xsl:sequence select="true()"/>
      </xsl:when>
      <!-- correction: pipeline declarations need only have names if they actually contain a subpipeline --> 
      <xsl:when test="($elt/local-name(), $elt/@source-type) = ('pipeline', 'declare-step', 'step-declaration')">
        <xsl:sequence select="some $child in $elt/* satisfies (transpect:is-step($child))"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="false()"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

</xsl:stylesheet>