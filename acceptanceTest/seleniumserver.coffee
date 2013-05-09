exec = require("child_process").exec
spawn = require("child_process").spawn
os = require "os"
path = require "path"
fs = require "fs"
http = require "http"

wd      = require "wd"

class SeleniumServer
    executableFile = "selenium-server-standalone-2.31.0.jar"
    executableFolder = "./acceptanceTest/bin/"
    executableCommand = "java -jar"
    executableDownloadUrl = "http://selenium.googlecode.com/files/"
    ghostDriverCommand  = "phantomjs --webdriver=8080 --webdriver-selenium-grid-hub=http://127.0.0.1:4444"

    serverModes:
        standard:
            options: ""
            driver: "firefox"
        chrome:
            options: "-role hub"
            driver: "chrome"            
        phantomjs:
            options: "-role hub"
            driver: "phantomjs"

    constructor: (mode) ->
        @mode = @serverModes.standard
        @mode = @serverModes[mode] if mode?
        @seleniumServerCommand = "#{executableCommand} #{path.join(process.cwd(), executableFolder, executableFile)} #{@mode.options}"

    start: (cb) ->
        @checkForBinary =>
            @stop =>
                @spawn cb

    stop: (cb) ->
        isWindows = os.platform().match /^win/
        if isWindows
            killCommand = "#{path.join(process.cwd(), executableFolder)}kill_selenium_process.ps1"
            killSelenium = spawn "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe", ["-Command", killCommand]
            killSelenium.on "exit", ->
                cb()
            killSelenium.stdin.end()
        else
            @getProcessId (pid) =>
                if pid? and pid isnt ""
                    exec "kill #{pid}", (err, stdout, stderr) -> 
                        if err
                            console.log "Error killing Selenium server process #{pid} #{err}"        
                        cb()
                else
                    cb()

    spawn: (cb) ->
        spawnSelArgs = @seleniumServerCommand.split(" ")
        spawnSelenium = spawn(spawnSelArgs[0], spawnSelArgs[1..])
        spawnSelenium.stderr.on "data", (data) =>
            if (data.toString().indexOf("INFO:osjs.AbstractConnector:Started") >= 0)
                if @mode is @serverModes.phantomjs
                    @startGhostDriver cb
        spawnSelenium.stdout.on "data", (data) =>
            if (data.toString().indexOf("INFO - Started org.openqa.jetty.jetty.Server") >= 0)
                cb()

    exec: (cb) ->
        startCommand = =>
            console.log "Starting Selenium Server"
            selenium = exec @seleniumServerCommand, (err, stdout, stderr) ->
                if err then console.log err 
                console.log "Selenium Server process terminated."
        serverReady = (cb) =>
            console.log "Waiting for Selenium server to become responsive"
            ready = false
            startGhostDriver = (cb) ->
                console.log "Starting Ghostdriver"
                exec ghostDriverCommand, (err, stdout, stderr) ->
                cb()
            tryConnect = =>
                console.log "Testing server connection"
                driver = wd.remote()
                driverOptions = browserName: @mode.driver
                driver.init driverOptions, (err, sessionid) ->
                    if !err and sessionid?
                        console.log "Server responsive. Continuing..."
                        clearInterval intervalId
                        cb()
                    else
                        console.log "Server not yet available."
                    driver.quit()
            intervalId = setInterval tryConnect, 5000
        startSequence = (cb) ->
            startCommand()
            serverReady cb

        # Run the start command
        @getProcessId (pid) =>
            if pid?
                @stop ->
                    startSequence cb
            else
                startSequence cb

    startGhostDriver: (cb) ->
        spawnGhostArgs = ghostDriverCommand.split(" ")
        for arg in spawnGhostArgs 
            console.log "#{arg}"
        spawnGhostDriver = spawn(spawnGhostArgs[0], spawnGhostArgs[1..])
        spawnGhostDriver.stdout.on "data", (data) ->
            if (data.toString().indexOf("Registered with grid hub: http://127.0.0.1:4444/ (ok)") >= 0)
                cb()
        spawnGhostDriver.on "exit", (code) =>
            @stop cb

    getProcessId: (cb) =>
        isWindows = os.platform().match /^win/
        if isWindows
            getProcessCommand = "#{path.join(process.cwd(), executableFolder)}get_selenium_process.ps1"
            getWindowsProcessId = spawn "powershell.exe", ["-Command", getProcessCommand]
            getWindowsProcessId.stdout.on "data", (stdoutdata) ->
                if not isNaN parseInt stdoutdata
                    getWindowsProcessId.processId = stdoutdata
            getWindowsProcessId.on "exit", ->
                cb getWindowsProcessId.processId
            getWindowsProcessId.stdin.end()
        else
            processName = "selenium-server-standalone"
            if os.platform() is "linux" then processName = "java"
            exec "ps -A | grep #{processName} | grep -v grep | awk '{print $1}'", (err, stdout, stderr) ->
                cb stdout.split("\n")[0] # Assume it's the first ID we found

    checkForBinary: (cb) ->
        fs.stat "#{executableFolder}#{executableFile}", (err, stats) ->
            if stats?
                cb()
            else
                console.log "Downloading selenium server binary, please wait..."
                http.get "#{executableDownloadUrl}#{executableFile}", (res) ->
                    res.on "end", cb
                    fileStream = fs.createWriteStream "#{executableFolder}#{executableFile}"
                    res.pipe fileStream

 module.exports = SeleniumServer