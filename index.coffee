# initialization

fs = require 'fs'
http = require 'http'
express = require 'express'
ca = require 'connect-assets'
request = require 'request'
log = require('logule').init(module)

app = express()
server = http.createServer app

# error handling

process.on 'uncaughtException', (err) ->
  log.error err.stack

# configuration

app.configure ->
  app.set 'views', __dirname + '/app/views'
  app.set 'view engine', 'jade'
  app.use express.bodyParser()
  app.use express.cookieParser()
  app.use express.favicon __dirname + '/public/img/favicon.ico'
  app.use express.static __dirname + '/public'
  app.use ca {
    src: 'app/assets'
    buildDir: 'public'
  }
  app.set 'API_URL', 'http://bayareabikeshare.com/stations/json/'

app.configure 'development', ->
  app.set 'BASE_URL', 'http://localhost:3434'

app.configure 'production', ->
  app.set 'BASE_URL', 'http://babs.herokuapp.com'

# middlewares

logRequest = (req, res, next) ->
  log.info req.method + ' ' + req.url
  next()

# functions

distance = (lat1, lon1, lat2, lon2) ->
  R = 3961 # Earth radius in miles
  dLat = deg2rad(lat2-lat1)
  dLon = deg2rad(lon2-lon1) 
  a = Math.sin(dLat/2) * Math.sin(dLat/2) + Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) * Math.sin(dLon/2) * Math.sin(dLon/2)
  c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a)) 
  d = R * c
  return d

deg2rad = (deg) ->
  return deg * (Math.PI/180)

# routes

app.all '*', logRequest, (req, res, next) ->
  next()

app.get '/', (req, res) ->
  res.render 'babs'

app.get '/stations', (req, res) ->
  hasPosition = req.query.latitude && req.query.longitude
  request.get(app.get('API_URL'), {
    json: true
  }, (error, response, body) ->
    result = []
    for station in body.stationBeanList
      station.distance = distance(station.latitude, station.longitude, req.query.latitude, req.query.longitude) if hasPosition
      result.push station
    (result.sort (a, b) -> return a.distance - b.distance) if hasPosition
    res.send result
  )

app.get '/stations/:id', (req, res) ->
  hasPosition = req.query.latitude && req.query.longitude
  station_id = parseInt(req.params.id)
  request.get(app.get('API_URL'), {
    json: true
  }, (error, response, body) ->
    result = {}
    for station in body.stationBeanList
      if station.id == station_id
        station.distance = distance(station.latitude, station.longitude, req.query.latitude, req.query.longitude) if hasPosition
        result = station
        break
    res.send result
  )

# 404

app.all '*', (req, res) ->
  res.redirect '/'

# server creation

server.listen process.env.PORT ? '3434', ->
  log.info 'Express server listening on port ' + server.address().port + ' in ' + app.settings.env + ' mode'