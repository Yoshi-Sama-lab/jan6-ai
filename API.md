# API (Next.js service, default port 3000 / 8080 in container)
Headers: `Content-Type: application/json`; `X-API-Key` required only if `DINTEL_API_KEY` is set. CORS via `CORS_ORIGIN`. Limits: JSON 256 KB, image 5 MB (jpeg/png/webp, signature-checked), 15 s timeout. Errors: `{error:{code,message,details},timestamp}`.

| method | path | body |
|---|---|---|
| GET | /api/health | — |
| GET | /api/model | — (core + fusion metadata, test metrics, experiment status) |
| GET | /api/capabilities | — (modalities, languages, taxonomy, feature registry) |
| GET | /api/metrics | — (requests, latency p95, errors, low-confidence rate, modality availability) |
| POST | /api/predict | `{text, type?, language?, image_url?}` or `{payload: <JanRakshak object>}` |
| POST | /api/predict/text | `{text, type?, language?}` |
| POST | /api/predict/multimodal | multipart: `text`, `type?`, `image` file or `image_url` |
| POST | /api/predict/janrakshak | the Firebase incident payload as-is |
| PATCH | /api/review | `{request_id, decision: confirmed|corrected|dismissed, labels?, verified_by?}` |
| GET | /api/fixtures | prepared JanRakshak examples |
| GET | /api/reports/{name} | dataset_report.html · training_report.html · evaluation_report.html · failure_analysis.html · metrics.json |

## Response (canonical)
```json
{
  "request_id": "…", "model_version": "dintel-core-v1.0.0", "fusion_version": "dintel-fusion-v1.0.0", "timestamp": "…",
  "input_summary": {"text_available": true, "image_available": false, "structured_features_available": true, "sensor_evidence_available": true, "location_available": true, "supported_language": "en-IN", "language_warning": null},
  "predictions": {
    "disaster_type": {"label": "Flood", "confidence": 0.99, "source": "model_group_refined_by_citizen_type", "model_prediction": {"label": "Tropical cyclone", "confidence": 0.98}},
    "informative": {"label": "informative", "confidence": 0.89, "calibration_status": "calibrated_temperature_scaling_dev", "probabilities": {…}},
    "humanitarian_category": {"label": "Affected individuals", "confidence": 0.51, …},
    "damage_severity": {"label": "Severe", "confidence": 0.78, "label_provenance": "text proxy of CrisisMMD image-level damage annotation", …},
    "response_priority": {"label": "CRITICAL", "confidence": 0.84, "derived": true, "confidence_status": "heuristic_uncalibrated", "score": 0.79}
  },
  "overall_confidence": 0.79, "confidence_status": "calibrated (…); priority heuristic is uncalibrated",
  "evidence_fusion": {"text_confidence": 0.98, "image_confidence": null, "sensor_confidence": 0.87, "existing_ai_confidence": 0.93, "context_available": true, "independent_corroborating_groups": 3},
  "evidence_provenance": [{"source": "text_model", "independence_group": "report", "confidence": 0.98, …}, {"source": "phone_detector (aiDetection)", "independence_group": "image", …}, {"source": "sensor_consensus", "independence_group": "devices", …}],
  "evidence_agreement": {"text_vs_image": "aligned", "text_vs_citizen_type": "aligned", "sensor_vs_event": "supportive"},
  "janrakshak_context": {"sensor_evidence_used": true, "ai_detection_used": true, "location_used": true, "existing_urgency_used": true, "identity_fields_used": false},
  "review": {"requires_human_review": true, "reasons": ["high-severity assessment requires operator verification"]},
  "ood": {"flags": [], "vocab_coverage": 0.93, "method": "…"},
  "prediction_trace": {"text_model": "moderate", "image_model": "unavailable", "sensor_context": "strong", "location_context": "strong", "existing_ai_evidence": "strong", "cross_modal_agreement": "aligned"},
  "priority_breakdown": {"severity": …, "formula": "…"},
  "explanation": {"method": "exact linear contribution", "disaster_type": [{"token": "houses", "contribution": 0.31}, …]},
  "feature_map": [...], "adapter": {"ignored_identity_fields": ["userId"], …}, "latency_ms": 4
}
```
Values shown are illustrative of the *shape*; the actual numbers always come from the model at request time. No NaN, no logits, no fake confidence (`null` when not computable).

## Python Layer-A service (backend/app/main.py)
`uvicorn backend.app.main:app --port 8081` → /health /model /capabilities /metrics /predict /predict/text /predict/janrakshak (core predictions only; /predict/multimodal returns 501).
