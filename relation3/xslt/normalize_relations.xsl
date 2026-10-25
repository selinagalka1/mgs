<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:t="http://www.tei-c.org/ns/1.0"
    xmlns:f="urn:relation3:normalize"
    xmlns="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs t f" version="2.0">


    <!-- This stylesheet normalizes the exploratory <listRelation> in person_index.xml by
         suppressing a specific (subcategory) relation label when a more general (parent)
         label already exists for the same active–passive pair.

         The hierarchy is defined in $hierarchy below. Each <entry> maps one specific @name
         to its general parent @name. To extend the hierarchy, add entries there — no other
         changes are required.

         Suppression rule:
           A <relation> is suppressed when:
             1. Its @name appears as @specific in the hierarchy map, AND
             2. Another <relation> exists with the same @active and @passive,
                whose @name matches the corresponding @general in the hierarchy map.

         The general label is retained; the specific label is suppressed as redundant.
         Suppressed entries are replaced by XML comments documenting the decision.

         Current hierarchy (only labels that occur in the data):
           childOf   ← sonOf, daughterOf
           siblingOf ← sisterOf, brotherOf
           spouseOf  ← husbandOf, wifeOf

         The stylesheet must be applied to both files, so that the text keeps pointing to
         existing relations:

         Input:  person_index.xml
         Output: person_index.xml with the exploratory listRelation deduplicated

         Input:  annotated_text.xml (person_index.xml is loaded via doc())
         Output: annotated_text.xml in which every @ana reference to a suppressed relation
                 is redirected to the general relation that subsumes it
                 (e.g. "mon second fils": REL32 sonOf → REL5 childOf)
    -->

    <xsl:output indent="yes"/>


    <!-- HIERARCHY MAP — extend here to add new parent/child pairs.
         xmlns="" keeps the <entry> elements in no namespace, so that $hierarchy/entry matches
         (otherwise they would inherit the TEI default namespace of this stylesheet). -->
    <xsl:variable name="hierarchy" xmlns="">
        <!-- child / parent -->
        <entry specific="sonOf"          general="childOf"/>
        <entry specific="daughterOf"     general="childOf"/>
        <!-- sibling -->
        <entry specific="sisterOf"       general="siblingOf"/>
        <entry specific="brotherOf"      general="siblingOf"/>
        <!-- spouse -->
        <entry specific="husbandOf"      general="spouseOf"/>
        <entry specific="wifeOf"         general="spouseOf"/>
    </xsl:variable>


    <!-- Person index (needed when the stylesheet is applied to annotated_text.xml) -->
    <xsl:variable name="person_index" select="doc('../person_index.xml')"/>


    <!-- Returns the general relation that subsumes $rel, or nothing if $rel is kept -->
    <xsl:function name="f:general-counterpart" as="element(t:relation)?">
        <xsl:param name="rel" as="element(t:relation)"/>
        <xsl:variable name="general_name" as="xs:string?"
            select="$hierarchy/entry[@specific = $rel/@name]/@general"/>
        <xsl:sequence select="
            if (empty($general_name)) then ()
            else $rel/../t:relation[
                @active  = $rel/@active  and
                @passive = $rel/@passive and
                @xml:id  != $rel/@xml:id and
                @name    = $general_name
            ][1]"/>
    </xsl:function>


    <!-- Identity transform: copy all nodes unchanged -->
    <xsl:template match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>


    <!-- PERSON INDEX: exploratory listRelation, apply deduplication logic to its children -->
    <xsl:template match="t:listRelation[@subtype='exploratory']">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="node()" mode="deduplicate"/>
        </xsl:copy>
    </xsl:template>


    <!-- Default pass-through in deduplicate mode (comments, text nodes) -->
    <xsl:template match="node()" mode="deduplicate">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>


    <!-- Core deduplication rule for each <relation> -->
    <xsl:template match="t:relation" mode="deduplicate">
        <xsl:variable name="general_counterpart" select="f:general-counterpart(.)"/>

        <xsl:choose>

            <!-- Suppress: the general label covers this specific one for the same pair -->
            <xsl:when test="$general_counterpart">
                <xsl:comment>
                    <xsl:value-of select="concat(
                        ' ', @xml:id, ' (', @name, ') suppressed:',
                        ' subsumed by ', $general_counterpart/@xml:id,
                        ' (', $general_counterpart/@name, ')',
                        ' for ', substring-after(@active, '#'),
                        ' -> ', substring-after(@passive, '#'), ' '
                    )"/>
                </xsl:comment>
            </xsl:when>

            <!-- Keep all other relations unchanged -->
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:apply-templates select="@* | node()"/>
                </xsl:copy>
            </xsl:otherwise>

        </xsl:choose>
    </xsl:template>


    <!-- ANNOTATED TEXT: redirect references to suppressed relations to their general relation.
         Duplicates are removed if a <seg> already points to the general relation as well. -->
    <xsl:template match="t:seg[@type='relationship_mention']/@ana">
        <xsl:variable name="tokens" as="xs:string*">
            <xsl:for-each select="tokenize(normalize-space(.), '\s+')">
                <xsl:variable name="token" select="."/>
                <xsl:variable name="rel"
                    select="$person_index//t:listRelation[@subtype='exploratory']/t:relation[@xml:id = substring-after($token, '#')]"/>
                <xsl:variable name="general" select="if ($rel) then f:general-counterpart($rel) else ()"/>
                <xsl:sequence select="
                    if ($general)
                    then concat(substring-before($token, '#'), '#', $general/@xml:id)
                    else $token"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:attribute name="ana" select="string-join(distinct-values($tokens), ' ')"/>
    </xsl:template>

</xsl:stylesheet>
