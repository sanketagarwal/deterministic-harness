require("dotenv").config();
const express = require("express");
const path = require("path");
const fs = require("fs");
const {
  getClient,
  queryDatabase,
  createPage,
  updatePage,
  deletePage,
  richText,
  titleProp,
  selectProp,
  numberProp,
  dateProp,
  checkboxProp,
  urlProp,
  pageToObject
} = require("./notion/client");

const app = express();
app.use(express.json());
app.use(express.static(path.join(__dirname, "public")));

// Load database IDs
function loadConfig() {
  const configPath = path.join(__dirname, "notion-config.json");
  if (!fs.existsSync(configPath)) {
    return null;
  }
  return JSON.parse(fs.readFileSync(configPath, "utf-8"));
}

// --- Health / Config ---

app.get("/api/status", (req, res) => {
  const config = loadConfig();
  res.json({
    configured: !!config && !!process.env.NOTION_TOKEN,
    databases: config ? Object.keys(config) : []
  });
});

// --- Pipeline Stages ---

app.get("/api/stages", async (req, res) => {
  try {
    const config = loadConfig();
    if (!config) return res.status(400).json({ error: "Not configured. Run npm run setup first." });
    const pages = await queryDatabase(config.pipelineStages, null, [{ property: "Number", direction: "ascending" }]);
    res.json(pages.map(pageToObject));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post("/api/stages", async (req, res) => {
  try {
    const config = loadConfig();
    if (!config) return res.status(400).json({ error: "Not configured." });
    const { name, number, purpose, gateType, status, inputArtifact, outputArtifact, checklistTotal, checklistChecked, pipeline } = req.body;
    const page = await createPage(config.pipelineStages, {
      "Stage": titleProp(name),
      "Number": numberProp(number),
      "Purpose": richText(purpose),
      "Gate Type": selectProp(gateType),
      "Status": selectProp(status || "pending"),
      "Input Artifact": urlProp(inputArtifact),
      "Output Artifact": urlProp(outputArtifact),
      "Checklist Total": numberProp(checklistTotal || 0),
      "Checklist Checked": numberProp(checklistChecked || 0),
      "Pipeline": richText(pipeline)
    });
    res.json(pageToObject(page));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.patch("/api/stages/:id", async (req, res) => {
  try {
    const props = {};
    const { name, number, purpose, gateType, status, inputArtifact, outputArtifact, checklistTotal, checklistChecked, pipeline } = req.body;
    if (name !== undefined) props["Stage"] = titleProp(name);
    if (number !== undefined) props["Number"] = numberProp(number);
    if (purpose !== undefined) props["Purpose"] = richText(purpose);
    if (gateType !== undefined) props["Gate Type"] = selectProp(gateType);
    if (status !== undefined) props["Status"] = selectProp(status);
    if (inputArtifact !== undefined) props["Input Artifact"] = urlProp(inputArtifact);
    if (outputArtifact !== undefined) props["Output Artifact"] = urlProp(outputArtifact);
    if (checklistTotal !== undefined) props["Checklist Total"] = numberProp(checklistTotal);
    if (checklistChecked !== undefined) props["Checklist Checked"] = numberProp(checklistChecked);
    if (pipeline !== undefined) props["Pipeline"] = richText(pipeline);
    const page = await updatePage(req.params.id, props);
    res.json(pageToObject(page));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete("/api/stages/:id", async (req, res) => {
  try {
    await deletePage(req.params.id);
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// --- Failure Registry ---

app.get("/api/failures", async (req, res) => {
  try {
    const config = loadConfig();
    if (!config) return res.status(400).json({ error: "Not configured." });
    const pages = await queryDatabase(config.failureRegistry, null, [{ property: "Date", direction: "descending" }]);
    res.json(pages.map(pageToObject));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post("/api/failures", async (req, res) => {
  try {
    const config = loadConfig();
    if (!config) return res.status(400).json({ error: "Not configured." });
    const { failure, date, stage, rootCause, fixApplied, fileChanged, committed, pipeline } = req.body;
    const page = await createPage(config.failureRegistry, {
      "Failure": titleProp(failure),
      "Date": dateProp(date),
      "Stage": selectProp(stage),
      "Root Cause": richText(rootCause),
      "Fix Applied": richText(fixApplied),
      "File Changed": richText(fileChanged),
      "Committed": checkboxProp(committed),
      "Pipeline": richText(pipeline)
    });
    res.json(pageToObject(page));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.patch("/api/failures/:id", async (req, res) => {
  try {
    const props = {};
    const { failure, date, stage, rootCause, fixApplied, fileChanged, committed, pipeline } = req.body;
    if (failure !== undefined) props["Failure"] = titleProp(failure);
    if (date !== undefined) props["Date"] = dateProp(date);
    if (stage !== undefined) props["Stage"] = selectProp(stage);
    if (rootCause !== undefined) props["Root Cause"] = richText(rootCause);
    if (fixApplied !== undefined) props["Fix Applied"] = richText(fixApplied);
    if (fileChanged !== undefined) props["File Changed"] = richText(fileChanged);
    if (committed !== undefined) props["Committed"] = checkboxProp(committed);
    if (pipeline !== undefined) props["Pipeline"] = richText(pipeline);
    const page = await updatePage(req.params.id, props);
    res.json(pageToObject(page));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete("/api/failures/:id", async (req, res) => {
  try {
    await deletePage(req.params.id);
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// --- Reliability Tracking ---

app.get("/api/reliability", async (req, res) => {
  try {
    const config = loadConfig();
    if (!config) return res.status(400).json({ error: "Not configured." });
    const pages = await queryDatabase(config.reliability, null, [{ property: "Date", direction: "ascending" }]);
    res.json(pages.map(pageToObject));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post("/api/reliability", async (req, res) => {
  try {
    const config = loadConfig();
    if (!config) return res.status(400).json({ error: "Not configured." });
    const { reason, date, reliability, change, pipeline } = req.body;
    const page = await createPage(config.reliability, {
      "Reason": titleProp(reason),
      "Date": dateProp(date),
      "Reliability %": numberProp(reliability),
      "Change": richText(change),
      "Pipeline": richText(pipeline)
    });
    res.json(pageToObject(page));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// --- Open Failure Modes ---

app.get("/api/open-failures", async (req, res) => {
  try {
    const config = loadConfig();
    if (!config) return res.status(400).json({ error: "Not configured." });
    const pages = await queryDatabase(config.openFailureModes);
    res.json(pages.map(pageToObject));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post("/api/open-failures", async (req, res) => {
  try {
    const config = loadConfig();
    if (!config) return res.status(400).json({ error: "Not configured." });
    const { failureMode, dateIdentified, stage, whyNoFix, owner, resolved, pipeline } = req.body;
    const page = await createPage(config.openFailureModes, {
      "Failure Mode": titleProp(failureMode),
      "Date Identified": dateProp(dateIdentified),
      "Stage": selectProp(stage),
      "Why No Fix Yet": richText(whyNoFix),
      "Owner": richText(owner),
      "Resolved": checkboxProp(resolved),
      "Pipeline": richText(pipeline)
    });
    res.json(pageToObject(page));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.patch("/api/open-failures/:id", async (req, res) => {
  try {
    const props = {};
    const { failureMode, dateIdentified, stage, whyNoFix, owner, resolved, pipeline } = req.body;
    if (failureMode !== undefined) props["Failure Mode"] = titleProp(failureMode);
    if (dateIdentified !== undefined) props["Date Identified"] = dateProp(dateIdentified);
    if (stage !== undefined) props["Stage"] = selectProp(stage);
    if (whyNoFix !== undefined) props["Why No Fix Yet"] = richText(whyNoFix);
    if (owner !== undefined) props["Owner"] = richText(owner);
    if (resolved !== undefined) props["Resolved"] = checkboxProp(resolved);
    if (pipeline !== undefined) props["Pipeline"] = richText(pipeline);
    const page = await updatePage(req.params.id, props);
    res.json(pageToObject(page));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// --- Improvements Log ---

app.get("/api/improvements", async (req, res) => {
  try {
    const config = loadConfig();
    if (!config) return res.status(400).json({ error: "Not configured." });
    const pages = await queryDatabase(config.improvements, null, [{ property: "Date", direction: "descending" }]);
    res.json(pages.map(pageToObject));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post("/api/improvements", async (req, res) => {
  try {
    const config = loadConfig();
    if (!config) return res.status(400).json({ error: "Not configured." });
    const { description, date, sourceStage, targetStage, fileChanged, severity, committed, pipeline } = req.body;
    const page = await createPage(config.improvements, {
      "Description": titleProp(description),
      "Date": dateProp(date),
      "Source Stage": selectProp(sourceStage),
      "Target Stage": selectProp(targetStage),
      "File Changed": richText(fileChanged),
      "Severity": selectProp(severity),
      "Committed": checkboxProp(committed),
      "Pipeline": richText(pipeline)
    });
    res.json(pageToObject(page));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.patch("/api/improvements/:id", async (req, res) => {
  try {
    const props = {};
    const { description, date, sourceStage, targetStage, fileChanged, severity, committed, pipeline } = req.body;
    if (description !== undefined) props["Description"] = titleProp(description);
    if (date !== undefined) props["Date"] = dateProp(date);
    if (sourceStage !== undefined) props["Source Stage"] = selectProp(sourceStage);
    if (targetStage !== undefined) props["Target Stage"] = selectProp(targetStage);
    if (fileChanged !== undefined) props["File Changed"] = richText(fileChanged);
    if (severity !== undefined) props["Severity"] = selectProp(severity);
    if (committed !== undefined) props["Committed"] = checkboxProp(committed);
    if (pipeline !== undefined) props["Pipeline"] = richText(pipeline);
    const page = await updatePage(req.params.id, props);
    res.json(pageToObject(page));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// --- Serve frontend ---

app.get("*", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "index.html"));
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Dashboard running at http://localhost:${PORT}`);
});
