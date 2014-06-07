<p:library xmlns:p="http://www.w3.org/ns/xproc"
           xmlns:cx="http://xmlcalabash.com/ns/extensions"
           xmlns:cxf="http://xmlcalabash.com/ns/extensions/fileutils"
           xmlns:cxo="http://xmlcalabash.com/ns/extensions/osutils"
           xmlns:cxu="http://xmlcalabash.com/ns/extensions/xmlunit"
           xmlns:ml="http://xmlcalabash.com/ns/extensions/marklogic"
           xmlns:pos="http://exproc.org/proposed/steps/os"
           xmlns:pxf="http://exproc.org/proposed/steps/file"
           xmlns:pxp="http://exproc.org/proposed/steps"
           xmlns:xsd="http://www.w3.org/2001/XMLSchema"
           version="1.0">

<p:documentation xmlns="http://www.w3.org/1999/xhtml">
<div>
<h1>XML Calabash Extension Library</h1>
<h2>Version 1.0</h2>
<p>The steps defined in this library are implemented in
<a href="http://xmlcalabash.com/">XML Calabash</a>.
</p>
</div>
</p:documentation>

<p:declare-step type="cx:collection-manager">
   <p:input port="source" sequence="true"/>
   <p:output port="result" sequence="true" primary="false"/>
   <p:option name="href" required="true" cx:type="xsd:anyURI"/>
</p:declare-step>

<p:declare-step type="cx:css-formatter">
   <p:input port="source" primary="true"/>
   <p:input port="css" sequence="true"/>
   <p:input port="parameters" kind="parameter"/>
   <p:output port="result" primary="false"/>
   <p:option name="href" required="true"/>
   <p:option name="content-type"/>
</p:declare-step>

<p:declare-step type="cx:delta-xml">
   <p:input port="source"/>
   <p:input port="alternate"/>
   <p:input port="dxp"/>
   <p:output port="result"/>
</p:declare-step>

<p:declare-step type="cx:eval">
   <p:input port="pipeline"/>
   <p:input port="source" sequence="true"/>
   <p:input port="options"/>
   <p:output port="result"/>
   <p:option name="step" cx:type="xsd:QName"/>
   <p:option name="detailed" cx:type="xsd:boolean"/>
</p:declare-step>

<p:declare-step type="cx:get-cookies">
   <p:output port="result"/>
   <p:option name="cookies" required="true"/>
</p:declare-step>

<p:declare-step type="cx:java-properties">
   <p:output port="result"/>
   <p:option name="href" cx:type="xsd:anyURI"/>
</p:declare-step>

<p:declare-step type="cx:message">
   <p:input port="source" sequence="true"/>
   <p:output port="result" sequence="true"/>
   <p:option name="message" required="true"/>
</p:declare-step>

<p:declare-step type="cx:metadata-extractor">
   <p:output port="result"/>
   <p:option name="href" cx:type="xsd:anyURI"/>
</p:declare-step>

<p:declare-step type="cx:namespace-delete">
   <p:input port="source"/>
   <p:output port="result"/>
   <p:option name="prefixes"/>
</p:declare-step>

<p:declare-step type="cx:nvdl">
   <p:input port="source" primary="true"/>
   <p:input port="nvdl"/>
   <p:input port="schemas" sequence="true"/>
   <p:output port="result"/>
   <p:option name="assert-valid" select="'true'" cx:type="xsd:boolean"/>
</p:declare-step>

<p:declare-step type="cx:pretty-print">
   <p:input port="source"/>
   <p:output port="result"/>
</p:declare-step>

<p:declare-step type="cx:report-errors">
   <p:input port="source" primary="true"/>
   <p:input port="report" sequence="true"/>
   <p:output port="result" sequence="true"/>
   <p:option name="code" cx:type="xsd:QName"/>
   <p:option name="code-prefix" cx:type="xsd:NCName"/>
   <p:option name="code-namespace" cx:type="xsd:anyURI"/>
</p:declare-step>

<p:declare-step type="cx:send-mail">
   <p:input port="source" sequence="true"/>
   <p:output port="result"/>
</p:declare-step>

<p:declare-step type="cx:set-cookies">
   <p:input port="source"/>
   <p:option name="cookies" required="true"/>
</p:declare-step>

<p:declare-step type="cx:unzip">
   <p:output port="result"/>
   <p:option name="href" required="true" cx:type="xsd:anyURI"/>
   <p:option name="file"/>
   <p:option name="content-type"/>
</p:declare-step>

<p:declare-step type="cx:uri-info">
   <p:output port="result"/>
   <p:option name="href" required="true" cx:type="xsd:anyURI"/>
   <p:option name="username"/>
   <p:option name="password"/>
   <p:option name="auth-method"/>
   <p:option name="send-authorization"/>
</p:declare-step>

<p:declare-step type="cx:zip">
   <p:input port="source" sequence="true" primary="true"/>
   <p:input port="manifest"/>
   <p:output port="result"/>
   <p:option name="href" required="true" cx:type="xsd:anyURI"/>
   <p:option name="compression-method" cx:type="stored|deflated"/>
   <p:option name="compression-level" cx:type="smallest|fastest|default|huffman|none"/>
   <p:option name="command" select="'update'" cx:type="update|freshen|create|delete"/>
