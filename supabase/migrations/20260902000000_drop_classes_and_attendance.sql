-- Drop the dashboard/classes/report-card feature schema.
-- This is a rollback migration for the class and attendance tables that were
-- created for the removed dashboard, classes, and report card features.

DROP TABLE IF EXISTS public.attendance CASCADE;
DROP TABLE IF EXISTS public.classes CASCADE;
