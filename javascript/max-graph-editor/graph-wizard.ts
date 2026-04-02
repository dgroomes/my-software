#!/usr/bin/env bun
import { mkdir } from 'node:fs/promises';
import { dirname, join, resolve } from 'node:path';
import { draftHeuristicDiagram } from './src/wizard/heuristic';
import { applyAutoLayout } from './src/wizard/layout';
import { draftOpenAiDiagram } from './src/wizard/openai';
import { renderDiagramArtifacts } from './src/wizard/render';
import { reviseSpecWithReport } from './src/wizard/revise';
import type { DiagramDraft, DiagramSpec, WizardArtifacts, WizardResult } from './src/wizard/types';
import { fileStemFromPrompt, json, titleFromPrompt, writeTextFile } from './src/wizard/utils';
import { specToMaxGraphXml } from './src/wizard/xml';

const ROOT = dirname(new URL(import.meta.url).pathname);

type Args = {
  positional: string[];
  flags: Map<string, string | boolean>;
};

const args = parseArgs(Bun.argv.slice(2));

try {
  const result = await run(args);
  process.stdout.write(`${JSON.stringify(result, null, 2)}\n`);
} catch (error) {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
}

async function run(parsed: Args): Promise<WizardResult> {
  const prompt = getPrompt(parsed);
  const provider = getFlag(parsed, 'provider', 'auto');
  const requestedOutDir = getOptionalFlag(parsed, 'out-dir');
  const renderPort = Number(getFlag(parsed, 'port', '3100'));
  const maxIterations = Math.max(0, Number(getFlag(parsed, 'max-iterations', '1')));

  if (!Number.isInteger(renderPort) || renderPort <= 0 || renderPort > 65535) {
    throw new Error(`Invalid --port value: ${renderPort}`);
  }
  if (!Number.isInteger(maxIterations) || maxIterations < 0 || maxIterations > 4) {
    throw new Error(`Invalid --max-iterations value: ${maxIterations}`);
  }

  const draft = await draftDiagram(prompt, provider);
  let spec = applyAutoLayout(draft.spec);
  const outputDir = resolve(ROOT, requestedOutDir || join('out', fileStemFromPrompt(prompt)));
  await mkdir(outputDir, { recursive: true });

  const promptPath = join(outputDir, 'prompt.txt');
  const specPath = join(outputDir, 'diagram-spec.json');
  const xmlPath = join(outputDir, 'diagram.maxgraph.xml');
  const reportPath = join(outputDir, 'diagram-report.json');
  const imagePath = join(outputDir, 'diagram.png');
  const summaryPath = join(outputDir, 'diagram-summary.md');
  const mxgraphXmlPath = join(outputDir, 'diagram.mxgraph.xml');

  const providerNotes = [...draft.notes];
  let revisionsApplied = 0;
  let report = await writeAndRender(spec, {
    outputDir,
    prompt,
    promptPath,
    specPath,
    xmlPath,
    reportPath,
    imagePath,
    mxgraphXmlPath,
    renderPort,
  });

  for (let iteration = 0; iteration < maxIterations; iteration += 1) {
    const revision = reviseSpecWithReport(spec, report, prompt);
    if (!revision.changed) {
      break;
    }
    revisionsApplied += 1;
    spec = applyAutoLayout(revision.spec);
    report = await writeAndRender(spec, {
      outputDir,
      prompt,
      promptPath,
      specPath,
      xmlPath,
      reportPath,
      imagePath,
      mxgraphXmlPath,
      renderPort,
    });
  }

  const summary = renderSummary(prompt, draft.provider, spec, report, providerNotes, revisionsApplied);
  await writeTextFile(summaryPath, summary);

  const artifacts: WizardArtifacts = {
    promptPath,
    specPath,
    xmlPath,
    mxgraphXmlPath,
    imagePath,
    reportPath,
    summaryPath,
  };

  return {
    outputDir,
    provider: draft.provider,
    spec,
    report,
    summary,
    artifacts,
    revisionsApplied,
    providerNotes,
  };
}

