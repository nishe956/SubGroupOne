import { defineConfig, loadEnv } from 'vite';
import react from '@vitejs/plugin-react';
import basicSsl from '@vitejs/plugin-basic-ssl';
import fs from 'fs';
import path from 'path';

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '');
  const apiTarget = env.VITE_API_TARGET || 'http://localhost:8000';
  const proxySecure = env.VITE_PROXY_SECURE === 'true';
  const useHttps = env.VITE_DEV_HTTPS === 'true';
  const certPath = path.resolve(__dirname, 'certs/localhost.pem');
  const keyPath = path.resolve(__dirname, 'certs/localhost-key.pem');
  const hasMkcertFiles = fs.existsSync(certPath) && fs.existsSync(keyPath);
  const httpsConfig = !useHttps
    ? false
    : hasMkcertFiles
      ? {
          cert: fs.readFileSync(certPath),
          key: fs.readFileSync(keyPath),
        }
      : true;

  return {
    plugins: [react(), ...(useHttps && !hasMkcertFiles ? [basicSsl()] : [])],
    resolve: {
      alias: { '@': path.resolve(__dirname, './src') },
    },
    server: {
      port: 5173,
      https: httpsConfig,
      proxy: {
        '/api': { target: apiTarget, changeOrigin: true, secure: proxySecure },
        '/media': { target: apiTarget, changeOrigin: true, secure: proxySecure },
      },
    },
  };
});
