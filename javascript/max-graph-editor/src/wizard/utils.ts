import { dirname } from 'node:path';
import { mkdir, writeFile } from 'node:fs/promises';
import { basename } from 'node:path';

export function slugify(value: string) {
  return value
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 60) || 'diagram';
}

export function stamp() {
  const now = new Date();
  const yyyy = now.getFullYear();
  const mm = String(now.getMonth() + 1).padStart(2, '0');
  const dd = String(now.getDate()).padStart(2, '0');
  const hh = String(now.getHours()).padStart(2, '0');
  const mi = String(now.getMinutes()).padStart(2, '0');
  const ss = String(now.getSeconds()).padStart(2, '0');
  return `${yyyy}${mm}${dd}-${hh}${mi}${ss}`;
}

export function ensureArray<T>(value: T | T[] | undefined | null): T[] {
  if (value == null) {
    return [];
  }
  return Array.isArray(value) ? value : [value];
}

export function unique<T>(values: T[]): T[] {
  return [...new Set(values)];
}

export function escapeXmlText(value: string) {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
}

export function json(value: unknown) {
  return `${JSON.stringify(value, null, 2)}\n`;
}

export async function writeTextFile(path: string, contents: string) {
  await mkdir(dirname(path), { recursive: true });
  await writeFile(path, contents.endsWith('\n') ? contents : `${contents}\n`, 'utf8');
}

export function titleFromPrompt(prompt: string) {
  const cleaned = prompt.trim().replace(/\s+/g, ' ');
  if (cleaned.length <= 72) {
    return cleaned;
  }
  return `${cleaned.slice(0, 69).trimEnd()}...`;
}

export function fileStemFromPrompt(prompt: string) {
  return `${stamp()}-${slugify(basename(titleFromPrompt(prompt)))}`;
}
