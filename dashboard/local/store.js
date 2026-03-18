// local/store.js — File-based JSON store for when Notion is not configured
// Stores pipeline data as JSON files in .harness-data/ within the pipeline directory
// or in dashboard/.harness-data/ for the dashboard server

const fs = require("fs");
const path = require("path");
const crypto = require("crypto");

const DEFAULT_DATA_DIR = path.join(__dirname, "..", ".harness-data");

function ensureDir(dir) {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
}

function generateId() {
  return crypto.randomBytes(12).toString("hex");
}

class LocalStore {
  constructor(dataDir) {
    this.dataDir = dataDir || DEFAULT_DATA_DIR;
    ensureDir(this.dataDir);
  }

  _filePath(collection) {
    return path.join(this.dataDir, `${collection}.json`);
  }

  _read(collection) {
    const fp = this._filePath(collection);
    if (!fs.existsSync(fp)) return [];
    return JSON.parse(fs.readFileSync(fp, "utf-8"));
  }

  _write(collection, data) {
    ensureDir(this.dataDir);
    fs.writeFileSync(this._filePath(collection), JSON.stringify(data, null, 2));
  }

  query(collection, filter) {
    let records = this._read(collection);
    if (filter) {
      records = records.filter(record => {
        for (const [key, value] of Object.entries(filter)) {
          if (record[key] !== value) return false;
        }
        return true;
      });
    }
    return records;
  }

  create(collection, record) {
    const records = this._read(collection);
    const entry = { id: generateId(), ...record, _createdAt: new Date().toISOString() };
    records.push(entry);
    this._write(collection, records);
    return entry;
  }

  update(collection, id, updates) {
    const records = this._read(collection);
    const idx = records.findIndex(r => r.id === id);
    if (idx === -1) return null;
    records[idx] = { ...records[idx], ...updates, _updatedAt: new Date().toISOString() };
    this._write(collection, records);
    return records[idx];
  }

  delete(collection, id) {
    const records = this._read(collection);
    const filtered = records.filter(r => r.id !== id);
    this._write(collection, filtered);
    return filtered.length < records.length;
  }

  getById(collection, id) {
    const records = this._read(collection);
    return records.find(r => r.id === id) || null;
  }
}

// Collection names matching the 5 Notion databases
const COLLECTIONS = {
  pipelineStages: "pipeline-stages",
  failureRegistry: "failure-registry",
  reliability: "reliability",
  openFailureModes: "open-failure-modes",
  improvements: "improvements"
};

module.exports = { LocalStore, COLLECTIONS, DEFAULT_DATA_DIR };
