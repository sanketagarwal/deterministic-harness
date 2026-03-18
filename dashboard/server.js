require("dotenv").config();
const express = require("express");
const path = require("path");
const fs = require("fs");

const app = express();
app.use(express.json());
app.use(express.static(path.join(__dirname, "public")));

// --- Backend detection ---

function isNotionConfigured() {
  const configPath = path.join(__dirname, "notion-config.json");
  return !!process.env.NOTION_TOKEN && fs.existsSync(configPath);
}

function loadNotionConfig() {
  const configPath = path.join(__dirname, "notion-config.json");
  if (!fs.existsSync(configPath)) return null;
  return JSON.parse(fs.readFileSync(configPath, "utf-8"));
}

// Lazy-load backends
let notionClient = null;
let localStore = null;

function getNotion() {
  if (!notionClient) notionClient = require("./notion/client");
  return notionClient;
}

function getLocal() {
  if (!localStore) {
    const { LocalStore, COLLECTIONS } = require("./local/store");
    localStore = { store: new LocalStore(), COLLECTIONS };
  }
  return localStore;
}

// --- Health / Config ---

app.get("/api/status", (req, res) => {
  const useNotion = isNotionConfigured();
  const config = useNotion ? loadNotionConfig() : null;
  res.json({
    configured: true,
    backend: useNotion ? "notion" : "local",
    databases: config ? Object.keys(config) : ["pipelineStages", "failureRegistry", "reliability", "openFailureModes", "improvements"]
  });
});

// --- CSV export endpoint ---

app.get("/api/export/csv", (req, res) => {
  if (isNotionConfigured()) {
    return res.status(400).json({ error: "CSV export is for local mode only. Export from Notion directly." });
  }
  const { exportAll } = require("./local/csv-export");
  const outputDir = path.join(__dirname, ".harness-data");
  const results = exportAll(undefined, outputDir);
  res.json({ exported: results });
});

// --- Generic CRUD helpers for both backends ---

async function queryCollection(collectionKey, sort) {
  if (isNotionConfigured()) {
    const config = loadNotionConfig();
    const { queryDatabase, pageToObject } = getNotion();
    const pages = await queryDatabase(config[collectionKey], null, sort ? [sort] : undefined);
    return pages.map(pageToObject);
  } else {
    const { store, COLLECTIONS } = getLocal();
    let records = store.query(COLLECTIONS[collectionKey]);
    if (sort) {
      const key = sort.property;
      records.sort((a, b) => {
        const av = a[key] || "";
        const bv = b[key] || "";
        return sort.direction === "descending" ? (bv > av ? 1 : -1) : (av > bv ? 1 : -1);
      });
    }
    return records;
  }
}

async function createRecord(collectionKey, notionProps, localRecord) {
  if (isNotionConfigured()) {
    const config = loadNotionConfig();
    const { createPage, pageToObject } = getNotion();
    const page = await createPage(config[collectionKey], notionProps);
    return pageToObject(page);
  } else {
    const { store, COLLECTIONS } = getLocal();
    return store.create(COLLECTIONS[collectionKey], localRecord);
  }
}

async function updateRecord(collectionKey, id, notionProps, localUpdates) {
  if (isNotionConfigured()) {
    const { updatePage, pageToObject } = getNotion();
    const page = await updatePage(id, notionProps);
    return pageToObject(page);
  } else {
    const { store, COLLECTIONS } = getLocal();
    return store.update(COLLECTIONS[collectionKey], id, localUpdates);
  }
}

async function deleteRecord(collectionKey, id) {
  if (isNotionConfigured()) {
    const { deletePage } = getNotion();
    await deletePage(id);
  } else {
    const { store, COLLECTIONS } = getLocal();
    store.delete(COLLECTIONS[collectionKey], id);
  }
  return { ok: true };
}

// --- Pipeline Stages ---

