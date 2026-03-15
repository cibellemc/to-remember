-- Migração para adicionar campos de paciente e relacionamento
-- Execute este SQL no SQL Editor do seu Dashboard Supabase

-- Adicionar colunas faltantes na tabela 'patients'
ALTER TABLE patients ADD COLUMN IF NOT EXISTS birthdate DATE;
ALTER TABLE patients ADD COLUMN IF NOT EXISTS stage TEXT;

-- Adicionar coluna 'relationship' na tabela 'patient_caregivers'
-- Isso permite descrever o vínculo (ex: "filha", "vizinha")
ALTER TABLE patient_caregivers ADD COLUMN IF NOT EXISTS relationship TEXT;
