# JanRakshak integration
```
Firebase incident document / PacketPayload
        │  POST /api/predict/janrakshak   (body = payload as-is; nulls/empties already stripped by the phone serializer are fine)
        ▼
D-Intel adapter (src/lib/dintel/adapter.ts)
   text precedence rawText > description > title → normalized_report_text
   type → taxonomy (configs/label_mapping.yaml) → core_supported? / unknown?
   urgency, score, confidence → normalized operational context
   aiDetection / aiVision → external evidence (present flag, label group, clipped confidence)
   sensorEvidence → SensorEvidenceEncoder features + sensor_present mask (raw IMU never expected)
   lat/lng/accuracyM/geo → validity + accuracy quality + coarse bbox (no raw coordinate feature, never logged)
   language → support gate
   userId / reporterId / userEmail → dropped (audit list only)
   reviewStatus / autoDispatched / etaMinutes … → dropped (outcome leakage)
        ▼
Layer A core model (src/lib/dintel/core.ts, weights from models/exported/dintel_core_v1.json)
   informative · humanitarian_category · damage_severity · disaster_type   (calibrated, T per head)
        ▼
Layer B evidence fusion (src/lib/dintel/fusion.ts)
   provenance list with independence_group ∈ {report, image, devices, device_gps}
   agreement: text_vs_image, text_vs_citizen_type, sensor_vs_event
   response_priority (derived) · requires_human_review · OOD flags · prediction_trace
        ▼
Response (API.md) — request_id is the audit key; raw text not stored unless LOG_RAW_TEXT=true
```
## Field extraction shown for the flood fixture
rawText → TEXT · type → HAZARD CONTEXT · urgency/score → OPERATIONAL CONTEXT · confidence/aiDetection → EXISTING AI EVIDENCE · sensorEvidence → SENSOR CONTEXT · lat/lng/accuracyM → LOCATION CONTEXT · userId → dropped. The live view is at `/integration/janrakshak`.

## Tolerance guarantees (tested in tests/dintel.test.ts)
missing text · missing image · missing sensorEvidence · missing lat/lng · unknown type · unsupported type · malformed JSON · confidence outside [0,1] · unknown detector label · missing AI evidence · contradictory text/image · weak sensor evidence · unsupported language · mesh-relayed anonymous incident.

## Do-not-double-count rule
`citizen type = Flood`, `text model = Flood`, `janrakshak confidence = 0.91` all belong to independence_group **report** and count as one source. Only **image** (aiDetection), **devices** (sensorEvidence) and **device_gps** (precise/moderate fix) can add independent corroboration votes.

## Future flywheel (controlled)
citizen report → prediction → operator review (`PATCH /api/review`) → verified label → `verified_janrakshak_dataset` → offline retraining → new versions `dintel-core-v1.x` / `dintel-fusion-v2`. No automatic retraining; model output is never promoted to ground truth.
