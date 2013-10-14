require.config
  paths:
    jquery: '../bower_components/jquery/jquery'
    bootstrap: '//netdna.bootstrapcdn.com/bootstrap/3.0.0/js/bootstrap'
    handlebars: '../bower_components/handlebars/handlebars'
    hammer: '../bower_components/hammerjs/dist/jquery.hammer'

  shim:
    bootstrap:
      deps: ['jquery']
      exports: 'jquery'

    handlebars:
      exports: 'Handlebars'

    hammer:
      deps: ['jquery']
      exports: 'jquery'

require ['jquery', 'handlebars', 'hammer'], ($, hb) ->
  active = discover = {}
  $main = $('#js-main')

  updateStatus = (_str, _class, _obj) ->
    $status = $('#js-status')
    $status.text(_str)
    $status.attr('class', "text-#{_class}") if _class
    logMessage _str, _obj

  logMessage = (_str, _pkg, _level) ->
    console[_level || "log"] _str, (_pkg if _pkg)

  ajaxMessage = (_data, _status, _xhr) ->
    logMessage _xhr, _data, _status

  discoverDevices = (_id) ->
    $.getJSON('/discover')
      .done (_data) ->
        device = _data[0]
        discover[device.device_id] = device
        updateStatus('waiting...', false, device)

        template = hb.compile $('#jst-alert').html()
        $main.html template device

  createDevice = ->
    id = $(this).data('id')
    $.getJSON("/create/#{id}/#{discover[id].device_ip}")
      .done (_data) ->
        active = discover[_data.device_id]
        updateStatus("connected to #{id}!", 'success', active)
        $main.find('.js-alert').remove()

        updateDeviceInfo()

        template = hb.compile $('#jst-device').html()
        $main.append template active

  updateDeviceInfo = ->
    updateHwModel()
    # updateTunerStatus(0)
    # updateTunerStatus(1)

  updateTunerStatus = (n) ->
    tuner = "tuner#{n}"
    $tuner = $.getJSON("/get/#{tuner}/status")
    $tuner.fail ajaxMessage
    $tuner.done (data) ->
      active[tuner] = data
      logMessage "update #{tuner} status", data

  updateHwModel = () ->
    $.getJSON("/get/sys/hwmodel")
      .done (data) ->
        active.hwmodel = data
        logMessage 'updated /sys/hwmodel', data

  tuneChannel = (e) ->
    channel = $(this).data 'channel'
    tuner = "tuner0"
    $tuner = $.getJSON("set/#{tuner}/channel/#{channel}")
    $tuner.done (data) ->
      console.log "tuned channel #{channel}"
      updateTunerStatus(0)

  setTarget = (e) ->
    tuner = "tuner0"
    ip = '10.0.0.24:5000'
    $tuner = $.getJSON("set/#{tuner}/target/#{ip}")
    $tuner.done (data) ->
      console.log "targeted computer #{ip}"
      updateTunerStatus(0)

  discoverDevices()
  $main.hammer().on 'tap', '#js-connect', createDevice
  $main.hammer().on 'tap', '.js-channel', tuneChannel
