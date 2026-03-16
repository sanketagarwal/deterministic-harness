// Notion database schemas for deterministic-harness

const pipelineStagesSchema = {
  title: "Pipeline Stages",
  properties: {
    "Stage": { title: {} },
    "Number": { number: {} },
    "Purpose": { rich_text: {} },
    "Gate Type": {
      select: {
        options: [
          { name: "human", color: "orange" },
          { name: "auto", color: "green" }
        ]
      }
    },
    "Status": {
      select: {
        options: [
          { name: "pending", color: "default" },
          { name: "in-progress", color: "blue" },
          { name: "blocked", color: "red" },
          { name: "passed", color: "green" }
        ]
      }
    },
    "Input Artifact": { url: {} },
    "Output Artifact": { url: {} },
    "Checklist Total": { number: {} },
    "Checklist Checked": { number: {} },
    "Pipeline": { rich_text: {} }
  }
};

const failureRegistrySchema = {
  title: "Failure Registry",
  properties: {
    "Failure": { title: {} },
    "Date": { date: {} },
    "Stage": {
      select: {
        options: [
          { name: "Stage 1", color: "red" },
          { name: "Stage 2", color: "orange" },
          { name: "Stage 3", color: "yellow" },
          { name: "Stage 4", color: "blue" },
          { name: "Stage 5", color: "purple" }
        ]
      }
    },
    "Root Cause": { rich_text: {} },
    "Fix Applied": { rich_text: {} },
    "File Changed": { rich_text: {} },
    "Committed": { checkbox: {} },
    "Pipeline": { rich_text: {} }
  }
};

const reliabilitySchema = {
  title: "Reliability Tracking",
  properties: {
    "Reason": { title: {} },
    "Date": { date: {} },
    "Reliability %": { number: { format: "percent" } },
    "Change": { rich_text: {} },
    "Pipeline": { rich_text: {} }
  }
};

const openFailureModesSchema = {
  title: "Open Failure Modes",
  properties: {
    "Failure Mode": { title: {} },
    "Date Identified": { date: {} },
    "Stage": {
      select: {
        options: [
          { name: "Stage 1", color: "red" },
          { name: "Stage 2", color: "orange" },
          { name: "Stage 3", color: "yellow" },
          { name: "Stage 4", color: "blue" },
          { name: "Stage 5", color: "purple" }
        ]
      }
    },
    "Why No Fix Yet": { rich_text: {} },
    "Owner": { rich_text: {} },
    "Resolved": { checkbox: {} },
    "Pipeline": { rich_text: {} }
  }
};

const improvementsSchema = {
  title: "Improvements Log",
  properties: {
    "Description": { title: {} },
    "Date": { date: {} },
    "Source Stage": {
      select: {
        options: [
          { name: "Stage 1", color: "red" },
          { name: "Stage 2", color: "orange" },
          { name: "Stage 3", color: "yellow" },
          { name: "Stage 4", color: "blue" },
          { name: "Stage 5", color: "purple" }
        ]
      }
    },
    "Target Stage": {
      select: {
        options: [
          { name: "Stage 1", color: "red" },
          { name: "Stage 2", color: "orange" },
          { name: "Stage 3", color: "yellow" },
          { name: "Stage 4", color: "blue" },
          { name: "Stage 5", color: "purple" }
        ]
      }
    },
    "File Changed": { rich_text: {} },
    "Severity": {
      select: {
        options: [
          { name: "high", color: "red" },
          { name: "medium", color: "yellow" },
          { name: "low", color: "green" }
        ]
      }
    },
    "Committed": { checkbox: {} },
    "Pipeline": { rich_text: {} }
  }
};

module.exports = {
  pipelineStagesSchema,
  failureRegistrySchema,
  reliabilitySchema,
  openFailureModesSchema,
  improvementsSchema
};
