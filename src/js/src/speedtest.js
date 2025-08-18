import https from 'https';
import http from 'http';
import { performance } from 'perf_hooks';
import { URL } from 'url';

// Helper to fetch a URL and measure bytes/time with cutoff
function downloadUrl(url, maxSeconds = 5) {
	return new Promise((resolve, reject) => {
		const start = performance.now();
		let bytes = 0;
		let finished = false;
		const u = new URL(url);
		const lib = u.protocol === 'http:' ? http : https;

		// Force cutoff after maxSeconds
		const cutoffTimer = setTimeout(() => {
			if (!finished) {
				finished = true;
				const duration = (performance.now() - start) / 1000;
				console.log('Download force cutoff at', duration, 's, bytes:', bytes);
				try {
					req.destroy();
				} catch (e) {}
				resolve({ bytes, duration, cut: true });
			}
		}, maxSeconds * 1000);

		const req = lib.get(u, (res) => {
			if (res.statusCode && res.statusCode >= 400) {
				clearTimeout(cutoffTimer);
				finished = true;
				return reject(new Error('HTTP ' + res.statusCode));
			}
			res.on('data', (chunk) => {
				if (!finished) {
					bytes += chunk.length;
				}
			});
			res.on('end', () => {
				if (!finished) {
					finished = true;
					clearTimeout(cutoffTimer);
					const end = performance.now();
					const duration = (end - start) / 1000;
					resolve({ bytes, duration, cut: false });
				}
			});
		});
		req.on('error', (e) => {
			if (!finished) {
				finished = true;
				clearTimeout(cutoffTimer);
				reject(e);
			}
		});
		req.setTimeout(maxSeconds * 1000 + 1000, () => {
			if (!finished) {
				finished = true;
				clearTimeout(cutoffTimer);
				try {
					req.destroy();
				} catch (e) {}
				const duration = (performance.now() - start) / 1000;
				resolve({ bytes, duration, cut: true });
			}
		});
	});
}

// Upload: send random buffer continuously until cutoff time reached
function uploadTest(url, totalSizeBytes = Infinity, maxSeconds = 5) {
	return new Promise((resolve, reject) => {
		const start = performance.now();
		let sent = 0;
		let finished = false;
		const chunk = Buffer.alloc(256 * 1024, 'x'); // 256KB
		const u = new URL(url);
		const lib = u.protocol === 'http:' ? http : https;
		const options = {
			method: 'POST',
			hostname: u.hostname,
			port: u.port || (u.protocol === 'http:' ? 80 : 443),
			path: u.pathname + u.search,
			headers: { 'Content-Type': 'application/octet-stream' },
		};

		// Force cutoff after maxSeconds
		const cutoffTimer = setTimeout(() => {
			if (!finished) {
				finished = true;
				const duration = (performance.now() - start) / 1000;
				console.log('Upload force cutoff at', duration, 's, bytes:', sent);
				try {
					req.destroy();
				} catch (e) {}
				resolve({ bytes: sent, duration, cut: true });
			}
		}, maxSeconds * 1000);

		const req = lib.request(options, (res) => {
			res.on('data', () => {});
			res.on('end', () => {
				if (!finished) {
					finished = true;
					clearTimeout(cutoffTimer);
					const duration = (performance.now() - start) / 1000;
					resolve({ bytes: sent, duration, cut: false });
				}
			});
		});
		req.on('error', (e) => {
			if (!finished) {
				finished = true;
				clearTimeout(cutoffTimer);
				reject(e);
			}
		});
		function writeMore() {
			if (finished) return;
			const elapsed = (performance.now() - start) / 1000;
			if (elapsed >= maxSeconds) {
				if (!finished) {
					finished = true;
					clearTimeout(cutoffTimer);
					const duration = (performance.now() - start) / 1000;
					console.log('Upload time cutoff at', duration, 's, bytes:', sent);
					try {
						req.end();
					} catch (e) {}
					resolve({ bytes: sent, duration, cut: true });
				}
				return;
			}
			if (req.write(chunk)) {
				sent += chunk.length;
				setImmediate(writeMore);
			} else {
				req.once('drain', () => {
					sent += chunk.length;
					writeMore();
				});
			}
		}
		writeMore();
	});
}

class SpeedTestManager {
	constructor() {
		// Single large (1 GiB) file; we will abort after cutoff (default 5s)
		this.downloadUrl = 'https://speed.cloudflare.com/__down?bytes=1073741824';
		this.uploadTarget = 'https://speed.cloudflare.com/__up'; // may fail; keep placeholder
	}

	formatMbps(bytes, seconds) {
		if (!seconds || seconds <= 0) return 0;
		return (bytes * 8) / (1024 * 1024) / seconds;
	}

	async ping(params = {}) {
		const host = params.host || '1.1.1.1';
		const start = performance.now();
		return new Promise((resolve) => {
			https
				.get('https://' + host + '/cdn-cgi/trace?_=' + Date.now(), (res) => {
					res.resume();
					res.on('end', () => {
						const latency = performance.now() - start;
						resolve({ status: 'success', latencyMs: latency });
					});
				})
				.on('error', (e) => {
					resolve({ status: 'error', message: e.message });
				});
		});
	}

	async download(params = {}) {
		const maxSeconds = params.maxSeconds || 5;
		try {
			const { bytes, duration, cut } = await downloadUrl(this.downloadUrl, maxSeconds);
			const mbps = this.formatMbps(bytes, duration);
			return { status: 'success', url: this.downloadUrl, bytes, duration, mbps, cutoff: cut };
		} catch (e) {
			return { status: 'error', message: e.message };
		}
	}

	async upload(params = {}) {
		const maxSeconds = params.maxSeconds || 5;
		try {
			const { bytes, duration, cut } = await uploadTest(this.uploadTarget, Infinity, maxSeconds);
			const mbps = this.formatMbps(bytes, duration);
			return { status: 'success', bytes, duration, mbps, cutoff: cut };
		} catch (e) {
			return { status: 'error', message: e.message };
		}
	}

	async full(params = {}) {
		const ping = await this.ping(params);
		const download = await this.download(params);
		const upload = await this.upload(params);
		return { status: 'success', ping, download, upload };
	}
}

export default SpeedTestManager;
