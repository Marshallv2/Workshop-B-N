#!/usr/bin/env node
/*
 * Erzeugt dist/kanalstandard.html: eine einzelne Datei mit eingebettetem
 * Stylesheet, Quelldaten, Skript und allen Anhängen aus assets/ als Data-URI.
 * Diese Fassung ist offline lauffähig und lässt sich per Mail oder Teams
 * weitergeben, ohne den Ordner assets/ mitzuschicken.
 *
 * Aufruf: node tools/build-standalone.mjs
 */

import { readFile, writeFile, mkdir, readdir, stat } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

const MIME = {
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.webp': 'image/webp',
  '.svg': 'image/svg+xml',
  '.pdf': 'application/pdf',
  '.xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  '.xls': 'application/vnd.ms-excel',
  '.dwg': 'application/acad',
  '.lin': 'text/plain'
};

const MAX_TOTAL_MB = 120;

async function collectAssets() {
  const dir = path.join(ROOT, 'assets');
  if (!existsSync(dir)) return { map: {}, skipped: [], bytes: 0 };

  const entries = await readdir(dir);
  const map = {};
  const skipped = [];
  let bytes = 0;

  for (const name of entries.sort()) {
    if (name.startsWith('.') || name.toLowerCase() === 'readme.md') continue;
    const full = path.join(dir, name);
    const info = await stat(full);
    if (!info.isFile()) continue;

    const mime = MIME[path.extname(name).toLowerCase()];
    if (!mime) {
      skipped.push(`${name} (unbekannter Dateityp)`);
      continue;
    }

    const buffer = await readFile(full);
    map[name] = `data:${mime};base64,${buffer.toString('base64')}`;
    bytes += buffer.length;
  }

  return { map, skipped, bytes };
}

function inject(html, marker, replacement) {
  if (!html.includes(marker)) {
    throw new Error(`Platzhalter nicht gefunden: ${marker}`);
  }
  return html.replace(marker, () => replacement);
}

/* Verhindert, dass ein </script> in eingebetteten Daten das Skript beendet. */
const safeForScript = (text) => text.replace(/<\/script>/gi, '<\\/script>');

async function main() {
  const [html, css, data, app] = await Promise.all([
    readFile(path.join(ROOT, 'index.html'), 'utf8'),
    readFile(path.join(ROOT, 'src/styles.css'), 'utf8'),
    readFile(path.join(ROOT, 'src/data.js'), 'utf8'),
    readFile(path.join(ROOT, 'src/app.js'), 'utf8')
  ]);

  const { map, skipped, bytes } = await collectAssets();
  const assetCount = Object.keys(map).length;
  const megabytes = bytes / (1024 * 1024);

  if (megabytes > MAX_TOTAL_MB) {
    console.warn(
      `Warnung: ${megabytes.toFixed(1)} MB Anhänge überschreiten die Empfehlung von ${MAX_TOTAL_MB} MB. ` +
      'Die Einzeldatei kann in Browsern und Mailsystemen träge werden.'
    );
  }

  let out = html;
  out = inject(out, '<link rel="stylesheet" href="src/styles.css">', `<style>\n${css}\n</style>`);
  out = inject(
    out,
    '<script src="src/data.js"></script>',
    `<script>window.KANALSTANDARD_ASSETS=${safeForScript(JSON.stringify(map))};</script>\n` +
    `<script>\n${safeForScript(data)}\n</script>`
  );
  out = inject(out, '<script src="src/app.js"></script>', `<script>\n${safeForScript(app)}\n</script>`);

  await mkdir(path.join(ROOT, 'dist'), { recursive: true });
  const target = path.join(ROOT, 'dist/kanalstandard.html');
  await writeFile(target, out, 'utf8');

  const sizeMb = Buffer.byteLength(out, 'utf8') / (1024 * 1024);
  console.log(`dist/kanalstandard.html erzeugt – ${sizeMb.toFixed(2)} MB, ${assetCount} Anhänge eingebettet.`);
  if (!assetCount) {
    console.log('Hinweis: assets/ enthält noch keine Abbildungen; im Dokument erscheinen Platzhalter.');
  }
  if (skipped.length) {
    console.log(`Übersprungen: ${skipped.join(', ')}`);
  }
}

main().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
