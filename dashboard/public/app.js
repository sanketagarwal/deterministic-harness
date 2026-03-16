// State
let currentView = "overview";
let stages = [];
let failures = [];
let reliability = [];
let openFailures = [];
let improvements = [];

// --- API helpers ---

async function api(method, path, body) {
  const opts = { method, headers: { "Content-Type": "application/json" } };
  if (body) opts.body = JSON.stringify(body);
  const res = await fetch(`/api${path}`, opts);
  const data = await res.json();
  if (!res.ok) throw new Error(data.error || "Request failed");
  return data;
}

function toast(msg, type = "success") {
  const el = document.createElement("div");
  el.className = `toast ${type}`;
  el.textContent = msg;
  document.body.appendChild(el);
  setTimeout(() => el.remove(), 3000);
}

// --- Data loading ---

async function loadAll() {
  try {
    [stages, failures, reliability, openFailures, improvements] = await Promise.all([
      api("GET", "/stages"),
      api("GET", "/failures"),
      api("GET", "/reliability"),
      api("GET", "/open-failures"),
      api("GET", "/improvements")
    ]);
    render();
  } catch (err) {
    toast(err.message, "error");
  }
}

// --- Navigation ---

function navigate(view) {
  currentView = view;
  document.querySelectorAll(".sidebar nav a").forEach(a => {
    a.classList.toggle("active", a.dataset.view === view);
  });
  render();
}

// --- Rendering ---

function render() {
  const main = document.querySelector(".main");
  switch (currentView) {
    case "overview": main.innerHTML = renderOverview(); break;
    case "stages": main.innerHTML = renderStages(); break;
    case "failures": main.innerHTML = renderFailures(); break;
    case "reliability": main.innerHTML = renderReliability(); break;
    case "open-failures": main.innerHTML = renderOpenFailures(); break;
    case "improvements": main.innerHTML = renderImprovements(); break;
  }
  bindEvents();
}

