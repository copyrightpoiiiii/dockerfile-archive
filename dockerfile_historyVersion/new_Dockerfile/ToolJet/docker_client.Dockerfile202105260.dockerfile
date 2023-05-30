# pull official base image
FROM node:14.17.0-alpine

# set working directory
WORKDIR /app

# add `/app/node_modules/.bin` to $PATH
ENV PATH /app/node_modules/.bin:$PATH

# Fix for heap limit allocation issue
ENV NODE_OPTIONS="--max-old-space-size=2048"

# install app dependencies
COPY package.json package-lock.json  ./
RUN npm install
RUN npm install react-scripts@3.4.1 -g --silent

# add app
COPY . ./


# start app
CMD ["npm", "start"]

EXPOSE 8082
