sys = require "sys"
spawn = require('child_process').spawn
exec = require('child_process').exec
http = require "http"
send = require "send"
url = require "url"
os = require "os"

nodeModulesPath = "./node_modules"
hemCmd = "#{nodeModulesPath}/hem/bin/hem"
coffeeCmd = "#{nodeModulesPath}/coffee-script/bin/coffee"
jasmineNodeCmd = "#{nodeModulesPath}/jasmine-node/bin/jasmine-node"

selenium = require "./acceptanceTest/seleniumserver"

printOut = (msg, header = false) ->
    console.log "##############################################################" if header
    console.log msg
    console.log "##############################################################" if header

runCmd = (cmd, args, callback, local = false) ->
    isWindows = os.platform().match /^win/
    if isWindows
        args.unshift cmd
        args.unshift "node" if local
        cmd = args.join " "
        execProcess cmd, callback
    else
        spawnProcess cmd, args, callback

runLocalCmd = (cmd, args, callback) ->
    runCmd cmd, args, callback, true

spawnProcess = (cmd, args, callback) ->
    c = spawn cmd, args
    c.stdout.setEncoding('utf8')
    c.stdout.on "data", (data) ->
        process.stdout.write data
    c.stderr.setEncoding('utf8')
    c.stderr.on "data", (data) ->
        process.stdout.write data
    c.on "exit", (code) ->
        callback?()

execProcess = (cmd, callback) ->
    exec cmd, (err, stdout, stderr) ->
        printOut "'#{cmd}': stdout: #{stdout}\nstderr: #{stderr}"
        printOut "'#{cmd}': ERROR: #{err}" if err
        callback?()

###
We need to serve the files in the public folder because
the codeReceiver tests rely on the ability to load the
codeReceiver.html in an iFrame.
###
codeReceiverServer = null
startCodeReceiverServer = (port) ->
    codeReceiverServer = http.createServer (req, res) ->
        error = (err) ->
            res.statusCode = err.status || 500
            res.end err.message
        redirect = ->
            res.statusCode = 301
            res.setHeader "Location", req.url + "/"
            res.end "Redirecting to " + req.url + "/"
        send(req, url.parse(req.url).pathname)
            .root("./public")
            .on("error", error)
            .on("directory", redirect)
            .pipe(res)
    codeReceiverServer.listen port

build = (args, callback) ->
    args or= []
    args.unshift "build"
    runLocalCmd hemCmd, args, callback

appServer = (callback) ->
    console.log "Starting app server"
    runLocalCmd coffeeCmd, ["server.coffee"], callback

task "build", "build app", ->
    build ["-d"]

task "build:minify", "build and minify the app", ->
    build()

task "server", "serve the app", ->
    appServer()

task "server:rebuild", "rebuild then serve the app", ->
    build ["-d"], -> appServer()
        
task "test:unit", "build app then run all jasmine unit tests", ->
    startCodeReceiverServer 8878
    printOut "Building application", true
    build ["-d"], ->
        printOut "Running tests", true
        runCmd "testacular", ["run"], ->
            process.exit(0)

task "test:server", "runs unit tests for the server component", ->
    runLocalCmd jasmineNodeCmd, ["--test-dir", "serverTest", "--coffee"]

task "test:acceptance", "Runs webdriver acceptance tests. Requires selenium server and phantomJS", ->
    printOut "RUNNING ACCEPTANCE TESTS", true
    appServer()
    srv = new selenium()
    srv.start ->
        printOut "RUNNING ACCEPTANCE TESTS"
        runLocalCmd jasmineNodeCmd, ["--test-dir", "acceptanceTest", "--coffee"], ->
            srv.stop ->
                printOut "ACCEPTANCE TESTS COMPLETE", true
                process.exit(0)