</p:declare-step>

<p:declare-step type="cxf:copy">
   <p:output port="result" primary="false"/>
   <p:option name="href" required="true" cx:type="xsd:anyURI"/>
   <p:option name="target" required="true" cx:type="xsd:boolean"/>
   <p:option name="fail-on-error" select="'true'" cx:type="xsd:boolean"/>
</p:declare-step>

<p:declare-step type="cxf:delete">
   <p:output port="result" primary="false"/>
   <p:option name="href" required="true" cx:type="xsd:anyURI"/>
   <p:option name="recursive" select="'false'" cx:type="xsd:boolean"/>
   <p:option name="fail-on-error" select="'true'" cx:type="xsd:boolean"/>
</p:declare-step>

<p:declare-step type="cxf:head">
   <p:output port="result"/>
   <p:option name="href" required="true" cx:type="xsd:anyURI"/>
   <p:option name="count" required="true" cx:type="xsd:int"/>
   <p:option name="fail-on-error" select="'true'" cx:type="xsd:boolean"/>
</p:declare-step>

<p:declare-step type="cxf:info">
   <p:output port="result" sequence="true"/>
   <p:option name="href" required="true" cx:type="xsd:anyURI"/>
   <p:option name="fail-on-error" select="'true'" cx:type="xsd:boolean"/>
</p:declare-step>

<p:declare-step type="cxf:mkdir">
   <p:output port="result" primary="false"/>
   <p:option name="href" required="true" cx:type="xsd:anyURI"/>
   <p:option name="fail-on-error" select="'true'" cx:type="xsd:boolean"/>
</p:declare-step>

<p:declare-step type="cxf:move">
   <p:output port="result" primary="false"/>
   <p:option name="href" required="true" cx:type="xsd:anyURI"/>
   <p:option name="target" required="true" cx:type="xsd:boolean"/>
   <p:option name="fail-on-error" select="'true'" cx:type="xsd:boolean"/>
</p:declare-step>

<p:declare-step type="cxf:tail">
   <p:output port="result"/>
   <p:option name="href" required="true" cx:type="xsd:anyURI"/>
   <p:option name="count" required="true" cx:type="xsd:int"/>
   <p:option name="fail-on-error" select="'true'" cx:type="xsd:boolean"/>
</p:declare-step>

<p:declare-step type="cxf:tempfile">
   <p:output port="result" primary="false"/>
   <p:option name="href" required="true" cx:type="xsd:anyURI"/>
   <p:option name="prefix" cx:type="xsd:string"/>
   <p:option name="suffix" cx:type="xsd:string"/>
   <p:option name="delete-on-exit" cx:type="xsd:boolean"/>
   <p:option name="fail-on-error" select="'true'" cx:type="xsd:boolean"/>
</p:declare-step>

<p:declare-step type="cxf:touch">
   <p:output port="result" primary="false"/>
   <p:option name="href" required="true" cx:type="xsd:anyURI"/>
   <p:option name="timestamp" cx:type="xs:dateTime"/>
   <p:option name="fail-on-error" select="'true'" cx:type="xsd:boolean"/>
</p:declare-step>

<p:declare-step type="cxo:cwd">
   <p:output port="result" sequence="true"/>
</p:declare-step>

<p:declare-step type="cxo:env">
   <p:output port="result"/>
</p:declare-step>

<p:declare-step type="cxo:info">
   <p:output port="result"/>
</p:declare-step>

<p:declare-step type="cxu:compare">
   <p:input port="source" primary="true"/>
   <p:input port="alternate"/>
   <p:output port="result" primary="false"/>
   <p:option name="compare-unmatched" select="'false'"/>
   <p:option name="ignore-comments" select="'false'"/>
   <p:option name="ignore-diff-between-text-and-cdata" select="'false'"/>
   <p:option name="ignore-whitespace" select="'false'"/>
   <p:option name="normalize" select="'false'"/>
   <p:option name="normalize-whitespace" select="'false'"/>
   <p:option name="fail-if-not-equal" select="'false'"/>
</p:declare-step>

<p:declare-step type="ml:adhoc-query">
   <p:input port="source"/>
   <p:input port="parameters" kind="parameter"/>
   <p:output port="result" sequence="true"/>
   <p:option name="host"/>
   <p:option name="port" cx:type="xsd:integer"/>
   <p:option name="user"/>
   <p:option name="password"/>
   <p:option name="content-base"/>
   <p:option name="wrapper" cx:type="xsd:QName"/>
</p:declare-step>

<p:declare-step type="ml:insert-document">
   <p:input port="source"/>
   <p:output port="result" primary="false"/>
   <p:option name="host"/>
   <p:option name="port" cx:type="xsd:integer"/>
   <p:option name="user"/>
   <p:option name="password"/>
   <p:option name="content-base"/>
   <p:option name="uri" required="true"/>
   <p:option name="buffer-size" cx:type="xsd:integer"/>
   <p:option name="collections"/>
   <p:option name="format" cx:type="xml|text|binary"/>
   <p:option name="language"/>
   <p:option name="locale"/>
