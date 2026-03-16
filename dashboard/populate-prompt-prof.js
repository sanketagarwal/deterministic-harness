#!/usr/bin/env node

/**
 * Populate Notion databases for the prompt-prof-harness pipeline.
 * Creates 5 pipeline stage rows and 1 reliability baseline row.
 */

require('dotenv').config({ path: require('path').join(__dirname, '.env') });

const {
  getClient,
  createPage,
  titleProp,
  numberProp,
  richText,
  selectProp,
  dateProp
} = require('./notion/client');

const config = require('./notion-config.json');

const PIPELINE_NAME = 'prompt-prof-harness';

// Stage definitions with checklist items from pipeline.md
const stages = [
  {
    name: 'Session Parsing',
    number: 1,
    purpose: 'Parse raw session data from Claude Code and Cursor into structured prompt objects with text, timestamp, session ID, source, and tool usage/outcomes.',
    gateType: 'auto',
    checklist: [
      'Both Claude Code and Cursor parsers ran without errors',
      'Total prompt count is non-zero (if zero, verify data exists at expected paths)',
      'Each parsed prompt has: text, timestamp, sessionId, source fields populated',
      'Malformed JSONL lines logged with count — not silently skipped',
      'TypeScript compiles: npx tsc --noEmit'
    ]
  },
  {
    name: 'Prompt Classification',
    number: 2,
    purpose: 'Classify each parsed prompt into types: Code Generation, Questions, File Operations, Commands/Actions, Clarifications, Other.',
    gateType: 'auto',
    checklist: [
      'Every prompt has exactly one classification type assigned',
      'Distribution includes at least 3 different types (if all prompts are "Other", classifier is broken)',
      'Clarification detection checked: prompts starting with "No,", "Actually,", "Not that" are flagged',
      'Short prompts (<5 words) without action verbs classified as Commands or Other, not Code Generation'
    ]
  },
  {
    name: 'Quality Scoring',
    number: 3,
    purpose: 'Score each prompt 0-100 across 4 dimensions: Clarity (25%), Context (25%), Efficiency (25%), Outcome (25%).',
    gateType: 'human',
    checklist: [
      'Every prompt has a total score and per-dimension breakdown (clarity, context, efficiency, outcome)',
      'Score distribution is not flat — if >90% of prompts score 50-60, scoring lacks discriminating power',
      'Retry detection working: prompts >60% similar to previous prompt in session get efficiency penalty',
      'At least one prompt scored above 80 and one below 40 exist (if not, verify edge cases are handled)',
      'Direct CLI commands (e.g., "/help", "y", "n") scored appropriately — not penalized as vague'
    ]
  },
  {
    name: 'Pattern Analysis',
    number: 4,
    purpose: 'Aggregate scores into actionable insights: best/worst prompts, type distributions, score trends, cost per session, improvement opportunities.',
    gateType: 'auto',
    checklist: [
      'Top 10 and bottom 10 prompts identified with scores and reasons',
      'Type distribution computed with percentages',
      'At least 2 specific, actionable recommendations generated (not generic advice)',
      'Cost analysis included if Claude Code cost data is available',
      'Recommendations reference specific scoring dimensions the user can improve'
    ]
  },
  {
    name: 'Report Generation',
    number: 5,
    purpose: 'Render the final CLI report with formatted tables, score distributions, and recommendations. Run self-improvement retrospective.',
    gateType: 'human',
    checklist: [
      'Report renders without errors in terminal',
      'Total prompt count in report matches count from Stage 1',
      'Top prompt score in report matches highest score from Stage 3',
      'All tests pass: npm test (with at least 1 test executed)',
      'Build succeeds: npm run build'
    ]
  }
];

async function main() {
  // Initialize client
  getClient(process.env.NOTION_TOKEN);

  console.log('Populating prompt-prof-harness pipeline data...\n');

  // 1. Pipeline Stages — 5 rows
  console.log('--- Pipeline Stages ---');
  for (const stage of stages) {
    const checklistText = stage.checklist.map((item, i) => `${i + 1}. ${item}`).join('\n');
    const properties = {
      'Stage': titleProp(stage.name),
      'Number': numberProp(stage.number),
      'Purpose': richText(stage.purpose),
      'Gate Type': selectProp(stage.gateType),
      'Status': selectProp('not_started'),
      'Checklist Total': numberProp(stage.checklist.length),
      'Checklist Checked': numberProp(0),
      'Pipeline': richText(PIPELINE_NAME)
    };

    const page = await createPage(config.pipelineStages, properties);
    console.log(`  Created Stage ${stage.number}: ${stage.name} (${page.id})`);

    // Add checklist as page content (children blocks)
    const notion = getClient();
    const children = stage.checklist.map(item => ({
      object: 'block',
      type: 'to_do',
      to_do: {
        rich_text: [{ type: 'text', text: { content: item } }],
        checked: false
      }
    }));

    await notion.blocks.children.append({
      block_id: page.id,
      children
    });
    console.log(`    Added ${stage.checklist.length} checklist items as to-do blocks`);
  }

  // 2. Reliability Tracking — 1 baseline row
  console.log('\n--- Reliability Tracking ---');
  const reliabilityProps = {
    'Reason': titleProp('Initial pipeline setup'),
    'Date': dateProp('2026-03-16'),
    'Reliability %': numberProp(70),
    'Change': richText('baseline'),
    'Pipeline': richText(PIPELINE_NAME)
  };

  const relPage = await createPage(config.reliability, reliabilityProps);
  console.log(`  Created baseline: 70%, ${relPage.id}`);

  // 3. Failure Registry, Open Failure Modes, Improvements Log — left empty
  console.log('\n--- Failure Registry: left empty (populated during runs) ---');
  console.log('--- Open Failure Modes: left empty (populated during runs) ---');
  console.log('--- Improvements Log: left empty (populated during runs) ---');

  console.log('\nDone. All databases populated for prompt-prof-harness.');
}

main().catch(err => {
  console.error('Error:', err.message);
  if (err.body) console.error('Notion API:', JSON.stringify(err.body, null, 2));
  process.exit(1);
});
