-- ==============================================================================
-- OmniFlow AI - Database Schema Definition
-- Target Engine: PostgreSQL 14+ (Verified on PostgreSQL 18)
-- Description: Core tables for business metrics extraction and workflow execution audit logging.
-- ==============================================================================

-- 1. Business Metrics Storage Table
CREATE TABLE IF NOT EXISTS monthly_business_metrics (
    id SERIAL PRIMARY KEY,
    company_name VARCHAR(255) NOT NULL,
    reporting_month VARCHAR(7) NOT NULL, -- Format: 'YYYY-MM' (e.g., '2026-10')
    currency VARCHAR(10) NOT NULL DEFAULT 'TND',
    total_revenue NUMERIC(15, 2) NOT NULL,
    total_expenses NUMERIC(15, 2) NOT NULL,
    total_invoices INTEGER NOT NULL,
    overdue_invoices INTEGER NOT NULL,
    completed_projects INTEGER NOT NULL,
    active_projects INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Business logic constraints
    CONSTRAINT chk_positive_revenue CHECK (total_revenue >= 0),
    CONSTRAINT chk_positive_expenses CHECK (total_expenses >= 0),
    CONSTRAINT chk_invoices_valid CHECK (total_invoices >= 0 AND overdue_invoices >= 0 AND overdue_invoices <= total_invoices),
    CONSTRAINT chk_projects_valid CHECK (completed_projects >= 0 AND active_projects >= 0),
    CONSTRAINT uq_company_month UNIQUE (company_name, reporting_month)
);

-- Indexing for high-frequency queries
CREATE INDEX IF NOT EXISTS idx_mbm_reporting_month ON monthly_business_metrics(reporting_month);
CREATE INDEX IF NOT EXISTS idx_mbm_company ON monthly_business_metrics(company_name);

-- 2. Automation Execution Logs Table
CREATE TABLE IF NOT EXISTS automation_execution_logs (
    id SERIAL PRIMARY KEY,
    workflow_name VARCHAR(255) NOT NULL,
    company_name VARCHAR(255),
    reporting_month VARCHAR(7),
    execution_status VARCHAR(50) NOT NULL, -- 'SUCCESS', 'FAILED', 'VALIDATION_ERROR'
    report_filename VARCHAR(255),
    error_message TEXT,
    execution_started_at TIMESTAMP WITH TIME ZONE,
    execution_finished_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexing for audit trail and observability
CREATE INDEX IF NOT EXISTS idx_ael_reporting_month ON automation_execution_logs(reporting_month);
CREATE INDEX IF NOT EXISTS idx_ael_status ON automation_execution_logs(execution_status);
CREATE INDEX IF NOT EXISTS idx_ael_finished_at ON automation_execution_logs(execution_finished_at DESC);
