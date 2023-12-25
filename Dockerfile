FROM node:16 as deps
WORKDIR /app

RUN apt-get update && apt-get full-upgrade -yqq && apt-get install build-essential cmake python3 g++ make -yqq

COPY package.json .

RUN npm ci \
    && mv ./node_modules/@types/jsonstream ./node_modules/@types/JSONStream


FROM deps as frontend
WORKDIR /app

COPY public ./public
COPY src ./src
COPY plugins ./plugins
COPY types ./types
COPY Shared ./Shared
COPY .browserslistrc tsconfig.json tslint.json vue.config.js ./
COPY .eslintrc.js ./

RUN npm run build-frontend


FROM deps as backend
WORKDIR /app

COPY backend ./backend
COPY Shared ./Shared

RUN npm run build-backend



FROM node:16
WORKDIR /app

RUN apt-get update && apt-get full-upgrade -yqq && apt-get install npm git ffmpeg -yqq

COPY --from=deps /app/node_modules node_modules
COPY --from=deps /app/package.json .
COPY --from=frontend /app/client client
COPY --from=backend /app/backend/build .
COPY --from=backend /app/backend/tsconfig.json ./backend
COPY .git ./.git

RUN echo "window.build=\"$(git rev-parse HEAD | cut -c 1-7)_$(date +'%d.%m.%Y')_$(date +"%T")\";" > /app/client/env.js \
    && rm -rf .git

EXPOSE 80 443
ENTRYPOINT [ "npm", "start" ]
