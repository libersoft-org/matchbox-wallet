// Simple bootstrap code - filesystem only
(function(require) {
  try {
    const module = require('module');
    const path = require('path');
    
    // Set up standard Node.js require for src/js directory
    // Create require context pointing to the actual src/js directory  
    const srcJsPath = '/home/koom/repos/libersoft-org/matchbox-wallet/0/matchbox-wallet/src/js/index.js';
    const publicRequire = module.createRequire(srcJsPath);
    globalThis.require = publicRequire;
    
  } catch (e) {
    console.error('Bootstrap error:', e.message);
    throw e;
  }
})