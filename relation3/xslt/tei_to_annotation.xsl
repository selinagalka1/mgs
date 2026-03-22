<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:t="http://www.tei-c.org/ns/1.0"
    xmlns="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs t" version="2.0">


    <!-- This stylesheet transforms the Relation³ annotation scheme to tei:annotation.

    Primary input:   annotated_tei.xml  (text with <seg type="relationship_mention"> elements)
    Secondary input: person_index.xml   (loaded via doc(), contains relations and persons)

    For each relation in the exploratory <listRelation subtype="exploratory"> of the person index,
    a <tei:annotation> is created that:
      - points to the relation (URI of the REL element)
      - contains the text of all <seg> elements that reference this relation
      - contains a human-readable description of the relationship ("Person A is the X of Person B.")
      - points to all referencing <seg> elements

    -->

    <xsl:output indent="yes"/>

    <!-- Secondary document: person index containing relations and persons -->
    <xsl:variable name="person_index" select="doc('../person_index.xml')"/>

    <!-- Store reference to primary document for access from secondary document context -->
    <xsl:variable name="tei_doc" select="/"/>

    <!-- Base URI for relations in the person index -->
    <xsl:variable name="persons_base_uri" select="'https://gams.uni-graz.at/o:mgs.persons#'"/>

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
            <!-- Resolved full ontology URI from @ana on <relation>:
                 pl:ChildOf → http://purl.org/vocab/relationship/ChildOf
                 mgs:MotherInLawOf → http://gams.uni-graz.at/o:mgs#MotherInLawOf -->
            <xsl:attribute name="ana">
                <xsl:call-template name="resolve_ana_uri">
                    <xsl:with-param name="ana" select="@ana"/>
                </xsl:call-template>
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

            <!-- Text passages from all segments referencing this relation -->
            <note type="editiontext">
                <xsl:for-each select="$segs">
                    <xsl:if test="position() > 1">; </xsl:if>
                    <xsl:value-of select="normalize-space(.)"/>
                </xsl:for-each>
            </note>

            <!-- Human-readable description of the relationship -->
            <note type="relation">
                <xsl:call-template name="relation_description">
                    <xsl:with-param name="active_uri" select="@active"/>
                    <xsl:with-param name="passive_uri" select="@passive"/>
                    <xsl:with-param name="rel_name" select="@name"/>
                </xsl:call-template>
            </note>

            <!-- Pointer to the relation in the person index -->
            <ptr target="{$rel_uri}"/>

            <!-- Pointers to all referencing text segments -->
            <xsl:for-each select="$segs">
                <ptr target="#{@xml:id}"/>
            </xsl:for-each>
        </annotation>
    </xsl:template>


    <!-- Builds the relation description: "Person A is the relationType of Person B." -->
    <xsl:template name="relation_description">
        <xsl:param name="active_uri"/>
        <xsl:param name="passive_uri"/>
        <xsl:param name="rel_name"/>
        <xsl:call-template name="person_display_name">
            <xsl:with-param name="person_uri" select="$active_uri"/>
        </xsl:call-template>
        <xsl:text> is the </xsl:text>
        <xsl:value-of select="$rel_name"/>
        <xsl:text> of </xsl:text>
        <xsl:call-template name="person_display_name">
            <xsl:with-param name="person_uri" select="$passive_uri"/>
        </xsl:call-template>
        <xsl:text>.</xsl:text>
    </xsl:template>


    <!-- Resolves @ana prefix notation to full URIs.
         pl:ChildOf  → http://purl.org/vocab/relationship/ChildOf
         mgs:AuntOf  → http://gams.uni-graz.at/o:mgs#AuntOf -->
    <xsl:template name="resolve_ana_uri">
        <xsl:param name="ana"/>
        <xsl:choose>
            <xsl:when test="starts-with($ana, 'pl:')">
                <xsl:value-of select="concat('http://cedric.cnam.fr/isid/ontologies/PersonLink.owl#', substring-after($ana, 'pl:'))"/>
            </xsl:when>
            <xsl:when test="starts-with($ana, 'mgs:')">
                <xsl:value-of select="concat('https://gams.uni-graz.at/o:mgs.ontology#', substring-after($ana, 'mgs:'))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$ana"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <!-- Returns a display name for a person from the person index.
         Expects a full URI such as http://gams.uni-graz.at/o:mgs.persons#P154.
         Returns forename + roleName + surname; falls back to the local ID if the person is not found. -->
    <xsl:template name="person_display_name">
        <xsl:param name="person_uri"/>
        <xsl:variable name="person_id" select="substring-after($person_uri, '#')"/>
        <xsl:variable name="person" select="$person_index//t:person[@xml:id = $person_id]"/>
        <xsl:choose>
            <xsl:when test="$person">
                <xsl:value-of select="normalize-space(string-join((
                    $person/t:persName/t:forename,
                    $person/t:persName/t:roleName,
                    $person/t:persName/t:surname
                ), ' '))"/>
            </xsl:when>
            <xsl:otherwise>
                <!-- Person not in the index (e.g. P0 = the narrator) -->
                <xsl:value-of select="$person_id"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
