FROM node:7-alpine

COPY . /app
WORKDIR /app
RUN mkdir static
RUN npm install

ENV PORT=1443
EXPOSE $PORT

CMD ["npm", "start"]
