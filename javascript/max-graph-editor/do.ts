import { existsSync } from 'node:fs';
import { mkdir, open, readFile, rm, writeFile } from 'node:fs/promises';
import { basename, dirname, extname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import puppeteer, { type Browser, type Page } from 'puppeteer';

type Args = {
  positional: string[];
  flags: Map<string, string | boolean>;
};

type ServerState = {
  pid: number;
  port: number;
  diagramPath: string;
  logPath: string;
  startedAt: string;
};

type BrowserMode = 'headful' | 'headless';

type BrowserState = {
  wsEndpoint: string;
  pid: number | null;
  mode: BrowserMode;
  userDataDir: string;
  startedAt: string;
};

const ROOT = dirname(fileURLToPath(import.meta.url));
const RUN_DIR = join(ROOT, '.my', 'run');
const SCREENSHOT_DIR = join(ROOT, '.my', 'screenshots');

const SERVER_STATE_PATH = join(RUN_DIR, 'server.json');
const SERVER_LOG_PATH = join(RUN_DIR, 'server.log');
const BROWSER_STATE_PATH = join(RUN_DIR, 'browser.json');
const BROWSER_LOG_PATH = join(RUN_DIR, 'browser.log');
const BROWSER_PROFILE_DIR = join(ROOT, '.my', 'puppeteer-profile');

const args = parseArgs(Bun.argv.slice(2));
const command = args.positional[0] ?? 'help';

try {
  await dispatch(command, args);
} catch (error) {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
}

async function dispatch(commandName: string, parsed: Args) {
  switch (commandName) {
    case 'help':
      printHelp();
      return;
    case 'server-start':
      await serverStart(parsed);
      return;
    case 'server-stop':
      await serverStop();
      return;
    case 'server-status':
      await serverStatus();
      return;
    case 'server-log':
      await serverLog();
      return;
    case 'browser-start':
      await browserStart(parsed);
      return;
    case 'browser-stop':
      await browserStop();
      return;
    case 'browser-status':
      await browserStatus();
      return;
    case 'browser-eval':
      await browserEval(parsed);
      return;
    case 'screenshot':
      await screenshot(parsed);
      return;
    case 'screenshot-latest':
      await screenshotLatest();
      return;
    case 'export-mxgraph':
      await exportMxGraph(parsed);
      return;
    case 'status':
      await serverStatus();
      await browserStatus();
      return;
    case 'stop':
      await serverStop();
      await browserStop();
      return;
    default:
      throw new Error(`Unknown command: ${commandName}`);
  }
}

function parseArgs(argv: string[]): Args {
  const positional: string[] = [];
  const flags = new Map<string, string | boolean>();

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    if (!token.startsWith('--')) {
      positional.push(token);
      continue;
    }

    const key = token.slice(2);
    const next = argv[i + 1];
    if (!next || next.startsWith('--')) {
      flags.set(key, true);
      continue;
    }
    flags.set(key, next);
    i += 1;
  }

  return { positional, flags };
}

function flagString(parsed: Args, key: string, fallback?: string): string {
  const value = parsed.flags.get(key);
  if (typeof value === 'string') {
    return value;
  }
  if (typeof value === 'boolean') {
    throw new Error(`Missing value for --${key}`);
  }
  if (typeof fallback === 'string') {
    return fallback;
  }
  throw new Error(`Missing required flag --${key}`);
}

function flagOptionalString(parsed: Args, key: string): string | null {
  const value = parsed.flags.get(key);
  if (typeof value === 'undefined') {
    return null;
  }
  if (typeof value === 'boolean') {
    throw new Error(`Missing value for --${key}`);
  }
  return value;
}

function flagInt(parsed: Args, key: string, fallback: number): number {
  const raw = parsed.flags.get(key);
  if (typeof raw === 'undefined') {
    return fallback;
  }
  const n = Number(raw);
  if (!Number.isInteger(n) || n <= 0 || n > 65535) {
    throw new Error(`Invalid --${key}: ${raw}`);
  }
  return n;
}

