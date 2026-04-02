import type { DiagramReport, DiagramSpec } from './types';

export function reviseSpecWithReport(spec: DiagramSpec, report: DiagramReport, prompt: string) {
  const next: DiagramSpec = {
    ...spec,
    nodes: [...spec.nodes],
    edges: [...spec.edges],
    rationale: [...spec.rationale],
    changeSuggestions: [...spec.changeSuggestions],
  };

  const lowerPrompt = prompt.toLowerCase();
  let changed = false;

  if (/\b(logging|logs|observability|metrics|trace|cloudwatch)\b/.test(lowerPrompt)) {
    const hasObservability = next.nodes.some((node) => node.kind === 'observability');
    if (!hasObservability) {
      next.nodes.push({
        id: 'observability',
        label: 'Observability',
        kind: 'observability',
        description: 'Logs, metrics, and traces collected for the system.',
      });
      const lambdaNode = next.nodes.find((node) => node.kind === 'lambda');
      const primaryNode = lambdaNode ?? next.nodes.find((node) => node.kind !== 'user') ?? next.nodes[0];
      if (primaryNode) {
        next.edges.push({
          id: `${primaryNode.id}-to-observability`,
          source: primaryNode.id,
          target: 'observability',
          label: 'logs/metrics',
          kind: 'log',
        });
      }
      next.rationale.push('Added an observability sink after inspecting the draft against the prompt requirements.');
      changed = true;
    }
  }

  if (/\blambda\b/.test(lowerPrompt)) {
    const hasGateway = next.nodes.some((node) => node.label === 'API Gateway');
    const lambdaNode = next.nodes.find((node) => node.kind === 'lambda');
    const userNode = next.nodes.find((node) => node.kind === 'user');
    if (lambdaNode && userNode && !hasGateway) {
      next.nodes.unshift({
        id: 'api-gateway',
        label: 'API Gateway',
        kind: 'network',
        description: 'Ingress and routing for Lambda requests.',
      });
      next.edges = next.edges.filter((edge) => !(edge.source === userNode.id && edge.target === lambdaNode.id));
      next.edges.unshift(
        {
          id: `${userNode.id}-to-api-gateway`,
          source: userNode.id,
          target: 'api-gateway',
          label: 'request',
          kind: 'flow',
        },
        {
          id: `api-gateway-to-${lambdaNode.id}`,
          source: 'api-gateway',
          target: lambdaNode.id,
          label: 'invoke',
          kind: 'control',
        },
      );
      next.rationale.push('Inserted an API Gateway in the request path after inspection to improve AWS Lambda topology clarity.');
      changed = true;
    }
  }

  if (report.vertexCount < 3 && next.nodes.length < 3) {
    next.changeSuggestions.push('The diagram is still minimal. Consider adding operational or infrastructure context.');
  }

  return { changed, spec: dedupeSpec(next) };
}

function dedupeSpec(spec: DiagramSpec): DiagramSpec {
  const nodeIds = new Set<string>();
  const nodes = spec.nodes.filter((node) => {
    if (nodeIds.has(node.id)) {
      return false;
    }
    nodeIds.add(node.id);
    return true;
  });

  const edgeIds = new Set<string>();
  const edges = spec.edges.filter((edge) => {
    if (!nodeIds.has(edge.source) || !nodeIds.has(edge.target)) {
      return false;
    }
    if (edgeIds.has(edge.id)) {
      return false;
    }
    edgeIds.add(edge.id);
    return true;
  });

  return {
    ...spec,
    nodes,
    edges,
    rationale: [...new Set(spec.rationale)],
    changeSuggestions: [...new Set(spec.changeSuggestions)],
  };
}
