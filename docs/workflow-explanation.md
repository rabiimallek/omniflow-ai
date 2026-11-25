# Workflow Deep Dive: Monthly Business Reporting

This document explains the architecture, logic, and node-level implementation of the `01 - Monthly Business Reporting` workflow in OmniFlow AI.

---

## 1. Node Execution Pipeline

| Sequence | Node Name | Node Type | Purpose / Action |
| :--- | :--- | :--- | :--- |
| **01** | `When clicking ‘Execute workflow’` | `manualTrigger` | Manual entry point for on-demand reporting. |
| **02** | `Set Reporting Parameters` | `set` | Defines the target reporting period (`reporting_month = "2026-10"`). |
| **03** | `Fetch Monthly Business Data` | `postgres` | Queries `monthly_business_metrics` for the requested reporting month. |
| **04** | `Prepare Business Data` | `set` | Structures business variables and ensures fallback values for required fields. |
| **05** | `Calculate Business KPIs` | `set` | Computes gross profit, overdue invoice rate, total projects, and completion percentage. |
| **06** | `Validate Business Data` | `if` | Validates that financial figures are positive and logical before LLM processing. |
| **07a** | `Build Validation Error` | `set` | Failure branch: tags the item as `DATA_VALIDATION_ERROR` and halts PDF rendering. |
| **07b** | `Generate AI Management Report` | `chainLlm` | Success branch: Prompts Gemini LLM with structured business data and guidelines. |
| **08** | `Structured Output Parser` | `outputParserStructured` | Validates and parses LLM response into strict JSON schema. |
| **09** | `Google Gemini Chat Model` | `lmChatGoogleGemini` | Primary LLM engine (`gemini-1.5-flash`). |
| **10** | `Generate AI Report - Fallback` | `chainLlm` | Fallback branch triggered if primary model invocation fails. |
| **11** | `OpenAI Chat Model` | `lmChatOpenAi` | Fallback LLM provider (`gpt-4o-mini`). |
| **12** | `Format Management Report` | `code` (JS) | Converts parsed JSON report into a styled, professional HTML report. |
| **13** | `Convert to File` | `convertToFile` | Encodes HTML string into a binary file (`index.html`). |
| **14** | `Generate PDF Report` | `httpRequest` | Dispatches binary HTML to Gotenberg Chromium endpoint (`:3000`). |
| **15** | `Set PDF Filename` | `code` (JS) | Standardizes the output PDF filename with company name and month. |
| **16** | `Save PDF Report` | `readWriteFile` | Persists binary PDF to `/reports` volume on disk. |
| **17** | `Execute a SQL query` | `postgres` | Inserts execution status record into `automation_execution_logs`. |

---

## 2. Business KPI Formulations

The workflow automatically calculates four core business indicators:

1. **Gross Profit**:
   $$\text{Gross Profit} = \text{total\_revenue} - \text{total\_expenses}$$
2. **Overdue Invoice Rate**:
   $$\text{Overdue Rate (\%)} = \left(\frac{\text{overdue\_invoices}}{\text{total\_invoices}}\right) \times 100$$
3. **Total Projects**:
   $$\text{Total Projects} = \text{completed\_projects} + \text{active\_projects}$$
4. **Project Completion Rate**:
   $$\text{Completion Rate (\%)} = \left(\frac{\text{completed\_projects}}{\text{completed\_projects} + \text{active\_projects}}\right) \times 100$$

---

## 3. Data Validation Guardrail

The `Validate Business Data` conditional node enforces strict assertions:
- `total_revenue > 0`
- `total_expenses >= 0`
- `total_invoices > 0`
- `overdue_invoices <= total_invoices`

If any assertion fails, execution routes to `Build Validation Error`. This prevents malformed data or division-by-zero errors from entering the generative AI pipeline.

---

## 4. LLM Prompting & Strict Output Enforcement

The prompt directs the model to act as a senior business analyst, strictly enforcing:
- Outputting pure JSON matching the JSON Schema.
- Calculating metrics without inventing missing information.
- Formulating exactly three prioritized, actionable management recommendations.
- Identifying real risks grounded in the data without exaggeration.

The `Structured Output Parser` ensures that the downstream HTML generator receives guaranteed object types.

---

## 5. Gotenberg Rendering & PDF Delivery

Gotenberg's Chromium engine provides deterministic rendering:
- Standard A4 dimensions (`paperWidth: 8.27`, `paperHeight: 11.7` inches).
- Clean print margins (0.5 inch top/bottom).
- CSS media formatting with modern typography, badge indicators, and responsive card layouts.
