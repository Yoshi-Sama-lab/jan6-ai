# D-Intel inference service (Next.js: Layer A + Layer B + dashboard). Models are loaded once at process start.
FROM node:22-slim AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:22-slim
WORKDIR /app
ENV NODE_ENV=production PORT=8080 LOG_RAW_TEXT=false MAX_JSON_BYTES=262144 MAX_IMAGE_BYTES=5242880 REQUEST_TIMEOUT_MS=15000
COPY --from=build /app/package.json /app/package-lock.json ./
RUN npm ci --omit=dev
COPY --from=build /app/.next ./.next
COPY --from=build /app/public ./public
COPY --from=build /app/models ./models
COPY --from=build /app/reports ./reports
COPY --from=build /app/configs ./configs
COPY --from=build /app/tests/fixtures ./tests/fixtures
COPY --from=build /app/next.config.ts ./
EXPOSE 8080
CMD ["npx", "next", "start", "-p", "8080"]
