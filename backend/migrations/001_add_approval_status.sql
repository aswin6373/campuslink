-- ============================================================
-- Migration 001: Account approval workflow
-- Run this ONCE in the Supabase SQL Editor (existing databases).
-- Fresh installs already get this from schema.sql.
-- ============================================================

alter table users    add column if not exists status text not null default 'approved';
alter table students add column if not exists status text not null default 'approved';
alter table teachers add column if not exists status text not null default 'approved';

-- Existing rows stay approved (they were created by trusted flows).
