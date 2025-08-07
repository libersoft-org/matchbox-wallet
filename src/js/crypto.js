const crypto = require('crypto');

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
}

module.exports = CryptoHandler;