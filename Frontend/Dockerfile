FROM node:16.13.1-alpine

WORKDIR /app
ENV PATH /app/node_modules/.bin:$PATH
COPY . ./
RUN npm install


EXPOSE 80
CMD ["node", "index.js"]