# JanRakshak → D-Intel feature mapping (authoritative)
`*` = only enabled in Layer B (rule fusion) because the public training pipeline has no supervision for it. A field is **never** marked YES just because it exists in the payload.

| Firebase field | Used? | Transformation | Model component |
|---|---|---|---|
| rawText | **YES** | dintel-norm-v1 → TF-IDF (1–2 gram, sublinear, l2) | text encoder (core, Layer A) |
| description | fallback | same tokenizer (used only if rawText absent) | text encoder |
| title | fallback | same tokenizer (used only if rawText & description absent) | text encoder |
| type | YES (fusion) | alias table → 13-class taxonomy → compatibility group | agreement check vs model / detector; unsupported-class gate (NOT a core input: would be circular with the disaster_type target) |
| urgency | YES* | LOW .25 / MEDIUM .5 / HIGH .75 / CRITICAL 1 | fusion → priority term (weight 0.15) |
| score | YES* | /10, clip [0,1] | fusion → priority fallback when text is absent |
| confidence | YES* | clip [0,1], flag if outside range | fusion, independence_group = report (never counted as independent) |
| lat | YES* | validity check → coarse context (accuracy quality, India bbox); raw value never a feature, never logged | location context |
| lng | YES* | as above | location context |
| accuracyM | YES* | ≤25 m precise · ≤150 m moderate · else coarse | location confidence → priority confidence, corroboration vote |
| language | YES | gate: en / en-IN supported; hi / multi / other → language_warning | input_summary |
| aiDetection.label | YES* | detector label → compatibility group; unknown label → null (not used) | fusion → evidence_agreement (text_vs_image) |
| aiDetection.confidence | YES* | clip [0,1], flag if invalid | fusion, independence_group = image |
| aiDetection.model | NO | metadata only | trace |
| aiVision | YES* | presence only (schema not fixed) | fusion presence flag |
| imageStorageRef | NOT USED | reference retained | input_summary.image_available (no image encoder in v1) |
| sensorEvidence.deviceCount | YES* | log1p | SensorEvidenceEncoder → fusion (devices group) |
| sensorEvidence.clusterRadiusMeters | YES* | /500 clip | SensorEvidenceEncoder |
| sensorEvidence.eventDurationMs | YES* | log1p | SensorEvidenceEncoder |
| sensorEvidence.clusterScore | YES* | clip [0,1] | fusion (sensor strength fallback) |
| sensorEvidence.sensorAgreement | YES* | clip [0,1] | SensorEvidenceEncoder |
| sensorEvidence.spatialCorrelation | YES* | clip [0,1] | SensorEvidenceEncoder |
| sensorEvidence.temporalCorrelation | YES* | clip [0,1] | SensorEvidenceEncoder |
| sensorEvidence.confidence | YES* | clip [0,1] | fusion (sensor strength) |
| sensorEvidence.eventType | YES* | categorical (embedding reserved) | fusion trace |
| (sensor missing) | YES | explicit mask `sensor_present = 0` (≠ deviceCount 0) | fusion; review rule for motion-sensitive events |
| rawAudioBlobId | NOT USED | presence | — |
| geo / locationStatus | YES* | fallback source for lat/lng; status retained | location context |
| source | NO | trace only | — |
| pendingScoring | NO | trace | — |
| city / stateName / location | NOT USED | trace only (no gazetteer join in v1) | — |
| isMeshRouted / meshHopCount / meshOrigin | OPTIONAL | relayed flag, hop count | review rule: relayed without location |
| meshRelayPath / meshPacketHash | NO | transport metadata | — |
| userId | **NO** | identity — dropped by adapter | none (listed in `adapter.ignored_identity_fields`) |
| reporterId | **NO** | identity — dropped | none |
| userEmail | **NO** | identity — dropped | none |
| reviewStatus | **NO** | operational state (would leak review outcome) | none |
| autoDispatched / acknowledged / resolved / etaMinutes / log | **NO** | response outcome → target leakage | none |
| incidentCode | NO | echoed in `trace` for audit | none |
| timestamp / createdAt | NO | — | none |

## Fields that require JanRakshak-specific training data before they can be *learned*
urgency, score, confidence, aiDetection.*, aiVision, sensorEvidence.*, accuracyM, meshHopCount, location-derived context. Collection path: operator decisions via `PATCH /api/review` → `verified_janrakshak_dataset` → offline retraining of Layer B (`dintel-fusion-v2`) and the ablation study in §27.
