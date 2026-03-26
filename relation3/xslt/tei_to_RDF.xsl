<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:schema="https://schema.org/"
    xmlns:ex="http://example.org/vocab#"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:mgs="https://gams.uni-graz.at/o:mgs.ontology#"
    exclude-result-prefixes="tei xs">

    <!-- annotated_text.xml as second input document (one level up from xslt/) -->
    <xsl:variable name="teiText" select="document('../annotated_text.xml')"/>
    
    <!-- Parameters -->
    <!-- Base URI to mint person URIs from TEI xml:id, e.g. https://edition.example.org/register -->
    <xsl:param name="base-uri" as="xs:string" select="'https://gams.uni-graz.at/o:mgs.persons'"/>
    
    <!-- If you use a placeholder like P0 for "unknown", skip it -->
    <xsl:param name="skip-unknown-person" as="xs:boolean" select="false()"/>
    <xsl:param name="unknown-person-id" as="xs:string" select="'P0'"/>
    
    <!-- Optional: emit rdf:Statement nodes to attach evidence/cert/xml:id to assertions -->
    <xsl:param name="emit-reification" as="xs:boolean" select="false()"/>
    
    <xsl:output method="xml" indent="yes"/>
    
    <!-- Helpers -->
    
    <!-- Normalize IDs: accepts "#P154" or "P154" -->
    <xsl:function name="ex:norm-id" as="xs:string">
        <xsl:param name="s" as="xs:string?"/>
        <xsl:sequence select="replace(normalize-space($s), '^#', '')"/>
    </xsl:function>
    
    <xsl:function name="ex:person-uri" as="xs:string">
        <xsl:param name="pid" as="xs:string"/>
        <xsl:sequence select="
            if (starts-with($pid, 'http://') or starts-with($pid, 'https://'))
            then $pid
            else concat($base-uri, '#', $pid)
        "/>
    </xsl:function>
    
    <!-- Extract namespace prefix (agrelon or mgs) from ana="agrelon:hasChild" or "mgs:isSisterInLawOf" -->
    <xsl:function name="ex:ana-prefix" as="xs:string?">
        <xsl:param name="ana" as="xs:string?"/>
        <xsl:variable name="a" select="normalize-space($ana)"/>
        <xsl:sequence select="
            if (matches($a, '(^|\s)(agrelon|mgs):[A-Za-z0-9_]+'))
            then replace($a, '.*(^|\s)(agrelon|mgs):([A-Za-z0-9_]+).*', '$2')
            else ()
        "/>
    </xsl:function>

    <!-- Extract local name from ana="agrelon:hasChild" or "mgs:isSisterInLawOf" -->
    <xsl:function name="ex:ana-local" as="xs:string?">
        <xsl:param name="ana" as="xs:string?"/>
        <xsl:variable name="a" select="normalize-space($ana)"/>
        <xsl:sequence select="
            if (matches($a, '(^|\s)(agrelon|mgs):[A-Za-z0-9_]+'))
            then replace($a, '.*(^|\s)(agrelon|mgs):([A-Za-z0-9_]+).*', '$3')
            else ()
        "/>
    </xsl:function>
    
    <!-- Fallback mapping for listRelation entries without @ana.
         Only triggered if @ana is absent; all current data has @ana so this is a safety net.
         All relation types now map to agrelon: properties (prefix resolved by caller as 'agrelon'). -->
    <xsl:function name="ex:local-from-name" as="xs:string?">
        <xsl:param name="name" as="xs:string?"/>
        <xsl:variable name="n" select="lower-case(normalize-space($name))"/>
        <xsl:sequence select="
            if ($n = 'sisterinlawof' or $n = 'sister-in-law') then 'hasSiblingInlaw'
            else if ($n = 'brotherinlawof' or $n = 'brother-in-law') then 'hasSiblingInlaw'
            else if ($n = 'motherinlawof' or $n = 'mother-in-law') then 'hasChildInlaw'
            else if ($n = 'fatherinlawof' or $n = 'father-in-law') then 'hasChildInlaw'
            else if ($n = 'auntof' or $n = 'aunt') then 'hasNieceNephew'
            else if ($n = 'uncleof' or $n = 'uncle') then 'hasNieceNephew'
            else if ($n = 'cousinof' or $n = 'cousin') then 'hasCousin'
            else if ($n = 'relativeof' or $n = 'relative') then 'hasRelative'
            else if ($n = 'spouseof' or $n = 'spouse') then 'hasSpouse'
            else ()
            "/>
    </xsl:function>
    
    <!-- Build a readable label from persName, with fallback to <name> -->
    <xsl:function name="ex:person-label" as="xs:string">
        <xsl:param name="p" as="element(tei:person)"/>
        
        <xsl:variable name="persName" select="$p/tei:persName"/>
        <xsl:variable name="hasStructured"
            select="exists($persName/tei:forename) or exists($persName/tei:surname) or exists($persName/tei:roleName)"/>
        
        <xsl:variable name="structured" select="
            normalize-space(string-join((
            $persName/tei:forename[1],
            $persName/tei:roleName[1],
            $persName/tei:surname[1]
            ), ' '))
            "/>
        
        <xsl:variable name="fallback" select="normalize-space(string($persName/tei:name[1]))"/>
        
        <xsl:sequence select="if ($hasStructured and $structured != '') then $structured else $fallback"/>
    </xsl:function>
    
    <xsl:function name="ex:date-value" as="xs:string?">
        <xsl:param name="d" as="element()?"/>
        <xsl:sequence select="
            if (not($d)) then ()
            else (
            normalize-space($d/@when),
            normalize-space($d/@notBefore),
            normalize-space($d/@notAfter)
            )[. != ''][1]
            "/>
    </xsl:function>
    
    <!-- Main -->
    <xsl:template match="/">
        
        <rdf:RDF
            xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
            xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
            xmlns:agrelon="https://d-nb.info/standards/elementset/agrelon#"
            xmlns:mgs="https://gams.uni-graz.at/o:mgs.ontology#"
            xmlns:schema="https://schema.org/">
            
            <!-- Persons -->
            <xsl:for-each select="//tei:listPerson/tei:person[@xml:id]">
                <xsl:variable name="pid" select="string(@xml:id)"/>
                <xsl:variable name="puri" select="ex:person-uri($pid)"/>
                <xsl:variable name="label" select="ex:person-label(.)"/>
                
                <rdf:Description rdf:about="{$puri}">
                    <rdf:type rdf:resource="https://schema.org/Person"/>
                    <rdf:type rdf:resource="https://gams.uni-graz.at/o:mgs.ontology#Person"/>
                    <xsl:if test="tei:sex/@value">
                        <schema:gender>
                            <xsl:value-of select="tei:sex/@value"/>
                        </schema:gender>
                    </xsl:if>
                    <!-- Additional rdf:type assertions from TEI (note[@type='personlink']) -->
                    <xsl:for-each select="tei:note[@type='personlink'][normalize-space(.)!='']">
                        <rdf:type rdf:resource="{normalize-space(.)}"/>
                    </xsl:for-each>
                    
                    <!-- Label / name -->
                    <xsl:if test="normalize-space($label) != ''">
                        <rdfs:label><xsl:value-of select="$label"/></rdfs:label>
                        <schema:name><xsl:value-of select="$label"/></schema:name>
                    </xsl:if>
                    
                    <!-- Structured name parts & variants -->
                    <xsl:for-each select="tei:persName/tei:forename[normalize-space(.)!='']">
                        <schema:givenName><xsl:value-of select="normalize-space(.)"/></schema:givenName>
                    </xsl:for-each>
                    
                    <xsl:for-each select="tei:persName/tei:surname[normalize-space(.)!='']">
                        <!-- keep @type for birth/marriage_1/... -->
                        <schema:familyName>
                            <xsl:value-of select="normalize-space(.)"/>
                        </schema:familyName>
                    </xsl:for-each>
                    
                    <xsl:for-each select="tei:persName/tei:roleName[normalize-space(.)!='']">
                        <schema:honorificPrefix>

                            <xsl:value-of select="normalize-space(.)"/>
                        </schema:honorificPrefix>
                    </xsl:for-each>
                    
                    <xsl:for-each select="tei:persName/tei:name[@type='variant'][normalize-space(.)!='']">
                        <schema:alternateName><xsl:value-of select="normalize-space(.)"/></schema:alternateName>
                    </xsl:for-each>
                    
                    <!-- BirthDate (schema.org) -->
                    <xsl:variable name="b" select="tei:birth[1]"/>
                    <xsl:variable name="bVal" select="ex:date-value($b)"/>
                    <xsl:if test="$bVal">
                        <xsl:choose>
                            <xsl:when test="matches($bVal, '^[0-9]{4}$')">
                                <schema:birthDate rdf:datatype="http://www.w3.org/2001/XMLSchema#gYear">
                                    <xsl:value-of select="$bVal"/>
                                </schema:birthDate>
                            </xsl:when>
                            <xsl:otherwise>
                                <schema:birthDate rdf:datatype="http://www.w3.org/2001/XMLSchema#date">
                                    <xsl:value-of select="$bVal"/>
                                </schema:birthDate>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:if>
                    
                    <!-- DeathDate (schema.org) -->
                    <xsl:variable name="d" select="tei:death[1]"/>
                    <xsl:variable name="dVal" select="ex:date-value($d)"/>
                    <xsl:if test="$dVal">
                        <xsl:choose>
                            <xsl:when test="matches($dVal, '^[0-9]{4}$')">
                                <schema:deathDate rdf:datatype="http://www.w3.org/2001/XMLSchema#gYear">
                                    <xsl:value-of select="$dVal"/>
                                </schema:deathDate>
                            </xsl:when>
                            <xsl:otherwise>
                                <schema:deathDate rdf:datatype="http://www.w3.org/2001/XMLSchema#date">
                                    <xsl:value-of select="$dVal"/>
                                </schema:deathDate>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:if>
                    
                    <!-- Faith -->
                    <xsl:if test="normalize-space(tei:faith) != ''">
                        <mgs:faith><xsl:value-of select="normalize-space(tei:faith)"/></mgs:faith>
                    </xsl:if>
                    
                    <!-- Notes (selected) -->
                    <xsl:for-each select="tei:note[@type=('description','confession','conversion','conversion_year','cleric','vienna')][normalize-space(.)!='']">
                        <xsl:element name="mgs:{translate(@type,'-','_')}">
                            <xsl:value-of select="normalize-space(.)"/>
                        </xsl:element>
                    </xsl:for-each>
                    
                    <!-- Identifiers -->
                    <xsl:for-each select="tei:idno[normalize-space(.)!='']">
                        <schema:sameAs rdf:resource="{normalize-space(.)}"/>
                        <xsl:if test="lower-case(normalize-space(@type)) = 'gnd'">
                            <schema:identifier><xsl:value-of select="normalize-space(.)"/></schema:identifier>
                        </xsl:if>
                    </xsl:for-each>
                    
                    <!-- Portrait -->
                    <xsl:for-each select="tei:note[@type='portrait']/tei:graphic[@url]">
                        <schema:image rdf:resource="{normalize-space(@url)}"/>
                    </xsl:for-each>
                    
                    <!-- Occurrences: ptr targets -->
                    <xsl:for-each-group select="tei:linkGrp[@type='occurrences']/tei:ptr[@target]" group-by="normalize-space(@target)">
                        <mgs:occursIn rdf:resource="{concat('https://gams.uni-graz.at', normalize-space(current-grouping-key()))}"/>
                    </xsl:for-each-group>
                    
                </rdf:Description>
            </xsl:for-each>
            
            <!-- Relations -->
            <xsl:for-each select="//tei:listRelation/tei:relation">
                <xsl:variable name="active-id" select="ex:norm-id(string(@active))"/>
                <xsl:variable name="passive-id" select="ex:norm-id(string(@passive))"/>

                <xsl:variable name="anaPrefix" select="
                    if (ex:ana-prefix(string(@ana))) then ex:ana-prefix(string(@ana))
                    else if (ex:local-from-name(string(@name))) then 'agrelon'
                    else ()
                "/>
                <xsl:variable name="anaLocal" select="
                    (ex:ana-local(string(@ana)), ex:local-from-name(string(@name)))[1]
                "/>

                <xsl:variable name="skipPassive"
                    select="$skip-unknown-person and $passive-id = $unknown-person-id"/>

                <xsl:if test="$anaPrefix and $anaLocal and $active-id != '' and $passive-id != '' and not($skipPassive)">
                    <!-- Direct triple: active PREFIX:REL passive -->
                    <rdf:Description rdf:about="{ex:person-uri($active-id)}">
                        <xsl:element name="{$anaPrefix}:{$anaLocal}">
                            <xsl:attribute name="rdf:resource" select="ex:person-uri($passive-id)"/>
                        </xsl:element>
                        <!-- Certainty value from TEI @cert (high / medium / low) -->
                        <xsl:if test="normalize-space(@cert) != ''">
                            <mgs:cert><xsl:value-of select="normalize-space(@cert)"/></mgs:cert>
                        </xsl:if>
                        <!-- Find matching <seg> elements in the secondary TEI text document -->
                        <xsl:variable name="relid" select="string(@xml:id)"/>
                        <xsl:for-each select="$teiText//tei:seg[@xml:id][some $a in tokenize(normalize-space(@ana), '\s+') satisfies ends-with($a, concat('#', $relid))]">
                            <mgs:relationshipMention rdf:resource="https://gams.uni-graz.at/o:mgs.normalizedText#{@xml:id}"/>
                        </xsl:for-each>
                    </rdf:Description>

                    <!-- Optional: attach TEI assertion metadata -->
                    <xsl:if test="$emit-reification">
                        <rdf:Statement rdf:about="{concat($base-uri, '#', ex:norm-id(string(@xml:id)))}">
                            <rdf:subject rdf:resource="{ex:person-uri($active-id)}"/>
                            <rdf:predicate rdf:resource="{
                                if ($anaPrefix = 'agrelon')
                                then concat('https://d-nb.info/standards/elementset/agrelon#', $anaLocal)
                                else concat('https://gams.uni-graz.at/o:mgs.ontology#', $anaLocal)
                            }"/>
                            <rdf:object rdf:resource="{ex:person-uri($passive-id)}"/>

                            <xsl:if test="normalize-space(@evidence) != ''">
                                <mgs:evidence><xsl:value-of select="normalize-space(@evidence)"/></mgs:evidence>
                            </xsl:if>
                            <xsl:if test="normalize-space(@cert) != ''">
                                <mgs:cert><xsl:value-of select="normalize-space(@cert)"/></mgs:cert>
                            </xsl:if>
                            <xsl:if test="normalize-space(@type) != ''">
                                <ex:teiType><xsl:value-of select="normalize-space(@type)"/></ex:teiType>
                            </xsl:if>
                            <xsl:if test="normalize-space(@name) != ''">
                                <ex:teiName><xsl:value-of select="normalize-space(@name)"/></ex:teiName>
                            </xsl:if>
                        </rdf:Statement>
                    </xsl:if>
                </xsl:if>
            </xsl:for-each>
                <!-- Emit each referenced text passage as an rdf:Description of type mgs:RelationshipMention -->
                <xsl:variable name="relids" select="//tei:listRelation/tei:relation/string(@xml:id)"/>
                <xsl:for-each select="$teiText//tei:seg[@xml:id][some $a in tokenize(normalize-space(@ana), '\s+') satisfies (some $r in $relids satisfies ends-with($a, concat('#', $r)))]">
                    <rdf:Description rdf:about="https://gams.uni-graz.at/o:mgs.normalizedText#{@xml:id}">
                        <rdf:type rdf:resource="https://gams.uni-graz.at/o:mgs.ontology#RelationshipMention"/>
                        <rdfs:label><xsl:value-of select="normalize-space(.)"/></rdfs:label>
                    </rdf:Description>
                </xsl:for-each>
            
        </rdf:RDF>
    </xsl:template>
    

</xsl:stylesheet>