# Architecture
```
                       JANRAKSHAK PAYLOAD (or plain text / multipart)
                                     │
                              adapter.ts  (Layer 0: normalisation, masks, privacy)
          ┌──────────────────────────┼──────────────────────────────┐
          ▼                          ▼                              ▼
        TEXT                 IMAGE / EXTERNAL EVIDENCE           STRUCTURED
  normalized_report_text     aiDetection · aiVision · imageRef   type · urgency · score · confidence
          │                  (no trained encoder in v1;           sensorEvidence (+ sensor_present mask)
          ▼                   evidence only, never invented)      lat/lng/accuracyM → coarse context
  TF-IDF (1-2g, sublinear)              │                              │
          │                             │                              │
   ┌──────┴────────┬────────────┬───────┴─────┐                        │
   ▼               ▼            ▼             ▼                        │
 informative  humanitarian  severity   disaster_type   ← Layer A heads (LogReg / LinearSVM, temperature-scaled)
   └───────────────┴────────────┴─────────────┘                        │
                        │  calibrated probabilities                    │
                        ▼                                              ▼
              ┌────────────────── Layer B: operational evidence fusion (fusion.ts) ─────────────────┐
              │ provenance (source, independence_group, confidence) · agreement checks              │
              │ derived priority · overall confidence · review reasons · OOD flags · trace         │
              └──────────────────────────────────────────────────────────────────────────────────────┘
                        ▼
                 canonical response  →  PostgreSQL audit row (no raw text / GPS by default)
```
## Missing-modality behaviour
| available | behaviour |
|---|---|
| text only | full Layer A + Layer B (priority from core outputs) |
| text + structured | Layer A + agreement checks + priority terms |
| text + aiDetection | Layer A + text_vs_image agreement, image group corroboration |
| text + sensorEvidence | Layer A + devices-group corroboration, motion-event rule |
| image only | image accepted & validated, **not analysed** (no encoder) → review |
| nothing usable | priority from citizen urgency only, low confidence, review |
Missing modalities are represented by explicit masks (`sensor_present = 0`, `text_available = false`), never by zero-filled fake values.

## Components
* `ml/dintel/core.py` — data prep, dedupe/contamination, training, temperature scaling, one-shot test evaluation, failure mining, JSON export.
* `src/lib/dintel/core.ts` — exact TypeScript re-implementation of the exported pipeline (verified numerically against Python).
* `src/lib/dintel/adapter.ts` — JanRakshak payload adapter, taxonomy, SensorEvidenceEncoder features, location adapter, identity dropping.
* `src/lib/dintel/fusion.ts` — Layer B rules, provenance, priority, review, OOD.
* `src/lib/dintel/predictor.ts` — response contract, attribution, persistence.
* `backend/app/main.py` — FastAPI Layer-A-only service for Python consumers.

## Planned (interfaces reserved, not trained): DistilBERT text encoder (`ml/scripts/train_transformer.py`), EfficientNet image encoder with gated fusion, learned Layer B on verified JanRakshak data, embedding-distance / conformal OOD.
