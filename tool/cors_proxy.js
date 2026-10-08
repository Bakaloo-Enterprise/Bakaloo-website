// Local dev CORS proxy: forwards http://localhost:8010/* to https://api.bakaloo.in/*
// and adds CORS headers. Usage: node tool/cors_proxy.js
const http = require('http');
const https = require('https');
const tls = require('tls');

const TARGET = 'api.bakaloo.in';
const PORT = process.env.PORT || 8010;

const cors = (req) => ({
  'access-control-allow-origin': req.headers.origin || '*',
  'access-control-allow-credentials': 'true',
  'access-control-allow-methods': 'GET,POST,PUT,PATCH,DELETE,OPTIONS',
  'access-control-allow-headers':
    req.headers['access-control-request-headers'] || '*',
  'access-control-expose-headers': '*',
  vary: 'Origin',
});

http
  .createServer((req, res) => {
    if (req.method === 'OPTIONS') {
      res.writeHead(204, { ...cors(req), 'access-control-max-age': '86400' });
      return res.end();
    }
    const headers = { ...req.headers, host: TARGET };
    delete headers.origin;
    delete headers.referer;
    const up = https.request(
      { host: TARGET, path: req.url, method: req.method, headers },
      (r) => {
        const h = { ...r.headers };
        for (const k of Object.keys(h)) {
          if (k.startsWith('access-control-')) delete h[k];
        }
        res.writeHead(r.statusCode, { ...h, ...cors(req) });
        r.pipe(res);
      },
    );
    up.on('error', (e) => {
      res.writeHead(502, cors(req));
      res.end(JSON.stringify({ error: 'proxy_error', message: e.message }));
    });
    req.pipe(up);
  })
  .on('upgrade', (req, socket, head) => {
    const up = tls.connect(443, TARGET, { servername: TARGET }, () => {
      const lines = [`${req.method} ${req.url} HTTP/1.1`, `Host: ${TARGET}`];
      for (const [k, v] of Object.entries(req.headers)) {
        if (!['host', 'origin'].includes(k)) lines.push(`${k}: ${v}`);
      }
      up.write(lines.join('\r\n') + '\r\n\r\n');
      up.write(head);
      up.pipe(socket);
      socket.pipe(up);
    });
    up.on('error', () => socket.destroy());
    socket.on('error', () => up.destroy());
  })
  .listen(PORT, () => console.log(`CORS proxy on :${PORT} -> https://${TARGET}`));
