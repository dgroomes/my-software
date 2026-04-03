import type { DiagramEdge, DiagramNode, DiagramSpec } from './types';
import { escapeXmlText } from './utils';

const STYLE_BY_KIND: Record<string, Record<string, string | number>> = {
  service: { rounded: 1, whiteSpace: 'wrap', html: 1, fillColor: '#dae8fc', strokeColor: '#6c8ebf' },
  storage: { rounded: 1, whiteSpace: 'wrap', html: 1, fillColor: '#d5e8d4', strokeColor: '#82b366' },
  queue: { rounded: 1, whiteSpace: 'wrap', html: 1, fillColor: '#ffe6cc', strokeColor: '#d79b00' },
  network: { rounded: 1, whiteSpace: 'wrap', html: 1, fillColor: '#e1d5e7', strokeColor: '#9673a6' },
  user: { shape: 'ellipse', whiteSpace: 'wrap', html: 1, fillColor: '#f8cecc', strokeColor: '#b85450' },
  observability: { rounded: 1, whiteSpace: 'wrap', html: 1, fillColor: '#fff2cc', strokeColor: '#d6b656' },
  lambda: { rounded: 1, whiteSpace: 'wrap', html: 1, fillColor: '#f5f5f5', strokeColor: '#666666' },
  group: { rounded: 1, dashed: 1, whiteSpace: 'wrap', html: 1, fillColor: '#f5f5f5', strokeColor: '#999999' },
};

const EDGE_STYLE_BY_KIND: Record<string, Record<string, string | number>> = {
  flow: { endArrow: 'block', html: 1, rounded: 1, strokeColor: '#6c8ebf' },
  data: { endArrow: 'block', html: 1, rounded: 1, strokeColor: '#82b366' },
  event: { endArrow: 'block', html: 1, rounded: 1, dashed: 1, strokeColor: '#d79b00' },
  control: { endArrow: 'block', html: 1, rounded: 1, strokeColor: '#9673a6' },
  log: { endArrow: 'block', html: 1, rounded: 1, dashed: 1, strokeColor: '#d6b656' },
};

export function specToMaxGraphXml(spec: DiagramSpec) {
  const nodeIndex = new Map(spec.nodes.map((node, index) => [node.id, index]));
  const edgeOffset = spec.nodes.length + 2;
  const cells = [
    '  <root>',
    '    <Cell id="0">',
    '      <Object as="style" />',
    '    </Cell>',
    '    <Cell id="1" parent="0">',
    '      <Object as="style" />',
    '    </Cell>',
    ...spec.nodes.map((node, index) => renderNode(node, index + 2)),
    ...spec.edges.map((edge, index) => renderEdge(edge, edgeOffset + index, nodeIndex)),
    '  </root>',
  ];

  return ['<GraphDataModel>', ...cells, '</GraphDataModel>'].join('\n');
}

function renderNode(node: DiagramNode, cellId: number) {
  const style = node.shape === 'ellipse'
    ? { ...STYLE_BY_KIND[node.kind], shape: 'ellipse' }
    : STYLE_BY_KIND[node.kind] ?? STYLE_BY_KIND.service;
  const geometry = `      <Geometry _x="${round(node.x ?? 0)}" _y="${round(node.y ?? 0)}" _width="${round(node.width ?? 180)}" _height="${round(node.height ?? 72)}" as="geometry" />`;
  return [
    `    <Cell id="${cellId}" value="${escapeXmlText(node.label)}" vertex="1" parent="1">`,
    geometry,
    `      <Object ${renderStyleAttributes(style)} as="style" />`,
    '    </Cell>',
  ].join('\n');
}

function renderEdge(edge: DiagramEdge, cellId: number, nodeIndex: Map<string, number>) {
  const sourceCellId = (nodeIndex.get(edge.source) ?? 0) + 2;
  const targetCellId = (nodeIndex.get(edge.target) ?? 0) + 2;
  const style = EDGE_STYLE_BY_KIND[edge.kind ?? 'flow'] ?? EDGE_STYLE_BY_KIND.flow;
  return [
    `    <Cell id="${cellId}" value="${escapeXmlText(edge.label ?? '')}" edge="1" parent="1" source="${sourceCellId}" target="${targetCellId}">`,
    '      <Geometry relative="1" as="geometry" />',
    `      <Object ${renderStyleAttributes(style)} as="style" />`,
    '    </Cell>',
  ].join('\n');
}

function renderStyleAttributes(style: Record<string, string | number>) {
  return Object.entries(style)
    .map(([key, value]) => `${key}="${escapeXmlText(String(value))}"`)
    .join(' ');
}

function round(value: number) {
  return Math.round(value);
}