function flagBool(parsed: Args, key: string, fallback = false): boolean {
  const value = parsed.flags.get(key);
  if (typeof value === 'undefined') {
    return fallback;
  }
  if (typeof value === 'boolean') {
    return value;
  }
  const lower = value.toLowerCase();
  if (lower === 'true' || lower === '1' || lower === 'yes') {
    return true;
  }
  if (lower === 'false' || lower === '0' || lower === 'no') {
    return false;
  }
  throw new Error(`Invalid --${key}: ${value}`);
}

async function ensureRuntimeDirs() {
  await mkdir(RUN_DIR, { recursive: true });
  await mkdir(SCREENSHOT_DIR, { recursive: true });
}

async function writeJson(path: string, value: unknown) {
  await mkdir(dirname(path), { recursive: true });
  await writeFile(path, `${JSON.stringify(value, null, 2)}\n`, 'utf8');
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

function isPidAlive(pid: number): boolean {
  try {
    process.kill(pid, 0);
    return true;
  } catch {
    return false;
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

async function appendLog(path: string, message: string) {
  const line = `[${new Date().toISOString()}] ${message}\n`;
  const file = await open(path, 'a');
  await file.write(line);
  await file.close();
}

async function killAndWait(pid: number, name: string) {
  if (!isPidAlive(pid)) {
    console.log(`${name} pid=${pid} is not running.`);
    return;
  }
  process.kill(pid, 'SIGTERM');
  const deadline = Date.now() + 3_000;
  while (Date.now() < deadline) {
    if (!isPidAlive(pid)) {
      console.log(`Stopped ${name} pid=${pid}`);
      return;
    }
    await Bun.sleep(100);
  }
  process.kill(pid, 'SIGKILL');
  console.log(`Force-stopped ${name} pid=${pid}`);
}

async function serverStart(parsed: Args) {
  await ensureRuntimeDirs();

  const diagram = flagString(parsed, 'diagram');
  const port = flagInt(parsed, 'port', 3000);
  const endpoint = `http://127.0.0.1:${port}/api/diagram`;
  const diagramPath = resolve(ROOT, diagram);
  if (!existsSync(diagramPath)) {
    throw new Error(`Diagram file does not exist: ${diagramPath}`);
  }

  const existing = await readJson<ServerState>(SERVER_STATE_PATH);
  if (existing && isPidAlive(existing.pid)) {
    console.log(`Server already running pid=${existing.pid} on port ${existing.port}`);
    return;
  }
  if (await isHttpReachable(endpoint)) {
    if (existing && !isPidAlive(existing.pid)) {
      await rm(SERVER_STATE_PATH, { force: true });
    }
    console.log(`Server endpoint already reachable on ${endpoint}.`);
    console.log('Reusing existing server (possibly unmanaged by do.ts).');
    return;
  }

  const logFile = await open(SERVER_LOG_PATH, 'a');
  const proc = Bun.spawn({
    cmd: ['bun', 'src/server.ts', diagramPath, String(port)],
    cwd: ROOT,
    stdin: 'ignore',
    stdout: logFile.fd,
    stderr: logFile.fd,
    detached: true,
  });
  proc.unref();
  await logFile.close();

  const state: ServerState = {
    pid: proc.pid,
    port,
    diagramPath,
    logPath: SERVER_LOG_PATH,
    startedAt: new Date().toISOString(),
  };
  await writeJson(SERVER_STATE_PATH, state);

  const up = await waitForHttp(endpoint, 8_000);
  if (!up) {
    await rm(SERVER_STATE_PATH, { force: true });
    throw new Error(`Server did not become ready on port ${port}. Check log: ${SERVER_LOG_PATH}`);
  }
  if (!isPidAlive(proc.pid)) {
    await rm(SERVER_STATE_PATH, { force: true });
    throw new Error(
      `Server process pid=${proc.pid} exited early after startup. Check log: ${SERVER_LOG_PATH}`,
    );
  }

  console.log(`Started server pid=${proc.pid} on http://127.0.0.1:${port}`);
  console.log(`Log: ${SERVER_LOG_PATH}`);
}

async function serverStop() {
  const state = await readJson<ServerState>(SERVER_STATE_PATH);
  if (!state) {
    console.log('No server state found.');
    return;
  }
  await killAndWait(state.pid, 'server');
  await rm(SERVER_STATE_PATH, { force: true });
}

async function serverStatus() {
  let state = await readJson<ServerState>(SERVER_STATE_PATH);
  let alive = state ? isPidAlive(state.pid) : false;
  if (state && !alive) {
    await rm(SERVER_STATE_PATH, { force: true });
    console.log(`Removed stale server state for pid=${state.pid}`);
    state = null;
  }

  const port = state?.port ?? 3000;
  const reachable = await isHttpReachable(`http://127.0.0.1:${port}/api/diagram`);

  if (state) {
    console.log(`Server state: pid=${state.pid} port=${state.port} diagram=${state.diagramPath}`);
  } else {
    console.log(`Server state: none (checked default port ${port})`);
  }
  alive = state ? isPidAlive(state.pid) : false;
  console.log(`Server pid alive: ${alive}`);
  console.log(`Server endpoint reachable: ${reachable}`);
}

async function serverLog() {
  if (!existsSync(SERVER_LOG_PATH)) {
    console.log(`Server log not found: ${SERVER_LOG_PATH}`);
    return;
  }
  process.stdout.write(await readFile(SERVER_LOG_PATH, 'utf8'));
}

async function browserStart(parsed: Args) {
  await ensureRuntimeDirs();

  const modeRaw = flagString(parsed, 'mode', 'headful');
  if (modeRaw !== 'headful' && modeRaw !== 'headless') {
    throw new Error(`Invalid --mode: ${modeRaw}. Expected headful|headless.`);
  }
  const mode = modeRaw as BrowserMode;
  const resetProfile = flagBool(parsed, 'reset-profile', false);
  const url = flagOptionalString(parsed, 'url');
  const settleMs = flagInt(parsed, 'settle-ms', 800);

  if (resetProfile) {
    await rm(BROWSER_PROFILE_DIR, { recursive: true, force: true });
  }
  await mkdir(BROWSER_PROFILE_DIR, { recursive: true });

  const existing = await readJson<BrowserState>(BROWSER_STATE_PATH);
  if (existing) {
    const connected = await tryConnectBrowser(existing.wsEndpoint);
    if (connected) {
      const page = await ensurePage(connected, url, settleMs);
      await appendLog(BROWSER_LOG_PATH, `Reused browser; active page ${page.url()}`);
      console.log(`Browser already running pid=${existing.pid ?? 'n/a'}`);
      console.log(`wsEndpoint: ${existing.wsEndpoint}`);
      await connected.disconnect();
      return;
    }
    if (existing.pid && isPidAlive(existing.pid)) {
      await killAndWait(existing.pid, 'browser');
    }
    await rm(BROWSER_STATE_PATH, { force: true });
  }

  const browser = await puppeteer.launch({
    headless: mode === 'headless',
    userDataDir: BROWSER_PROFILE_DIR,
    defaultViewport: null,
    args: ['--no-first-run', '--no-default-browser-check'],
  });
  const pid = browser.process()?.pid ?? null;
  const wsEndpoint = browser.wsEndpoint();
  const state: BrowserState = {
    wsEndpoint,
    pid,
    mode,
    userDataDir: BROWSER_PROFILE_DIR,
    startedAt: new Date().toISOString(),
  };
  await writeJson(BROWSER_STATE_PATH, state);

  const page = await ensurePage(browser, url, settleMs);
  await appendLog(BROWSER_LOG_PATH, `Started browser mode=${mode} pid=${pid ?? 'n/a'} page=${page.url()}`);

  console.log(`Started browser (${mode}) pid=${pid ?? 'n/a'}`);
  console.log(`wsEndpoint: ${wsEndpoint}`);
  console.log(`Profile: ${BROWSER_PROFILE_DIR}`);
  await browser.disconnect();
}

async function browserStop() {
  const state = await readJson<BrowserState>(BROWSER_STATE_PATH);
  if (!state) {
    console.log('No browser state found.');
    return;
  }

  const browser = await tryConnectBrowser(state.wsEndpoint);
  if (browser) {
    await browser.close();
    await appendLog(BROWSER_LOG_PATH, 'Closed browser via websocket');
    console.log('Stopped browser.');
  } else if (state.pid && isPidAlive(state.pid)) {
    await killAndWait(state.pid, 'browser');
  } else {
    console.log('Browser process already stopped.');
  }

  await rm(BROWSER_STATE_PATH, { force: true });
}

async function browserStatus() {
  const state = await readJson<BrowserState>(BROWSER_STATE_PATH);
  if (!state) {
    console.log('Browser state: none');
    return;
  }

  const pidAlive = state.pid ? isPidAlive(state.pid) : false;
  const browser = await tryConnectBrowser(state.wsEndpoint);
  const wsReachable = Boolean(browser);
  if (browser) {
    await browser.disconnect();
  }

  console.log(`Browser state: pid=${state.pid ?? 'n/a'} mode=${state.mode}`);
  console.log(`Browser pid alive: ${pidAlive}`);
  console.log(`Browser ws reachable: ${wsReachable}`);
}

async function browserEval(parsed: Args) {
  const js = await loadScriptArg(parsed, 'js', 'js-file');
  const argsValue = parseOptionalJsonFlag(parsed, 'args-json', null);
  const url = flagOptionalString(parsed, 'url');
  const settleMs = flagInt(parsed, 'settle-ms', 800);

  const browser = await connectBrowserFromState();
  try {
    const page = await ensurePage(browser, url, settleMs);
    const value = await page.evaluate((source, inputArgs) => {
      // eslint-disable-next-line no-eval
      const evaluated = (0, eval)(source);
      if (typeof evaluated === 'function') {
        return evaluated(inputArgs);
      }
      return evaluated;
    }, js, argsValue);
    console.log(JSON.stringify(value ?? null, null, 2));
  } finally {
    await browser.disconnect();
  }
}

async function screenshot(parsed: Args) {
  await ensureRuntimeDirs();

  const url = flagString(parsed, 'url', 'http://127.0.0.1:3000');
  const settleMs = flagInt(parsed, 'settle-ms', 800);
  const width = flagInt(parsed, 'width', 1440);
  const height = flagInt(parsed, 'height', 900);
  const fullPage = flagBool(parsed, 'full-page', false);
  const preJs = await loadOptionalScriptArg(parsed, 'pre-js', 'pre-js-file');
  const preArgsValue = parseOptionalJsonFlag(parsed, 'pre-args-json', null);

  const outRaw = flagString(parsed, 'out', join('.my', 'screenshots', `editor-${stamp()}.png`));
  const outPath = resolve(ROOT, outRaw);
  await mkdir(dirname(outPath), { recursive: true });

  const browser = await connectBrowserFromState();
  try {
    const page = await ensurePage(browser, url, settleMs);
    await page.setViewport({ width, height });
    if (preJs) {
      await page.evaluate((source, inputArgs) => {
        // eslint-disable-next-line no-eval
        const evaluated = (0, eval)(source);
        if (typeof evaluated === 'function') {
          return evaluated(inputArgs);
        }
        return evaluated;
      }, preJs, preArgsValue);
      await Bun.sleep(150);
    }
    await page.screenshot({ path: outPath, fullPage, type: 'png' });
    console.log(`Screenshot file: ${outPath}`);
  } finally {
    await browser.disconnect();
  }
}

async function screenshotLatest() {
  if (!existsSync(SCREENSHOT_DIR)) {
    console.log('No screenshots directory yet.');
    return;
  }
  const entries = await Array.fromAsync(new Bun.Glob('*.png').scan({ cwd: SCREENSHOT_DIR }));
  if (entries.length === 0) {
    console.log('No screenshots found.');
    return;
  }

  let latestPath = '';
  let latestTime = 0;
  for (const rel of entries) {
    const full = join(SCREENSHOT_DIR, rel);
    const stat = await Bun.file(full).stat();
    const t = stat.mtimeMs ?? 0;
    if (t >= latestTime) {
      latestTime = t;
      latestPath = full;
    }
  }
  console.log(latestPath);
}

async function exportMxGraph(parsed: Args) {
  const diagram = flagString(parsed, 'diagram');
  const inputPath = resolve(ROOT, diagram);
  if (!existsSync(inputPath)) {
    throw new Error(`Diagram file does not exist: ${inputPath}`);
  }

  const outRaw = flagOptionalString(parsed, 'out');
  const outputPath = outRaw ? resolve(ROOT, outRaw) : defaultMxGraphOutputPath(inputPath);
  if (inputPath === outputPath) {
    throw new Error('Input and output paths must be different.');
  }

  const inputXml = await readFile(inputPath, 'utf8');
  const outputXml = convertMaxGraphXmlToMxGraphXml(inputXml);

  await mkdir(dirname(outputPath), { recursive: true });
  await writeFile(outputPath, outputXml.endsWith('\n') ? outputXml : `${outputXml}\n`, 'utf8');

  console.log(`Exported mxGraph XML: ${outputPath}`);
}

function defaultMxGraphOutputPath(inputPath: string) {
  const ext = extname(inputPath);
  if (ext.toLowerCase() === '.xml') {
    const stem = basename(inputPath, ext);
    return join(dirname(inputPath), `${stem}.mxgraph.xml`);
  }
  return `${inputPath}.mxgraph.xml`;
}

function convertMaxGraphXmlToMxGraphXml(xml: string) {
  let output = xml.replace(/\r\n/g, '\n');

  output = output.replace(/<Cell\b[\s\S]*?<\/Cell>/g, (cellBlock) => convertCellBlockToMxGraph(cellBlock));

  // Rename maxGraph element/class names to legacy mxGraph names.
  output = output
    .replace(/<GraphDataModel\b/g, '<mxGraphModel')
    .replace(/<\/GraphDataModel>/g, '</mxGraphModel>')
    .replace(/<Cell\b/g, '<mxCell')
    .replace(/<\/Cell>/g, '</mxCell>')
    .replace(/<Geometry\b/g, '<mxGeometry')
    .replace(/<\/Geometry>/g, '</mxGeometry>')
    .replace(/<Point\b/g, '<mxPoint')
    .replace(/<\/Point>/g, '</mxPoint>');

  // maxGraph encodes internal geometry fields as _x/_y/...; mxGraph expects x/y/...
  output = output.replace(/\b_([a-zA-Z][a-zA-Z0-9]*)=/g, '$1=');

  return output;
}

function convertCellBlockToMxGraph(cellBlock: string) {
  const openTagMatch = /^<Cell\b[^>]*>/.exec(cellBlock);
  if (!openTagMatch) {
    return cellBlock;
  }

  const openTag = openTagMatch[0];
  const closeTag = '</Cell>';
  if (!cellBlock.endsWith(closeTag)) {
    return cellBlock;
  }

  const body = cellBlock.slice(openTag.length, cellBlock.length - closeTag.length);
  const extracted = extractStyleNode(body);
  if (!extracted) {
    return cellBlock;
  }

  const cleanOpenTag = openTag.replace(/\sstyle="[^"]*"/g, '');
  const withStyleOpenTag = extracted.style.length > 0
    ? cleanOpenTag.replace(/>$/, ` style="${escapeXmlAttribute(extracted.style)}">`)
    : cleanOpenTag;
  return `${withStyleOpenTag}${extracted.bodyWithoutStyle}${closeTag}`;
}

function extractStyleNode(body: string): { bodyWithoutStyle: string; style: string } | null {
  const styleNodeRegexes = [
    /<Object\b([^>]*?)\bas="style"([^>]*)\/>/m,
    /<Object\b([^>]*?)\bas="style"([^>]*)>([\s\S]*?)<\/Object>/m,
  ];

  for (const regex of styleNodeRegexes) {
    const match = regex.exec(body);
    if (!match || match.index < 0) {
      continue;
    }
    const attributes = parseXmlAttributes(`${match[1] ?? ''} ${match[2] ?? ''}`);
    const inner = match[3] ?? '';
    const style = buildMxStyle(attributes, inner);
    const bodyWithoutStyle = `${body.slice(0, match.index)}${body.slice(match.index + match[0].length)}`;
    return { bodyWithoutStyle, style };
  }

  return null;
}

function parseXmlAttributes(raw: string): Map<string, string> {
  const attributes = new Map<string, string>();
  const attrRegex = /([a-zA-Z_:][a-zA-Z0-9_.:-]*)="([^"]*)"/g;
  for (const match of raw.matchAll(attrRegex)) {
    attributes.set(match[1], match[2]);
  }
  return attributes;
}

function buildMxStyle(attributes: Map<string, string>, styleInnerXml: string) {
  const styleEntries: string[] = [];
  const ignoreDefaultStyle = isTrueLike(attributes.get('ignoreDefaultStyle'));

  const directBaseStyles = attributes.get('baseStyleNames');
  if (directBaseStyles) {
    for (const styleName of splitStyleNames(directBaseStyles)) {
      styleEntries.push(styleName);
    }
  }
  for (const styleName of parseBaseStyleNamesFromInnerXml(styleInnerXml)) {
    styleEntries.push(styleName);
  }

  for (const [rawKey, value] of attributes.entries()) {
    if (rawKey === 'as' || rawKey === 'ignoreDefaultStyle' || rawKey === 'baseStyleNames') {
      continue;
    }
    const mxKey = rawKey === 'autoSize' ? 'autosize' : rawKey;
    styleEntries.push(`${mxKey}=${value}`);
  }

  const body = styleEntries.join(';');
  if (body.length === 0) {
    return ignoreDefaultStyle ? ';' : '';
  }
  return `${ignoreDefaultStyle ? ';' : ''}${body};`;
}

function parseBaseStyleNamesFromInnerXml(innerXml: string): string[] {
  const match = /<Array\b[^>]*\bas="baseStyleNames"[^>]*>([\s\S]*?)<\/Array>/m.exec(innerXml);
  if (!match) {
    return [];
  }
  const names: string[] = [];
  const addRegex = /<add\b[^>]*\bvalue="([^"]*)"[^>]*\/>/g;
  for (const addMatch of match[1].matchAll(addRegex)) {
    for (const styleName of splitStyleNames(addMatch[1])) {
      names.push(styleName);
    }
  }
  return names;
}

