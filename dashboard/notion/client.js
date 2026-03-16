const { Client } = require("@notionhq/client");

let notionClient = null;

function getClient(token) {
  if (!notionClient || token) {
    notionClient = new Client({ auth: token || process.env.NOTION_TOKEN });
  }
  return notionClient;
}

// --- Database creation ---

async function createDatabase(parentPageId, title, schema) {
  const notion = getClient();
  const response = await notion.databases.create({
    parent: { type: "page_id", page_id: parentPageId },
    title: [{ type: "text", text: { content: title } }],
    properties: schema.properties
  });
  return response.id;
}

// --- Generic CRUD ---

async function queryDatabase(databaseId, filter, sorts) {
  const notion = getClient();
  const params = { database_id: databaseId };
  if (filter) params.filter = filter;
  if (sorts) params.sorts = sorts;

  const results = [];
  let cursor;
  do {
    if (cursor) params.start_cursor = cursor;
    const response = await notion.databases.query(params);
    results.push(...response.results);
    cursor = response.has_more ? response.next_cursor : null;
  } while (cursor);

  return results;
}

async function createPage(databaseId, properties) {
  const notion = getClient();
  return notion.pages.create({
    parent: { database_id: databaseId },
    properties
  });
}

async function updatePage(pageId, properties) {
  const notion = getClient();
  return notion.pages.update({
    page_id: pageId,
    properties
  });
}

async function deletePage(pageId) {
  const notion = getClient();
  return notion.pages.update({
    page_id: pageId,
    archived: true
  });
}

// --- Property helpers ---

function richText(content) {
  return { rich_text: [{ text: { content: content || "" } }] };
}

function titleProp(content) {
  return { title: [{ text: { content: content || "" } }] };
}

function selectProp(name) {
  return { select: name ? { name } : null };
}

function numberProp(value) {
  return { number: value };
}

function dateProp(dateStr) {
  return { date: dateStr ? { start: dateStr } : null };
}

function checkboxProp(checked) {
  return { checkbox: !!checked };
}

function urlProp(url) {
  return { url: url || null };
}

// --- Extract values from Notion page ---

function extractText(prop) {
  if (!prop) return "";
  if (prop.type === "title") {
    return prop.title.map(t => t.plain_text).join("");
  }
  if (prop.type === "rich_text") {
    return prop.rich_text.map(t => t.plain_text).join("");
  }
  if (prop.type === "select") {
    return prop.select ? prop.select.name : "";
  }
  if (prop.type === "number") {
    return prop.number;
  }
  if (prop.type === "date") {
    return prop.date ? prop.date.start : "";
  }
  if (prop.type === "checkbox") {
    return prop.checkbox;
  }
  if (prop.type === "url") {
    return prop.url || "";
  }
  return "";
}

function pageToObject(page) {
  const obj = { id: page.id };
  for (const [key, prop] of Object.entries(page.properties)) {
    obj[key] = extractText(prop);
  }
  return obj;
}

module.exports = {
  getClient,
  createDatabase,
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
};
