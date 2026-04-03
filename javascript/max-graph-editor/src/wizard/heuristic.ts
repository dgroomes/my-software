import type { DiagramDraft, DiagramEdge, DiagramNode, DiagramSpec, DiagramStyle } from './types';
import { titleFromPrompt, unique } from './utils';

const KEYWORD_NODES: Array<{ pattern: RegExp; label: string; kind: DiagramStyle; description: string }> = [
  { pattern: /\b(user|browser|client|engineer|developer)\b/i, label: 'User', kind: 'user', description: 'Human or client entry point.' },
  { pattern: /\b(api gateway|gateway|ingress)\b/i, label: 'API Gateway', kind: 'network', description: 'Public entry point and request routing.' },
  { pattern: /\blambda|function(s)?\b/i, label: 'Lambda Functions', kind: 'lambda', description: 'Compute layer handling event-driven logic.' },
  { pattern: /\bqueue|sqs|event bus|events\b/i, label: 'Event Bus / Queue', kind: 'queue', description: 'Async messaging and event propagation.' },
  { pattern: /\bsns|notification\b/i, label: 'Notifications', kind: 'queue', description: 'Fan-out and notification delivery.' },
  { pattern: /\bdynamodb|database|rds|postgres|mysql\b/i, label: 'Data Store', kind: 'storage', description: 'Primary persistence layer.' },
  { pattern: /\bs3|bucket|object storage\b/i, label: 'Object Storage', kind: 'storage', description: 'Blob and file storage.' },
  { pattern: /\bcloudwatch|logging|logs|monitoring|metrics|trace|observability|x-ray\b/i, label: 'Observability', kind: 'observability', description: 'Logs, metrics, and traces.' },
  { pattern: /\biam|auth|authorization|identity\b/i, label: 'Identity / IAM', kind: 'service', description: 'AuthN/AuthZ and policy enforcement.' },
  { pattern: /\bnetwork|vpc|subnet|internet\b/i, label: 'Network Boundary', kind: 'network', description: 'Connectivity and network isolation.' },
];

export function draftHeuristicDiagram(prompt: string): DiagramDraft {
  const normalized = prompt.trim();
  const title = titleFromPrompt(normalized);
  const lower = normalized.toLowerCase();
  const nodes: DiagramNode[] = [];
  const notes: string[] = ['Used heuristic drafting because no LLM provider credentials were configured.'];

  for (const candidate of KEYWORD_NODES) {
    if (candidate.pattern.test(normalized)) {
      nodes.push({
        id: toNodeId(candidate.label),
        label: candidate.label,
        kind: candidate.kind,
        description: candidate.description,
        shape: candidate.kind === 'user' ? 'ellipse' : 'rect',
      });
    }
  }

  if (nodes.length === 0) {
    nodes.push(
      {
        id: 'user',
        label: 'User',
        kind: 'user',
        description: 'Primary actor requesting the system.',
        shape: 'ellipse',
      },
      {
        id: 'system',
        label: 'System',
        kind: 'service',
        description: 'Core system inferred from the natural-language prompt.',
      },
      {
        id: 'observability',
        label: 'Observability',
        kind: 'observability',
        description: 'Visibility into system behavior.',
      },
    );
    notes.push('No domain-specific keywords matched, so a generic interaction topology was generated.');
  }

  ensureEssentialNodes(nodes, lower);
  const edges = buildHeuristicEdges(nodes, lower);
  const summary = buildSummary(normalized, nodes, edges);
  const rationale = buildRationale(nodes, lower);
  const changeSuggestions = buildSuggestions(nodes, edges, lower);

  const spec: DiagramSpec = {
    title,
    summary,
    prompt: normalized,
    nodes,
    edges,
    rationale,
    changeSuggestions,
  };

  return { provider: 'heuristic', spec, notes };
}

function ensureEssentialNodes(nodes: DiagramNode[], lowerPrompt: string) {
  addIfMissing(nodes, {
    when: () => !hasNode(nodes, 'user') && !/internal|backend|batch/.test(lowerPrompt),
    node: { id: 'user', label: 'User', kind: 'user', description: 'Primary actor or calling client.', shape: 'ellipse' },
  });

  addIfMissing(nodes, {
    when: () => /lambda/.test(lowerPrompt) && !hasLabel(nodes, 'API Gateway'),
    node: {
      id: 'api-gateway',
      label: 'API Gateway',
      kind: 'network',
      description: 'Ingress for Lambda-triggering requests.',
    },
  });

  addIfMissing(nodes, {
    when: () => /lambda/.test(lowerPrompt) && !hasLabel(nodes, 'Observability'),
    node: {
      id: 'observability',
      label: 'Observability',
      kind: 'observability',
      description: 'Logs, metrics, and traces for Lambda workloads.',
    },
  });

  addIfMissing(nodes, {
    when: () => nodes.length < 3,
    node: { id: 'system-core', label: 'Core Service', kind: 'service', description: 'Central processing service.' },
  });
}

