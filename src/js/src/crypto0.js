const crypto0 = require('crypto');

// Lazy-load ethers to avoid module loading issues in embedded environment
let ethers = null;
function getEthers() {
	if (!ethers) {
		console.log('Lazy-loading ethers library...');
		ethers = require('ethers');
		console.log('ETHERS:', ethers);
		console.log('ETHERS.VERSION:', ethers.version);
	}
	return ethers;
}

class CryptoManager {
	hash(params = {}) {
		const input = params?.input;
		if (!input) {
			throw new Error('Missing input for hash operation');
		}

		const hash = crypto0.createHash('sha256').update(input).digest('hex');

		return {
			status: 'success',
			hash: hash,
		};
	}

	generateKeyPair() {
		const { publicKey, privateKey } = crypto0.generateKeyPairSync('rsa', {
			modulusLength: 2048,
			publicKeyEncoding: { type: 'spki', format: 'pem' },
			privateKeyEncoding: { type: 'pkcs8', format: 'pem' },
		});

		return {
			status: 'success',
			publicKey: publicKey,
			privateKey: privateKey,
		};
	}

	generateRandomBytes(params = {}) {
		const length = params?.length || 32;
		const bytes = crypto0.randomBytes(length);
		return {
			status: 'success',
			bytes: bytes.toString('hex'),
			length: length,
		};
	}

	hmac(params = {}) {
		const data = params?.data;
		const key = params?.key;
		const algorithm = params?.algorithm || 'sha256';

		if (!data || !key) {
			throw new Error('Missing data or key for HMAC operation');
		}

		const hmac = crypto0.createHmac(algorithm, key).update(data).digest('hex');

		return {
			status: 'success',
			hmac: hmac,
			algorithm: algorithm,
		};
	}

	// Ethereum wallet functions using ethers.js
	createWallet() {
		const ethers = getEthers();
		const wallet = ethers.Wallet.createRandom();
		return {
			status: 'success',
			address: wallet.address,
			privateKey: wallet.privateKey,
			mnemonic: wallet.mnemonic.phrase,
		};
	}

	walletFromMnemonic(params = {}) {
		const mnemonic = params?.mnemonic;
		if (!mnemonic) {
			throw new Error('Missing mnemonic phrase');
		}

		const ethers = getEthers();
		const wallet = ethers.Wallet.fromPhrase(mnemonic);
		return {
			status: 'success',
			address: wallet.address,
			privateKey: wallet.privateKey,
		};
	}

	walletFromPrivateKey(params = {}) {
		const privateKey = params?.privateKey;
		if (!privateKey) {
			throw new Error('Missing private key');
		}

		const ethers = getEthers();
		const wallet = new ethers.Wallet(privateKey);
		return {
			status: 'success',
			address: wallet.address,
			privateKey: wallet.privateKey,
		};
	}

	validateAddress(params = {}) {
		const address = params?.address;
		try {
			const ethers = getEthers();
			const isValid = ethers.isAddress(address);
			return {
				status: 'success',
				isValid: isValid,
				checksumAddress: isValid ? ethers.getAddress(address) : null,
			};
		} catch (error) {
			return {
				status: 'success',
				isValid: false,
				error: error.message,
			};
		}
	}

	keccak256(params = {}) {
		const data = params?.input;
		if (!data) {
			throw new Error('Missing data for keccak256 hash');
		}

		const ethers = getEthers();
		const hash = ethers.keccak256(ethers.toUtf8Bytes(data));
		return {
			status: 'success',
			hash: hash,
		};
	}

	// Async function to get latest block from Ethereum mainnet
	async getLatestBlock(params = {}) {
		const rpcUrl = params?.rpcUrl;
		console.log('CryptoHandler.getLatestBlock...:', rpcUrl);
		console.log('Checking network capabilities...');

		// Check what networking globals are available
		console.log('typeof fetch:', typeof fetch);
		console.log('typeof XMLHttpRequest:', typeof XMLHttpRequest);
		console.log('process.versions.node:', process.versions.node);

		try {
			console.log('Testing fetch functionality...');
			const testResponse = await fetch('https://httpbin.org/json');
			const testData = await testResponse.json();
			console.log('Fetch test successful, received data keys:', Object.keys(testData));

			console.log('Creating ethers.JsonRpcProvider...');
			const ethers = getEthers();
			const provider = new ethers.JsonRpcProvider('https://ethereum-rpc.publicnode.com');
			console.log('Provider created successfully');

			console.log('Attempting to fetch latest block...');
			const block = await provider.getBlock('latest');

			return {
				status: 'success',
				blockNumber: block.number,
				blockHash: block.hash,
				timestamp: block.timestamp,
				gasUsed: block.gasUsed.toString(),
				gasLimit: block.gasLimit.toString(),
				transactionCount: block.transactions.length,
			};
		} catch (error) {
			console.error('Network error:', error.message);
			return {
				status: 'error',
				message: `Network error: ${error.message}`,
				capabilities: {
					fetch: typeof fetch,
					XMLHttpRequest: typeof XMLHttpRequest,
					nodeVersion: process.versions.node,
				},
			};
		}
	}

	// Async function to get ETH balance for an address
	async getBalance(params = {}) {
		const address = params?.address;
		const rpcUrl = params?.rpcUrl;

		if (!address) {
			throw new Error('Missing address for balance query');
		}

		const ethers = getEthers();
		console.log('ETHERS:', ethers);
		console.log('ETHERS.VERSION:', ethers.version);
		const provider = new ethers.JsonRpcProvider(rpcUrl || 'https://eth.llamarpc.com');
		console.log('PROVIDER:', provider);

		const balance = await provider.getBalance(address);
		return {
			status: 'success',
			address: address,
			balanceWei: balance.toString(),
			balanceEth: ethers.formatEther(balance),
		};
	}
}

module.exports = CryptoManager;
