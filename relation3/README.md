# Relation³ — Data and XSLT Transformations

Accompanying data and materials for the paper:

**"Relation³: Modeling and relating text describing (family) relationships with structured encoding of the relationships in digital editions"**

> **Note on the data:** The TEI and RDF files in this repository are **exploratory sample data**, not the authoritative edition data. They are based on a manual annotation of a sample of 100 paragraphs distributed across the text, conducted to explore the range of family relationships mentioned in the memoirs. Encoding of person relationships across the full text is planned for a later phase of the project.
>
> The authoritative digital edition is published in GAMS and should be cited as:
> Digitale Edition der Memoiren der Gräfin Schwerin (1684–1732). Hrsg. von Selina Galka, Ines Peper, Michael Pölzl, Chiara Petrolini, Georg Vogeler und Joëlle Weiss, unter Mitarbeit von Sabine Amon. Institut für die Erforschung der Habsburgermonarchie und des Balkanraumes (ÖAW) / Institut für Digitale Geisteswissenschaften (Universität Graz), 2026. GAMS – Geisteswissenschaftliches Asset Management System. TODO: ADD URL. Zuletzt geändert: März 2026.

This repository provides the sample TEI/XML data, XSLT stylesheets, a project ontology, and a relationship visualization illustrating the modeling approach described in the paper.

---

## Contents

```
annotated_text.xml        TEI/XML edition text with relationship mentions
person_index.xml          TEI/XML person register and relationship index
ontology.xml              MGS project ontology (RDF/OWL)
relations_graph.html      Interactive visualization of encoded relationships
xslt/
  tei_to_RDF.xsl          Transform person index + text to RDF/XML
  tei_to_annotation.xsl   Transform relations to TEI <annotation> (standOff)
  tei_to_xenodata.xsl     Transform relations to RDF embedded in TEI <xenoData>
  normalize_relations.xsl Deduplicate the exploratory listRelation
```

---

## Data

### `annotated_text.xml`
The normalized TEI P5 text of the memoirs with annotated relationship mentions. Text passages that describe a family relationship between persons are marked with `<seg type="relationship_mention">`. Each segment carries:
- `@xml:id` — a unique identifier for the text passage
- `@ana` — a URI pointing to the corresponding `<relation>` element in the person index

### `person_index.xml`
The TEI person register and relationship index. It contains:
- `<listPerson>` — all persons mentioned in the memoirs, with biographical metadata (name, birth/death dates, gender, religious denomination, authority identifiers such as GND). The data has been collected by Ines Peper and Michael Pölzl.
- `<listRelation>` — 26 project relationship assertions (primarily *sister-in-law* and *female cousin*), encoding the relationship type in `@name` and linking to the ontology via `@ana`
- `<listRelation subtype="exploratory">` — ~80 relationship assertions from the exploratory annotation of the 100-paragraph sample, covering 18 relationship types; this is the primary dataset in this repository

In both listRelation sections, `@ana` maps text-near labels (e.g. `daughterOf`) to ontology terms: PersonLink properties (e.g. `pl:ChildOf`) where available, and project-specific terms (e.g. `mgs:AuntOf`) for types not covered by PersonLink.

### `ontology.xml`
The MGS project ontology (`https://gams.uni-graz.at/o:mgs.ontology#`). It defines:
- Custom relationship properties not available in PersonLink: `SisterInLawOf`, `BrotherInLawOf`, `MotherInLawOf`, `FatherInLawOf`, `AuntOf`, `UncleOf`, `CousinOf`, `RelativeOf`
- Datatype properties for person metadata: `faith`, `description`, `confession`, `conversion`, `conversion_year`, `cleric`, `vienna`
- Object properties: `relationshipMention` (links a person to a text passage mentioning their relationship), `occursIn` (links a person to a text document)
- Stubs documenting the five PersonLink properties used in this dataset (`ChildOf`, `ParentOf`, `SiblingOf`, `SpouseOf`, `CousinOf`)
- Imports the [PersonLink ontology](http://cedric.cnam.fr/isid/ontologies/PersonLink.owl)

---

## XSLT Stylesheets

All stylesheets require an XSLT 2.0 or 3.0 processor (e.g. Saxon).

### `tei_to_RDF.xsl`
**Primary input:** `person_index.xml`
**Secondary input:** `annotated_text.xml` (referenced internally as `annotated_TEI.xml`)
**Output:** RDF/XML

Transforms all persons in `<listPerson>` into RDF resources typed as `schema:Person` and `mgs:Person`, with names, dates, authority identifiers, and occurrence links. Transforms all `<relation>` elements into direct RDF triples (`active → predicate → passive`), where the predicate is derived from `@ana` (either a `pl:` or `mgs:` term). Each assertion is additionally linked to its textual evidence via `mgs:relationshipMention`.

### `tei_to_annotation.xsl`
**Primary input:** `annotated_text.xml`
**Secondary input:** `person_index.xml` (referenced as `../person_index.xml`)
**Output:** TEI with an appended `<standOff><listAnnotation>` block

Creates one `<annotation motivation="linking">` per relation in the exploratory listRelation. Each annotation contains a human-readable relation description, pointers to the relation URI and all referencing text segments, and a resolved full ontology URI in `@ana`.

### `tei_to_xenodata.xsl`
**Primary input:** `annotated_text.xml`
**Secondary input:** `person_index.xml` (referenced as `../person_index.xml`)
**Output:** TEI with RDF/XML embedded in `<teiHeader><xenoData>`

Embeds one direct RDF triple per relation as an `rdf:Description` inside `<xenoData>`, using the same predicate resolution as `tei_to_RDF.xsl`. Each assertion is linked to its textual mentions via `mgs:relationshipMention`.

### `normalize_relations.xsl`
**Input:** `person_index.xml`
**Output:** `person_index.xml` with the exploratory listRelation deduplicated

Removes redundant entries where both a specific label (e.g. `daughterOf`) and a general label (e.g. `childOf`) exist for the same active–passive pair and `@ana` value. Suppressed entries are replaced by XML comments.

---

## Vocabularies and Namespaces

| Prefix | Namespace | Used for |
|--------|-----------|----------|
| `mgs:` | `https://gams.uni-graz.at/o:mgs.ontology#` | Project-specific relations and person properties |
| `pl:` | `http://cedric.cnam.fr/isid/ontologies/PersonLink.owl#` | Standard kinship relations (PersonLink ontology) |
| `schema:` | `https://schema.org/` | Person metadata (name, birth/death, gender, identifiers) |

---

## Project Context

The data originates from the FWF-funded project *"Tout Vienne me riait": Family and Court Relations in the Memoirs of Countess Louise Charlotte von Schwerin (1684–1732)* (Grant DOI: [10.55776/P34943](https://doi.org/10.55776/P34943)), carried out at the Institute for Habsburg and Balkan Studies (ÖAW) in cooperation with the Department of Digital Humanities, University of Graz.

The digital edition is published in the long-term repository [GAMS](https://gams.uni-graz.at) at: TODO: ADD URL.

---

## License

The data and stylesheets are made available under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).

## Citation

Selina Galka (2026): Relation³ — Data and XSLT Transformations. Accompanying materials for "Relation³: Modeling and relating text describing (family) relationships with structured encoding of the relationships in digital editions". GitHub. [URL]
