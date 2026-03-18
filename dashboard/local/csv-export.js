#!/usr/bin/env node
// csv-export.js — Export local JSON store data to CSV files
//
// Usage:
//   node csv-export.js [data-dir] [output-dir]
//
// Defaults:
//   data-dir:   ../.harness-data (relative to this file)
//   output-dir: same as data-dir

const fs = require("fs");
const path = require("path");
const { LocalStore, COLLECTIONS } = require("./store");

function escapeCSV(value) {
  if (value === null || value === undefined) return "";
  const str = String(value);
  if (str.includes(",") || str.includes('"') || str.includes("\n")) {
    return '"' + str.replace(/"/g, '""') + '"';
  }
  return str;
}

function jsonToCSV(records) {
  if (records.length === 0) return "";

  // Collect all keys, excluding internal fields
  const keys = new Set();
  for (const record of records) {
    for (const key of Object.keys(record)) {
      if (!key.startsWith("_")) keys.add(key);
    }
  }

  const headers = Array.from(keys);
  const lines = [headers.map(escapeCSV).join(",")];

  for (const record of records) {
    const row = headers.map(h => escapeCSV(record[h]));
    lines.push(row.join(","));
  }

  return lines.join("\n") + "\n";
}

function exportAll(dataDir, outputDir) {
  const store = new LocalStore(dataDir);
  outputDir = outputDir || dataDir || store.dataDir;

  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }

  const exported = [];

  for (const [name, collection] of Object.entries(COLLECTIONS)) {
    const records = store.query(collection);
    if (records.length === 0) {
      console.log(`  ${name}: empty, skipped`);
      continue;
    }
    const csv = jsonToCSV(records);
    const csvPath = path.join(outputDir, `${collection}.csv`);
    fs.writeFileSync(csvPath, csv);
    exported.push({ name, file: csvPath, count: records.length });
    console.log(`  ${name}: ${records.length} records → ${csvPath}`);
  }

  return exported;
}

// CLI mode
if (require.main === module) {
  const dataDir = process.argv[2] || undefined;
  const outputDir = process.argv[3] || dataDir || undefined;
  console.log("Exporting local store to CSV...");
  const results = exportAll(dataDir, outputDir);
  if (results.length === 0) {
    console.log("No data to export.");
  } else {
    console.log(`\nExported ${results.length} collection(s).`);
  }
}

module.exports = { jsonToCSV, exportAll };
