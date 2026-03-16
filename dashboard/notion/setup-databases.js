#!/usr/bin/env node
// Sets up Notion databases for a deterministic-harness project.
// Usage: NOTION_TOKEN=xxx NOTION_PARENT_PAGE_ID=xxx node setup-databases.js

require("dotenv").config();
const { createDatabase } = require("./client");
const schemas = require("./schema");
const fs = require("fs");
const path = require("path");

async function main() {
  const token = process.env.NOTION_TOKEN;
  const parentPageId = process.env.NOTION_PARENT_PAGE_ID;

  if (!token || !parentPageId) {
    console.error("Missing NOTION_TOKEN or NOTION_PARENT_PAGE_ID in environment.");
    console.error("Copy .env.example to .env and fill in your values.");
    process.exit(1);
  }

  console.log("Creating Notion databases...");

  const dbIds = {};

  const entries = [
    ["pipelineStages", schemas.pipelineStagesSchema],
    ["failureRegistry", schemas.failureRegistrySchema],
    ["reliability", schemas.reliabilitySchema],
    ["openFailureModes", schemas.openFailureModesSchema],
    ["improvements", schemas.improvementsSchema]
  ];

  for (const [key, schema] of entries) {
    console.log(`  Creating: ${schema.title}...`);
    dbIds[key] = await createDatabase(parentPageId, schema.title, schema);
    console.log(`  Created: ${schema.title} (${dbIds[key]})`);
  }

  // Save database IDs for the server
  const configPath = path.join(__dirname, "..", "notion-config.json");
  fs.writeFileSync(configPath, JSON.stringify(dbIds, null, 2));
  console.log(`\nDatabase IDs saved to notion-config.json`);
  console.log("\nSetup complete. Run 'npm start' to launch the dashboard.");
}

main().catch(err => {
  console.error("Setup failed:", err.message);
  process.exit(1);
});
