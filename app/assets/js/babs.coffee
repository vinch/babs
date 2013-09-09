class window.BABS


class BABS.App

  start: (position) ->
    BABS.position = position if position
    BABS.router = new BABS.Router
    Backbone.history.start()

  noLocation: ->
    alert('You must accept to share your location to use this application!')


class BABS.Router extends Backbone.Router

  routes:
    '': 'list'
    ':id': 'details'

  list: ->
    BABS.stations = new BABS.Stations
    BABS.stationsListView = new BABS.StationsListView({ collection: BABS.stations })
    BABS.stations.fetch
      success: ->
        $('#content').html BABS.stationsListView.render().el

  details: (id) ->
    BABS.station = new BABS.Station({ id: id })
    BABS.stationView = new BABS.StationView({ model: BABS.station })
    BABS.station.fetch
      success: ->
        $('#content').html BABS.stationView.render().el


class BABS.Station extends Backbone.Model

  url: ->
    if BABS.position
      return '/stations/' + @id + '?latitude=' + BABS.position.coords.latitude + '&longitude=' + BABS.position.coords.longitude
    else
      return '/stations/' + @id


class BABS.Stations extends Backbone.Collection

  url: ->
    if BABS.position
      return '/stations?latitude=' + BABS.position.coords.latitude + '&longitude=' + BABS.position.coords.longitude
    else
      return '/stations'

  model: BABS.Station


class BABS.StationsListView extends Backbone.View

  tagName: 'ul'

  initialize: ->
    @collection.bind 'reset', @render, @

  render: ->
    for model in @collection.models
      $(@el).append new BABS.StationsListItemView({ model: model }).render().el
    return @


class BABS.StationsListItemView extends Backbone.View

  tagName: 'li'

  events: {
    'click': 'clicked'
  }

  render: ->
    template = Handlebars.compile $('#stations_list_item').html()
    $(@el).html template @model.toJSON()
    return @

  clicked: ->
    window.location.hash = @model.get('id')


class BABS.StationView extends Backbone.View

  events: {
    'click .back': 'back'
  }

  render: ->
    template = Handlebars.compile $('#station').html()
    $(@el).html template @model.toJSON()
    return @

  back: ->
    window.location.hash = ''


Handlebars.registerHelper 'prettyDistance', (distance) ->
  if distance < 0.1
    return Math.round(distance*5280) + ' ft'
  else
    return distance.toFixed(1) + ' mi'


$ ->

  BABS.app = new BABS.App

  if Modernizr.geolocation
    navigator.geolocation.getCurrentPosition ((position) ->
      BABS.app.start(position)
    ), (err) ->
      BABS.app.noLocation()  
  else
    BABS.app.noLocation()

  FastClick.attach document.body