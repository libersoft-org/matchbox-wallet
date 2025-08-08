#!/bin/bash
set -euo pipefail

SECRET_DEPLOY="${DEPLOY_ENV:-$(pwd)/.secret_deploy}"

if [[ ! -f "$SECRET_DEPLOY" ]]; then
	echo "Missing deploy secret file: $SECRET_DEPLOY" >&2
	exit 1
fi

source "$SECRET_DEPLOY"

: "${TARGET1_HOST:?TARGET1_HOST is required in $SECRET_DEPLOY}"
: "${TARGET1_USER:?TARGET1_USER is required in $SECRET_DEPLOY}"
: "${TARGET1_PASSWORD:?TARGET1_PASSWORD is required in $SECRET_DEPLOY}"

./build.sh

echo "Deploying to ${TARGET1_USER}@${TARGET1_HOST}..."
sshpass -p "$TARGET1_PASSWORD" scp -v -o StrictHostKeyChecking=no ./build/linux/wallet "$TARGET1_USER@$TARGET1_HOST:/root/"
# If needed, deploy QML resources folder too
# sshpass -p "$TARGET1_PASSWORD" scp -v -r -o StrictHostKeyChecking=no ./build/linux/WalletModule "$TARGET1_USER@$TARGET1_HOST:/root/"
sshpass -p "$TARGET1_PASSWORD" scp -v -o StrictHostKeyChecking=no ./start.sh "$TARGET1_USER@$TARGET1_HOST:/root/"
sshpass -p "$TARGET1_PASSWORD" ssh -o StrictHostKeyChecking=no "$TARGET1_USER@$TARGET1_HOST" "set -x; killall wallet || true; sed -i 's|./build/linux/wallet|./wallet|g; s|build/linux/wallet|wallet|g' /root/start.sh; chmod +x /root/start.sh; /root/start.sh "

# Optional: Target 2 (enable if variables present)
#if [[ -n "${TARGET2_HOST:-}" && -n "${TARGET2_USER:-}" && -n "${TARGET2_PASSWORD:-}" ]]; then
#	echo "Deploying to ${TARGET2_USER}@${TARGET2_HOST}..."
#	sshpass -p "$TARGET2_PASSWORD" scp -v -o StrictHostKeyChecking=no ./build/linux/wallet "$TARGET2_USER@$TARGET2_HOST:/root/"
#	sshpass -p "$TARGET2_PASSWORD" scp -v -o StrictHostKeyChecking=no ./start.sh "$TARGET2_USER@$TARGET2_HOST:/root/"
#	sshpass -p "$TARGET2_PASSWORD" ssh -o StrictHostKeyChecking=no "$TARGET2_USER@$TARGET2_HOST" "set -x; killall wallet || true; sed -i 's|./build/linux/wallet|./wallet|g; s|build/linux/wallet|wallet|g' /root/start.sh; chmod +x /root/start.sh; /root/start.sh "
#fi

echo "Deployment completed."
