<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:t="http://www.tei-c.org/ns/1.0"
    xmlns="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs t" version="2.0">


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

         Current hierarchy:
           childOf   ← sonOf, daughterOf
           parentOf  ← fatherOf, motherOf
           siblingOf ← sisterOf, brotherOf
           spouseOf  ← husbandOf, wifeOf
           inLawOf   ← sisterInLawOf, brotherInLawOf, motherInLawOf, fatherInLawOf

         Input:  person_index.xml
         Output: person_index.xml with the exploratory listRelation deduplicated
    -->

    <xsl:output indent="yes"/>


    <!-- HIERARCHY MAP — extend here to add new parent/child pairs -->
    <xsl:variable name="hierarchy">
        <!-- child / parent -->
        <entry specific="sonOf"          general="childOf"/>
        <entry specific="daughterOf"     general="childOf"/>
        <entry specific="fatherOf"       general="parentOf"/>
        <entry specific="motherOf"       general="parentOf"/>
        <!-- sibling -->
        <entry specific="sisterOf"       general="siblingOf"/>
        <entry specific="brotherOf"      general="siblingOf"/>
        <!-- spouse -->
        <entry specific="husbandOf"      general="spouseOf"/>
        <entry specific="wifeOf"         general="spouseOf"/>
        <!-- in-law -->
        <entry specific="sisterInLawOf"  general="inLawOf"/>
        <entry specific="brotherInLawOf" general="inLawOf"/>
        <entry specific="motherInLawOf"  general="inLawOf"/>
        <entry specific="fatherInLawOf"  general="inLawOf"/>
    </xsl:variable>


    <!-- Identity transform: copy all nodes unchanged -->
    <xsl:template match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>


    <!-- Exploratory listRelation: apply deduplication logic to its children -->
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
        <xsl:variable name="current" select="."/>

        <!-- Look up the general (parent) name for this relation's @name -->
        <xsl:variable name="general_name" as="xs:string?"
            select="$hierarchy/entry[@specific = $current/@name]/@general"/>

        <!-- Is there a relation with that general name for the same active–passive pair? -->
        <xsl:variable name="general_counterpart"
            select="../t:relation[
                @active  = $current/@active  and
                @passive = $current/@passive and
                @xml:id  != $current/@xml:id and
                @name    = $general_name
            ][1]"/>

        <xsl:choose>

            <!-- Suppress: the general label covers this specific one for the same pair -->
            <xsl:when test="$general_name and $general_counterpart">
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

</xsl:stylesheet>
