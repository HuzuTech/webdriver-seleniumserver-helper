class WebDriverHelper
    constructor: () ->

    # Helper methods
    setElementValueByCss : (webDriver, cssSelector, value, callback) ->
        try
            webDriver.elementByCss cssSelector, (err, element) -> 
                webDriver.type element, value, (err) -> callback()
        catch exc 
            console.log "Error setting value of page element: #{exc.message}"

module.exports = WebDriverHelper