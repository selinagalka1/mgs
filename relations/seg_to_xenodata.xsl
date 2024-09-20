<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:mgs="https://gams.uni-graz.at/ontology:mgs#"
    xmlns:foaf="http://xmlns.com/foaf/0.1/"
    xmlns:rel="http://purl.org/vocab/relationship/"
    xmlns:bio="http://purl.org/vocab/bio/0.1/"
    xmlns:ex="http://example.org/"
    xmlns:oa="http://www.w3.org/ns/oa#"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:t="http://www.tei-c.org/ns/1.0"
    xmlns="http://www.tei-c.org/ns/1.0" exclude-result-prefixes="xs t" version="2.0">


    <!-- Das Stylesheet transformiert die Annotation mit <seg> innerhalb des Annotationstextes und <relation> 
    nach tei:annotation. Das <seg> im Editionstext wird eliminiert. Stattdessen wird im teiHeader innerhalb von tei:standoff
    eine tei:listAnnotation einfügt, die für jedes <seg> im Editionstext ein tei:annotation auflistet.
    tei:annotation enthält Metadaten, den Text der Stelle, welche die Beziehung abbildet, und die Beschreibung der Beziehung, basierend
    auf den Attributen der tei:relation (momentan wird nur @active und @passive angenommen). Die Beschreibung der Beziehung innerhalb von
    <note> ist auf Englisch, da wir hier kein Problem der Anpassung des Artikels an das Substantiv haben ("the sister in law" vs. "die Schwägerin"). 
    -->

    <xsl:output indent="yes"/>

    <xsl:template match="@* | node()" priority="-2">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="t:teiHeader">
        <teiHeader>
            <xsl:apply-templates/>
            <xenoData>
                <rdf:RDF xmlns:foaf="http://xmlns.com/foaf/0.1/"
                    xmlns:rel="http://purl.org/vocab/relationship/"
                    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
					xmlns:bio="http://purl.org/vocab/bio/0.1/"
                    xmlns:ex="http://example.org/" xmlns:oa="http://www.w3.org/ns/oa#">
                    <xsl:apply-templates select="//t:seg[@ana]" mode="xenoData"/>
                </rdf:RDF>
            </xenoData>
        </teiHeader>
    </xsl:template>
	<!-- Convert annotations to RDF: relations
	FixMe: this is the prototype, proposal for a generic solution below -->
	<xsl:template match="//*[@ana]" mode="xenoData">
		<xsl:variable name="annotation" select="//t:relation[@xml:id=substring-after(current()/@ana,'#')]"/>
		<oa:Annotation>
			<oa:hasTarget>
				<xsl:attribute name="rdf:resource">
					<xsl:text>https://gams.uni-graz.at/o:mgs.lesefassung#</xsl:text>
					<xsl:value-of select="@xml:id"/>
				</xsl:attribute>
			</oa:hasTarget>
			<oa:hasBody>
				<bio:Relationship rdf:about="https://gams.uni-graz.at/o:mgs.lesefassung#{$annotation/@xml:id}">
					<rdf:type rdf:resource="https://gams.uni-graz.at/o:mgs.ontology#{$annotation/@type}"/>
					<bio:hasParticipant>
						<foaf:Person rdf:about="https://gams.uni-graz.at/o:mgs.lesefassung{$annotation/@active}">
							<xsl:element name="mgs:{$annotation/@name}">
							<xsl:attribute name="rdf:resource"><xsl:text>https://gams.uni-graz.at/o:mgs.lesefassung</xsl:text>
							<xsl:value-of select="$annotation/@passive"/></xsl:attribute>
							</xsl:element>
						</foaf:Person>
						<foaf:Person rdf:about="https://gams.uni-graz.at/o:mgs.lesefassung{$annotation/@passive}"/>							
					</bio:hasParticipant>
				</bio:Relationship>
			</oa:hasBody>
			<oa:bodyValue><xsl:call-template name="person_name">
					<xsl:with-param name="ID" select="$annotation/substring-after(@active,'#')"></xsl:with-param>
				</xsl:call-template>
				<xsl:text> </xsl:text><xsl:value-of select="$annotation/@name"/><xsl:text> </xsl:text>
				<xsl:call-template name="person_name">
					<xsl:with-param name="ID" select="$annotation/substring-after(@passive,'#')"></xsl:with-param>
				</xsl:call-template></oa:bodyValue>
		</oa:Annotation>
	</xsl:template>
	
	<!-- Generic handling of references to annotations in t:standOff -->
	<xsl:template match="//*[@ana]" mode="xenoData" priority="-1">
		<oa:Annotation>
			<oa:hasTarget>
				<xsl:attribute name="rdf:resource">
					<xsl:text>https://gams.uni-graz.at/o:mgs.lesefassung#</xsl:text>
					<xsl:value-of select="@xml:id"/>
				</xsl:attribute>
			</oa:hasTarget>
			<oa:hasBody>
				<xsl:apply-templates select="//t:standOff//t:*[@xml:id=substring-after(current()/@ana,'#')]" mode="#current"/>
			</oa:hasBody>
		</oa:Annotation>
	</xsl:template>
	<!-- Converting generic standOff annotations to RDF -->
	<xsl:template match="//t:standOff//t:*" mode="xenoData">
		<rdf:Description rdf:about="https://gams.uni-graz.at/o:mgs.lesefassung#{$annotation/@xml:id}">
			<rdf:type rdf:resource="https://tei-c.org/ns/1.0/{$annotation/name()}"/>
			<rdf:type rdf:resource="https://gams.uni-graz.at/o:mgs.ontology#{$annotation/@type}"/>
			<xsl:apply-templates select="*" mode="#current"/><!-- ToDo: define further RDF mappings -->
		</rdf:Description>
	</xsl:template>
	
	<xsl:template name="person_name">
        <xsl:param name="ID"/>
		<xsl:value-of select="//t:person[@xml:id = $ID]/t:name"/>
    </xsl:template>

</xsl:stylesheet>