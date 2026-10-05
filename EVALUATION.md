# Evaluation protocol & results
Protocol: train → dev (candidate selection by macro-F1, temperature fit) → **single** evaluation on the untouched official test split. No metric below was tuned on test.

## Test results
| task | model | n | acc | macro F1 | wF1 | ECE raw→cal | Brier |
|---|---|---|---|---|---|---|---|
| informative | tfidf_logreg_balanced | 2237 | 0.802 | 0.755 | 0.803 | 0.025 → 0.017 | 0.283 · ROC-AUC 0.835, PR-AUC 0.918 |
| humanitarian_category | tfidf_linearsvm_balanced | 2237 | 0.642 | 0.525 | 0.640 | 0.359 → 0.042 | 0.496 |
| damage_severity | tfidf_logreg_balanced | 520 | 0.577 | 0.373 | 0.530 | 0.057 → 0.048 | 0.528 · severe recall 0.829, severe under-prediction 0.171 |
| disaster_type | tfidf_linearsvm_balanced | 2237 | 0.981 | 0.965 | 0.981 | 0.325 → 0.005 | 0.031 |

## Dev-set candidate comparison (macro F1)
| task | LR | LR balanced | SVM | SVM balanced | selected |
|---|---|---|---|---|---|
| informative | 0.724 | 0.759 | 0.723 | 0.747 | **tfidf_logreg_balanced** |
| humanitarian_category | 0.398 | 0.457 | 0.423 | 0.506 | **tfidf_linearsvm_balanced** |
| damage_severity | 0.298 | 0.372 | 0.296 | 0.345 | **tfidf_logreg_balanced** |
| disaster_type | 0.955 | 0.960 | 0.958 | 0.961 | **tfidf_linearsvm_balanced** |

Class weighting improved macro-F1 on every task over the unweighted baseline (compared, not assumed). Focal loss / weighted samplers were not needed for linear models.

## Cross-modal experiments
| exp | status | reason |
|---|---|---|
| A text only | conducted | above |
| B image only | not conducted | image files not downloaded, no GPU |
| C text + image | not conducted | requires images |
| D text + structured | not conducted | CrisisMMD has no structured metadata; fabrication prohibited |
| E text + image + structured | not conducted | as above |
| transformer text | not conducted | script provided, unexecuted |
| JanRakshak ablation (§27) | blocked | needs verified_janrakshak_dataset |

## Operational priority
No ground-truth labels → no accuracy/recall figures are reported for response_priority. The derivation is fully specified in `priority_breakdown` of every response.

## Research questions (§70) — current answers
1. Text classification reliable? Hazard family: yes (macro-F1 0.965 in-domain). Informativeness: moderate (0.755). Humanitarian: partial (0.525; rare classes fail). 
2. Do images improve severity? **Unknown — not measured here.**
3. Does multimodal fusion help? **Unknown — not measured here.**
4. Can operational context improve prioritisation? Implemented as rules; **not yet measured**.
5. Does JanRakshak device evidence improve confidence? **Not demonstrated — requires verified data.**
6. Where does it fail? See /failures and reports/failure_analysis.json.

Artefacts: reports/metrics.json · reports/evaluation_report.html · reports/training_report.html · reports/calibration_report.json · reports/failure_analysis.{json,html}
