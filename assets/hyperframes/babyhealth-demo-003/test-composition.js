/**
 * Pruebas funcionales de visibilidad para composición HyperFrames.
 * Verifica que el index.html muestra contenido visible en cada escena.
 * 
 * Ejecutar: node test-composition.js
 * Requiere: Node.js (no necesita dependencias externas)
 */

const fs = require('fs');
const path = require('path');

const indexPath = path.join(__dirname, 'index.html');
const html = fs.readFileSync(indexPath, 'utf-8');

let errors = 0;
let warnings = 0;
let passed = 0;

function test(name, condition, detail) {
  if (condition) {
    console.log(`  ✅ ${name}`);
    passed++;
  } else {
    console.log(`  ❌ ${name}`);
    if (detail) console.log(`     → ${detail}`);
    errors++;
  }
}

function warn(name, condition, detail) {
  if (condition) {
    console.log(`  ✅ ${name}`);
    passed++;
  } else {
    console.log(`  ⚠️  ${name}`);
    if (detail) console.log(`     → ${detail}`);
    warnings++;
  }
}

console.log('\n🔍 Pruebas Funcionales de Composición HyperFrames\n');
console.log('━'.repeat(60));

// === 1. Estructura básica ===
console.log('\n📄 1. Estructura HTML básica\n');

test('index.html existe', fs.existsSync(indexPath));
test('Contiene <!DOCTYPE html>', html.includes('<!DOCTYPE html>'));
test('Contiene <body>', html.includes('<body>'));
test('Contiene elemento root con data-composition-id',
  /id="root"[^>]*data-composition-id/.test(html) || /data-composition-id[^>]*id="root"/.test(html),
  'El root debe tener id="root" y data-composition-id');
test('Contiene data-duration en el root',
  /data-duration="\d+"/.test(html),
  'data-duration define la duración total de la composición');

// === 2. Escenas ===
console.log('\n🎬 2. Escenas\n');

const sceneMatches = html.match(/class="scene"/g);
const sceneCount = sceneMatches ? sceneMatches.length : 0;
test('Tiene al menos 1 escena', sceneCount > 0, `Encontradas: ${sceneCount}`);
test('Tiene más de 2 escenas para una presentación', sceneCount >= 3,
  `Encontradas: ${sceneCount}. Una presentación debe tener al menos 3 escenas.`);

// Verificar que cada escena tiene data-enter y data-exit
const sceneRegex = /<div[^>]*class="scene"[^>]*>/g;
let sceneEl;
let sceneIndex = 0;
while ((sceneEl = sceneRegex.exec(html)) !== null) {
  sceneIndex++;
  const tag = sceneEl[0];
  test(`Escena ${sceneIndex} tiene data-enter`, /data-enter="\d+"/.test(tag),
    `Escena sin data-enter no se mostrará en el timeline`);
  test(`Escena ${sceneIndex} tiene data-exit`, /data-exit="\d+"/.test(tag),
    `Escena sin data-exit no desaparecerá del timeline`);
}

// Verificar IDs únicos en escenas
const idMatches = html.match(/id="scene-[^"]+"/g) || [];
const uniqueIds = new Set(idMatches);
test('Todas las escenas tienen IDs únicos',
  idMatches.length === uniqueIds.size,
  `${idMatches.length} IDs encontrados, ${uniqueIds.size} únicos`);

// === 3. Contenido visible ===
console.log('\n👁️  3. Contenido visible\n');

// Verificar que hay texto real (no solo tags vacíos)
const textContent = html.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();
const meaningfulText = textContent.replace(/[{}();\s]/g, '');
test('Contiene texto significativo (>100 chars)', meaningfulText.length > 100,
  `Solo ${meaningfulText.length} caracteres de texto encontrados`);

// Verificar headings
const h1Count = (html.match(/<h1[^>]*>/g) || []).length;
const h2Count = (html.match(/<h2[^>]*>/g) || []).length;
const h3Count = (html.match(/<h3[^>]*>/g) || []).length;
test('Contiene headings (h1/h2/h3)', (h1Count + h2Count + h3Count) > 0,
  `h1:${h1Count}, h2:${h2Count}, h3:${h3Count}`);

