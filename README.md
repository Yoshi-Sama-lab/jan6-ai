# D-INTEL — Disaster Intelligence Engine
> Turn disaster reports into actionable intelligence.

Independent ML product that converts a citizen-generated disaster report into structured intelligence for emergency operators, designed to become the cloud ML intelligence service consumed by **JanRakshak** through a real payload adapter — without depending on the JanRakshak repository.

## Why this exists
Citizen reports are noisy, partial and uneven. Operators need to know: *is this informative, what humanitarian situation is it, how severe, what hazard, and how urgently should someone look at it?* D-Intel answers those questions with a trained model where real labels exist and with **explicit, documented rules** where they do not.

## What the model predicts
| output | kind | how |
|---|---|---|
| disaster_type | **learned** (4 classes) + citizen-declared for unsupported classes | CrisisMMD event metadata → taxonomy |
| informative | **learned** | CrisisMMD text labels |
| humanitarian_category | **learned** (8 classes) | CrisisMMD text labels |
| damage_severity | **learned – proxy** | CrisisMMD *image-level* severity label applied to the paired tweet text |
| response_priority | **derived** operational layer (rules, uncalibrated) | severity · humanitarian relevance · informativeness · citizen urgency · independent corroboration |
| overall_confidence | derived | mean calibrated confidence of core tasks |
| requires_human_review | derived (rules) | low confidence, contradictions, unsupported type, missing sensor for motion events, OOD flags |

D-Intel always distinguishes **model prediction**, **phone-side AI evidence** (aiDetection), **citizen-provided information** (type, urgency) and **derived recommendations** (priority, review). They are never treated as the same thing.

## Where the data came from
**CrisisMMD v2.0** official data splits (Alam, Ofli, Imran — QCRI), `https://crisisnlp.qcri.org/crisismmd`. Downloaded by `ml/scripts/download_crisismmd.py` (text + labels, 3 MB). Image files (2.1 GB) were **not** downloaded in this build → no image or multimodal model was trained, and none is claimed.

| task | train | dev | test | label source |
|---|---|---|---|---|
| informative | 11579 | 2237 | 2237 | CrisisMMD text annotation (label_text) |
| disaster_type | 11579 | 2237 | 2237 | CrisisMMD event_name metadata mapped to internal taxonomy (4 of 13 taxonomy classes covered) |
| humanitarian_category | 11580 | 2237 | 2237 | CrisisMMD text annotation (label_text) |
| damage_severity | 2140 | 512 | 520 | CrisisMMD IMAGE annotation used as proxy label for the paired tweet text (no text-level severity labels exist) |

Train-set rows whose normalised text also appears in dev/test were removed (informative 4, humanitarian 2, damage 76). The official test split was left untouched and evaluated once.

## Results (held-out CrisisMMD test split — measured, not simulated)
| task | selected on dev | n | acc | macro F1 | weighted F1 | ECE raw → calibrated | Brier |
|---|---|---|---|---|---|---|---|
| informative | tfidf_logreg_balanced | 2237 | 0.802 | 0.755 | 0.803 | 0.025 → 0.017 | 0.283 · ROC-AUC 0.835, PR-AUC 0.918 |
| humanitarian_category | tfidf_linearsvm_balanced | 2237 | 0.642 | 0.525 | 0.640 | 0.359 → 0.042 | 0.496 |
| damage_severity | tfidf_logreg_balanced | 520 | 0.577 | 0.373 | 0.530 | 0.057 → 0.048 | 0.528 · severe recall 0.829, severe under-prediction 0.171 |
| disaster_type | tfidf_linearsvm_balanced | 2237 | 0.981 | 0.965 | 0.981 | 0.325 → 0.005 | 0.031 |

Dev-set macro-F1 for every candidate (selection basis; test never used for selection):

| task | LR | LR balanced | SVM | SVM balanced | selected |
|---|---|---|---|---|---|
| informative | 0.724 | 0.759 | 0.723 | 0.747 | **tfidf_logreg_balanced** |
| humanitarian_category | 0.398 | 0.457 | 0.423 | 0.506 | **tfidf_linearsvm_balanced** |
| damage_severity | 0.298 | 0.372 | 0.296 | 0.345 | **tfidf_logreg_balanced** |
| disaster_type | 0.955 | 0.960 | 0.958 | 0.961 | **tfidf_linearsvm_balanced** |

