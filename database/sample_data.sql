-- ==============================================================================
-- OmniFlow AI - Demonstration & Sample Data
-- Company: Northstar Business Services
-- Currency: TND (Tunisian Dinar)
-- Note: All financial and operational records are fictional demonstration data.
-- ==============================================================================

-- Seed Business Metrics
INSERT INTO monthly_business_metrics (
    company_name,
    reporting_month,
    currency,
    total_revenue,
    total_expenses,
    total_invoices,
    overdue_invoices,
    completed_projects,
    active_projects
)
VALUES
    -- Primary reporting period used in demonstration
    ('Northstar Business Services', '2026-10', 'TND', 125000.00, 78000.00, 150, 12, 18, 7),
    -- Historical periods for trend baseline and testing
    ('Northstar Business Services', '2026-09', 'TND', 118000.00, 75000.00, 142, 15, 16, 8),
    ('Northstar Business Services', '2026-08', 'TND', 110000.00, 72000.00, 135, 10, 14, 9)
ON CONFLICT (company_name, reporting_month) 
DO UPDATE SET
    total_revenue = EXCLUDED.total_revenue,
    total_expenses = EXCLUDED.total_expenses,
    total_invoices = EXCLUDED.total_invoices,
    overdue_invoices = EXCLUDED.overdue_invoices,
    completed_projects = EXCLUDED.completed_projects,
    active_projects = EXCLUDED.active_projects,
    currency = EXCLUDED.currency;

-- Seed Sample Execution Log (historical demonstration baseline)
INSERT INTO automation_execution_logs (
    workflow_name,
    company_name,
    reporting_month,
    execution_status,
    report_filename,
    error_message,
    execution_started_at,
    execution_finished_at
)
VALUES (
    '01 - Monthly Business Reporting',
    ('Northstar Business Services'),
    '2026-09',
    'SUCCESS',
    'Northstar_Management_Report_2026-09.pdf',
    NULL,
    CURRENT_TIMESTAMP - INTERVAL '30 days' - INTERVAL '5 minutes',
    CURRENT_TIMESTAMP - INTERVAL '30 days'
);
