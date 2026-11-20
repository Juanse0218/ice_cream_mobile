
FROM ghcr.io/cirruslabs/flutter:3.50.0 AS build

WORKDIR /app

COPY . .

RUN flutter --version

RUN flutter pub get

RUN flutter build web --release

FROM nginx:alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf

COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
