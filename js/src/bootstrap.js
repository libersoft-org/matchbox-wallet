// Simple bootstrap code - filesystem only
(function (require) {
	try {
		const module = require('module');
		const path = require('path');

		// Set up standard Node.js require for js directory
		// Create require context pointing to the actual source directory
		// Go up from build directory to find js
		const buildDir = process.cwd();
		const srcJsPath = path.resolve(buildDir, '..', '..', 'src', 'js', 'index.js');
		const publicRequire = module.createRequire(srcJsPath);
		globalThis.require = publicRequire;
	} catch (e) {
		console.error('Bootstrap error:', e.message);
		throw e;
	}
});
