FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json  ./
RUN npm ci

COPY . .

RUN npm run build -- --configuration production

FROM nginx:1.25-alpine AS production

ARG HOST_PORT=8082

COPY --from=builder /app/dist/angular-conduit /opt/app-dist

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE ${HOST_PORT}

ENTRYPOINT ["/entrypoint.sh"]