function buildHeuristicEdges(nodes: DiagramNode[], lowerPrompt: string): DiagramEdge[] {
  const edges: DiagramEdge[] = [];
  const user = findNode(nodes, 'user') ?? nodes[0];
  const gateway = findNodeByLabel(nodes, 'API Gateway');
  const lambda = findNodeByLabel(nodes, 'Lambda Functions');
  const queue = findNodeByLabel(nodes, 'Event Bus / Queue');
  const notifications = findNodeByLabel(nodes, 'Notifications');
  const dataStore = findStorageNode(nodes);
  const observability = findNodeByLabel(nodes, 'Observability');
  const networkBoundary = findNodeByLabel(nodes, 'Network Boundary');

  if (networkBoundary && gateway) {
    edges.push(makeEdge('network-ingress', networkBoundary.id, gateway.id, 'ingress', 'flow'));
  } else if (networkBoundary && lambda) {
    edges.push(makeEdge('network-entry', networkBoundary.id, lambda.id, 'network path', 'flow'));
  }

  if (user && gateway) {
    edges.push(makeEdge('request', user.id, gateway.id, 'request', 'flow'));
  }

  if (gateway && lambda) {
    edges.push(makeEdge('invoke', gateway.id, lambda.id, 'invoke', 'control'));
  }

  if (user && !gateway && lambda) {
    edges.push(makeEdge('invoke', user.id, lambda.id, 'invoke', 'control'));
  }

  if (lambda && dataStore) {
    edges.push(makeEdge('persist', lambda.id, dataStore.id, 'read/write', 'data'));
  }

  if (lambda && queue) {
    edges.push(makeEdge('publish', lambda.id, queue.id, 'publish event', 'event'));
  }

  if (queue && notifications) {
    edges.push(makeEdge('fanout', queue.id, notifications.id, 'fan-out', 'event'));
  }

  if (queue && lambda && /event|async|queue|sqs/.test(lowerPrompt)) {
    edges.push(makeEdge('trigger', queue.id, lambda.id, 'trigger', 'event'));
  }

  if (lambda && observability) {
    edges.push(makeEdge('logs', lambda.id, observability.id, 'logs/metrics', 'log'));
  }

  if (!edges.length) {
    for (let i = 0; i < nodes.length - 1; i += 1) {
      edges.push(makeEdge(`flow-${i + 1}`, nodes[i].id, nodes[i + 1].id, '', 'flow'));
    }
  }

  return dedupeEdges(edges);
}

function buildSummary(prompt: string, nodes: DiagramNode[], edges: DiagramEdge[]) {
  const nodeLabels = nodes.map((node) => node.label);
  return `Drafted a ${nodes.length}-node, ${edges.length}-edge architecture diagram for "${prompt}" highlighting ${nodeLabels.slice(0, 4).join(', ')}${nodeLabels.length > 4 ? ', and related components' : ''}.`;
}

function buildRationale(nodes: DiagramNode[], lowerPrompt: string) {
  const rationale = [
    `Started from the entities explicitly mentioned or strongly implied by the prompt.`,
    `Grouped the draft around execution flow first, then persistence and observability.`,
  ];

  if (/logging|observability|metrics|trace/.test(lowerPrompt)) {
    rationale.push('Promoted observability to a first-class node because the prompt explicitly asked for it.');
  }

  if (nodes.some((node) => node.kind === 'lambda')) {
    rationale.push('Represented Lambda separately so request paths and async event paths stay readable.');
  }

  return rationale;
}

function buildSuggestions(nodes: DiagramNode[], edges: DiagramEdge[], lowerPrompt: string) {
  const suggestions = [
    'Review whether any missing infrastructure boundaries should be grouped visually, such as VPC or account boundaries.',
    'Consider adding failure paths, retries, or DLQs if operational behavior matters.',
  ];

  if (!nodes.some((node) => node.kind === 'storage')) {
    suggestions.push('If the system persists state, add the specific data stores rather than leaving them implied.');
  }
  if (!/security|iam|auth/.test(lowerPrompt)) {
    suggestions.push('If security architecture matters, add IAM, auth, or trust boundaries as explicit nodes.');
  }
  if (edges.every((edge) => edge.label)) {
    suggestions.push('Edge labels are present; tighten them further if protocol-level detail matters.');
  }

  return unique(suggestions);
}

function addIfMissing(nodes: DiagramNode[], options: { when: () => boolean; node: DiagramNode }) {
  if (options.when() && !hasNode(nodes, options.node.id) && !hasLabel(nodes, options.node.label)) {
    nodes.push(options.node);
  }
}

function findStorageNode(nodes: DiagramNode[]) {
  return nodes.find((node) => node.kind === 'storage') ?? null;
}

function findNode(nodes: DiagramNode[], id: string) {
  return nodes.find((node) => node.id === id) ?? null;
}

function findNodeByLabel(nodes: DiagramNode[], label: string) {
  return nodes.find((node) => node.label === label) ?? null;
}

function hasNode(nodes: DiagramNode[], id: string) {
  return nodes.some((node) => node.id === id);
}

function hasLabel(nodes: DiagramNode[], label: string) {
  return nodes.some((node) => node.label === label);
}

function makeEdge(id: string, source: string, target: string, label: string, kind: DiagramEdge['kind']): DiagramEdge {
  return { id, source, target, label, kind };
}

function dedupeEdges(edges: DiagramEdge[]) {
  const seen = new Set<string>();
  return edges.filter((edge) => {
    const key = `${edge.source}->${edge.target}:${edge.label ?? ''}:${edge.kind ?? ''}`;
    if (seen.has(key)) {
      return false;
    }
    seen.add(key);
    return true;
  });
}

function toNodeId(label: string) {
  return label
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}
