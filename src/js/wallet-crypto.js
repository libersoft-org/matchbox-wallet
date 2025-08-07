const crypto = require('crypto');
const ethers = require('ethers');

class CryptoHandler {
    static hash(input) {
        if (!input) {
            throw new Error('Missing input for hash operation');
        }
        
        const hash = crypto.createHash('sha256')
            .update(input)
            .digest('hex');
            
        return {
            status: 'success',
            hash: hash
        };
    }
    
    static generateKeyPair() {
        const { publicKey, privateKey } = crypto.generateKeyPairSync('rsa', {
            modulusLength: 2048,
            publicKeyEncoding: { type: 'spki', format: 'pem' },
            privateKeyEncoding: { type: 'pkcs8', format: 'pem' }
        });
        
        return {
            status: 'success',
            publicKey: publicKey,
            privateKey: privateKey
        };
    }
    
    static generateRandomBytes(length = 32) {
        const bytes = crypto.randomBytes(length);
        return {
            status: 'success',
            bytes: bytes.toString('hex'),
            length: length
        };
    }
    
    static hmac(data, key, algorithm = 'sha256') {
        if (!data || !key) {
            throw new Error('Missing data or key for HMAC operation');
        }
        
        const hmac = crypto.createHmac(algorithm, key)
            .update(data)
            .digest('hex');
            
        return {
            status: 'success',
            hmac: hmac,
            algorithm: algorithm
        };
    }
    
    // Ethereum wallet functions using ethers.js
    static createWallet() {
        const wallet = ethers.Wallet.createRandom();
        return {
            status: 'success',
            address: wallet.address,
            privateKey: wallet.privateKey,
            mnemonic: wallet.mnemonic.phrase
        };
    }
    
    static walletFromMnemonic(mnemonic) {
        if (!mnemonic) {
            throw new Error('Missing mnemonic phrase');
        }
        
        const wallet = ethers.Wallet.fromPhrase(mnemonic);
        return {
            status: 'success',
            address: wallet.address,
            privateKey: wallet.privateKey
        };
    }
    
    static walletFromPrivateKey(privateKey) {
        if (!privateKey) {
            throw new Error('Missing private key');
        }
        
        const wallet = new ethers.Wallet(privateKey);
        return {
            status: 'success',
            address: wallet.address,
            privateKey: wallet.privateKey
        };
    }
    
    static validateAddress(address) {
        try {
            const isValid = ethers.isAddress(address);
            return {
                status: 'success',
                isValid: isValid,
                checksumAddress: isValid ? ethers.getAddress(address) : null
            };
        } catch (error) {
            return {
                status: 'success',
                isValid: false,
                error: error.message
            };
        }
    }
    
    static keccak256(data) {
        if (!data) {
            throw new Error('Missing data for keccak256 hash');
        }
        
        const hash = ethers.keccak256(ethers.toUtf8Bytes(data));
        return {
            status: 'success',
            hash: hash
        };
    }
}

module.exports = CryptoHandler;