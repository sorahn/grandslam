express = require 'express'
hd = require 'hdhomerun'
_ = require 'lodash'
jade_static = require 'jade-static'
proc = require('child_process')
app = express()
active = {}
vlc = {}

noActive = (r) -> r.send "no active device", 404

app.use jade_static "views"
app.use express.static "#{__dirname}"

app.get '/discover', (q, r) ->
  hd.discover (err, res) ->
    r.send res

app.get '/create/:id/:ip', (q, r) ->
  id = q.param('id')

  conf =
    device_ip: q.param('ip')
    device_id: id

  active = hd.create conf
  out =
    device_id: active.device_id

  r.send out

app.get '/set/:command/:action/:value', (q, r) ->
  query = "/#{q.param('command')}/#{q.param('action')}"

  unless active.device_id
    noActive r
  else
    active.set query, q.param('value'), (err, res) ->
      if err
        r.send err, 404
        console.error(err)
      else r.send res

app.get '/get/:command/:action', (q, r) ->
  query = "/#{q.param('command')}/#{q.param('action')}"

  unless active.device_id
    noActive r
  else
    active.get query, (err, res) ->
      if err
        r.send err, 404
        console.error(err)
      else r.send res


app.get '/vlc/start', (q, r) ->
  vlc = proc.exec '/Applications/VLC.app/Contents/MacOS/VLC', ['udp://@:5000']

  out =
    pid: vlc.pid

  r.send out

app.get '/vlc/kill/?:pid', (q, r) ->
  pid = vlc.pid || q.param('pid')

  if pid
    kill = proc.exec 'kill', ['-9', pid]
    console.log "killing pid #{pid}"
  r.send()

app.listen 3000
console.log 'listening on port 3000'
