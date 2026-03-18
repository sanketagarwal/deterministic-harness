#!/usr/bin/env node
// gate-check.js — Check or create gate approval cards
// Works with Notion when configured, falls back to local JSON store
//
// Usage:
//   node gate-check.js check <pipeline-name> <stage-number>
//   node gate-check.js create <pipeline-name> <stage-number> <stage-name> <gate-type>
//   node gate-check.js status
//
// Exit codes:
//   0 = approved (or auto gate)
//   1 = not approved / blocked
//   2 = error

require("dotenv").config({ path: require("path").join(__dirname, "..", ".env") });
const fs = require("fs");
const path = require("path");

// --- Storage backend detection ---

function isNotionConfigured() {
  const configPath = path.join(__dirname, "..", "notion-config.json");
  return !!process.env.NOTION_TOKEN && fs.existsSync(configPath);
}

function loadNotionConfig() {
  const configPath = path.join(__dirname, "..", "notion-config.json");
  if (!fs.existsSync(configPath)) return null;
  return JSON.parse(fs.readFileSync(configPath, "utf-8"));
}

function getLocalStore() {
  const { LocalStore, COLLECTIONS } = require("../local/store");
  return { store: new LocalStore(), COLLECTIONS };
}

// --- Notion backend ---

async function findGatePageNotion(config, pipelineName, stageNumber) {
  const { queryDatabase, pageToObject } = require("./client");
  const pages = await queryDatabase(config.pipelineStages, {
    and: [
      { property: "Pipeline", rich_text: { equals: pipelineName } },
      { property: "Number", number: { equals: parseInt(stageNumber) } }
    ]
  });
  return pages.length > 0 ? pageToObject(pages[0]) : null;
}

// --- Local backend ---

function findGatePageLocal(store, collections, pipelineName, stageNumber) {
  const records = store.query(collections.pipelineStages, {
    Pipeline: pipelineName,
    Number: parseInt(stageNumber)
  });
  return records.length > 0 ? records[0] : null;
}

// --- Commands ---

async function checkGate(pipelineName, stageNumber) {
  let page;

  if (isNotionConfigured()) {
    const config = loadNotionConfig();
    page = await findGatePageNotion(config, pipelineName, stageNumber);
  } else {
    const { store, COLLECTIONS } = getLocalStore();
    page = findGatePageLocal(store, COLLECTIONS, pipelineName, stageNumber);
  }

  if (!page) {
    console.log("GATE_NOT_FOUND");
    console.error(`No gate card found for ${pipelineName} stage ${stageNumber}`);
    process.exit(1);
  }

  const status = page.Status || page.status || "";
  const gateType = page["Gate Type"] || page.gateType || "auto";

  if (gateType === "auto") {
    console.log("AUTO_GATE");
    process.exit(0);
  }

  if (status === "passed") {
    console.log("APPROVED");
    console.log(`Stage ${stageNumber} approved`);
    process.exit(0);
  }

  console.log("NOT_APPROVED");
  console.log(`Stage ${stageNumber} status: "${status}" (needs "passed" to advance)`);

  if (isNotionConfigured()) {
    console.log(`Approve in Notion: set the stage status to "passed"`);
  } else {
    console.log(`Approve locally: run`);
    console.log(`  node gate-check.js approve ${pipelineName} ${stageNumber}`);
  }
  process.exit(1);
}

async function createGate(pipelineName, stageNumber, stageName, gateType) {
  if (isNotionConfigured()) {
    const config = loadNotionConfig();
    const { queryDatabase, createPage, pageToObject, titleProp, selectProp, richText, numberProp } = require("./client");

    const existing = await findGatePageNotion(config, pipelineName, stageNumber);
    if (existing) {
      console.log(`EXISTING:${existing.id}`);
      return;
    }

    const page = await createPage(config.pipelineStages, {
      "Stage": titleProp(stageName),
      "Number": numberProp(parseInt(stageNumber)),
      "Gate Type": selectProp(gateType),
      "Status": selectProp("pending"),
      "Pipeline": richText(pipelineName)
    });
    console.log(`CREATED:${page.id}`);
  } else {
    const { store, COLLECTIONS } = getLocalStore();
    const existing = findGatePageLocal(store, COLLECTIONS, pipelineName, stageNumber);
    if (existing) {
      console.log(`EXISTING:${existing.id}`);
      return;
    }

    const entry = store.create(COLLECTIONS.pipelineStages, {
      Stage: stageName,
      Number: parseInt(stageNumber),
      "Gate Type": gateType,
      Status: "pending",
      Pipeline: pipelineName
    });
    console.log(`CREATED:${entry.id}`);
  }
}

function approveGate(pipelineName, stageNumber) {
  if (isNotionConfigured()) {
    console.log("Notion is configured — approve the gate in Notion instead.");
    process.exit(1);
  }

  const { store, COLLECTIONS } = getLocalStore();
  const page = findGatePageLocal(store, COLLECTIONS, pipelineName, stageNumber);

  if (!page) {
    console.error(`No gate card found for ${pipelineName} stage ${stageNumber}`);
    console.error("Create it first with: node gate-check.js create ...");
    process.exit(2);
  }

  store.update(COLLECTIONS.pipelineStages, page.id, { Status: "passed" });
  console.log("APPROVED");
  console.log(`Stage ${stageNumber} approved locally`);
}

async function showStatus() {
  if (isNotionConfigured()) {
    console.log("CONFIGURED");
    console.log("Backend: Notion");
    console.log("Notion gate enforcement is active");
  } else {
    console.log("CONFIGURED");
    console.log("Backend: local JSON");
    console.log("Data stored in: .harness-data/");
    console.log("To export CSV: node local/csv-export.js");
  }
  process.exit(0);
}

// --- CLI ---

const [,, command, ...args] = process.argv;

switch (command) {
  case "check":
    checkGate(args[0], args[1]).catch(err => {
      console.error(`ERROR: ${err.message}`);
      process.exit(2);
    });
    break;
  case "create":
    createGate(args[0], args[1], args[2], args[3]).catch(err => {
      console.error(`ERROR: ${err.message}`);
      process.exit(2);
    });
    break;
  case "approve":
    approveGate(args[0], args[1]);
    break;
  case "status":
    showStatus().catch(err => {
      console.error(`ERROR: ${err.message}`);
      process.exit(2);
    });
    break;
  default:
    console.error("Usage: node gate-check.js [check|create|approve|status] <args>");
    process.exit(2);
}
