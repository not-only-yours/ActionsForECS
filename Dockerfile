FROM node:16.13.1-alpine

WORKDIR /app
ENV PATH /app/node_modules/.bin:$PATH
#RUN npm install


EXPOSE 80
COPY HelloWorld ./
CMD ["node", "index.js"]