import type { DiagramNode, DiagramSpec } from './types';

const DEFAULT_WIDTH = 180;
const DEFAULT_HEIGHT = 72;
const HORIZONTAL_GAP = 220;
const VERTICAL_GAP = 150;
const START_X = 80;
const START_Y = 80;

export function applyAutoLayout(spec: DiagramSpec): DiagramSpec {
  const incomingCount = new Map<string, number>();
  const outgoingCount = new Map<string, number>();

  for (const edge of spec.edges) {
    incomingCount.set(edge.target, (incomingCount.get(edge.target) ?? 0) + 1);
    outgoingCount.set(edge.source, (outgoingCount.get(edge.source) ?? 0) + 1);
  }

  const orderedNodes = [...spec.nodes].sort((a, b) => scoreNode(a, incomingCount, outgoingCount) - scoreNode(b, incomingCount, outgoingCount));

  const layerByNodeId = new Map<string, number>();
  const nodeIds = new Set(spec.nodes.map((node) => node.id));

  for (const node of orderedNodes) {
    const parentLayers = spec.edges
      .filter((edge) => edge.target === node.id && nodeIds.has(edge.source))
      .map((edge) => layerByNodeId.get(edge.source) ?? 0);
    const layer = parentLayers.length === 0 ? 0 : Math.max(...parentLayers) + 1;
    layerByNodeId.set(node.id, layer);
  }

  const lanes = new Map<number, DiagramNode[]>();
  for (const node of orderedNodes) {
    const layer = layerByNodeId.get(node.id) ?? 0;
    const lane = lanes.get(layer) ?? [];
    lane.push(node);
    lanes.set(layer, lane);
  }

  const nodes = spec.nodes.map((node) => {
    const layer = layerByNodeId.get(node.id) ?? 0;
    const lane = lanes.get(layer) ?? [];
    const index = lane.findIndex((candidate) => candidate.id === node.id);
    return {
      ...node,
      x: node.x ?? START_X + layer * HORIZONTAL_GAP,
      y: node.y ?? START_Y + index * VERTICAL_GAP,
      width: node.width ?? defaultWidth(node),
      height: node.height ?? defaultHeight(node),
    };
  });

  return {
    ...spec,
    nodes,
  };
}

function scoreNode(
  node: DiagramNode,
  incomingCount: Map<string, number>,
  outgoingCount: Map<string, number>,
) {
  const incoming = incomingCount.get(node.id) ?? 0;
  const outgoing = outgoingCount.get(node.id) ?? 0;
  const roleBias = node.kind === 'user' ? -2 : node.kind === 'network' ? -1 : node.kind === 'observability' ? 2 : 0;
  return incoming * 10 - outgoing * 5 + roleBias;
}

function defaultWidth(node: DiagramNode) {
  if (node.label.length > 18) {
    return 220;
  }
  if (node.kind === 'observability' || node.kind === 'network') {
    return 190;
  }
  return DEFAULT_WIDTH;
}

function defaultHeight(node: DiagramNode) {
  if (node.description && node.description.length > 70) {
    return 86;
  }
  return DEFAULT_HEIGHT;
}