Not conducted (honestly): image-only, text+image, text+structured, transformer text, JanRakshak ablation — see `EVALUATION.md`.

## Architecture (two tiers)
```
JanRakshak payload ──► adapter ──► text ──► Layer A core model (TF-IDF → 4 calibrated linear heads)
                          │                        │
                          ├── type / urgency / score / confidence ─┐
                          ├── aiDetection (YOLO evidence) ─────────┤
                          ├── sensorEvidence (aggregated, masked) ─┼─► Layer B evidence fusion (rules, provenance,
                          └── lat/lng/accuracyM (coarse context) ──┘    independence groups) ─► priority · review · trace
```
Layer A is trained on public data only. Layer B consumes JanRakshak-specific evidence with explicit rules until a **human-verified JanRakshak dataset** exists (collection table `verified_janrakshak_dataset` is implemented). See `ARCHITECTURE.md`.

## What is learned vs derived vs unsupported
* **Learned:** informative, humanitarian_category, damage_severity (proxy), disaster_type {Flood, Tropical cyclone, Earthquake, Wildfire}.
* **Derived:** response_priority, requires_human_review, overall_confidence, evidence_agreement, prediction_trace.
* **Not supported by the core model:** Landslide, Storm, Extreme temperature, Drought, Pollution, Chemical hazard, Emergency/SOS, Infrastructure, Other → citizen declaration retained (confidence `null`) and routed to review.
* **Languages:** en / en-IN. `hi` and others are accepted with `language_warning`; no multilingual claim.

## Training-data honesty
JanRakshak fields absent from CrisisMMD (urgency, score, confidence, aiDetection, sensorEvidence, GPS, mesh) are **never** fabricated, sampled, or derived from labels. They enter only Layer B (option D of §68) and are marked `optional_until_training_data_exists` in `configs/feature_registry.yaml`. Identity fields (userId, reporterId, userEmail) are dropped by the adapter and are never features.

## Reproduction
```bash
pip install -r requirements.txt
python ml/scripts/download_crisismmd.py
python ml/scripts/prepare_dataset.py      # dedupe, contamination removal, label mapping → data/processed, reports/dataset_report.json
python ml/scripts/validate_dataset.py
python ml/scripts/train.py                # 4 candidates × 4 tasks, dev selection → models/checkpoints/dintel_core_v1.pkl
python ml/scripts/calibrate.py            # temperature scaling on dev
python ml/scripts/evaluate.py             # ONE pass on test → reports/metrics.json, failure_analysis.json
python ml/scripts/export_model.py         # → models/exported/dintel_core_v1.json (+ metadata)
python ml/scripts/make_reports.py         # HTML reports
python ml/scripts/predict.py --text "Water has entered several houses"
python ml/scripts/predict.py --janrakshak tests/fixtures/janrakshak/flood.json

npm install && npx drizzle-kit push && npm run build && npm start   # inference API + dashboard
npx tsx --test tests/dintel.test.ts                                   # 29 contract tests (all fixtures through the real pipeline)
```

## API
`GET /api/health` · `GET /api/model` · `GET /api/capabilities` · `GET /api/metrics` · `POST /api/predict` · `POST /api/predict/text` · `POST /api/predict/multimodal` · `POST /api/predict/janrakshak` · `PATCH /api/review` — see `API.md`.

## Dashboard
`/` overview · `/analyze` (TEXT / IMAGE / JANRAKSHAK PAYLOAD) · `/models` · `/evaluation` · `/failures` · `/integration/janrakshak`.

## Known limitations
See `LIMITATIONS.md`. Headline: hurricane-dominated training prior (74% of tweets) pulls hazard-word-free text toward *Tropical cyclone*; severity is a noisy text proxy of image labels (macro-F1 0.373, severe recall 0.829); no image encoder; English only; 2017 events; priority is a heuristic.

## Repository map
`ml/` Python training pipeline · `src/lib/dintel/` TypeScript inference (core, adapter, fusion, predictor) · `src/app/api/` endpoints · `src/app/` dashboard · `backend/app/main.py` FastAPI Layer-A service · `configs/` feature registry, label mapping, data sources · `models/` checkpoints / exported / metadata · `reports/` dataset / training / evaluation / failure analysis · `tests/` contract tests + JanRakshak fixtures.
