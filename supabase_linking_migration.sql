-- Migração para Fluxo de Vinculação de Paciente
-- Este SQL prepara o banco para o novo fluxo onde cuidadores e pacientes podem se vincular via código.

-- 1. Tabela de códigos de conexão (caso não exista ou precise ser atualizada)
CREATE TABLE IF NOT EXISTS public.connection_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT UNIQUE NOT NULL,
    patient_id UUID REFERENCES public.patients(id) ON DELETE CASCADE,
    created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + interval '24 hours'),
    used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Habilitar RLS
ALTER TABLE public.connection_codes ENABLE ROW LEVEL SECURITY;

-- Políticas de RLS para connection_codes
-- Usuários podem ver códigos que eles criaram
CREATE POLICY "Users can view codes they created" 
ON public.connection_codes FOR SELECT 
USING (auth.uid() = created_by);

-- Usuários autenticados podem inserir códigos
CREATE POLICY "Authenticated users can insert codes" 
ON public.connection_codes FOR INSERT 
WITH CHECK (auth.uid() IS NOT NULL);

-- 2. Função para consumir o código
CREATE OR REPLACE FUNCTION public.consume_connection_code(p_code TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_code_record RECORD;
    v_user_id UUID;
    v_user_role TEXT;
    v_result JSONB;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Não autenticado';
    END IF;

    -- Buscar o código (case insensitive)
    SELECT * INTO v_code_record 
    FROM public.connection_codes 
    WHERE upper(code) = upper(p_code) 
      AND used_at IS NULL 
      AND expires_at > now();

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'message', 'Código inválido ou expirado');
    END IF;

    -- Pegar o papel do usuário (do metadado do auth ou profile)
    SELECT (raw_user_meta_data->>'role') INTO v_user_role 
    FROM auth.users 
    WHERE id = v_user_id;

    -- Se não achou no meta_data, tenta no profiles
    IF v_user_role IS NULL THEN
        SELECT role INTO v_user_role FROM public.profiles WHERE id = v_user_id;
    END IF;

    -- Lógica baseada no papel
    IF v_user_role = 'patient' THEN
        -- O paciente está herdando o perfil criado pelo cuidador (ou se vinculando)
        -- Primeiro, vemos se esse paciente já não tem um registro 'master'
        -- Se o patient_id do código já tiver um auth_id, é um erro de segurança ou troca de conta
        
        UPDATE public.patients 
        SET auth_id = v_user_id 
        WHERE id = v_code_record.patient_id 
          AND (auth_id IS NULL OR auth_id = v_user_id);
          
        v_result := jsonb_build_object('success', true, 'type', 'patient_linked', 'patient_id', v_code_record.patient_id);
    
    ELSIF v_user_role = 'caregiver' OR v_user_role = 'family' OR v_user_role = 'professional' THEN
        -- O cuidador está se vinculando a um paciente existente
        INSERT INTO public.patient_caregivers (patient_id, caregiver_id)
        VALUES (v_code_record.patient_id, v_user_id)
        ON CONFLICT (patient_id, caregiver_id) DO NOTHING;
        
        v_result := jsonb_build_object('success', true, 'type', 'caregiver_linked', 'patient_id', v_code_record.patient_id);
    
    ELSE
        RAISE EXCEPTION 'Papel de usuário desconhecido: %', v_user_role;
    END IF;

    -- Marcar código como usado
    UPDATE public.connection_codes 
    SET used_at = now() 
    WHERE id = v_code_record.id;

    RETURN v_result;
END;
$$;
