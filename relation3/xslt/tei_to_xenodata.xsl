<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:agrelon="https://d-nb.info/standards/elementset/agrelon#"
    xmlns:mgs="https://gams.uni-graz.at/o:mgs.ontology#"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:t="http://www.tei-c.org/ns/1.0"
    xmlns="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs t" version="2.0">


    <!-- This stylesheet transforms the Relation³ annotation scheme to RDF/tei:xenoData.

    Primary input:   annotated_tei.xml  (text with <seg type="relationship_mention"> elements)
    Secondary input: person_index.xml   (loaded via doc(), contains relations and persons)

    For each relation in the exploratory <listRelation subtype="exploratory">, one direct RDF
    triple is generated linking the active person to the passive person. The RDF predicate is
    derived from the @ana attribute of <relation> using AgRelOn (agrelon:) properties where
    available, and project-specific (mgs:) properties for relation types not covered by AgRelOn.

    Each relationship assertion is additionally linked to all text segments mentioning it via
    the project-specific property mgs:relationshipMention, ensuring traceability between the
    interpretative assertion and its textual evidence.

    RDF structure per relation (e.g. REL6: P82 motherInLawOf P0, mentioned in RM_R11_1 etc.):
      <P82> mgs:isMotherInLawOf <P0>
      <P82> mgs:relationshipMention <RM_R11_1>
      <P82> mgs:relationshipMention <RM_R18_1>
      ...

    Differences from the old scheme:
      - Direct RDF triple per relation instead of oa:Annotation / bio:Relationship wrappers
      - RDF predicate comes from @ana on <relation> (agrelon: or mgs: prefix, resolved to full URI)
      - mgs:relationshipMention links each assertion to its textual evidence
      - Two-document input (annotated_tei.xml + person_index.xml)
      - @active/@passive in <relation> are full URIs (used directly as rdf:about / rdf:resource)
    -->

    <xsl:output indent="yes"/>

    <!-- Secondary document: person index containing relations and persons -->
    <xsl:variable name="person_index" select="doc('../person_index.xml')"/>

    <!-- Store reference to primary document for access from secondary document context -->
    <xsl:variable name="tei_doc" select="/"/>

    <!-- Base URI for text segments in the edition text -->
    <xsl:variable name="text_base_uri" select="'https://gams.uni-graz.at/o:mgs.normalizedText#'"/>

    <!-- Base URI for relations in the person index -->
    <xsl:variable name="persons_base_uri" select="'https://gams.uni-graz.at/o:mgs.persons#'"/>


    <!-- Identity transform: copy all nodes unchanged -->
    <xsl:template match="@* | node()" priority="-2">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>


    <!-- teiHeader: append xenoData with RDF block at the end -->
    <xsl:template match="t:teiHeader">
        <teiHeader>
            <xsl:apply-templates/>
            <xenoData>
                <rdf:RDF
                    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                    xmlns:agrelon="https://d-nb.info/standards/elementset/agrelon#"
                    xmlns:mgs="https://gams.uni-graz.at/o:mgs.ontology#">
                    <!-- One rdf:Description per relation in the exploratory listRelation -->
                    <xsl:apply-templates
                        select="$person_index//t:listRelation[@subtype='exploratory']/t:relation"
                        mode="xenoData"/>
                </rdf:RDF>
            </xenoData>
        </teiHeader>
    </xsl:template>


    <!-- Each relation: direct triple (active → passive) + mgs:relationshipMention for all text mentions -->
    <xsl:template match="t:relation" mode="xenoData">
        <xsl:variable name="rel_id" select="@xml:id"/>
        <xsl:variable name="rel_uri" select="concat($persons_base_uri, $rel_id)"/>

        <!-- All <seg type="relationship_mention"> elements in the edition text that reference this relation -->
        <xsl:variable name="segs"
            select="$tei_doc//t:seg[@type='relationship_mention'][
                some $uri in tokenize(@ana, '\s+') satisfies $uri = $rel_uri
            ]"/>

        <rdf:Description rdf:about="{@active}">

            <!-- Direct relationship triple: active [agrelon:hasChild | mgs:isMotherInLawOf | ...] passive
                 Predicate is resolved from @ana (agrelon: → AgRelOn ontology, mgs: → project ontology) -->
            <xsl:call-template name="relationship_predicate">
                <xsl:with-param name="ana" select="@ana"/>
                <xsl:with-param name="passive" select="@passive"/>
            </xsl:call-template>

            <!-- Certainty of the relation, if present -->
            <xsl:if test="@cert">
                <mgs:cert><xsl:value-of select="@cert"/></mgs:cert>
            </xsl:if>

            <!-- Link to all text segments mentioning this relation -->
            <xsl:for-each select="$segs">
                <mgs:relationshipMention rdf:resource="{$text_base_uri}{@xml:id}"/>
            </xsl:for-each>

        </rdf:Description>
    </xsl:template>


    <!-- Creates the relationship predicate element from @ana.
         agrelon:hasChild   → <agrelon:hasChild> in https://d-nb.info/standards/elementset/agrelon#
         mgs:isMotherInLawOf → <mgs:isMotherInLawOf> in https://gams.uni-graz.at/o:mgs.ontology# -->
    <xsl:template name="relationship_predicate">
        <xsl:param name="ana"/>
        <xsl:param name="passive"/>
        <xsl:choose>
            <xsl:when test="starts-with($ana, 'agrelon:')">
                <xsl:element name="agrelon:{substring-after($ana, 'agrelon:')}"
                    namespace="https://d-nb.info/standards/elementset/agrelon#">
                    <xsl:attribute name="rdf:resource">
                        <xsl:value-of select="$passive"/>
                    </xsl:attribute>
                </xsl:element>
            </xsl:when>
            <xsl:when test="starts-with($ana, 'mgs:')">
                <xsl:element name="mgs:{substring-after($ana, 'mgs:')}"
                    namespace="https://gams.uni-graz.at/o:mgs.ontology#">
                    <xsl:attribute name="rdf:resource">
                        <xsl:value-of select="$passive"/>
                    </xsl:attribute>
                </xsl:element>
            </xsl:when>
            <xsl:otherwise>
                <!-- Fallback: treat @ana as a full URI -->
                <rdf:predicate rdf:resource="{$ana}"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
