class TestManager {
	ping() {
		return {
			status: 'success',
			message: 'pong',
			timestamp: Date.now(),
		};
	}

	async delayedPing(params = {}) {
		const delay = params?.delay || 2000;
		console.log(`Starting delayed ping with ${delay}ms delay...`);
		return new Promise((resolve) => {
			setTimeout(() => {
				console.log('Delayed ping completed!');
				resolve({
					status: 'success',
					message: 'delayed pong',
					timestamp: Date.now(),
					delay,
				});
			}, delay);
		});
	}
}

module.exports = TestManager;
