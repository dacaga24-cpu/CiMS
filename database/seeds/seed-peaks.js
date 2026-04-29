const path = require('path');
const fs   = require('fs');
const backendModules = path.resolve(__dirname, '../../backend/node_modules');

require(`${backendModules}/dotenv`).config({
  path: path.resolve(__dirname, '../../backend/.env')
});

const mysql = require(`${backendModules}/mysql2/promise`);

const DB_CONFIG = {
  host:     process.env.DB_HOST     || 'localhost',
  user:     process.env.DB_USER     || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME     || 'cims_db',
};

const CSV_PATH = path.resolve(__dirname, '../data/peaks.csv');

// ── Lectura i parsing del CSV ────────────────────────────────────────────────
function loadPeaksFromCSV(filePath) {
  if (!fs.existsSync(filePath)) {
    throw new Error(`No s'ha trobat el fitxer CSV: ${filePath}`);
  }

  const raw   = fs.readFileSync(filePath, 'utf-8');
  const lines = raw.split('\n').map(l => l.trim()).filter(l => l.length > 0);

  // Primera línia: capçalera
  const headers = lines[0].split(',').map(h => h.trim());
  const requiredHeaders = ['name', 'altitude', 'latitude', 'longitude'];
  for (const req of requiredHeaders) {
    if (!headers.includes(req)) {
      throw new Error(`El CSV no conté la columna obligatòria: "${req}"`);
    }
  }

  const peaks = [];
  for (let i = 1; i < lines.length; i++) {
    const values = lines[i].split(',');

    const row = {};
    headers.forEach((h, idx) => {
      row[h] = values[idx] !== undefined ? values[idx].trim() : '';
    });

    const altitude  = parseFloat(row.altitude);
    const latitude  = parseFloat(row.latitude);
    const longitude = parseFloat(row.longitude);

    if (!row.name || isNaN(altitude) || isNaN(latitude) || isNaN(longitude)) {
      console.warn(`   ⚠️  Línia ${i + 1} invàlida, s'omet: "${lines[i]}"`);
      continue;
    }

    peaks.push({
      name:        row.name,
      altitude,
      latitude,
      longitude,
      description: row.description || null,
    });
  }

  return peaks;
}

// ── Procés principal ─────────────────────────────────────────────────────────
async function seed() {
  // ── FASE 1: Llegir cims des del CSV ─────────────────────────────
  console.log(`📂 Llegint cims des de: ${CSV_PATH}`);
  const peaks = loadPeaksFromCSV(CSV_PATH);
  console.log(`   → ${peaks.length} cims carregats correctament`);

  // ── FASE 2: Inserir a MySQL ──────────────────────────────────────
  console.log('\n💾 Connectant a MySQL...');
  const db = await mysql.createConnection(DB_CONFIG);
  console.log('   → Connexió establerta');

  let inserted = 0;
  let skipped  = 0;

  for (const peak of peaks) {
    try {
      await db.execute(
        `INSERT INTO peaks (name, altitude, latitude, longitude)
         VALUES (?, ?, ?, ?)`,
        [peak.name, peak.altitude, peak.latitude, peak.longitude]
      );
      inserted++;
    } catch (err) {
      if (err.code === 'ER_DUP_ENTRY') skipped++;
      else throw err;
    }
  }

  await db.end();

  console.log(`\n✅ Seeding completat:`);
  console.log(`   Inserits:       ${inserted}`);
  console.log(`   Saltats (dup.): ${skipped}`);
}

seed().catch(err => {
  console.error('❌ Error durant el seeding:', err.message);
  process.exit(1);
});