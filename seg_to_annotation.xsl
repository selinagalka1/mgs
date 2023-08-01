<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
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
    

    <xsl:template match="//t:listPerson">

        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>


        <listAnnotation>
            <xsl:for-each select="t:listRelation/t:relation">
                <annotation motivation="linking">
                    <xsl:attribute name="xml:id">
                        <xsl:value-of select="concat('A', @xml:id)"/>
                    </xsl:attribute>
                    <xsl:attribute name="target">
                        <xsl:value-of select="concat('#', @xml:id)"/>
                    </xsl:attribute>
                    <respStmt>
                        <resp>creator</resp>
                        <persName>Ines Peper</persName>
                    </respStmt>
                    <revisionDesc>
                        <change status="created" when="2023-07-27" who="#inespeper"/>
                    </revisionDesc>
                    <licence target="http://creativecommons.org/licenses/by/3.0/"/>
                    <note type="editiontext">
                        <xsl:call-template name="seg_text">
                            <xsl:with-param name="ID" select="@xml:id"/>
                        </xsl:call-template>
                    </note>
                    <note type="relation">
                        <xsl:call-template name="seg_relation">
                            <xsl:with-param name="ID" select="@xml:id"/>
                        </xsl:call-template>
                    </note>
                    <ptr><xsl:attribute name="target">
                        <xsl:value-of select="concat('#', @xml:id)"/>
                    </xsl:attribute></ptr>
                    <ptr>
                        <xsl:call-template name="seg_ID">
                            <xsl:with-param name="ID" select="@xml:id"/>
                        </xsl:call-template>
                    </ptr>
                </annotation>
            </xsl:for-each>
        </listAnnotation>
    </xsl:template>

    <xsl:template name="seg_text">
        <xsl:param name="ID"/>
        <xsl:for-each select="//t:seg">
            <xsl:if test="contains(@ana, $ID)">
                <xsl:value-of select="."/>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="seg_ID">
        <xsl:param name="ID"/>
        <xsl:for-each select="//t:seg">
            <xsl:if test="contains(@ana, $ID)">
                <xsl:attribute name="target">
                    <xsl:text>#</xsl:text>
                    <xsl:value-of select="@xml:id"/>
                </xsl:attribute>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="seg_relation">
        <xsl:param name="ID"/>
        <xsl:for-each select="//t:relation">
            <xsl:if test="contains(@xml:id, $ID)">

                <xsl:call-template name="persons_relations">
                    <xsl:with-param name="ID_active" select="substring-after(@active, '#')"/>
                    <xsl:with-param name="ID_passive" select="substring-after(@passive, '#')"/>
                    <xsl:with-param name="name" select="@name"/>
                </xsl:call-template>
            </xsl:if>
            <!-- <xsl:if test="contains(@ana, $ID)">
                <xsl:for-each select="t:persName">
                    <xsl:call-template name="persons_relations">
                        <xsl:with-param name="ID" select="substring-after(@ref, '#')"></xsl:with-param>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:if>-->
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="persons_relations">
        <xsl:param name="ID_active"> </xsl:param>
        <xsl:param name="ID_passive"> </xsl:param>
        <xsl:param name="name"> </xsl:param>

        <xsl:for-each select="//t:person">
            <xsl:if test="@xml:id = $ID_active">
                <xsl:value-of select="t:name"/>
            </xsl:if>
        </xsl:for-each>

        <xsl:text> is the </xsl:text>

        <xsl:value-of select="$name"/>

        <xsl:text> of </xsl:text>

        <xsl:for-each select="//t:person">
            <xsl:if test="@xml:id = $ID_passive">
                <xsl:value-of select="t:name"/>
            </xsl:if>
        </xsl:for-each>

        <xsl:text>.</xsl:text>
    </xsl:template>

</xsl:stylesheet>
