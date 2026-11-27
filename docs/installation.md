# Installation and Setup Guide

This guide details how to configure, run, and verify OmniFlow AI on Windows 11 or Linux hosts.

---

## 1. Prerequisites

1. **Docker & Docker Desktop**:
   - Ensure Docker Desktop is installed and running with WSL2 backend or Hyper-V.
2. **PostgreSQL (v14+)**:
   - Local installation on host (PostgreSQL 18 tested) or a containerized instance listening on port `5432`.
3. **Google Gemini API Key**:
   - Obtain from [Google AI Studio](https://aistudio.google.com/).
4. **Ollama (Local Fallback LLM)**:
   - Install [Ollama](https://ollama.ai/) on your host machine.
   - Pull the fallback model:
     ```bash
     ollama pull qwen2.5:1.5b
     ```
   - Ensure Ollama is running on port `11434` (default).

---

## 2. Step-by-Step Setup

### Step 1: Clone Repository & Prepare Environment

```bash
git clone https://github.com/rabiimallek/omniflow-ai.git
cd omniflow-ai
cp .env.example .env
```

Review `.env` to verify your target ports and host settings.

---

### Step 2: Database Initialization

Connect to your local PostgreSQL instance and execute the schema and sample data scripts:

```powershell
# Using psql on Windows
& "C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -d postgres -f database\schema.sql
& "C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -d postgres -f database\sample_data.sql
```

---

### Step 3: Launch Containers via Docker Compose

Start the n8n orchestrator and Gotenberg PDF service:

```bash
docker compose up -d
```

Verify containers are running:
```bash
docker ps
```
You should see:
- `omniflow-n8n` listening on `http://localhost:5678`
- `omniflow-gotenberg` listening on `http://localhost:3000`

---

### Step 4: Configure Credentials in n8n

Open your browser at `http://localhost:5678`.

1. **PostgreSQL Credentials**:
   - Navigate to **Credentials** -> **New Credential** -> **Postgres**.
   - Host: `host.docker.internal`
   - Port: `5432`
   - Database: `postgres`
   - User & Password: Your PostgreSQL username and password.
   - SSL: `disable` (for local development).
   - Name: `Postgres account`.

2. **Google Gemini (PaLM) Credentials**:
   - Navigate to **Credentials** -> **New Credential** -> **Google Gemini(PaLM) Api**.
   - API Key: Insert your Google AI Studio API key.
   - Name: `Google Gemini(PaLM) Api account`.

3. **Ollama Credentials (Local Fallback)**:
   - Navigate to **Credentials** -> **New Credential** -> **Ollama**.
   - Base URL: `http://host.docker.internal:11434`
   - Name: `Ollama account`.

---

### Step 5: Import and Run the Workflow

1. In n8n, navigate to **Workflows** -> click **Add Workflow** -> three dots `...` -> **Import from File**.
2. Select `workflows/monthly-business-reporting.json`.
3. Verify that the nodes reference your newly created credentials.
4. Click **Execute workflow**.
5. Once complete, check the `./reports` directory on your host to view the generated PDF report (`Northstar_Management_Report_2026-10.pdf`).
6. Query `automation_execution_logs` in PostgreSQL to view the audit log entry.
