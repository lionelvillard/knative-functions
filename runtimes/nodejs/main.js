const http = require('http')
const handler = require('./___handler')
const server = http.createServer(handler)
server.listen(process.env.PORT || 8080)