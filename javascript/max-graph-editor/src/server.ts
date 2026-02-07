import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';

const appRoot = new URL('..', import.meta.url).pathname;
const publicDir = join(appRoot, 'public');

const diagramPathArg = Bun.argv[2];
if (!diagramPathArg) {
  console.error('Usage: bun src/server.ts <diagram-file-path> [port]');
  process.exit(1);
}

const portArg = Bun.argv[3] ?? Bun.env.PORT ?? '3000';
const port = Number(portArg);
if (!Number.isInteger(port) || port <= 0 || port > 65535) {
  console.error(`Invalid port: ${portArg}`);
  process.exit(1);
}

const diagramBaseDir = process.cwd();
const diagramPath = resolve(diagramBaseDir, diagramPathArg);
if (!existsSync(diagramPath)) {
  console.error(`Diagram file does not exist: ${diagramPath}`);
  process.exit(1);
}

const sockets = new Set<ServerWebSocket<unknown>>();

const server = Bun.serve({
  port,
  fetch(req, server) {
    const url = new URL(req.url);

    if (url.pathname === '/sync' && server.upgrade(req)) {
      return;
    }

    if (url.pathname === '/api/diagram' && req.method === 'GET') {
      return new Response(readDiagram(), {
        headers: { 'content-type': 'application/xml; charset=utf-8' },
      });
    }

    if (url.pathname === '/api/diagram' && req.method === 'PUT') {
      return handleHttpUpdate(req);
    }

    const pathPart = url.pathname === '/' ? 'index.html' : url.pathname.replace(/^\//, '');
    const filePath = join(publicDir, pathPart);
    if (!existsSync(filePath)) {
      return new Response('Not found', { status: 404 });
    }

    return new Response(Bun.file(filePath));
  },
  websocket: {
    open(ws) {
      sockets.add(ws);
      ws.send(JSON.stringify({ type: 'diagram', xml: readDiagram(), source: 'server' }));
    },
    close(ws) {
      sockets.delete(ws);
    },
    message(ws, raw) {
      try {
        const payload = JSON.parse(decodeWebSocketMessage(raw)) as { type?: string; xml?: string };
        if (payload.type !== 'diagram' || typeof payload.xml !== 'string') {
          ws.send(JSON.stringify({ type: 'error', message: 'Invalid payload.' }));
          return;
        }

        writeDiagram(payload.xml);
        broadcast({ type: 'diagram', xml: payload.xml, source: 'peer' }, ws);
      } catch {
        ws.send(JSON.stringify({ type: 'error', message: 'Malformed JSON.' }));
      }
    },
  },
});

console.log(`MaxGraph editor listening on http://localhost:${server.port}`);
console.log(`Diagram file: ${diagramPath}`);

async function handleHttpUpdate(req: Request) {
  const xml = await req.text();
  writeDiagram(xml);
  broadcast({ type: 'diagram', xml, source: 'http' });
  return new Response(JSON.stringify({ ok: true }), {
    headers: { 'content-type': 'application/json; charset=utf-8' },
  });
}

function readDiagram() {
  return readFileSync(diagramPath, 'utf-8');
}

function writeDiagram(xml: string) {
  const dir = dirname(diagramPath);
  if (!existsSync(dir)) {
    console.error(`Parent directory does not exist: ${dir}`);
    return;
  }
  writeFileSync(diagramPath, xml.endsWith('\n') ? xml : `${xml}\n`, 'utf-8');
}

function broadcast(message: unknown, except?: ServerWebSocket<unknown>) {
  const json = JSON.stringify(message);
  for (const socket of sockets) {
    if (socket !== except) {
      socket.send(json);
    }
  }
}

function decodeWebSocketMessage(raw: string | ArrayBuffer | Uint8Array) {
  if (typeof raw === 'string') {
    return raw;
  }

  if (raw instanceof Uint8Array) {
    return new TextDecoder().decode(raw);
  }

  return new TextDecoder().decode(new Uint8Array(raw));
}
