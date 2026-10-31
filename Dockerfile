FROM node:22-slim AS builder

# install git to install plugins
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app
COPY package.json .
COPY package-lock.json* .
COPY .npmrc* .
COPY quartz/ ./quartz/
COPY quartz.lock.json* .
RUN npm ci && npm run quartz -- plugin install --from-config

FROM node:22-slim
WORKDIR /usr/src/app
COPY --from=builder /usr/src/app/ /usr/src/app/
COPY . .
CMD ["npm", "run", "quartz", "--", "build", "--serve"]
