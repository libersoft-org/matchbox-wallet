// Simple wrapper for Node.js communication
function msg(action, params, callback) {
	console.log('NodeUtils.msg', action, params);
	NodeJS.msg(action, params || {}, function (resultJson) {
		console.log('NodeUtils callback received JSON:', resultJson);
		try {
			var result = JSON.parse(resultJson);
			console.log('NodeUtils JSON parsed successfully:', JSON.stringify(result));
			callback(result);
		} catch (e) {
			console.error('NodeUtils JSON parse error:', e.message);
			console.error('Raw JSON was:', resultJson);
		}
	});
}
