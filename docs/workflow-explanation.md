# Workflow Deep Dive: Monthly Business Reporting

This document explains the architecture, logic, and node-level implementation of the updated `01 - Monthly Business Reporting` workflow in OmniFlow AI.

---

## 1. Node Execution Pipeline

| Sequence | Node Name | Node Type | Purpose / Action |
| :--- | :--- | :--- | :--- |
| **01** | `When clicking ‘Execute workflow’` | `manualTrigger` | Manual entry point for on-demand reporting. |
| **02** | `Set Reporting Parameters` | `set` | Defines the target reporting period (`reporting_month = "2026-10"`). |
| **03** | `Fetch Monthly Business Data` | `postgres` | Queries `monthly_business_metrics` for the requested reporting month. |
| **04** | `Prepare Business Data` | `set` | Structures business variables and maps default inputs. |
| **05** | `Calculate Business KPIs` | `set` | Computes gross profit, profit margin %, overdue invoice rate %, total projects, and completion %. |
| **06** | `Validate Business Data` | `if` | Validates that financial figures are positive and logical before LLM processing. |
| **07a** | `Build Validation Error` | `set` | Failure branch: builds error payload (`DATA_VALIDATION_ERROR`). |
| **07b** | `Log Validation Failure node` | `postgres` | Inserts failure audit record into `automation_execution_logs` with status `VALIDATION_FAILED`. |
| **08** | `Generate AI Management Report` | `chainLlm` | Success branch: Prompts Gemini LLM with structured business data. |
| **09** | `Google Gemini Chat Model` | `lmChatGoogleGemini` | Primary LLM engine (`gemini-1.5-flash` / `gemini-3.8-flash`). |
| **10** | `Structured Output Parser` | `outputParserStructured` | Validates and parses LLM response into strict JSON schema. |
| **11** | `Generate Report - Ollama Fallback`| `chainLlm` | Fallback branch triggered if primary Gemini invocation fails (`onError: continueErrorOutput`). |
| **12** | `Ollama Model` | `lmOllama` | Local LLM engine (`qwen2.5:1.5b`) running via Ollama. |
| **13** | `Parse and Validate Ollama Output` | `code` (JS) | Deterministic validator & fallback generator: verifies facts, checks constraints, and outputs validated report. |
| **14** | `Format Management Report` | `code` (JS) | Converts parsed JSON report into a styled, professional HTML report. |
| **15** | `Convert to File` | `convertToFile` | Encodes HTML string into a binary file (`index.html`). |
| **16** | `Generate PDF Report` | `httpRequest` | Dispatches binary HTML to Gotenberg Chromium endpoint (`:3000`). |
| **17** | `Set PDF Filename` | `code` (JS) | Standardizes the output PDF filename (`Northstar_Management_Report_2026-10.pdf`). |
| **18** | `Save PDF Report` | `readWriteFile` | Persists binary PDF to `/reports` volume on disk. |
| **19** | `Execute a SQL query` | `postgres` | Inserts execution status record into `automation_execution_logs` with status `SUCCESS`. |

---

## 2. Business KPI Formulations

The workflow automatically calculates key performance indicators:

1. **Gross Profit**:
   $$\text{Gross Profit} = \text{total\_revenue} - \text{total\_expenses}$$
2. **Gross Profit Margin (%)**:
   $$\text{Gross Margin (\%)} = \left(\frac{\text{total\_revenue} - \text{total\_expenses}}{\text{total\_revenue}}\right) \times 100$$
3. **Overdue Invoice Rate**:
   $$\text{Overdue Rate (\%)} = \left(\frac{\text{overdue\_invoices}}{\text{total\_invoices}}\right) \times 100$$
4. **Total Projects**:
   $$\text{Total Projects} = \text{completed\_projects} + \text{active\_projects}$$
5. **Project Completion Rate**:
   $$\text{Completion Rate (\%)} = \left(\frac{\text{completed\_projects}}{\text{completed\_projects} + \text{active\_projects}}\right) \times 100$$

---

## 3. Data Validation Guardrail & Failure Auditing

The `Validate Business Data` conditional node enforces strict assertions:
- `total_revenue > 0`
- `total_expenses >= 0`
- `total_invoices > 0`
- `overdue_invoices <= total_invoices`

If validation passes, execution continues to the AI tier. If validation fails:
1. `Build Validation Error` constructs a structured diagnostic object.
2. `Log Validation Failure node` records the event in `automation_execution_logs`:
   ```sql
   INSERT INTO automation_execution_logs (
       workflow_name, company_name, reporting_month, execution_status, error_message, execution_finished_at
   ) VALUES (
       '01 - Monthly Business Reporting', $1, $2, 'VALIDATION_FAILED', $3, CURRENT_TIMESTAMP
   );
   ```

---

## 4. Multi-Tier AI & Deterministic Fallback Engine

OmniFlow AI implements a resilient dual-tier AI architecture:

1. **Primary Tier (Google Gemini)**:
   - Uses `models/gemini-1.5-flash` / `models/gemini-3.8-flash`.
   - Constrained by a `Structured Output Parser` requiring an executive summary, segmented financial performance, operational analysis, risk assessments, prioritized action items, and data limitations.
2. **Local Fallback Tier (Ollama `qwen2.5:1.5b`)**:
   - If the cloud provider fails, execution automatically routes to the local Ollama instance.
   - The output passes into `Parse and Validate Ollama Output`, a deterministic JavaScript verification engine that asserts all required KPI numbers are finite and non-empty, computes strictly grounded summaries, generates rule-based management recommendations, and tags the metadata as `ai_provider: 'Deterministic JavaScript'`.

---

## 5. Gotenberg Rendering & Output Delivery

The formatted HTML is submitted to Gotenberg's headless Chromium endpoint:
- Standard A4 dimensions with 0.5-inch margins.
- Clean typography and structured KPI metric grid.
- Output PDF is saved to `/reports` and indexed in PostgreSQL as `SUCCESS`.