function splitStyleNames(raw: string): string[] {
  return raw
    .split(/[,\s]+/)
    .map((value) => value.trim())
    .filter((value) => value.length > 0);
}

function isTrueLike(value?: string) {
  if (!value) {
    return false;
  }
  const normalized = value.trim().toLowerCase();
  return normalized === '1' || normalized === 'true' || normalized === 'yes';
}

function escapeXmlAttribute(value: string) {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('"', '&quot;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');
}

async function connectBrowserFromState(): Promise<Browser> {
  const state = await readJson<BrowserState>(BROWSER_STATE_PATH);
  if (!state) {
    throw new Error('Browser is not started. Run: bun do.ts browser-start --mode headful');
  }

  const browser = await tryConnectBrowser(state.wsEndpoint);
  if (!browser) {
    if (state.pid && isPidAlive(state.pid)) {
      throw new Error('Could not connect to browser wsEndpoint even though PID is alive. Restart browser.');
    }
    await rm(BROWSER_STATE_PATH, { force: true });
    throw new Error('Browser state was stale. Run: bun do.ts browser-start --mode headful');
  }
  return browser;
}

async function tryConnectBrowser(wsEndpoint: string): Promise<Browser | null> {
  try {
    return await puppeteer.connect({ browserWSEndpoint: wsEndpoint, defaultViewport: null });
  } catch {
    return null;
  }
}

