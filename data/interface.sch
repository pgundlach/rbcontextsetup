<?xml version="1.0" standalone="yes"?>
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns:rng="http://relaxng.org/ns/structure/1.0">
  <sch:ns xmlns:a="http://relaxng.org/ns/compatibility/annotations/1.0" prefix="c" uri="http://www.pragma-ade.com/commands"/>
  <sch:pattern xmlns:a="http://relaxng.org/ns/compatibility/annotations/1.0" name="Check that any resolve has a cd:define.">
        <sch:rule context="c:resolve">
          <sch:assert test="//c:define[@name=current()/@name]">resolve must be defined</sch:assert>
        </sch:rule>
      </sch:pattern>
  <sch:pattern xmlns:a="http://relaxng.org/ns/compatibility/annotations/1.0" name="check inherit">
        <sch:rule context="c:inherit">
          <sch:assert test="//c:command[@id=current()/@ref]">The referenced commmand does not exist!</sch:assert>
        </sch:rule>
      </sch:pattern>
  <sch:diagnostics/>
</sch:schema>
