# Dataset
**CrisisMMD v2.0 data splits** — https://crisisnlp.qcri.org/crisismmd (Alam, Ofli, Imran; ICWSM 2018, ISCRAM 2020). Seven 2017 events: Hurricanes Harvey, Irma, Maria; California wildfires; Mexico & Iraq–Iran earthquakes; Sri Lanka floods.

## What the dataset contains / does not contain
Contains: tweet text, image paths, text labels (informative, humanitarian), image labels (informative, humanitarian, damage severity), text/image agreement flag, event name.
Does **not** contain: GPS, sensor data, JanRakshak fields, YOLO confidence, citizen urgency, Firebase metadata, response priority. None of these were fabricated.

## Pipeline (ml/scripts/prepare_dataset.py)
1. ingest official TSVs · 2. validate columns/labels · 3. tweet-level de-duplication (multiple images per tweet) · 4. drop tweets whose images carry conflicting severity labels · 5. mojibake repair · 6. normalisation (dintel-norm-v1) · 7. remove train rows whose normalised text appears in dev/test · 8. map labels to internal taxonomy · 9. write data/processed/{train,dev,test}.jsonl · 10. reports/dataset_report.json

## Sizes after preparation
| task | train | dev | test | label source |
|---|---|---|---|---|
| informative | 11579 | 2237 | 2237 | CrisisMMD text annotation (label_text) |
| disaster_type | 11579 | 2237 | 2237 | CrisisMMD event_name metadata mapped to internal taxonomy (4 of 13 taxonomy classes covered) |
| humanitarian_category | 11580 | 2237 | 2237 | CrisisMMD text annotation (label_text) |
| damage_severity | 2140 | 512 | 520 | CrisisMMD IMAGE annotation used as proxy label for the paired tweet text (no text-level severity labels exist) |

## Class distributions (train)
- **informative** (train): informative 8282, not_informative 3297
- **disaster_type** (train): Wildfire 1036, Flood 613, Earthquake 1253, Tropical cyclone 8677
- **humanitarian_category** (train): Other relevant information 4266, Infrastructure and utility damage 882, Not humanitarian 3297, Affected individuals 338, Rescue, volunteering or donation effort 2384, Injured or dead people 346, Vehicle damage 39, Missing or found people 28
- **damage_severity** (train): Severe 1382, Little or none 277, Mild 481

## Notes
* disaster_type labels come from event metadata; event-identifying tokens (harvey, irma, napa, …) are masked during training to reduce memorisation.
* damage_severity text labels are proxies of image annotations — noisy by construction; reported honestly (macro-F1 0.373).
* The official damage dev/test splits share 16 identical texts; the test split was left untouched.
* Images (2.1 GB) not downloaded in this build.
