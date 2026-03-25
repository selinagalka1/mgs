<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:t="http://www.tei-c.org/ns/1.0"
    xmlns="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs t" version="2.0">


    <!-- This stylesheet transforms the Relation³ annotation scheme to tei:annotation.

    Primary input:   annotated_text.xml  (text with <seg type="relationship_mention"> elements)
    Secondary input: person_index.xml   (loaded via doc(), contains relations and persons)

    For each relation in the exploratory <listRelation subtype="exploratory"> of the person index,
    a <tei:annotation> is created that:
      - points to the relation via @target and a <ptr>
      - points to all referencing <seg> elements via <ptr>

    -->

    <xsl:output indent="yes"/>

    <!-- Secondary document: person index containing relations and persons -->
    <xsl:variable name="person_index" select="doc('../person_index.xml')"/>

    <!-- Store reference to primary document for access from secondary document context -->
    <xsl:variable name="tei_doc" select="/"/>

    <!-- Base URI for relations in the person index -->
    <xsl:variable name="persons_base_uri" select="'http://gams.uni-graz.at/o:mgs.persons#'"/>

    <!-- Base URI for text segments in the edition text -->
    <xsl:variable name="text_base_uri" select="'https://gams.uni-graz.at/o:mgs.normalizedText#'"/>


    <!-- Identity transform: copy all nodes unchanged -->
    <xsl:template match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>


    <!-- TEI root element: append a <standOff> containing <listAnnotation> -->
    <xsl:template match="t:TEI">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
            <standOff>
                <listAnnotation>
                    <xsl:apply-templates
                        select="$person_index//t:listRelation[@subtype='exploratory']/t:relation"
                        mode="make-annotation"/>
                </listAnnotation>
            </standOff>
        </xsl:copy>
    </xsl:template>


    <!-- Creates one <annotation> for each relation in the exploratory listRelation -->
    <xsl:template match="t:relation" mode="make-annotation">
        <xsl:variable name="rel_id" select="@xml:id"/>
        <xsl:variable name="rel_uri" select="concat($persons_base_uri, $rel_id)"/>

        <!-- All <seg type="relationship_mention"> elements in the edition text that reference this relation -->
        <xsl:variable name="segs"
            select="$tei_doc//t:seg[@type='relationship_mention'][
                some $uri in tokenize(@ana, '\s+') satisfies $uri = $rel_uri
            ]"/>

        <annotation motivation="linking">
            <xsl:attribute name="xml:id">
                <xsl:value-of select="concat('A', $rel_id)"/>
            </xsl:attribute>
            <xsl:attribute name="target">
                <xsl:value-of select="$rel_uri"/>
            </xsl:attribute>
            <!-- Certainty of the relation, if present (@cert is a global TEI attribute) -->
            <xsl:if test="@cert">
                <xsl:attribute name="cert">
                    <xsl:value-of select="@cert"/>
                </xsl:attribute>
            </xsl:if>
            <respStmt>
                <resp>creator</resp>
                <persName>Selina Galka</persName>
            </respStmt>
            <revisionDesc>
                <change status="created" when="2026" who="#selinagalka"/>
            </revisionDesc>
            <licence target="http://creativecommons.org/licenses/by/4.0/"/>

            <!-- Pointers to all referencing text segments -->
            <xsl:for-each select="$segs">
                <ptr target="{concat($text_base_uri, @xml:id)}"/>
            </xsl:for-each>
        </annotation>
    </xsl:template>

</xsl:stylesheet>