app.get("/api/stages", async (req, res) => {
  try {
    const data = await queryCollection("pipelineStages", { property: "Number", direction: "ascending" });
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post("/api/stages", async (req, res) => {
  try {
    const { name, number, purpose, gateType, status, inputArtifact, outputArtifact, checklistTotal, checklistChecked, pipeline } = req.body;
    const { titleProp, numberProp, richText, selectProp, urlProp } = getNotion();
    const result = await createRecord("pipelineStages",
      // Notion props
      {
        "Stage": titleProp(name), "Number": numberProp(number), "Purpose": richText(purpose),
        "Gate Type": selectProp(gateType), "Status": selectProp(status || "pending"),
        "Input Artifact": urlProp(inputArtifact), "Output Artifact": urlProp(outputArtifact),
        "Checklist Total": numberProp(checklistTotal || 0), "Checklist Checked": numberProp(checklistChecked || 0),
        "Pipeline": richText(pipeline)
      },
      // Local record
      { Stage: name, Number: number, Purpose: purpose, "Gate Type": gateType, Status: status || "pending",
        "Input Artifact": inputArtifact, "Output Artifact": outputArtifact,
        "Checklist Total": checklistTotal || 0, "Checklist Checked": checklistChecked || 0, Pipeline: pipeline }
    );
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.patch("/api/stages/:id", async (req, res) => {
  try {
    const b = req.body;
    const notionProps = {};
    const localUpdates = {};
    const { titleProp, numberProp, richText, selectProp, urlProp } = isNotionConfigured() ? getNotion() : {};

    const fields = [
      ["name", "Stage", "title"], ["number", "Number", "number"], ["purpose", "Purpose", "richText"],
      ["gateType", "Gate Type", "select"], ["status", "Status", "select"],
      ["inputArtifact", "Input Artifact", "url"], ["outputArtifact", "Output Artifact", "url"],
      ["checklistTotal", "Checklist Total", "number"], ["checklistChecked", "Checklist Checked", "number"],
      ["pipeline", "Pipeline", "richText"]
    ];

    for (const [bodyKey, propName, type] of fields) {
      if (b[bodyKey] !== undefined) {
        localUpdates[propName] = b[bodyKey];
        if (isNotionConfigured()) {
          if (type === "title") notionProps[propName] = titleProp(b[bodyKey]);
          else if (type === "number") notionProps[propName] = numberProp(b[bodyKey]);
          else if (type === "richText") notionProps[propName] = richText(b[bodyKey]);
          else if (type === "select") notionProps[propName] = selectProp(b[bodyKey]);
          else if (type === "url") notionProps[propName] = urlProp(b[bodyKey]);
        }
      }
    }

    const result = await updateRecord("pipelineStages", req.params.id, notionProps, localUpdates);
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete("/api/stages/:id", async (req, res) => {
  try { res.json(await deleteRecord("pipelineStages", req.params.id)); }
  catch (err) { res.status(500).json({ error: err.message }); }
});

// --- Failure Registry ---

app.get("/api/failures", async (req, res) => {
  try {
    const data = await queryCollection("failureRegistry", { property: "Date", direction: "descending" });
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post("/api/failures", async (req, res) => {
  try {
    const { failure, date, stage, rootCause, fixApplied, fileChanged, committed, pipeline } = req.body;
    const { titleProp, richText, selectProp, dateProp, checkboxProp } = isNotionConfigured() ? getNotion() : {};
    const result = await createRecord("failureRegistry",
      isNotionConfigured() ? {
        "Failure": titleProp(failure), "Date": dateProp(date), "Stage": selectProp(stage),
        "Root Cause": richText(rootCause), "Fix Applied": richText(fixApplied),
        "File Changed": richText(fileChanged), "Committed": checkboxProp(committed), "Pipeline": richText(pipeline)
      } : {},
      { Failure: failure, Date: date, Stage: stage, "Root Cause": rootCause,
        "Fix Applied": fixApplied, "File Changed": fileChanged, Committed: !!committed, Pipeline: pipeline }
    );
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.patch("/api/failures/:id", async (req, res) => {
  try {
    const b = req.body;
    const localUpdates = {};
    const notionProps = {};

    if (isNotionConfigured()) {
      const { titleProp, richText, selectProp, dateProp, checkboxProp } = getNotion();
      if (b.failure !== undefined) { notionProps["Failure"] = titleProp(b.failure); localUpdates.Failure = b.failure; }
      if (b.date !== undefined) { notionProps["Date"] = dateProp(b.date); localUpdates.Date = b.date; }
      if (b.stage !== undefined) { notionProps["Stage"] = selectProp(b.stage); localUpdates.Stage = b.stage; }
      if (b.rootCause !== undefined) { notionProps["Root Cause"] = richText(b.rootCause); localUpdates["Root Cause"] = b.rootCause; }
      if (b.fixApplied !== undefined) { notionProps["Fix Applied"] = richText(b.fixApplied); localUpdates["Fix Applied"] = b.fixApplied; }
      if (b.fileChanged !== undefined) { notionProps["File Changed"] = richText(b.fileChanged); localUpdates["File Changed"] = b.fileChanged; }
      if (b.committed !== undefined) { notionProps["Committed"] = checkboxProp(b.committed); localUpdates.Committed = b.committed; }
      if (b.pipeline !== undefined) { notionProps["Pipeline"] = richText(b.pipeline); localUpdates.Pipeline = b.pipeline; }
    } else {
      if (b.failure !== undefined) localUpdates.Failure = b.failure;
      if (b.date !== undefined) localUpdates.Date = b.date;
      if (b.stage !== undefined) localUpdates.Stage = b.stage;
      if (b.rootCause !== undefined) localUpdates["Root Cause"] = b.rootCause;
      if (b.fixApplied !== undefined) localUpdates["Fix Applied"] = b.fixApplied;
      if (b.fileChanged !== undefined) localUpdates["File Changed"] = b.fileChanged;
      if (b.committed !== undefined) localUpdates.Committed = b.committed;
      if (b.pipeline !== undefined) localUpdates.Pipeline = b.pipeline;
    }

    const result = await updateRecord("failureRegistry", req.params.id, notionProps, localUpdates);
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete("/api/failures/:id", async (req, res) => {
  try { res.json(await deleteRecord("failureRegistry", req.params.id)); }
  catch (err) { res.status(500).json({ error: err.message }); }
});

// --- Reliability Tracking ---

app.get("/api/reliability", async (req, res) => {
  try {
    const data = await queryCollection("reliability", { property: "Date", direction: "ascending" });
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post("/api/reliability", async (req, res) => {
  try {
    const { reason, date, reliability, change, pipeline } = req.body;
    const { titleProp, richText, dateProp, numberProp } = isNotionConfigured() ? getNotion() : {};
    const result = await createRecord("reliability",
      isNotionConfigured() ? {
        "Reason": titleProp(reason), "Date": dateProp(date), "Reliability %": numberProp(reliability),
        "Change": richText(change), "Pipeline": richText(pipeline)
      } : {},
      { Reason: reason, Date: date, "Reliability %": reliability, Change: change, Pipeline: pipeline }
    );
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// --- Open Failure Modes ---

app.get("/api/open-failures", async (req, res) => {
  try {
    const data = await queryCollection("openFailureModes");
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post("/api/open-failures", async (req, res) => {
  try {
    const { failureMode, dateIdentified, stage, whyNoFix, owner, resolved, pipeline } = req.body;
    const { titleProp, richText, selectProp, dateProp, checkboxProp } = isNotionConfigured() ? getNotion() : {};
    const result = await createRecord("openFailureModes",
      isNotionConfigured() ? {
        "Failure Mode": titleProp(failureMode), "Date Identified": dateProp(dateIdentified),
        "Stage": selectProp(stage), "Why No Fix Yet": richText(whyNoFix),
        "Owner": richText(owner), "Resolved": checkboxProp(resolved), "Pipeline": richText(pipeline)
      } : {},
      { "Failure Mode": failureMode, "Date Identified": dateIdentified, Stage: stage,
        "Why No Fix Yet": whyNoFix, Owner: owner, Resolved: !!resolved, Pipeline: pipeline }
    );
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.patch("/api/open-failures/:id", async (req, res) => {
  try {
    const b = req.body;
    const localUpdates = {};
    const notionProps = {};

    if (isNotionConfigured()) {
      const { titleProp, richText, selectProp, dateProp, checkboxProp } = getNotion();
      if (b.failureMode !== undefined) { notionProps["Failure Mode"] = titleProp(b.failureMode); localUpdates["Failure Mode"] = b.failureMode; }
      if (b.dateIdentified !== undefined) { notionProps["Date Identified"] = dateProp(b.dateIdentified); localUpdates["Date Identified"] = b.dateIdentified; }
      if (b.stage !== undefined) { notionProps["Stage"] = selectProp(b.stage); localUpdates.Stage = b.stage; }
      if (b.whyNoFix !== undefined) { notionProps["Why No Fix Yet"] = richText(b.whyNoFix); localUpdates["Why No Fix Yet"] = b.whyNoFix; }
      if (b.owner !== undefined) { notionProps["Owner"] = richText(b.owner); localUpdates.Owner = b.owner; }
      if (b.resolved !== undefined) { notionProps["Resolved"] = checkboxProp(b.resolved); localUpdates.Resolved = b.resolved; }
      if (b.pipeline !== undefined) { notionProps["Pipeline"] = richText(b.pipeline); localUpdates.Pipeline = b.pipeline; }
    } else {
      if (b.failureMode !== undefined) localUpdates["Failure Mode"] = b.failureMode;
      if (b.dateIdentified !== undefined) localUpdates["Date Identified"] = b.dateIdentified;
      if (b.stage !== undefined) localUpdates.Stage = b.stage;
      if (b.whyNoFix !== undefined) localUpdates["Why No Fix Yet"] = b.whyNoFix;
      if (b.owner !== undefined) localUpdates.Owner = b.owner;
      if (b.resolved !== undefined) localUpdates.Resolved = b.resolved;
      if (b.pipeline !== undefined) localUpdates.Pipeline = b.pipeline;
    }

    const result = await updateRecord("openFailureModes", req.params.id, notionProps, localUpdates);
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// --- Improvements Log ---

app.get("/api/improvements", async (req, res) => {
  try {
    const data = await queryCollection("improvements", { property: "Date", direction: "descending" });
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post("/api/improvements", async (req, res) => {
  try {
    const { description, date, sourceStage, targetStage, fileChanged, severity, committed, pipeline } = req.body;
    const { titleProp, richText, selectProp, dateProp, checkboxProp } = isNotionConfigured() ? getNotion() : {};
    const result = await createRecord("improvements",
      isNotionConfigured() ? {
        "Description": titleProp(description), "Date": dateProp(date),
        "Source Stage": selectProp(sourceStage), "Target Stage": selectProp(targetStage),
        "File Changed": richText(fileChanged), "Severity": selectProp(severity),
        "Committed": checkboxProp(committed), "Pipeline": richText(pipeline)
      } : {},
      { Description: description, Date: date, "Source Stage": sourceStage, "Target Stage": targetStage,
        "File Changed": fileChanged, Severity: severity, Committed: !!committed, Pipeline: pipeline }
    );
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.patch("/api/improvements/:id", async (req, res) => {
  try {
    const b = req.body;
    const localUpdates = {};
    const notionProps = {};

    if (isNotionConfigured()) {
      const { titleProp, richText, selectProp, dateProp, checkboxProp } = getNotion();
      if (b.description !== undefined) { notionProps["Description"] = titleProp(b.description); localUpdates.Description = b.description; }
      if (b.date !== undefined) { notionProps["Date"] = dateProp(b.date); localUpdates.Date = b.date; }
      if (b.sourceStage !== undefined) { notionProps["Source Stage"] = selectProp(b.sourceStage); localUpdates["Source Stage"] = b.sourceStage; }
      if (b.targetStage !== undefined) { notionProps["Target Stage"] = selectProp(b.targetStage); localUpdates["Target Stage"] = b.targetStage; }
      if (b.fileChanged !== undefined) { notionProps["File Changed"] = richText(b.fileChanged); localUpdates["File Changed"] = b.fileChanged; }
      if (b.severity !== undefined) { notionProps["Severity"] = selectProp(b.severity); localUpdates.Severity = b.severity; }
      if (b.committed !== undefined) { notionProps["Committed"] = checkboxProp(b.committed); localUpdates.Committed = b.committed; }
      if (b.pipeline !== undefined) { notionProps["Pipeline"] = richText(b.pipeline); localUpdates.Pipeline = b.pipeline; }
    } else {
      if (b.description !== undefined) localUpdates.Description = b.description;
      if (b.date !== undefined) localUpdates.Date = b.date;
      if (b.sourceStage !== undefined) localUpdates["Source Stage"] = b.sourceStage;
      if (b.targetStage !== undefined) localUpdates["Target Stage"] = b.targetStage;
      if (b.fileChanged !== undefined) localUpdates["File Changed"] = b.fileChanged;
      if (b.severity !== undefined) localUpdates.Severity = b.severity;
      if (b.committed !== undefined) localUpdates.Committed = b.committed;
      if (b.pipeline !== undefined) localUpdates.Pipeline = b.pipeline;
    }

    const result = await updateRecord("improvements", req.params.id, notionProps, localUpdates);
    res.json(result);
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
  const backend = isNotionConfigured() ? "Notion" : "Local JSON";
  console.log(`Dashboard running at http://localhost:${PORT} (backend: ${backend})`);
});