</p:declare-step>

<p:declare-step type="ml:invoke-module">
   <p:input port="parameters" kind="parameter"/>
   <p:output port="result" sequence="true"/>
   <p:option name="module" required="true"/>
   <p:option name="host"/>
   <p:option name="port" cx:type="xsd:integer"/>
   <p:option name="user"/>
   <p:option name="password"/>
   <p:option name="content-base"/>
   <p:option name="wrapper" cx:type="xsd:QName"/>
</p:declare-step>

<p:declare-step type="pos:cwd">
   <p:output port="result" sequence="true"/>
</p:declare-step>

<p:declare-step type="pos:env">
   <p:output port="result"/>
</p:declare-step>

<p:declare-step type="pos:info">
   <p:output port="result"/>
</p:declare-step>

<p:declare-step type="pxf:copy">
   <p:output port="result" primary="false"/>
   <p:option name="href" required="true" cx:type="xsd:anyURI"/>
   <p:option name="target" required="true" cx:type="xsd:boolean"/>
   <p:option name="fail-on-error" select="'true'" cx:type="xsd:boolean"/>
</p:declare-step>

<p:declare-step type="pxf:delete">
   <p:output port="result" primary="false"/>
   <p:option name="href" required="true" cx:type="xsd:anyURI"/>
   <p:option name="recursive" select="'false'" cx:type="xsd:boolean"/>
   <p:option name="fail-on-error" select="'true'" cx:type="xsd:boolean"/>
</p:declare-step>

<p:declare-step type="pxf:head">
   <p:output port="result"/>
   <p:option name="href" required="true" cx:type="xsd:anyURI"/>
   <p:option name="count" required="true" cx:type="xsd:int"/>
   <p:option name="fail-on-error" select="'true'" cx:type="xsd:boolean"/>
</p:declare-step>

<p:declare-step type="pxf:info">
   <p:output port="result" sequence="true"/>
   <p:option name="href" required="true" cx:type="xsd:anyURI"/>
   <p:option name="fail-on-error" select="'true'" cx:type="xsd:boolean"/>
</p:declare-step>

<p:declare-step type="pxf:mkdir">
   <p:output port="result" primary="false"/>
   <p:option name="href" required="true" cx:type="xsd:anyURI"/>
   <p:option name="fail-on-error" select="'true'" cx:type="xsd:boolean"/>
</p:declare-step>

<p:declare-step type="pxf:move">
   <p:output port="result" primary="false"/>
   <p:option name="href" required="true" cx:type="xsd:anyURI"/>
   <p:option name="target" required="true" cx:type="xsd:boolean"/>
   <p:option name="fail-on-error" select="'true'" cx:type="xsd:boolean"/>
</p:declare-step>

<p:declare-step type="pxf:tail">
   <p:output port="result"/>
   <p:option name="href" required="true" cx:type="xsd:anyURI"/>
   <p:option name="count" required="true" cx:type="xsd:int"/>
   <p:option name="fail-on-error" select="'true'" cx:type="xsd:boolean"/>
</p:declare-step>

<p:declare-step type="pxf:tempfile">
   <p:output port="result" primary="false"/>
   <p:option name="href" required="true" cx:type="xsd:anyURI"/>
   <p:option name="prefix" cx:type="xsd:string"/>
   <p:option name="suffix" cx:type="xsd:string"/>
   <p:option name="delete-on-exit" cx:type="xsd:boolean"/>
   <p:option name="fail-on-error" select="'true'" cx:type="xsd:boolean"/>
</p:declare-step>

<p:declare-step type="pxf:touch">
   <p:output port="result" primary="false"/>
   <p:option name="href" required="true" cx:type="xsd:anyURI"/>
   <p:option name="timestamp" cx:type="xs:dateTime"/>
   <p:option name="fail-on-error" select="'true'" cx:type="xsd:boolean"/>
</p:declare-step>

<p:declare-step type="pxp:nvdl">
   <p:input port="source" primary="true"/>
   <p:input port="nvdl"/>
   <p:input port="schemas" sequence="true"/>
   <p:output port="result"/>
   <p:option name="assert-valid" select="'true'" cx:type="xsd:boolean"/>
</p:declare-step>

<p:declare-step type="pxp:unzip">
   <p:output port="result"/>
   <p:option name="href" required="true" cx:type="xsd:anyURI"/>
   <p:option name="file"/>
   <p:option name="content-type"/>
</p:declare-step>

<p:declare-step type="pxp:zip">
   <p:input port="source" sequence="true" primary="true"/>
   <p:input port="manifest"/>
   <p:output port="result"/>
   <p:option name="href" required="true" cx:type="xsd:anyURI"/>
   <p:option name="compression-method" cx:type="stored|deflated"/>
   <p:option name="compression-level" cx:type="smallest|fastest|default|huffman|none"/>
   <p:option name="command" select="'update'" cx:type="update|freshen|create|delete"/>
</p:declare-step>

</p:library>
