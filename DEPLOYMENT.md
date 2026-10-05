# Deployment (Google Cloud Run)
```bash
gcloud builds submit --tag gcr.io/PROJECT_ID/dintel-inference:1.0.0
gcloud secrets create dintel-database-url --data-file=<(echo -n "$DATABASE_URL")
gcloud secrets create dintel-api-key --data-file=<(echo -n "$DINTEL_API_KEY")
gcloud run services replace cloudrun.yaml --region asia-south1
gcloud run services add-iam-policy-binding dintel-inference --member=allUsers --role=roles/run.invoker --region asia-south1   # or keep private + API key
```
Properties: model JSON (4.7 MB) loaded once per instance and cached; stateless per request; 30 s Cloud Run timeout + 15 s internal timeout; 256 KB JSON / 5 MB image limits; health probes on `/api/health`; PostgreSQL (Cloud SQL) for audit/review/registry via `DATABASE_URL`; no training in production; `LOG_RAW_TEXT=false` by default.

Local: `docker compose up --build` → dashboard+API on :8080, Python Layer-A on :8081, Postgres on :5432. Run `npx drizzle-kit push` once against the database.

Future size work: ONNX/quantised transformer once trained; not needed for the current linear model.
