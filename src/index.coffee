exec = require('child_process').exec
os = require('os')
path = require('path')


class Idle

    ### Private ###

    listeners: null

    ### Public ###

    constructor: ->
        @listeners = []

    # Adds a listener which checks if user is away from keyboard.
    # If they are away for long than shouldSeconds, callback is called.
    # :shouldSeconds - {number} , how many seconds the user is afk before callback is called
    # :callback - {function} , function called after shouldSeconds
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

    # Removes away from keyboard listener
    # :listenerId - {number}
    removeListener: (listenerId) =>
        @listeners[listenerId] = false
        return true

    ### Private ###

    # compares isSeconds and shouldSeconds
    # :isSeconds - {number} , how many seconds user is afk
    # :shouldSeconds - {number} , how many seconds user should be afk before function is called
    whenToCheck: (isSeconds, shouldSeconds) ->
        whenSeconds = shouldSeconds - isSeconds
        return if whenSeconds > 0 then whenSeconds else 0

    # counts how long user is afk in seconds
    # :callback - {function}
    tick: (callback) ->
        callback ?= ->

        if /^win/.test process.platform
            cmd = '"' + path.join(__dirname, 'bin', 'idle.exe') + '"'
            exec cmd, (error, stdout, stderr) ->
                if error
                    callback(0, error)
                    return
                callback Math.floor(parseInt(stdout, 10) / 1000), null

        else if /darwin/.test process.platform
            cmd = '/usr/sbin/ioreg -c IOHIDSystem | /usr/bin/awk \'/HIDIdleTime/ {print int($NF/1000000000); exit}\''
            exec cmd, (error, stdout, stderr) ->
                if error
                    callback(0, error)
                    return
                callback parseInt(stdout, 10), null

        else if /linux/.test(process.platform)
            cmd = 'xprintidle'
            exec cmd, (error, stdout, stderr) ->
                if error
                    callback(0, error)
                    return
                callback Math.round(parseInt(stdout, 10) / 1000), null

        else
            callback(0)

module.exports = new Idle()
