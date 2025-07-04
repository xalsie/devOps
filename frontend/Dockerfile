FROM node:24-alpine as builder

LABEL org.opencontainers.image.source https://github.com/xalsie/devops

ARG VITE_BACKEND_URL=http://localhost:3000
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN echo "# Configuration générée depuis les arguments Docker" > .env.production && \
    echo "VITE_BACKEND_URL=${VITE_BACKEND_URL}" >> .env.production && \
    echo "✅ Fichier .env.production créé avec VITE_BACKEND_URL=${VITE_BACKEND_URL}"
RUN cat .env.production
RUN npm run build
FROM nginx:alpine
COPY --from=builder /app/public /usr/share/nginx/html
RUN echo 'server { \
    listen 80; \
    location / { \
        root /usr/share/nginx/html; \
        index index.html index.htm; \
        try_files $uri $uri/ /index.html; \
    } \
}' > /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
