export type DiagramStyle = 'service' | 'storage' | 'queue' | 'network' | 'user' | 'observability' | 'lambda' | 'group';

export type DiagramNode = {
  id: string;
  label: string;
  kind: DiagramStyle;
  description?: string;
  x?: number;
  y?: number;
  width?: number;
  height?: number;
  shape?: 'rect' | 'ellipse';
};

export type DiagramEdge = {
  id: string;
  source: string;
  target: string;
  label?: string;
  kind?: 'flow' | 'data' | 'event' | 'control' | 'log';
};

export type DiagramSpec = {
  title: string;
  summary: string;
  prompt: string;
  nodes: DiagramNode[];
  edges: DiagramEdge[];
  rationale: string[];
  changeSuggestions: string[];
};

export type WizardProvider = 'heuristic' | 'openai';

export type DiagramDraft = {
  provider: WizardProvider;
  spec: DiagramSpec;
  notes: string[];
};

export type DiagramNodeReport = {
  id: string;
  label: string;
  x: number;
  y: number;
  width: number;
  height: number;
  style: string;
};

export type DiagramEdgeReport = {
  id: string;
  label: string;
  sourceId: string;
  sourceLabel: string;
  targetId: string;
  targetLabel: string;
  style: string;
};

export type DiagramReport = {
  generatedAt: string;
  vertexCount: number;
  edgeCount: number;
  bounds: {
    x: number;
    y: number;
    width: number;
    height: number;
  };
  labels: string[];
  nodes: DiagramNodeReport[];
  edges: DiagramEdgeReport[];
};

export type WizardArtifacts = {
  promptPath: string;
  specPath: string;
  xmlPath: string;
  mxgraphXmlPath: string;
  imagePath: string;
  reportPath: string;
  summaryPath: string;
};

export type WizardResult = {
  outputDir: string;
  provider: WizardProvider;
  spec: DiagramSpec;
  report: DiagramReport;
  summary: string;
  artifacts: WizardArtifacts;
  revisionsApplied: number;
  providerNotes: string[];
};
