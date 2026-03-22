# mgs — The Memoirs of Countess Schwerin (1684–1732). Digital Edition: Accompanying Data

Data, scripts, and supplementary materials for the digital edition of the Memoirs of Countess Louise Charlotte von Schwerin (1684–1732).

The authoritative digital edition is published in GAMS:
Digitale Edition der Memoiren der Gräfin Schwerin (1684–1732). Hrsg. von Selina Galka, Ines Peper, Michael Pölzl, Chiara Petrolini, Georg Vogeler und Joëlle Weiss, unter Mitarbeit von Sabine Amon. Institut für die Erforschung der Habsburgermonarchie und des Balkanraumes (ÖAW) / Institut für Digitale Geisteswissenschaften (Universität Graz), 2026. GAMS – Geisteswissenschaftliches Asset Management System. TODO: ADD URL. Zuletzt geändert: März 2026.

---

## Contents

```
relation3/                Accompanying data for the paper "Relation³" (see relation3/README.md)
  annotated_text.xml      TEI/XML edition text with annotated relationship mentions
  person_index.xml        TEI/XML person register and relationship index
  ontology.xml            MGS project ontology (RDF/OWL)
  relations_graph.html    Interactive visualization of encoded relationships
  xslt/
    tei_to_RDF.xsl        Transform person index + text to RDF/XML
    tei_to_annotation.xsl Transform relations to TEI <annotation> (standOff)
    tei_to_xenodata.xsl   Transform relations to RDF embedded in TEI <xenoData>
    normalize_relations.xsl Deduplicate the exploratory listRelation

relations/                Files accompanying the TEI conference presentation (2023):
                          Selina Galka, Georg Vogeler: "Relation³: How to relate text describing
                          relationships with structured encoding of the relationships?"
                          TEI Member's Meeting & Conference 2023, Paderborn.
                          https://teimec2023.uni-paderborn.de/contributions/117.html
  Input_seg_relation_example.xml
  seg_to_annotation.xsl
  seg_to_xenodata.xsl
  output_seg_to_annotation.xml
  output_seg_to_xenodata.xml

topic modelling/          Exploratory topic modelling notebook
  Topic_modelling_with_BERT_sentences.ipynb
```

---

## Project Context

The data originates from the FWF-funded project *"Tout Vienne me riait": Family and Court Relations in the Memoirs of Countess Louise Charlotte von Schwerin (1684–1732)* (Grant DOI: [10.55776/P34943](https://doi.org/10.55776/P34943)), carried out at the Institute for Habsburg and Balkan Studies (ÖAW) in cooperation with the Department of Digital Humanities, University of Graz.

---

## License

The data and stylesheets are made available under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