// Verificar que los headings no están vacíos
const emptyHeadings = html.match(/<h[1-3][^>]*>\s*<\/h[1-3]>/g) || [];
test('No hay headings vacíos', emptyHeadings.length === 0,
  `${emptyHeadings.length} headings vacíos encontrados`);

// === 4. Visibilidad inicial ===
console.log('\n🖥️  4. Visibilidad inicial (scene-1 visible al cargar)\n');

// La primera escena DEBE ser visible al cargar (opacity > 0 o sin display:none)
test('CSS inicial: escenas comienzan con opacity:0',
  /\.scene[^{]*\{[^}]*opacity:\s*0/s.test(html),
  'Las escenas deben iniciar ocultas para que el timeline las controle');

// Verificar que el script de timeline existe y hace seek(0)
test('Script de timeline existe',
  /window\.__timelines/.test(html),
  'Debe registrar timeline en window.__timelines');
test('Timeline hace seek(0) al inicializar',
  /timeline\.seek\(0\)/.test(html) || /seek\(0\)/.test(html),
  'seek(0) muestra la primera escena al cargar');

// Verificar que la primera escena tiene data-enter="0"
test('Primera escena tiene data-enter="0"',
  /data-enter="0"/.test(html),
  'Sin data-enter="0" la primera escena no será visible al cargar');

// === 5. Timeline consistencia ===
console.log('\n⏱️  5. Timeline consistencia\n');

const enterExitRegex = /data-enter="(\d+)"[^>]*data-exit="(\d+)"/g;
let match;
let lastExit = 0;
let timelineGaps = [];
let sceneIdx = 0;

while ((match = enterExitRegex.exec(html)) !== null) {
  sceneIdx++;
  const enter = parseInt(match[1]);
  const exit = parseInt(match[2]);
  
  test(`Escena ${sceneIdx}: enter(${enter}) < exit(${exit})`, enter < exit,
    'Una escena con enter >= exit nunca será visible');
  
  if (sceneIdx > 1 && enter > lastExit) {
    timelineGaps.push({ after: sceneIdx - 1, gap: enter - lastExit });
  }
  lastExit = exit;
}

warn('Sin gaps mayores a 1s en el timeline',
  timelineGaps.filter(g => g.gap > 1).length === 0,
  timelineGaps.length > 0 ? `Gaps: ${JSON.stringify(timelineGaps)}` : 'OK');

// Verificar duración total vs última escena
const durationMatch = html.match(/data-duration="(\d+)"/);
if (durationMatch && lastExit > 0) {
  const totalDuration = parseInt(durationMatch[1]);
  warn('Última escena termina cerca de la duración total',
    Math.abs(totalDuration - lastExit) <= 5,
    `Duración: ${totalDuration}s, última escena termina: ${lastExit}s`);
}

// === 6. Estilos críticos ===
console.log('\n🎨 6. Estilos críticos\n');

test('Define color de texto (color o --text)',
  /color:\s*#|color:\s*var\(--text\)|color:\s*rgb/.test(html),
  'Sin color definido, el texto podría ser invisible sobre fondo oscuro');
test('Define fondo (background)',
  /background/.test(html),
  'Sin background definido la composición puede ser transparente');
test('Usa id="root" (no class="composition")',
  /id="root"/.test(html) && !/class="composition"/.test(html),
  'class="composition" rompe el scoping del runtime de HyperFrames');
test('Font-face declarado (no @import de Google Fonts)',
  /@font-face/.test(html),
  'Las fuentes deben declararse con @font-face, no @import');
warn('No usa @import url(fonts.googleapis.com)',
  !/@import\s+url\([^)]*fonts\.googleapis/.test(html),
  '@import de Google Fonts agrega latencia y puede fallar en render');

// === Resumen ===
console.log('\n' + '━'.repeat(60));
console.log(`\n📊 Resultados: ${passed} pasaron, ${errors} errores, ${warnings} advertencias\n`);

if (errors > 0) {
  console.log('❌ HAY ERRORES — La composición puede NO mostrar contenido correctamente.');
  console.log('   Corrige los errores antes de renderizar.\n');
  process.exit(1);
} else if (warnings > 0) {
  console.log('⚠️  Pasó con advertencias — Revisa los warnings antes de renderizar.\n');
  process.exit(0);
} else {
  console.log('✅ Todas las pruebas pasaron — La composición es funcional.\n');
  process.exit(0);
}
