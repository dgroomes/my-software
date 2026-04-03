import OpenAI from 'openai';
import { draftHeuristicDiagram } from './heuristic';
import type { DiagramDraft, DiagramEdge, DiagramNode, DiagramSpec } from './types';

const DEFAULT_MODEL = 'gpt-4.1-mini';

export async function draftOpenAiDiagram(prompt: string): Promise<DiagramDraft> {
  const apiKey = Bun.env.OPENAI_API_KEY;
  if (!apiKey) {
    return draftHeuristicDiagram(prompt);
  }

  const client = new OpenAI({ apiKey });
  const model = Bun.env.OPENAI_MODEL || DEFAULT_MODEL;

  try {
    const response = await client.responses.create({
      model,
      input: [
        {
          role: 'system',
          content: [
            {
              type: 'input_text',
              text:
                'You design clear architecture diagrams for maxGraph. Return JSON only. Produce a pragmatic first draft for an engineering diagram. Use 4-10 nodes, concise labels, and include observability when the prompt implies logs, metrics, or traces. Prefer graph readability over completeness.',
            },
          ],
        },
        {
          role: 'user',
          content: [
            {
              type: 'input_text',
              text: [
                'Create a maxGraph-ready diagram specification for this prompt:',
                prompt,
                '',
                'Return JSON with this exact shape:',
                '{',
                '  "title": string,',
                '  "summary": string,',
                '  "prompt": string,',
                '  "nodes": [{ "id": string, "label": string, "kind": "service"|"storage"|"queue"|"network"|"user"|"observability"|"lambda"|"group", "description"?: string, "shape"?: "rect"|"ellipse" }],',
                '  "edges": [{ "id": string, "source": string, "target": string, "label"?: string, "kind"?: "flow"|"data"|"event"|"control"|"log" }],',
                '  "rationale": string[],',
                '  "changeSuggestions": string[]',
                '}',
                '',
                'Requirements:',
                '- Use stable lowercase kebab-case ids.',
                '- Reference only node ids that exist.',
                '- Keep edge labels short.',
                '- Do not include markdown fences.',
              ].join('\n'),
            },
          ],
        },
      ],
    });

    const raw = response.output_text.trim();
    const parsed = JSON.parse(raw) as DiagramSpec;
    const spec = normalizeSpec(parsed, prompt);

    return {
      provider: 'openai',
      spec,
      notes: [`Drafted with OpenAI model ${model}.`],
    };
  } catch (error) {
    const fallback = draftHeuristicDiagram(prompt);
    fallback.notes.unshift(`OpenAI drafting failed, so the heuristic provider was used instead: ${String(error)}`);
    return fallback;
  }
}

function normalizeSpec(input: DiagramSpec, prompt: string): DiagramSpec {
  const nodes = normalizeNodes(Array.isArray(input.nodes) ? input.nodes : []);
  const nodeIds = new Set(nodes.map((node) => node.id));
  const edges = normalizeEdges(Array.isArray(input.edges) ? input.edges : []).filter(
    (edge) => nodeIds.has(edge.source) && nodeIds.has(edge.target),
  );

  return {
    title: String(input.title || prompt).trim(),
    summary: String(input.summary || '').trim() || `Drafted diagram for "${prompt}".`,
    prompt,
    nodes,
    edges,
    rationale: Array.isArray(input.rationale) ? input.rationale.map(String).map((value) => value.trim()).filter(Boolean) : [],
    changeSuggestions: Array.isArray(input.changeSuggestions)
      ? input.changeSuggestions.map(String).map((value) => value.trim()).filter(Boolean)
      : [],
  };
}

function normalizeNodes(nodes: DiagramNode[]): DiagramNode[] {
  const seen = new Set<string>();
  const output: DiagramNode[] = [];
  for (const node of nodes) {
    const id = toId(node.id || node.label || `node-${output.length + 1}`);
    if (seen.has(id)) {
      continue;
    }
    seen.add(id);
    output.push({
      id,
      label: String(node.label || id).trim(),
      kind: normalizeKind(node.kind),
      description: typeof node.description === 'string' ? node.description.trim() : undefined,
      shape: node.shape === 'ellipse' ? 'ellipse' : 'rect',
    });
  }
  return output;
}

function normalizeEdges(edges: DiagramEdge[]): DiagramEdge[] {
  const output: DiagramEdge[] = [];
  for (const edge of edges) {
    const source = toId(edge.source);
    const target = toId(edge.target);
    if (!source || !target) {
      continue;
    }
    output.push({
      id: toId(edge.id || `${source}-to-${target}`),
      source,
      target,
      label: typeof edge.label === 'string' ? edge.label.trim() : '',
      kind: normalizeEdgeKind(edge.kind),
    });
  }
  return output;
}

function normalizeKind(kind: DiagramNode['kind']): DiagramNode['kind'] {
  const allowed = new Set(['service', 'storage', 'queue', 'network', 'user', 'observability', 'lambda', 'group']);
  return allowed.has(String(kind)) ? (kind as DiagramNode['kind']) : 'service';
}

function normalizeEdgeKind(kind: DiagramEdge['kind']): DiagramEdge['kind'] {
  const allowed = new Set(['flow', 'data', 'event', 'control', 'log']);
  return allowed.has(String(kind)) ? (kind as DiagramEdge['kind']) : 'flow';
}

function toId(value: string) {
  return String(value)
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}
