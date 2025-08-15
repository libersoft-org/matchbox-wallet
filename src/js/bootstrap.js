// Bootstrap that loads our CommonJS bundle using Node.js require()
(function(require) {
    console.log('Bootstrap: Loading CommonJS bundle via Node.js require()');
    
    try {
        // Use Node.js require() to load our bundled CommonJS module
        // The bundle will set up global.handleMessage
        // Use absolute path since relative paths are problematic in embedded context
        console.log('Bootstrap: Attempting to require bundle from: ../../src/js/dist/bundle.cjs');
        require('../../src/js/dist/bundle.cjs');
        console.log('Bootstrap: CommonJS bundle loaded successfully');
    } catch (error) {
        console.error('Bootstrap: Failed to require bundle:', error.message);
        console.error('Bootstrap: Error stack:', error.stack);
    }
    
    // Return a dummy function since the real work is done by the bundle
    return function() {
        return {};
    };
});