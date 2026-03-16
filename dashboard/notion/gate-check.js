#!/usr/bin/env node
// gate-check.js — Check or create Notion gate approval cards
// Used by gate-enforcer.sh and run-pipeline.sh for mechanical Notion enforcement
//
// Usage:
//   node gate-check.js check <pipeline-name> <stage-number>
//   node gate-check.js create <pipeline-name> <stage-number> <stage-name> <gate-type>
//   node gate-check.js status
//
// Exit codes:
//   0 = approved (or auto gate)
//   1 = not approved / blocked
//   2 = error (not configured, API failure)

require("dotenv").config({ path: require("path").join(__dirname, "..", ".env") });
const { getClient, queryDatabase, createPage, pageToObject, titleProp, selectProp, richText, numberProp } = require("./client");
const fs = require("fs");
const path = require("path");

function loadConfig() {
  const configPath = path.join(__dirname, "..", "notion-config.json");
  if (!fs.existsSync(configPath)) return null;
  return JSON.parse(fs.readFileSync(configPath, "utf-8"));
}

async function findGatePage(config, pipelineName, stageNumber) {
  const pages = await queryDatabase(config.pipelineStages, {
    and: [
      { property: "Pipeline", rich_text: { equals: pipelineName } },
      { property: "Number", number: { equals: parseInt(stageNumber) } }
    ]
  });
  return pages.length > 0 ? pageToObject(pages[0]) : null;
}

async function checkGate(pipelineName, stageNumber) {
  const config = loadConfig();
  if (!config || !process.env.NOTION_TOKEN) {
    console.error("NOTION_NOT_CONFIGURED");
    process.exit(2);
  }

  const page = await findGatePage(config, pipelineName, stageNumber);
  if (!page) {
    console.log("GATE_NOT_FOUND");
    console.error(`No Notion card found for ${pipelineName} stage ${stageNumber}`);
    process.exit(1);
  }

  const status = page.Status || "";
  const gateType = page["Gate Type"] || "auto";

  if (gateType === "auto") {
    console.log("AUTO_GATE");
    process.exit(0);
  }

  if (status === "passed") {
    console.log("APPROVED");
    console.log(`Stage ${stageNumber} approved in Notion`);
    process.exit(0);
  }

  console.log("NOT_APPROVED");
  console.log(`Stage ${stageNumber} status: "${status}" (needs "passed" to advance)`);
  console.log(`Approve in Notion: set the stage status to "passed"`);
  process.exit(1);
}

async function createGate(pipelineName, stageNumber, stageName, gateType) {
  const config = loadConfig();
  if (!config || !process.env.NOTION_TOKEN) {
    console.error("NOTION_NOT_CONFIGURED");
    process.exit(2);
  }

  // Check if it already exists
  const existing = await findGatePage(config, pipelineName, stageNumber);
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
}

async function showStatus() {
  const config = loadConfig();
  if (!config || !process.env.NOTION_TOKEN) {
    console.log("NOT_CONFIGURED");
    console.log("Run: cd dashboard && npm run setup");
    process.exit(2);
  }
  console.log("CONFIGURED");
  console.log("Notion gate enforcement is active");
  process.exit(0);
}

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
  case "status":
    showStatus().catch(err => {
      console.error(`ERROR: ${err.message}`);
      process.exit(2);
    });
    break;
  default:
    console.error("Usage: node gate-check.js [check|create|status] <args>");
    process.exit(2);
}
