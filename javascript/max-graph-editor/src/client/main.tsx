import React, { useEffect, useMemo, useRef, useState } from 'react';
import { createRoot } from 'react-dom/client';
import {
  type Cell,
  Graph,
  InternalEvent,
  KeyHandler,
  ModelXmlSerializer,
  PopupMenuHandler,
  RubberBandHandler,
} from '@maxgraph/core';

type SyncMessage = {
  type?: string;
  xml?: string;
  source?: string;
  message?: string;
};

type DiagramNodeReport = {
  id: string;
  label: string;
  x: number;
  y: number;
  width: number;
  height: number;
  style: string;
};

type DiagramEdgeReport = {
  id: string;
  label: string;
  sourceId: string;
  sourceLabel: string;
  targetId: string;
  targetLabel: string;
  style: string;
};

type DiagramReport = {
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

type MaxGraphEditorApi = {
  graph: Graph;
  insertVertex: (
    label: string,
    x: number,
    y: number,
    width: number,
    height: number,
    style?: unknown,
  ) => { id: string; label: string };
  addBox: (label: string, x: number, y: number, width: number, height: number) => { id: string; label: string };
  addEllipse: (
    label: string,
    x: number,
    y: number,
    width: number,
    height: number,
  ) => { id: string; label: string };
  connectSelection: () => { id: string } | null;
  deleteSelection: () => number;
  getXml: () => string;
  setXml: (xml: string) => void;
  getDiagramReport: () => DiagramReport;
  prepareForExport: (options?: { padding?: number; maxScale?: number }) => DiagramReport;
};

const RECT_STYLE = { rounded: 1, whiteSpace: 'wrap', html: 1, fillColor: '#dae8fc', strokeColor: '#6c8ebf' };
const ELLIPSE_STYLE = { shape: 'ellipse', whiteSpace: 'wrap', html: 1, fillColor: '#fff2cc', strokeColor: '#d6b656' };
const DEFAULT_VERTEX_WIDTH = 150;
const DEFAULT_VERTEX_HEIGHT = 64;

declare global {
  interface Window {
    __maxGraphEditor?: MaxGraphEditorApi;
  }
}

function App() {
  const [xml, setXml] = useState('');
  const [status, setStatus] = useState('Connecting...');
  const [statusClass, setStatusClass] = useState('muted');
  const [preview, setPreview] = useState('No updates yet.');
  const [nextLabel, setNextLabel] = useState('New Node');
  const [selectionCount, setSelectionCount] = useState(0);

  const graphContainerRef = useRef<HTMLDivElement | null>(null);
  const graphRef = useRef<Graph | null>(null);
  const keyHandlerRef = useRef<KeyHandler | null>(null);
  const socketRef = useRef<WebSocket | null>(null);
  const sendTimerRef = useRef<number | null>(null);
  const xmlRef = useRef('');
  const applyingXmlRef = useRef(false);
  const nextInsertPointRef = useRef({ x: 80, y: 80 });

  const socketUrl = useMemo(
    () => `${location.protocol === 'https:' ? 'wss' : 'ws'}://${location.host}/sync`,
    [],
  );
  const renderOnly = useMemo(() => new URLSearchParams(location.search).get('mode') === 'render', []);

  useEffect(() => {
    document.body.classList.toggle('render-only', renderOnly);
    return () => {
      document.body.classList.remove('render-only');
    };
  }, [renderOnly]);

  useEffect(() => {
    const container = graphContainerRef.current;
    if (!container) {
      return;
    }

    container.tabIndex = 0;
    InternalEvent.disableContextMenu(container);
    const graph = new Graph(container);
    graph.setConnectable(!renderOnly);
    graph.setCellsEditable(!renderOnly);
    graph.setCellsMovable(!renderOnly);
    graph.setCellsResizable(!renderOnly);
    graph.setPanning(!renderOnly);
    new RubberBandHandler(graph);
    graph.getDataModel().addListener(InternalEvent.CHANGE, onGraphModelChanged);
    const onSelectionChanged = () => setSelectionCount(graph.getSelectionCount());
    graph.getSelectionModel().addListener(InternalEvent.CHANGE, onSelectionChanged);

    let keyHandler: KeyHandler | null = null;
    if (!renderOnly) {
      keyHandler = new KeyHandler(graph, container);
      keyHandler.bindKey(46, () => {
        removeSelection();
      });
      keyHandler.bindKey(8, () => {
        removeSelection();
      });
      keyHandlerRef.current = keyHandler;
    }

    const popupMenuHandler = graph.getPlugin<PopupMenuHandler>('PopupMenuHandler');
    if (popupMenuHandler && !renderOnly) {
      popupMenuHandler.factoryMethod = (menu, cell, mouseEvent) => {
        const point = graph.getPointForEvent(mouseEvent);
        menu.addItem('Add Box', null, () => {
          insertVertexWithStyle('New Node', point.x, point.y, DEFAULT_VERTEX_WIDTH, DEFAULT_VERTEX_HEIGHT, RECT_STYLE);
        });
        menu.addItem('Add Ellipse', null, () => {
          insertVertexWithStyle(
            'New Node',
            point.x,
            point.y,
            DEFAULT_VERTEX_WIDTH,
            DEFAULT_VERTEX_HEIGHT,
            ELLIPSE_STYLE,
          );
        });
        if (graph.getSelectionCount() >= 2) {
          menu.addItem('Connect Selected', null, () => {
            connectSelection();
          });
        }
        const candidateCells = cell ? [cell] : graph.getSelectionCells();
        if (candidateCells.length > 0) {
          menu.addItem('Delete', null, () => {
            const deletable = graph.getDeletableCells(candidateCells);
            if (deletable.length > 0) {
              graph.removeCells(deletable);
            }
          });
        }
      };
    }

    const focusGraph = () => {
      container.focus();
    };
    if (!renderOnly) {
      container.addEventListener('pointerdown', focusGraph);
    }

    onSelectionChanged();
    graphRef.current = graph;

    const api: MaxGraphEditorApi = {
      graph,
      insertVertex(label, x, y, width, height, style) {
        return insertVertexWithStyle(label, x, y, width, height, style);
      },
      addBox(label, x, y, width, height) {
        return insertVertexWithStyle(label, x, y, width, height, RECT_STYLE);
      },
      addEllipse(label, x, y, width, height) {
        return insertVertexWithStyle(label, x, y, width, height, ELLIPSE_STYLE);
      },
      connectSelection() {
        return connectSelection();
      },
      deleteSelection() {
        return removeSelection();
      },
      getXml() {
        return new ModelXmlSerializer(graph.getDataModel()).export();
      },
      setXml(nextXml: string) {
        try {
          applyingXmlRef.current = true;
          new ModelXmlSerializer(graph.getDataModel()).import(nextXml);
          graph.refresh();
        } finally {
          applyingXmlRef.current = false;
        }
      },
      getDiagramReport() {
        return buildDiagramReport();
      },
      prepareForExport(options) {
        return prepareForExport(options);
      },
    };
    window.__maxGraphEditor = api;

    return () => {
      if (window.__maxGraphEditor === api) {
        delete window.__maxGraphEditor;
      }
      if (!renderOnly) {
        container.removeEventListener('pointerdown', focusGraph);
      }
      keyHandler?.onDestroy();
      keyHandlerRef.current = null;
      graph.getSelectionModel().removeListener(onSelectionChanged);
      graph.getDataModel().removeListener(onGraphModelChanged);
      graph.destroy();
      graphRef.current = null;
    };
  }, [renderOnly]);

  useEffect(() => {
    void loadInitial();
    connect();

    return () => {
      if (sendTimerRef.current) {
        window.clearTimeout(sendTimerRef.current);
      }
      socketRef.current?.close();
    };
  }, [socketUrl]);

  function connect() {
    const socket = new WebSocket(socketUrl);
    socketRef.current = socket;

    socket.addEventListener('open', () => setStatusWithClass('Connected', 'ok'));

    socket.addEventListener('close', () => {
      setStatusWithClass('Disconnected; retrying...', 'warn');
      window.setTimeout(connect, 800);
    });

    socket.addEventListener('message', (event) => {
      const payload = JSON.parse(event.data) as SyncMessage;
      if (payload.type === 'diagram' && typeof payload.xml === 'string' && payload.xml !== xmlRef.current) {
        setXml(payload.xml);
        xmlRef.current = payload.xml;
        renderGraph(payload.xml);
        renderPreview(payload.source ?? 'remote', payload.xml);
      } else if (payload.type === 'error' && typeof payload.message === 'string') {
        setStatusWithClass(`Sync error: ${payload.message}`, 'warn');
      }
    });
  }

  async function loadInitial() {
    const response = await fetch('/api/diagram');
    const initialXml = await response.text();
    setXml(initialXml);
    xmlRef.current = initialXml;
    renderGraph(initialXml);
    renderPreview('loaded from disk', initialXml);
  }

  function onXmlChanged(nextXml: string) {
    setXml(nextXml);
    xmlRef.current = nextXml;
    renderGraph(nextXml);
    renderPreview('local edit', nextXml);
    queuePersist(nextXml);
  }

  async function persistXml(nextXml: string) {
    try {
      const response = await fetch('/api/diagram', {
        method: 'PUT',
        headers: { 'content-type': 'application/xml; charset=utf-8' },
        body: nextXml,
      });

      if (!response.ok) {
        setStatusWithClass(`Sync failed (${response.status})`, 'warn');
        return;
      }

      setStatusWithClass('Synced to disk', 'ok');
    } catch {
      setStatusWithClass('Sync failed (network)', 'warn');
    }
  }

  function renderGraph(nextXml: string) {
    const graph = graphRef.current;
    if (!graph) {
      return;
    }

    try {
      applyingXmlRef.current = true;
      new ModelXmlSerializer(graph.getDataModel()).import(nextXml);
      graph.refresh();
    } catch (error) {
      renderPreview('render error', String(error));
    } finally {
      applyingXmlRef.current = false;
    }

    if (renderOnly) {
      window.setTimeout(() => {
        prepareForExport();
      }, 25);
    }
  }

  function onGraphModelChanged() {
    if (applyingXmlRef.current) {
      return;
    }

    const graph = graphRef.current;
    if (!graph) {
      return;
    }

    const nextXml = new ModelXmlSerializer(graph.getDataModel()).export();
    setXml(nextXml);
    xmlRef.current = nextXml;
    renderPreview('graph edit', nextXml);
    queuePersist(nextXml);
  }

  function normalizedLabel(raw: string) {
    const trimmed = raw.trim();
    return trimmed.length > 0 ? trimmed : 'New Node';
  }

  function nextInsertPoint() {
    const point = { ...nextInsertPointRef.current };
    nextInsertPointRef.current = { x: point.x + 44, y: point.y + 28 };
    if (nextInsertPointRef.current.x > 900) {
      nextInsertPointRef.current.x = 80;
    }
    if (nextInsertPointRef.current.y > 620) {
      nextInsertPointRef.current.y = 80;
    }
    return point;
  }

  function insertVertexWithStyle(
    label: string,
    x: number,
    y: number,
    width: number,
    height: number,
    style?: unknown,
  ): { id: string; label: string } {
    const graph = graphRef.current;
    const safeLabel = normalizedLabel(label);
    if (!graph) {
      return { id: '', label: safeLabel };
    }

    let insertedId = '';
    let insertedCell: unknown;
    graph.batchUpdate(() => {
      insertedCell = graph.insertVertex(
        graph.getDefaultParent(),
        null,
        safeLabel,
        x,
        y,
        width,
        height,
        style as never,
      );
      insertedId = String((insertedCell as { id?: string }).id ?? '');
    });
    if (insertedCell) {
      graph.setSelectionCell(insertedCell as never);
    }
    setStatusWithClass('Node added', 'ok');
    return { id: insertedId, label: safeLabel };
  }

  function insertShape(shape: 'box' | 'ellipse') {
    const point = nextInsertPoint();
    if (shape === 'ellipse') {
      insertVertexWithStyle(
        nextLabel,
        point.x,
        point.y,
        DEFAULT_VERTEX_WIDTH,
        DEFAULT_VERTEX_HEIGHT,
        ELLIPSE_STYLE,
      );
      return;
    }
    insertVertexWithStyle(nextLabel, point.x, point.y, DEFAULT_VERTEX_WIDTH, DEFAULT_VERTEX_HEIGHT, RECT_STYLE);
  }

  function removeSelection() {
    const graph = graphRef.current;
    if (!graph) {
      return 0;
    }
    const selection = graph.getSelectionCells();
    const deletable = graph.getDeletableCells(selection);
    if (deletable.length === 0) {
      return 0;
    }
    graph.removeCells(deletable);
    setStatusWithClass(`Deleted ${deletable.length} cell${deletable.length === 1 ? '' : 's'}`, 'ok');
    return deletable.length;
  }

  function connectSelection() {
    const graph = graphRef.current;
    if (!graph) {
      return null;
    }

    const selection = graph.getSelectionCells();
    if (selection.length < 2) {
      return null;
    }

    const [source, target] = selection;
    let edgeId = '';
    graph.batchUpdate(() => {
      const edge = graph.insertEdge(
        graph.getDefaultParent(),
        null,
        '',
        source,
        target,
        { endArrow: 'block', html: 1, rounded: 1 } as never,
      ) as { id?: string };
      edgeId = String(edge.id ?? '');
      graph.setSelectionCell(edge as never);
    });
    setStatusWithClass('Connected selected cells', 'ok');
    return edgeId ? { id: edgeId } : null;
  }

  function queuePersist(nextXml: string) {
    if (sendTimerRef.current) {
      window.clearTimeout(sendTimerRef.current);
    }

    sendTimerRef.current = window.setTimeout(() => {
      void persistXml(nextXml);
    }, 250);
  }

  function setStatusWithClass(text: string, cssClass: string) {
    setStatus(text);
    setStatusClass(cssClass);
  }

  function renderPreview(source: string, nextXml: string) {
    setPreview(`[${new Date().toLocaleTimeString()}] ${source}\n\n${nextXml}`);
  }

  function buildDiagramReport(): DiagramReport {
    const graph = graphRef.current;
    if (!graph) {
      return {
        generatedAt: new Date().toISOString(),
        vertexCount: 0,
        edgeCount: 0,
        bounds: { x: 0, y: 0, width: 0, height: 0 },
        labels: [],
        nodes: [],
        edges: [],
      };
    }

    const parent = graph.getDefaultParent() as Cell;
    const nodes = parent.getChildVertices().map((cell) => {
      const geometry = cell.getGeometry();
      return {
        id: String(cell.id ?? ''),
        label: graph.getLabel(cell) ?? '',
        x: geometry?.x ?? 0,
        y: geometry?.y ?? 0,
        width: geometry?.width ?? 0,
        height: geometry?.height ?? 0,
        style: String(cell.getStyle() ?? ''),
      };
    });
    const edges = parent.getChildEdges().map((cell) => {
      const source = cell.getTerminal(true);
      const target = cell.getTerminal(false);
      return {
        id: String(cell.id ?? ''),
        label: graph.getLabel(cell) ?? '',
        sourceId: String(source?.id ?? ''),
        sourceLabel: source ? graph.getLabel(source) ?? '' : '',
        targetId: String(target?.id ?? ''),
        targetLabel: target ? graph.getLabel(target) ?? '' : '',
        style: String(cell.getStyle() ?? ''),
      };
    });

    const bounds = graph.getGraphBounds();
    return {
      generatedAt: new Date().toISOString(),
      vertexCount: nodes.length,
      edgeCount: edges.length,
      bounds: {
        x: Math.round(bounds.x),
        y: Math.round(bounds.y),
        width: Math.round(bounds.width),
        height: Math.round(bounds.height),
      },
      labels: nodes.map((node) => node.label).filter((label) => label.length > 0),
      nodes,
      edges,
    };
  }

  function prepareForExport(options?: { padding?: number; maxScale?: number }): DiagramReport {
    const graph = graphRef.current;
    const container = graphContainerRef.current;
    if (!graph || !container) {
      return buildDiagramReport();
    }

    const padding = Math.max(0, Number(options?.padding ?? 24));
    const maxScale = Math.max(0.1, Number(options?.maxScale ?? 1.4));
    graph.refresh();
    graph.zoomActual();

    const bounds = graph.getGraphBounds();
    if (bounds.width > 0 && bounds.height > 0) {
      const availableWidth = Math.max(200, container.clientWidth - padding * 2);
      const availableHeight = Math.max(200, container.clientHeight - padding * 2);
      const scale = Math.min(availableWidth / bounds.width, availableHeight / bounds.height, maxScale);
      if (Number.isFinite(scale) && scale > 0) {
        graph.zoomTo(scale, false);
      }
      graph.center(true, true);
    }

    graph.refresh();
    return buildDiagramReport();
  }

  return (
    <>
      {!renderOnly && (
        <header>
          <strong>MaxGraph Editor + Live Disk Sync</strong>
          <span className={statusClass}>{status}</span>
        </header>
      )}
      <main>
        {!renderOnly && (
          <section className="panel">
            <h2>Diagram XML (mxGraphModel)</h2>
            <textarea value={xml} spellCheck={false} onChange={(event) => onXmlChanged(event.target.value)} />
          </section>
        )}
        <section className="panel">
          {!renderOnly && <h2>Rendered Diagram (MaxGraph)</h2>}
          {!renderOnly && (
            <div className="graph-toolbar">
              <input
                value={nextLabel}
                onChange={(event) => setNextLabel(event.target.value)}
                aria-label="New node label"
                placeholder="Node label"
              />
              <button type="button" onClick={() => insertShape('box')}>
                Add Box
              </button>
              <button type="button" onClick={() => insertShape('ellipse')}>
                Add Ellipse
              </button>
              <button type="button" onClick={() => connectSelection()} disabled={selectionCount < 2}>
                Connect Selected
              </button>
              <button type="button" onClick={() => removeSelection()} disabled={selectionCount < 1}>
                Delete Selected
              </button>
              <span className="selection-summary">
                {selectionCount} selected. Tip: press Delete/Backspace in the graph pane.
              </span>
            </div>
          )}
          <div ref={graphContainerRef} id="graph" />
          {!renderOnly && <pre>{preview}</pre>}
        </section>
      </main>
    </>
  );
}

createRoot(document.getElementById('app')!).render(<App />);
