webdriver = require "wd"
assert = require "assert"

wdh = require "./webdriver_helper"

rootURL = "http://localhost:9294"
driverOptions =
    browserName : "firefox"
acceptableTimeout = 20000 # Long timeout needed to allow Firefox to startup

# Test Fixtures
describe "HAPI CMS homepage", ->
    driver = null
    beforeEach ->
        driverInitialised = false
        runs ->
            driver = webdriver.promiseRemote()
            #driver.init driverOptions, (err, sessionid) ->
            driverInitialised = true
        waitsFor (-> driverInitialised), "Initialising webdriver", acceptableTimeout
    afterEach ->
        driver.quit()

    it "should accept valid login details", ->
        finished = false
        foundAppWrapper = false
        username = ""
        pazzwrd = ""
        runs ->
            helper = new wdh();
            driver.init(driverOptions)
            .then(-> driver.get rootURL)
            .then(-> driver.frame 0)
            .then(-> helper.setElementValueByCss driver, "#Username", "")
            .then(-> helper.setElementValueByCss driver, "#Password", "")
            .then(-> driver.elementByCss "#login-btn")
            .then((el) -> el.click())
            .then(-> driver.frame null)
            .then(-> driver.elementByCss "div.hzt-app-wrapper")
            .then((el) -> foundAppWrapper = el?)
            .fin(-> finished = true)
            .done()
        waitsFor (-> finished), "whatever", acceptableTimeout
        runs ->
            expect(foundAppWrapper).toBe(true)

    it "should reject invalid login details", ->
        finished = false
        username = "ebeneezer"
        pazzwrd = "good"
        errorMessageVisible = false
        runs ->
            helper = new wdh();
            driver.init(driverOptions)
            .then(-> driver.get rootURL)
            .then(-> driver.frame 0)
            .then(-> helper.setElementValueByCss driver, "#Username", username)
            .then(-> helper.setElementValueByCss driver, "#Password", pazzwrd)
            .then(-> driver.elementByCss "#login-btn")
            .then((el) -> el.click())
            .then(-> driver.waitForVisibleByCssSelector "#validation-message", acceptableTimeout)
            .then(-> driver.waitForVisibleByCssSelector ".field-validation-error", acceptableTimeout)
            .then((err) -> errorMessageVisible = true unless err)
            .fin(-> finished = true)
            .done()
        waitsFor (-> finished), "server to reject login attempt", acceptableTimeout
        runs -> expect(errorMessageVisible).toBe(true)

    it "should display the current version of the CMS", ->
        finished = false
        versionNumber = ""
        runs ->
            driver.init(driverOptions)
            .then(-> driver.get rootURL)
            .then(-> driver.elementByCssSelector ".product-detail .version")
            .then((versionElement) -> versionElement.text())
            .then((value) -> versionNumber = value)
            .fin(-> finished = true)
            .done()
        waitsFor (-> finished), "the hompage to load", acceptableTimeout
        runs ->
            versionStringPattern = /v\s\d{1,3}\.\d{1,3}\.\d{1,3}/ # pattern when deployed on a server
            localhostVersionStringPattern = /v\.\s0\.x\.x/ # pattern when running in development monde on localhost
            versionNumberShowing = versionNumber.match(versionStringPattern) isnt null or versionNumber.match(localhostVersionStringPattern) isnt null
            expect(versionNumberShowing).toBe(true)
