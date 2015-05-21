exec = require('child_process').exec
os = require('os')
path = require('path')

class Idle
    listeners: null

    constructor: ->
        @listeners = []

    tick: (callback) ->
        callback ?= ->

        if /^win/.test process.platform
            cmd = '"' + path.join(__dirname, 'bin', 'idle.exe') + '"'
            exec cmd, (error, stdout, stderr) ->
                if error
                    calback(0, error)
                    return
                callback Math.floor(parseInt(stdout, 10) / 1000), null

        else if /darwin/.test process.platform
            cmd = '/usr/sbin/ioreg -c IOHIDSystem | /usr/bin/awk \'/HIDIdleTime/ {print int($NF/1000000000); exit}\''
            exec cmd, (error, stdout, stderr) ->
                if error
                    calback(0, error)
                    return
                callback parseInt(stdout, 10), null

        else if /linux/.test(process.platform)
            cmd = 'xprintidle'
            exec cmd, (error, stdout, stderr) ->
                if error
                    calback(0, error)
                    return
                callback Math.round(parseInt(stdout, 10) / 1000), null

        else
            callback(0)

    addListener: (shouldSeconds, callback) =>
        isAfk = false
        listenerId = @listeners.push(true) - 1
        timeoutRef = null
        checkIsAway = =>
            unless @listeners[listenerId]
                clearTimeout(timeoutRef)
                return
            @tick (isSeconds) =>
                whenSeconds = @whenToCheck(isSeconds, shouldSeconds)
                s = 1000

                if whenSeconds is 0 and not isAfk
                    callback
                        status: 'away'
                        seconds: isSeconds
                        id: listenerId
                    isAfk = true
                    timeoutRef = setTimeout(checkIsAway, s)

                else if isAfk and whenSeconds > 0
                    callback
                        status: 'back'
                        seconds: isSeconds
                        id: listenerId
                    isAfk = false
                    timeoutRef = setTimeout(checkIsAway, whenSeconds*s)

                else if whenSeconds > 0 and not isAfk
                    timeoutRef = setTimeout(checkIsAway, whenSeconds * s)

                else
                    timeoutRef = setTimeout(checkIsAway, s)

        checkIsAway()
        return listenerId

    removeListener: (listenerId) =>
        @listeners[listenerId] = false
        return true

    whenToCheck: (isSeconds, shouldSeconds) ->
        whenSeconds = shouldSeconds - isSeconds
        return if whenSeconds > 0 then whenSeconds else 0

module.exports = new Idle()