function renderOverview() {
  const totalFailures = failures.length;
  const committedFixes = failures.filter(f => f.Committed).length;
  const latestReliability = reliability.length > 0
    ? reliability[reliability.length - 1]["Reliability %"]
    : null;
  const openCount = openFailures.filter(f => !f.Resolved).length;
  const passedStages = stages.filter(s => s.Status === "passed").length;
  const blockedStages = stages.filter(s => s.Status === "blocked").length;

  return `
    <div class="page-header">
      <h2>Pipeline Overview</h2>
      <button class="btn" onclick="loadAll()">Refresh</button>
    </div>

    <div class="stats">
      <div class="stat-card">
        <div class="label">Reliability</div>
        <div class="value ${latestReliability !== null && latestReliability >= 0.8 ? 'green' : 'orange'}">
          ${latestReliability !== null ? Math.round(latestReliability * 100) + '%' : 'N/A'}
        </div>
      </div>
      <div class="stat-card">
        <div class="label">Stages Passed</div>
        <div class="value green">${passedStages}/${stages.length}</div>
      </div>
      <div class="stat-card">
        <div class="label">Total Failures</div>
        <div class="value red">${totalFailures}</div>
      </div>
      <div class="stat-card">
        <div class="label">Fixes Committed</div>
        <div class="value accent">${committedFixes}</div>
      </div>
      <div class="stat-card">
        <div class="label">Open Issues</div>
        <div class="value ${openCount > 0 ? 'orange' : 'green'}">${openCount}</div>
      </div>
    </div>

    ${stages.length > 0 ? renderPipelineFlow() : ''}
    ${reliability.length > 0 ? renderReliabilityChart() : ''}

    ${failures.length > 0 ? `
    <div class="table-container">
      <div class="table-header">
        <h3>Recent Failures</h3>
      </div>
      <table>
        <thead><tr><th>Date</th><th>Stage</th><th>Failure</th><th>Committed</th></tr></thead>
        <tbody>
          ${failures.slice(0, 5).map(f => `
            <tr>
              <td>${f.Date || '-'}</td>
              <td><span class="badge">${f.Stage || '-'}</span></td>
              <td>${f.Failure || '-'}</td>
              <td>${f.Committed ? '<span class="badge passed">Yes</span>' : '<span class="badge blocked">No</span>'}</td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    </div>` : `
    <div class="empty-state">
      <h3>No data yet</h3>
      <p>Add pipeline stages and start tracking failures to see your overview.</p>
    </div>`}
  `;
}

function renderPipelineFlow() {
  const sorted = [...stages].sort((a, b) => (a.Number || 0) - (b.Number || 0));
  return `
    <div class="pipeline-flow">
      ${sorted.map((s, i) => `
        ${i > 0 ? '<div class="pipeline-arrow">&rarr;</div>' : ''}
        <div class="pipeline-stage ${(s.Status || 'pending').toLowerCase()}">
          <div class="stage-num">${s.Number || i + 1}</div>
          <div class="stage-name">${s.Stage || 'Unnamed'}</div>
          <div class="stage-gate">${s['Gate Type'] || 'auto'} gate</div>
          ${s['Checklist Total'] ? `
            <div class="checklist-score">
              <div class="progress-bar" style="width:80px">
                <div class="fill" style="width:${s['Checklist Total'] ? (s['Checklist Checked'] / s['Checklist Total']) * 100 : 0}%"></div>
              </div>
              <span>${s['Checklist Checked'] || 0}/${s['Checklist Total'] || 0}</span>
            </div>
          ` : ''}
        </div>
      `).join('')}
    </div>
  `;
}

function renderReliabilityChart() {
  const maxVal = 1;
  return `
    <div class="reliability-chart">
      <h3>Reliability Over Time</h3>
      <div class="chart-bars">
        ${reliability.map(r => {
          const pct = (r["Reliability %"] || 0) / maxVal * 100;
          return `
            <div class="chart-bar">
              <div class="bar-value">${Math.round((r["Reliability %"] || 0) * 100)}%</div>
              <div class="bar" style="height:${pct}%"></div>
              <div class="bar-label">${r.Date ? r.Date.substring(5) : ''}</div>
            </div>
          `;
        }).join('')}
      </div>
    </div>
  `;
}

// --- Stages view ---

function renderStages() {
  const sorted = [...stages].sort((a, b) => (a.Number || 0) - (b.Number || 0));
  return `
    <div class="page-header">
      <h2>Pipeline Stages</h2>
      <button class="btn primary" data-action="add-stage">+ Add Stage</button>
    </div>
    ${sorted.length > 0 ? `
    <div class="table-container">
      <table>
        <thead><tr><th>#</th><th>Stage</th><th>Purpose</th><th>Gate</th><th>Status</th><th>Checklist</th><th>Actions</th></tr></thead>
        <tbody>
          ${sorted.map(s => `
            <tr>
              <td>${s.Number || '-'}</td>
              <td><strong>${s.Stage || '-'}</strong></td>
              <td>${s.Purpose || '-'}</td>
              <td><span class="badge ${s['Gate Type'] || ''}">${s['Gate Type'] || '-'}</span></td>
              <td><span class="badge ${(s.Status || 'pending').toLowerCase()}">${s.Status || 'pending'}</span></td>
              <td>
                <div class="checklist-score">
                  <div class="progress-bar" style="width:60px">
                    <div class="fill" style="width:${s['Checklist Total'] ? (s['Checklist Checked'] / s['Checklist Total']) * 100 : 0}%"></div>
                  </div>
                  ${s['Checklist Checked'] || 0}/${s['Checklist Total'] || 0}
                </div>
              </td>
              <td>
                <button class="btn sm" data-action="edit-stage" data-id="${s.id}">Edit</button>
                <button class="btn sm danger" data-action="delete-stage" data-id="${s.id}">Delete</button>
              </td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    </div>` : renderEmptyState("No stages", "Add pipeline stages to get started.")}
  `;
}

// --- Failures view ---

function renderFailures() {
  return `
    <div class="page-header">
      <h2>Failure Registry</h2>
      <button class="btn primary" data-action="add-failure">+ Log Failure</button>
    </div>
    ${failures.length > 0 ? `
    <div class="table-container">
      <table>
        <thead><tr><th>Date</th><th>Stage</th><th>Failure</th><th>Root Cause</th><th>Fix Applied</th><th>File Changed</th><th>Committed</th><th>Actions</th></tr></thead>
        <tbody>
          ${failures.map(f => `
            <tr>
              <td>${f.Date || '-'}</td>
              <td><span class="badge">${f.Stage || '-'}</span></td>
              <td>${f.Failure || '-'}</td>
              <td>${f['Root Cause'] || '-'}</td>
              <td>${f['Fix Applied'] || '-'}</td>
              <td><code>${f['File Changed'] || '-'}</code></td>
              <td>
                <input type="checkbox" ${f.Committed ? 'checked' : ''} data-action="toggle-failure-committed" data-id="${f.id}">
              </td>
              <td>
                <button class="btn sm danger" data-action="delete-failure" data-id="${f.id}">Delete</button>
              </td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    </div>` : renderEmptyState("No failures logged", "Log failures to build your harness knowledge base.")}
  `;
}

// --- Reliability view ---

function renderReliability() {
  return `
    <div class="page-header">
      <h2>Reliability Tracking</h2>
      <button class="btn primary" data-action="add-reliability">+ Add Entry</button>
    </div>
    ${reliability.length > 0 ? `
    ${renderReliabilityChart()}
    <div class="table-container">
      <table>
        <thead><tr><th>Date</th><th>Reliability</th><th>Change</th><th>Reason</th></tr></thead>
        <tbody>
          ${reliability.map(r => `
            <tr>
              <td>${r.Date || '-'}</td>
              <td><strong>${r["Reliability %"] !== null ? Math.round(r["Reliability %"] * 100) + '%' : '-'}</strong></td>
              <td>${r.Change || '-'}</td>
              <td>${r.Reason || '-'}</td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    </div>` : renderEmptyState("No reliability data", "Track how your pipeline improves over time.")}
  `;
}

// --- Open Failure Modes ---

function renderOpenFailures() {
  return `
    <div class="page-header">
      <h2>Open Failure Modes</h2>
      <button class="btn primary" data-action="add-open-failure">+ Add Issue</button>
    </div>
    ${openFailures.length > 0 ? `
    <div class="table-container">
      <table>
        <thead><tr><th>Date</th><th>Stage</th><th>Failure Mode</th><th>Why No Fix</th><th>Owner</th><th>Resolved</th><th>Actions</th></tr></thead>
        <tbody>
          ${openFailures.map(f => `
            <tr>
              <td>${f['Date Identified'] || '-'}</td>
              <td><span class="badge">${f.Stage || '-'}</span></td>
              <td>${f['Failure Mode'] || '-'}</td>
              <td>${f['Why No Fix Yet'] || '-'}</td>
              <td>${f.Owner || '-'}</td>
              <td>
                <input type="checkbox" ${f.Resolved ? 'checked' : ''} data-action="toggle-open-failure-resolved" data-id="${f.id}">
              </td>
              <td>
                <button class="btn sm danger" data-action="delete-open-failure" data-id="${f.id}">Delete</button>
              </td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    </div>` : renderEmptyState("No open failure modes", "Known issues without fixes yet will appear here.")}
  `;
}

// --- Improvements view ---

function renderImprovements() {
  return `
    <div class="page-header">
      <h2>Improvements Log</h2>
      <button class="btn primary" data-action="add-improvement">+ Log Improvement</button>
    </div>
    ${improvements.length > 0 ? `
    <div class="table-container">
      <table>
        <thead><tr><th>Date</th><th>Description</th><th>Source</th><th>Target</th><th>File Changed</th><th>Severity</th><th>Committed</th></tr></thead>
        <tbody>
          ${improvements.map(imp => `
            <tr>
              <td>${imp.Date || '-'}</td>
              <td>${imp.Description || '-'}</td>
              <td><span class="badge">${imp['Source Stage'] || '-'}</span></td>
              <td><span class="badge">${imp['Target Stage'] || '-'}</span></td>
              <td><code>${imp['File Changed'] || '-'}</code></td>
              <td><span class="badge ${(imp.Severity || '').toLowerCase()}">${imp.Severity || '-'}</span></td>
              <td>
                <input type="checkbox" ${imp.Committed ? 'checked' : ''} data-action="toggle-improvement-committed" data-id="${imp.id}">
              </td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    </div>` : renderEmptyState("No improvements logged", "Self-improvement fixes will appear here.")}
  `;
}

function renderEmptyState(title, desc) {
  return `<div class="empty-state"><h3>${title}</h3><p>${desc}</p></div>`;
}

// --- Modals ---

function showModal(title, fields, onSubmit) {
  const overlay = document.getElementById("modal-overlay");
  overlay.innerHTML = `
    <div class="modal">
      <h3>${title}</h3>
      <form id="modal-form">
        ${fields.map(f => `
          <div class="form-group">
            <label>${f.label}</label>
            ${f.type === "select"
              ? `<select name="${f.name}">${f.options.map(o => `<option value="${o.value}" ${f.value === o.value ? 'selected' : ''}>${o.label}</option>`).join('')}</select>`
              : f.type === "textarea"
                ? `<textarea name="${f.name}" placeholder="${f.placeholder || ''}">${f.value || ''}</textarea>`
                : `<input type="${f.type || 'text'}" name="${f.name}" value="${f.value || ''}" placeholder="${f.placeholder || ''}">`
            }
          </div>
        `).join('')}
        <div class="form-actions">
          <button type="button" class="btn" onclick="closeModal()">Cancel</button>
          <button type="submit" class="btn primary">Save</button>
        </div>
      </form>
    </div>
  `;
  overlay.classList.add("open");
  document.getElementById("modal-form").onsubmit = async (e) => {
    e.preventDefault();
    const data = Object.fromEntries(new FormData(e.target));
    try {
      await onSubmit(data);
      closeModal();
      await loadAll();
      toast("Saved successfully");
    } catch (err) {
      toast(err.message, "error");
    }
  };
}

function closeModal() {
  document.getElementById("modal-overlay").classList.remove("open");
}

const stageOptions = [1,2,3,4,5].map(n => ({ value: `Stage ${n}`, label: `Stage ${n}` }));
const severityOptions = ["high", "medium", "low"].map(s => ({ value: s, label: s }));

// --- Event binding ---

function bindEvents() {
  document.querySelectorAll("[data-action]").forEach(el => {
    const action = el.dataset.action;
    const id = el.dataset.id;

    if (action === "add-stage") {
      el.onclick = () => showModal("Add Stage", [
        { name: "name", label: "Stage Name", placeholder: "e.g., Specification" },
        { name: "number", label: "Stage Number", type: "number", placeholder: "1" },
        { name: "purpose", label: "Purpose", type: "textarea" },
        { name: "gateType", label: "Gate Type", type: "select", options: [{ value: "auto", label: "Auto" }, { value: "human", label: "Human" }] },
        { name: "checklistTotal", label: "Checklist Items", type: "number", value: "3" }
      ], data => api("POST", "/stages", {
        name: data.name,
        number: parseInt(data.number) || 1,
        purpose: data.purpose,
        gateType: data.gateType,
        checklistTotal: parseInt(data.checklistTotal) || 0
      }));
    }

    if (action === "edit-stage") {
      el.onclick = () => {
        const s = stages.find(x => x.id === id);
        showModal("Edit Stage", [
          { name: "name", label: "Stage Name", value: s.Stage },
          { name: "purpose", label: "Purpose", type: "textarea", value: s.Purpose },
          { name: "status", label: "Status", type: "select", value: s.Status || "pending", options: [
            { value: "pending", label: "Pending" },
            { value: "in-progress", label: "In Progress" },
            { value: "blocked", label: "Blocked" },
            { value: "passed", label: "Passed" }
          ]},
          { name: "checklistChecked", label: "Checklist Checked", type: "number", value: String(s['Checklist Checked'] || 0) },
          { name: "checklistTotal", label: "Checklist Total", type: "number", value: String(s['Checklist Total'] || 0) }
        ], data => api("PATCH", `/stages/${id}`, {
          name: data.name,
          purpose: data.purpose,
          status: data.status,
          checklistChecked: parseInt(data.checklistChecked) || 0,
          checklistTotal: parseInt(data.checklistTotal) || 0
        }));
      };
    }

    if (action === "delete-stage") {
      el.onclick = async () => {
        if (confirm("Delete this stage?")) {
          await api("DELETE", `/stages/${id}`);
          await loadAll();
          toast("Stage deleted");
        }
      };
    }

    if (action === "add-failure") {
      el.onclick = () => showModal("Log Failure", [
        { name: "failure", label: "What failed?", placeholder: "Agent skipped E2E tests" },
        { name: "date", label: "Date", type: "date", value: new Date().toISOString().split('T')[0] },
        { name: "stage", label: "Stage", type: "select", options: stageOptions },
        { name: "rootCause", label: "Root Cause", type: "textarea" },
        { name: "fixApplied", label: "Fix Applied", type: "textarea" },
        { name: "fileChanged", label: "File Changed", placeholder: "skills/stage-3-testing.md" }
      ], data => api("POST", "/failures", data));
    }

    if (action === "toggle-failure-committed") {
      el.onchange = async () => {
        await api("PATCH", `/failures/${id}`, { committed: el.checked });
        toast(el.checked ? "Marked as committed" : "Unmarked");
      };
    }

    if (action === "delete-failure") {
      el.onclick = async () => {
        if (confirm("Delete this failure entry?")) {
          await api("DELETE", `/failures/${id}`);
          await loadAll();
          toast("Deleted");
        }
      };
    }

    if (action === "add-reliability") {
      el.onclick = () => showModal("Add Reliability Entry", [
        { name: "date", label: "Date", type: "date", value: new Date().toISOString().split('T')[0] },
        { name: "reliability", label: "Reliability (0.0 - 1.0)", type: "number", placeholder: "0.75" },
        { name: "change", label: "Change", placeholder: "+5%" },
        { name: "reason", label: "Reason", type: "textarea" }
      ], data => api("POST", "/reliability", {
        ...data,
        reliability: parseFloat(data.reliability) || 0
      }));
    }

    if (action === "add-open-failure") {
      el.onclick = () => showModal("Add Open Failure Mode", [
        { name: "failureMode", label: "Failure Mode", placeholder: "What can go wrong?" },
        { name: "dateIdentified", label: "Date", type: "date", value: new Date().toISOString().split('T')[0] },
        { name: "stage", label: "Stage", type: "select", options: stageOptions },
        { name: "whyNoFix", label: "Why No Fix Yet?", type: "textarea" },
        { name: "owner", label: "Owner", placeholder: "Who's working on this?" }
      ], data => api("POST", "/open-failures", data));
    }

    if (action === "toggle-open-failure-resolved") {
      el.onchange = async () => {
        await api("PATCH", `/open-failures/${id}`, { resolved: el.checked });
        toast(el.checked ? "Resolved" : "Reopened");
      };
    }

    if (action === "delete-open-failure") {
      el.onclick = async () => {
        if (confirm("Delete?")) {
          await api("DELETE", `/open-failures/${id}`);
          await loadAll();
        }
      };
    }

    if (action === "add-improvement") {
      el.onclick = () => showModal("Log Improvement", [
        { name: "description", label: "What improved?", placeholder: "Added checklist item for E2E test verification" },
        { name: "date", label: "Date", type: "date", value: new Date().toISOString().split('T')[0] },
        { name: "sourceStage", label: "Found in Stage", type: "select", options: stageOptions },
        { name: "targetStage", label: "Fixed in Stage", type: "select", options: stageOptions },
        { name: "fileChanged", label: "File Changed", placeholder: "skills/stage-3-testing.md" },
        { name: "severity", label: "Severity", type: "select", options: severityOptions }
      ], data => api("POST", "/improvements", data));
    }

    if (action === "toggle-improvement-committed") {
      el.onchange = async () => {
        await api("PATCH", `/improvements/${id}`, { committed: el.checked });
        toast(el.checked ? "Marked as committed" : "Unmarked");
      };
    }
  });
}

// --- Init ---

async function init() {
  const status = await api("GET", "/status");
  if (!status.configured) {
    document.querySelector(".main").innerHTML = `
      <div class="setup-screen">
        <h2>Setup Required</h2>
        <p>Configure your Notion integration to get started.</p>
        <div class="form-group">
          <label>1. Create a Notion integration at notion.so/my-integrations</label>
        </div>
        <div class="form-group">
          <label>2. Copy .env.example to .env and add your token</label>
        </div>
        <div class="form-group">
          <label>3. Run: npm run setup</label>
        </div>
        <div class="form-group">
          <label>4. Restart the server: npm start</label>
        </div>
      </div>
    `;
    return;
  }

  // Bind navigation
  document.querySelectorAll(".sidebar nav a").forEach(a => {
    a.onclick = (e) => {
      e.preventDefault();
      navigate(a.dataset.view);
    };
  });

  await loadAll();
}

init();
