// Simple wrapper for Node.js communication
function msg(action, params, callback) {
    console.log('NodeUtils.msg', action, params)
    NodeJS.msg(action, params || {}, function(resultJson) {
        var result = JSON.parse(resultJson)
        callback(result)
    })
}