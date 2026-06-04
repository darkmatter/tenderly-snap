# syntax=docker/dockerfile:1

# ---- Build stage: compile the Gatsby site workspace ----------------------
# Pinned to the repo's Node (.nvmrc = v16). The full Debian image carries the
# toolchain Gatsby's native deps (sharp) need; this stage is discarded.
FROM node:16-bullseye AS build

# The npm-published snap MetaMask installs at runtime. Overridable at build
# time; baked into the client bundle by packages/site/gatsby-node.ts.
ARG SNAP_ORIGIN=npm:@tenderly/metamask-snap
ENV SNAP_ORIGIN=${SNAP_ORIGIN} \
    GATSBY_TELEMETRY_DISABLED=1 \
    NODE_OPTIONS=--max-old-space-size=4096

WORKDIR /app

# Use the Yarn version pinned in package.json (yarn@3.6.0, via the checked-in
# .yarn/releases binary + corepack shim).
RUN corepack enable

# Full monorepo is needed: yarn workspace resolution reads the root manifest,
# lockfile, and .yarn/. node_modules/public/caches are excluded by
# .dockerignore so the context stays small and installs are reproducible.
COPY . .

# node-modules linker; the committed lockfile is authoritative.
RUN yarn install --immutable

# Build only the site workspace -> packages/site/public
RUN yarn workspace @tenderly/simulate-asset-changes-ui run build

# ---- Runtime stage: serve the static output via unprivileged nginx -------
FROM nginxinc/nginx-unprivileged:1.27-alpine AS runtime

# Listen on :8000 with an SPA-style fallback (replaces the default :8080 conf).
COPY deploy/nginx.conf /etc/nginx/conf.d/default.conf

# Static assets only — no server-side runtime.
COPY --from=build /app/packages/site/public /usr/share/nginx/html

EXPOSE 8000

# Base image already runs `nginx -g 'daemon off;'` as uid 101 (non-root).
