// Now we can use regular require with proper file system access
const CryptoHandler = require('./wallet-crypto');
const fs = require('fs');
const path = require('path');

global.handleMessage = async function(message, callback) {
    console.log('node.js handleMessage ', JSON.stringify(message, null, 2));
    
    try {
        const { messageId, action, data } = message;
        let result = {};
        
        switch (action) {
            case 'ping':
                result = { 
                    status: 'success', 
                    message: 'pong',
                    timestamp: Date.now() 
                };
                break;
                
            case 'delayedPing':
                const delay = data?.delay || 2000;
                console.log(`Starting delayed ping with ${delay}ms delay...`);
                result = await new Promise(resolve => {
                    setTimeout(() => {
                        console.log('Delayed ping completed!');
                        resolve({
                            status: 'success',
                            message: 'delayed pong',
                            timestamp: Date.now(),
                            delay: delay
                        });
                    }, delay);
                });
                break;
                
            case 'hash':
                result = CryptoHandler.hash(data?.input);
                break;
                
            case 'generateKeyPair':
                result = CryptoHandler.generateKeyPair();
                break;
                
            case 'generateRandomBytes':
                result = CryptoHandler.generateRandomBytes(data?.length);
                break;
                
            case 'hmac':
                result = CryptoHandler.hmac(data?.data, data?.key, data?.algorithm);
                break;
                
            case 'createWallet':
                result = CryptoHandler.createWallet();
                break;
                
            case 'walletFromMnemonic':
                result = CryptoHandler.walletFromMnemonic(data?.mnemonic);
                break;
                
            case 'walletFromPrivateKey':
                result = CryptoHandler.walletFromPrivateKey(data?.privateKey);
                break;
                
            case 'validateAddress':
                result = CryptoHandler.validateAddress(data?.address);
                break;
                
            case 'keccak256':
                result = CryptoHandler.keccak256(data?.input);
                break;
                
            case 'getLatestBlock':
                console.log('CryptoHandler.getLatestBlock...:', data?.rpcUrl);
                result = await CryptoHandler.getLatestBlock(data?.rpcUrl);
                break;
                
            case 'getBalance':
                result = await CryptoHandler.getBalance(data?.address, data?.rpcUrl);
                break;
                
            default:
                result = { 
                    status: 'error', 
                    message: `Unknown action: ${action}` 
                };
        }
        
        if (typeof __nativeCallback === 'function') {
            __nativeCallback(messageId, result);
        }
        
    } catch (error) {
        const errorResult = {
            status: 'error',
            message: error.message,
            stack: error.stack
        };
        
        if (typeof __nativeCallback === 'function') {
            __nativeCallback(messageId, errorResult);
        }
    }
};

console.log('Matchbox Wallet JavaScript runtime initialized');
console.log('Available actions: ping, delayedPing, hash, generateKeyPair, generateRandomBytes, hmac, createWallet, walletFromMnemonic, walletFromPrivateKey, validateAddress, keccak256, getLatestBlock, getBalance');