async function ensurePage(browser: Browser, url: string | null, settleMs: number): Promise<Page> {
  const pages = await browser.pages();

  let page: Page | undefined;
  if (url) {
    page = pages.find((candidate) => candidate.url().startsWith(url));
  }
  if (!page) {
    page =
      pages.find((candidate) => !candidate.url().startsWith('chrome://') && !candidate.url().startsWith('devtools://')) ??
      pages[0];
  }
  if (!page) {
    page = await browser.newPage();
  }

  await page.bringToFront();
  if (url && !page.url().startsWith(url)) {
    await page.goto(url, { waitUntil: 'load' });
  }
  if (settleMs > 0) {
    await Bun.sleep(settleMs);
  }
  return page;
}

async function loadScriptArg(parsed: Args, inlineKey: string, fileKey: string) {
  const inline = flagOptionalString(parsed, inlineKey);
  if (inline) {
    return inline;
  }
  const file = flagOptionalString(parsed, fileKey);
  if (file) {
    return await readFile(resolve(ROOT, file), 'utf8');
  }
  throw new Error(`Missing script input. Use --${inlineKey} or --${fileKey}.`);
}

async function loadOptionalScriptArg(parsed: Args, inlineKey: string, fileKey: string) {
  const inline = flagOptionalString(parsed, inlineKey);
  if (inline) {
    return inline;
  }
  const file = flagOptionalString(parsed, fileKey);
  if (file) {
    return await readFile(resolve(ROOT, file), 'utf8');
  }
  return null;
}

