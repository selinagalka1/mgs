<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:mgs="https://gams-staging.uni-graz.at/context:mgs"
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

    <xsl:template match="@* | node()">
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
                    xmlns:ex="http://example.org/" xmlns:oa="http://www.w3.org/ns/oa#">

                    <xsl:for-each select="//t:relation">
                        <oa:Annotation>
                            <oa:hasTarget>
                                <xsl:attribute name="rdf:resource">
                                    <xsl:call-template name="target">
                                        <xsl:with-param name="ID">
                                            <xsl:value-of select="@xml:id"/>

                                        </xsl:with-param>
                                    </xsl:call-template>
                                </xsl:attribute>
                            </oa:hasTarget>
                            <oa:hasBody>
                                <rdf:Description>
                                    <xsl:attribute name="rdf:about">
                                        <xsl:text>https://gams.uni-graz.at/o:mgs.lesefassung#</xsl:text>
                                        <xsl:value-of select="@xml:id"/>
                                    </xsl:attribute>
                                    <foaf:Person>
                                        <xsl:attribute name="rdf:about">
                                            <xsl:text>https://gams.uni-graz.at/o:mgs.lesefassung</xsl:text>
                                            <xsl:value-of select="@active"/>
                                        </xsl:attribute>
                                        <foaf:name>
                                            <xsl:call-template name="person_name_active">
                                                <xsl:with-param name="ID_active">
                                                  <xsl:value-of
                                                  select="substring-after(@active, '#')"/>
                                                </xsl:with-param>
                                            </xsl:call-template>
                                        </foaf:name>
                                        <xsl:text>&lt;mgs:</xsl:text>

                                        <xsl:value-of select="@name"/>
                                        <xsl:text> rdf:resource="https://gams.uni-graz.at/o:mgs.lesefassung</xsl:text>
                                        <xsl:value-of select="@passive"/>
                                        <xsl:text>"&gt;&lt;mgs:sister-in-law&gt;</xsl:text>
                                    </foaf:Person>
                                    <foaf:Person>
                                        <xsl:attribute name="rdf:about">
                                            <xsl:text>https://gams.uni-graz.at/o:mgs.lesefassung</xsl:text>
                                            <xsl:value-of select="@passive"/>
                                        </xsl:attribute>
                                        <foaf:name>
                                            <xsl:call-template name="person_name_passive">
                                                <xsl:with-param name="ID_passive">
                                                  <xsl:value-of
                                                  select="substring-after(@passive, '#')"/>
                                                </xsl:with-param>
                                            </xsl:call-template>
                                        </foaf:name>
                                    </foaf:Person>


                                </rdf:Description>
                            </oa:hasBody>




                        </oa:Annotation>
                    </xsl:for-each>





                </rdf:RDF>
            </xenoData>
        </teiHeader>

    </xsl:template>

    <xsl:template name="target">
        <xsl:param name="ID"/>
        <xsl:for-each select="//t:seg">
            <xsl:if test="contains(@ana, $ID)">
                <xsl:attribute name="target">
                    <xsl:text>https://gams.uni-graz.at/o:mgs.lesefassung#</xsl:text>
                    <xsl:value-of select="@xml:id"/>
                </xsl:attribute>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="person_name_active">
        <xsl:param name="ID_active"/>

        <xsl:for-each select="//t:person">
            <xsl:if test="@xml:id = $ID_active">
                <xsl:value-of select="t:name"/>
            </xsl:if>
        </xsl:for-each>

    </xsl:template>

    <xsl:template name="person_name_passive">
        <xsl:param name="ID_passive"/>

        <xsl:for-each select="//t:person">
            <xsl:if test="@xml:id = $ID_passive">
                <xsl:value-of select="t:name"/>
            </xsl:if>
        </xsl:for-each>

    </xsl:template>








</xsl:stylesheet>