async function writeAndRender(
  spec: DiagramSpec,
  options: {
    outputDir: string;
    prompt: string;
    promptPath: string;
    specPath: string;
    xmlPath: string;
    reportPath: string;
    imagePath: string;
    mxgraphXmlPath: string;
    renderPort: number;
  },
) {
  const xml = specToMaxGraphXml(spec);
  await writeTextFile(options.promptPath, `${options.prompt}\n`);
  await writeTextFile(options.specPath, json(spec));
  await writeTextFile(options.xmlPath, xml);
  await writeTextFile(options.mxgraphXmlPath, convertMaxGraphXmlToMxGraphXml(xml));

  return renderDiagramArtifacts({
    rootDir: ROOT,
    diagramPath: options.xmlPath,
    imagePath: options.imagePath,
    reportPath: options.reportPath,
    port: options.renderPort,
  });
}

async function draftDiagram(prompt: string, provider: string): Promise<DiagramDraft> {
  switch (provider) {
    case 'heuristic':
      return draftHeuristicDiagram(prompt);
    case 'openai':
      return draftOpenAiDiagram(prompt);
    case 'auto':
      return draftOpenAiDiagram(prompt);
    default:
      throw new Error(`Unknown --provider value: ${provider}`);
  }
}

function renderSummary(
  prompt: string,
  provider: string,
  spec: DiagramSpec,
  report: WizardResult['report'],
  providerNotes: string[],
  revisionsApplied: number,
) {
  const lines = [
    `# ${titleFromPrompt(prompt)}`,
    '',
    `Provider: ${provider}`,
    `Revisions applied after render inspection: ${revisionsApplied}`,
    '',
    '## Final diagram description',
    spec.summary,
    '',
    '## Final graph contents',
    `- Nodes: ${report.vertexCount}`,
    `- Edges: ${report.edgeCount}`,
    `- Labels: ${report.labels.join(', ') || '(none)'}`,
    '',
    '## Rationale',
    ...spec.rationale.map((item) => `- ${item}`),
    '',
    '## Suggestions for changes',
    ...spec.changeSuggestions.map((item) => `- ${item}`),
    '',
    '## Provider notes',
    ...providerNotes.map((item) => `- ${item}`),
    '',
  ];
  return lines.join('\n');
}

function getPrompt(parsed: Args) {
  const fromFlag = getOptionalFlag(parsed, 'prompt');
  if (fromFlag) {
    return fromFlag.trim();
  }
  if (parsed.positional.length > 0) {
    return parsed.positional.join(' ').trim();
  }
  throw new Error('Missing prompt. Use graph-wizard "describe your graph" or --prompt "..."');
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

function getFlag(parsed: Args, key: string, fallback: string) {
  const value = parsed.flags.get(key);
  if (typeof value === 'string') {
    return value;
  }
  if (typeof value === 'boolean') {
    throw new Error(`Missing value for --${key}`);
  }
  return fallback;
}

function getOptionalFlag(parsed: Args, key: string) {
  const value = parsed.flags.get(key);
  if (typeof value === 'string') {
    return value;
  }
  if (typeof value === 'boolean') {
    throw new Error(`Missing value for --${key}`);
  }
  return null;
}

function convertMaxGraphXmlToMxGraphXml(xml: string) {
  let output = xml.replace(/\r\n/g, '\n');

  output = output.replace(/<Cell\b[\s\S]*?<\/Cell>/g, (cellBlock) => convertCellBlockToMxGraph(cellBlock));
  output = output
    .replace(/<GraphDataModel\b/g, '<mxGraphModel')
    .replace(/<\/GraphDataModel>/g, '</mxGraphModel>')
    .replace(/<Cell\b/g, '<mxCell')
    .replace(/<\/Cell>/g, '</mxCell>')
    .replace(/<Geometry\b/g, '<mxGeometry')
    .replace(/<\/Geometry>/g, '</mxGeometry>')
    .replace(/<Point\b/g, '<mxPoint')
    .replace(/<\/Point>/g, '</mxPoint>');
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
    const style = buildMxStyle(attributes);
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

function buildMxStyle(attributes: Map<string, string>) {
  const styleEntries: string[] = [];
  for (const [rawKey, value] of attributes.entries()) {
    if (rawKey === 'as') {
      continue;
    }
    const mxKey = rawKey === 'autoSize' ? 'autosize' : rawKey;
    styleEntries.push(`${mxKey}=${value}`);
  }
  return styleEntries.length === 0 ? '' : `${styleEntries.join(';')};`;
}

function escapeXmlAttribute(value: string) {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('"', '&quot;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');
}
