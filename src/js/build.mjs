import { build } from 'esbuild';

await build({
  entryPoints: ['src/index.ts'],
  bundle: true,
  platform: 'node',
  target: 'node18',
  format: 'esm',
  outfile: 'dist/bundle.js',
  external: [
    // Mark Node.js built-ins as external
    'child_process',
    'util',
    'crypto',
    'fs',
    'path',
    'os'
  ],
  sourcemap: true,
  minify: false, // Keep readable for debugging
  logLevel: 'info'
}).catch(() => process.exit(1));

console.log('Bundle created successfully!');