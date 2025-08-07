#!/usr/bin/env node

// Standalone test to verify ethers.js functionality outside embedded environment
console.log('Starting standalone Node.js test...');
console.log('Node.js version:', process.version);

// Import the index.js module which sets up global.handleMessage
require('./index.js');

// Mock the native callback function that would normally be provided by C++
global.__nativeCallback = function(result) {
    console.log('Callback received result:', JSON.stringify(result, null, 2));
    
    // Exit after receiving result
    setTimeout(() => {
        console.log('Test completed, exiting...');
        process.exit(0);
    }, 100);
};

// Test the async functionality
console.log('Testing getLatestBlock...');

const testMessage = {
    action: 'getLatestBlock',
    data: {}
};

// Call the global handleMessage function
global.handleMessage(testMessage);

// Set a timeout to prevent hanging indefinitely
setTimeout(() => {
    console.log('Test timed out after 30 seconds');
    process.exit(1);
}, 30000);

console.log('Test initiated, waiting for results...');