function parseOptionalJsonFlag(parsed: Args, key: string, fallback: unknown): unknown {
  const raw = flagOptionalString(parsed, key);
  if (raw === null) {
    return fallback;
  }
  try {
    return JSON.parse(raw);
  } catch (error) {
    throw new Error(`Invalid --${key}: ${String(error)}`);
  }
}

function stamp() {
  const now = new Date();
  const yyyy = now.getFullYear();
  const mm = String(now.getMonth() + 1).padStart(2, '0');
  const dd = String(now.getDate()).padStart(2, '0');
  const hh = String(now.getHours()).padStart(2, '0');
  const mi = String(now.getMinutes()).padStart(2, '0');
  const ss = String(now.getSeconds()).padStart(2, '0');
  return `${yyyy}${mm}${dd}-${hh}${mi}${ss}`;
}

function printHelp() {
  console.log(`Usage:
  bun do.ts <command> [flags]

Commands:
  help
  server-start --diagram <path> [--port 3000]
  server-stop
  server-status
  server-log
  browser-start [--mode headful|headless] [--reset-profile] [--url http://127.0.0.1:3000] [--settle-ms 800]
  browser-stop
  browser-status
  browser-eval [--url http://127.0.0.1:3000] [--settle-ms 800] [--args-json '{...}'] (--js '...')|(--js-file ./path/to/script.js)
  screenshot [--url http://127.0.0.1:3000] [--out .my/screenshots/file.png] [--width 1440] [--height 900] [--full-page] [--settle-ms 800] [--pre-js '...'] [--pre-js-file ./path/to/script.js] [--pre-args-json '{...}']
  screenshot-latest
  export-mxgraph --diagram ./path/to/diagram.xml [--out ./path/to/diagram.mxgraph.xml]
  status
  stop
`);
}
