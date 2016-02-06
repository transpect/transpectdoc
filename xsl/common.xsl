<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:p="http://www.w3.org/ns/xproc"
  xmlns:tr="http://transpect.io"
  exclude-result-prefixes="c xs tr"
  version="2.0">
  
  <xsl:function name="tr:is-step" as="xs:boolean">
    <!-- this function returns true if the element may carry a name attribute -->
    <xsl:param name="elt" as="element()"/>
    <xsl:choose>
      <xsl:when test="tr:name($elt) = (
                                              'p:option',
                                              'p:import',
                                              'p:pipeinfo',
                                              'p:serialization',
                                              'p:input', 
                                              'p:output',
                                              'p:variable',
                                              'p:documentation',
                                              'p:xpath-context',
                                              'p:iteration-source', 
                                              'p:empty'
                                             )">
        <xsl:sequence select="false()"/>
      </xsl:when>
      <xsl:when test="tr:name($elt) = ('p:choose', 'p:for-each', 'p:group', 'p:try', 'p:catch')">
        <xsl:sequence select="true()"/>
      </xsl:when>
      <!-- pipeline declarations itself and their children (except for the list above)
        qualify as 'steps' for the purpose of this function -->
      <xsl:when test="$elt/../@source-type = ('pipeline', 'declare-step', 'step-declaration')">
        <xsl:sequence select="true()"/>
      </xsl:when>
      <xsl:when test="tr:name($elt/../self::*) = ('p:for-each', 'p:group', 'p:catch', 'p:when', 'p:otherwise', 'p:pipeline', 'p:declare-step')">
        <xsl:sequence select="true()"/>
      </xsl:when>
      <!-- correction: pipeline declarations need only have names if they actually contain a subpipeline --> 
      <xsl:when test="$elt/@source-type = ('pipeline', 'declare-step', 'step-declaration')">
        <xsl:sequence select="some $child in $elt/* satisfies (tr:is-step($child))"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="false()"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- In interactive mode, the pipeline collection representation is stored in the DOM and read from
    there for rendering. The namespace prefixes of stored elements might get altered. Therefore we store
    an attribute tr:name on these elements that gives the correct prefixed name (e.g., p:store). -->
  <xsl:function name="tr:name" as="xs:string?">
    <xsl:param name="elt" as="element(*)?"/>
    <xsl:sequence select="($elt/@tr:name, name($elt))[1]"/>
  </xsl:function>

  <xsl:function name="tr:jsonify" as="xs:string?">
    <xsl:param name="str" as="xs:string*"/>
    <xsl:sequence select="replace(string-join($str, ''), '&quot;', '\\&quot;')"/>
  </xsl:function>
</xsl:stylesheet>