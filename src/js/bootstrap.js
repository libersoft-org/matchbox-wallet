// Universal bootstrap code - transparent QRC/filesystem loading
// JavaScript code never knows whether files come from QRC or filesystem
(function(require) {
  try {
    const module = require('module');
    const publicRequire = module.createRequire('%1/');
    
    // Use standard Node.js require - QRC/filesystem transparency handled by C++
    globalThis.require = publicRequire;
  } catch (e) {
    console.error('Bootstrap error:', e.message);
    throw e;
  }
})