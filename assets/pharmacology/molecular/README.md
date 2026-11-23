# Clinical Pharmacology molecular library

This folder is the build-time source and destination for the complete 41-profile drug molecular library. The GLB models and manifests are generated in GitHub Actions before Flutter assets are bundled; generated binary models are not committed to Git.

## Build pipeline

1. `drug_target_catalog.json` contains the 41 drug identities, target annotations, reference organisms, and UniProt accessions where a single protein target is appropriate.
2. `scripts/build_pharmacology_molecular_models.py` downloads curated experimental complexes from the RCSB Protein Data Bank and builds atom-level GLB files. It includes experimental complexes for lisinopril, atorvastatin, ibuprofen, apixaban, methotrexate, semaglutide, azithromycin, and gentamicin.
3. `scripts/build_pharmacology_drug_conformers.py` builds a rotatable, atom-and-bond model for every remaining drug profile. It prefers PubChem 3D conformers and falls back to a deterministic RDKit ETKDGv3 conformer generated from PubChem isomeric chemical identity data.
4. Where a UniProt target accession is available, the same script retrieves the corresponding AlphaFold DB predicted protein model and builds an interactive target-protein GLB. The viewer explicitly labels these as predicted, unbound target structures.

## Scientific interpretation

- A PubChem/RDKit isolated-molecule conformer is **not** a receptor-bound pose, docking result, molecular-dynamics trajectory, or binding-energy calculation.
- An AlphaFold DB protein model is a predicted target structure, not a drug-bound experimental complex.
- Only the eight named experimental PDB complexes are presented as co-crystallised/co-resolved drug–target structures. Semaglutide uses 7KI0 (GLP-1R, cryo-EM); methotrexate uses wild-type human DHFR structure 1U72; azithromycin uses 1M1K (archaeal 50S/23S rRNA); gentamicin C1a uses 2ET3 (16S rRNA A-site oligonucleotide).
- Several medicines act on RNA, multiple proteins, or indirect pathways rather than one unique protein. The catalogue labels these accurately; it must not invent a single receptor structure for them.
- Gentamicin is a mixture; the displayed molecular conformer is the representative gentamicin C1a component. Sodium valproate is represented by the valproate/valproic-acid active moiety.

## Generated files

- `drugs/<slug>.glb`: isolated molecular conformer with individually selectable atoms and explicit bond cylinders.
- `targets/<uniprot>.glb`: atom-level AlphaFold target protein model when available.
- `drug_manifest.json`: build-generated drug, conformer, target and provenance metadata.
- `manifest.json`: build-generated experimental-complex ligand and binding-site atom metadata.

Do not replace experimental coordinates with fabricated poses or remove the model provenance notes from the UI.
