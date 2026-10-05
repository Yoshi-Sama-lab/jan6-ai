# Limitations (read before trusting any output)
1. **Core model is a linear TF-IDF model**, not a transformer. The DistilBERT and image scripts exist but were not run (no GPU / images not downloaded) — no numbers are claimed for them.
2. **Hurricane-dominated prior.** Text without explicit hazard words is pulled toward Tropical cyclone. Flood text is often classified as Tropical cyclone (same "hydro" family); fusion refines to the citizen type when families agree and flags disagreement otherwise.
3. **Severity is a proxy.** CrisisMMD severity labels are image-level; the text head learns them second-hand. Macro-F1 0.373; treat Mild/Little predictions as weak. Severe recall 0.829 with under-prediction rate 0.171.
4. **Only 4 of 13 taxonomy classes are learned.** Landslide, Storm, Drought, Pollution, Chemical, Emergency/SOS, Infrastructure, Extreme temperature, Other rely on the citizen declaration and are always routed to review.
5. **English only.** `hi`/multilingual inputs produce `language_warning`; predictions on them are unreliable.
6. **No image encoder.** Images are validated and acknowledged, never analysed. aiDetection is used as external evidence only.
7. **Layer B is rules, not learning.** Priority weights/thresholds are documented heuristics; `confidence_status: heuristic_uncalibrated`. No evidence yet that JanRakshak device evidence improves assessment — the ablation needs a verified dataset.
8. **Location adapter is minimal.** Only accuracy quality and a coarse India bounding box; population/elevation/climate joins are documented in configs/data_sources.yaml but not integrated.
9. **OOD detection is lightweight** (confidence, margin, vocabulary coverage, label support). Embedding-distance / conformal methods are interfaces only.
10. **Temporal drift.** 2017 data; platform language and hazards evolve.
11. **Dataset quirks.** Official damage dev/test share 16 texts; rare classes have single-digit test support.
