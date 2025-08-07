const CryptoHandler = require('./crypto');
const fs = require('fs');
const path = require('path');

global.handleMessage = function(message, callback) {
    console.log('Received message from C++:', JSON.stringify(message, null, 2));
    
    try {
        const { action, data } = message;
        let result = {};
        
        switch (action) {
            case 'ping':
                result = { 
                    status: 'success', 
                    message: 'pong',
                    timestamp: Date.now() 
                };
                break;
                
            case 'hash':
                try {
                    result = CryptoHandler.hash(data?.input);
                } catch (error) {
                    result = { 
                        status: 'error', 
                        message: error.message 
                    };
                }
                break;
                
            case 'generateKeyPair':
                try {
                    result = CryptoHandler.generateKeyPair();
                } catch (error) {
                    result = { 
                        status: 'error', 
                        message: error.message 
                    };
                }
                break;
                
            case 'generateRandomBytes':
                try {
                    result = CryptoHandler.generateRandomBytes(data?.length);
                } catch (error) {
                    result = { 
                        status: 'error', 
                        message: error.message 
                    };
                }
                break;
                
            case 'hmac':
                try {
                    result = CryptoHandler.hmac(data?.data, data?.key, data?.algorithm);
                } catch (error) {
                    result = { 
                        status: 'error', 
                        message: error.message 
                    };
                }
                break;
                
            default:
                result = { 
                    status: 'error', 
                    message: `Unknown action: ${action}` 
                };
        }
        
        if (typeof __nativeCallback === 'function') {
            __nativeCallback(result);
        }
        
    } catch (error) {
        const errorResult = {
            status: 'error',
            message: error.message,
            stack: error.stack
        };
        
        if (typeof __nativeCallback === 'function') {
            __nativeCallback(errorResult);
        }
    }
};

console.log('Matchbox Wallet JavaScript runtime initialized');
console.log('Available actions: ping, hash, generateKeyPair, generateRandomBytes, hmac');