// Simple bootstrap - let the C++ code handle the bundle directly
(function(require) {
    console.log('Bootstrap: Minimal bootstrap - bundle should be loaded directly by C++');
    
    // Return a dummy function - the real handleMessage will be set by the bundle
    return function() {
        console.log('Bootstrap function called - this should not happen with bundled approach');
        return {};
    };
});