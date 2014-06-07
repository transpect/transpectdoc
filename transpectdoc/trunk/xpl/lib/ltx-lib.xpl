<p:library xmlns:p="http://www.w3.org/ns/xproc"
           xmlns:c="http://www.w3.org/ns/xproc-step"  
           xmlns:letex="http://www.le-tex.de/namespace"
           xmlns:pkg="http://expath.org/ns/pkg"
           pkg:import-uri="http://le-tex.de/tools/unzip.xpl"
           version="1.0">

   <p:declare-step type="letex:unzip">
      <p:option name="zip" required="true"/>
      <p:option name="dest-dir" required="true"/>
      <p:option name="overwrite" required="false" select="'no'"/>
      <p:option name="file" required="false"/>
      <p:output port="result" primary="true"/>
   </p:declare-step>

   <p:declare-step type="letex:validate-with-rng">
      <p:input  port="source" primary="true"/>	
      <p:input  port="schema"/>	
      <p:output port="result" primary="true"/>
      <p:output port="report"/>
   </p:declare-step>
   
   <p:declare-step type="letex:image-identify">
      <p:input  port="source" primary="true" sequence="true"/>
      <p:output port="result" primary="true" sequence="true"/>
      <p:output port="report" sequence="true"/>
      <p:option name="href"/>
   </p:declare-step>

</p:library>
