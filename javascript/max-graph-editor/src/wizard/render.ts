import { existsSync } from 'node:fs';
import { mkdir, open, readFile, rm, writeFile } from 'node:fs/promises';
import { dirname, join, resolve } from 'node:path';
import puppeteer from 'puppeteer';
import type { DiagramReport } from './types';

export type RenderOptions = {
  rootDir: string;
  diagramPath: string;
  imagePath: string;
  reportPath: string;
  port?: number;
  width?: number;
  height?: number;
};

type ServerState = {
  pid: number;
  port: number;
  diagramPath: string;
  logPath: string;
  startedAt: string;
};

const RUN_DIR_NAME = '.my/run';
const SERVER_STATE_NAME = 'server.json';
const SERVER_LOG_NAME = 'server.log';

type BrowserPageApi = {
  prepareForExport: (options?: { padding?: number; maxScale?: number }) => DiagramReport;
};

export async function renderDiagramArtifacts(options: RenderOptions): Promise<DiagramReport> {
  const rootDir = resolve(options.rootDir);
  const diagramPath = resolve(options.diagramPath);
  const imagePath = resolve(options.imagePath);
  const reportPath = resolve(options.reportPath);
  const port = options.port ?? 3100;
  const width = options.width ?? 1600;
  const height = options.height ?? 1000;
  const runDir = join(rootDir, RUN_DIR_NAME);
  const serverStatePath = join(runDir, SERVER_STATE_NAME);
  const serverLogPath = join(runDir, SERVER_LOG_NAME);

  await mkdir(runDir, { recursive: true });
  await mkdir(dirname(imagePath), { recursive: true });
  await mkdir(dirname(reportPath), { recursive: true });

  const previousState = await readJson<ServerState>(serverStatePath);
  let startedServerPid: number | null = null;

  if (!(await isHttpReachable(`http://127.0.0.1:${port}/api/diagram`))) {
    if (previousState?.pid && isPidAlive(previousState.pid)) {
      throw new Error(
        `Port ${port} is expected to be available for graph-wizard rendering, but an existing managed server is active for a different diagram.`,
      );
    }

    const logFile = await open(serverLogPath, 'a');
    const proc = Bun.spawn({
      cmd: ['bun', 'src/server.ts', diagramPath, String(port)],
      cwd: rootDir,
      stdout: logFile.fd,
      stderr: logFile.fd,
      stdin: 'ignore',
      detached: true,
    });
    proc.unref();
    startedServerPid = proc.pid;
    await logFile.close();

    const state: ServerState = {
      pid: proc.pid,
      port,
      diagramPath,
      logPath: serverLogPath,
      startedAt: new Date().toISOString(),
    };
    await writeFile(serverStatePath, `${JSON.stringify(state, null, 2)}\n`, 'utf8');

    const ready = await waitForHttp(`http://127.0.0.1:${port}/api/diagram`, 10_000);
    if (!ready) {
      throw new Error(`Rendering server did not become ready on port ${port}. Check ${serverLogPath}`);
    }
  }

  const browser = await puppeteer.launch({
    headless: true,
    defaultViewport: { width, height, deviceScaleFactor: 1 },
    args: ['--no-first-run', '--no-default-browser-check'],
  });

  try {
    const page = await browser.newPage();
    await page.goto(`http://127.0.0.1:${port}/?mode=render`, { waitUntil: 'networkidle0' });
    await page.waitForFunction(() => {
      const browserWindow = window as typeof window & { __maxGraphEditor?: BrowserPageApi };
      return Boolean(browserWindow.__maxGraphEditor);
    }, { timeout: 15_000 });
    const report = await page.evaluate(async () => {
      const browserWindow = window as typeof window & { __maxGraphEditor?: BrowserPageApi };
      const api = browserWindow.__maxGraphEditor;
      if (!api) {
        throw new Error('Missing editor API');
      }
      await new Promise((resolveWait) => window.setTimeout(resolveWait, 250));
      return api.prepareForExport({ padding: 48, maxScale: 1.25 });
    });
    const graphHandle = await page.$('#graph');
    if (!graphHandle) {
      throw new Error('Could not locate #graph in render mode');
    }
    await graphHandle.screenshot({ path: imagePath, type: 'png' });
    await writeFile(reportPath, `${JSON.stringify(report, null, 2)}\n`, 'utf8');
    return report as DiagramReport;
  } finally {
    await browser.close();
    if (startedServerPid) {
      await stopProcess(startedServerPid);
      await rm(serverStatePath, { force: true });
    }
  }
}

async function waitForHttp(url: string, timeoutMs: number) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    if (await isHttpReachable(url)) {
      return true;
    }
    await Bun.sleep(250);
  }
  return false;
}

async function isHttpReachable(url: string) {
  try {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 1_000);
    const response = await fetch(url, { signal: controller.signal });
    clearTimeout(timer);
    return response.ok || response.status < 500;
  } catch {
    return false;
  }
}

async function readJson<T>(path: string): Promise<T | null> {
  if (!existsSync(path)) {
    return null;
  }
  try {
    return JSON.parse(await readFile(path, 'utf8')) as T;
  } catch {
    return null;
  }
}

function isPidAlive(pid: number) {
  try {
    process.kill(pid, 0);
    return true;
  } catch {
    return false;
  }
}

async function stopProcess(pid: number) {
  if (!isPidAlive(pid)) {
    return;
  }
  process.kill(pid, 'SIGTERM');
  const deadline = Date.now() + 3_000;
  while (Date.now() < deadline) {
    if (!isPidAlive(pid)) {
      return;
    }
    await Bun.sleep(100);
  }
  process.kill(pid, 'SIGKILL');
}
