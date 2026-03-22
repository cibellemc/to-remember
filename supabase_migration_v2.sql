-- Updated RPC to handle history merge and flexible linking flows

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
    v_source_patient_id UUID;
    v_target_patient_id UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'message', 'Não autenticado');
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

    v_target_patient_id := v_code_record.patient_id;

    -- Pegar o papel do usuário
    SELECT (raw_user_meta_data->>'role') INTO v_user_role 
    FROM auth.users 
    WHERE id = v_user_id;

    IF v_user_role IS NULL THEN
        SELECT role INTO v_user_role FROM public.profiles WHERE id = v_user_id;
    END IF;

    -- Lógica baseada no papel
    IF v_user_role = 'patient' THEN
        -- O paciente está vinculando ou recuperando conta
        -- 1. Identificar o patient_id atual deste usuário (anonimo)
        SELECT id INTO v_source_patient_id 
        FROM public.patients 
        WHERE auth_id = v_user_id 
        LIMIT 1;

        -- 2. Se existe um paciente diferente, mesclar os dados
        IF v_source_patient_id IS NOT NULL AND v_source_patient_id <> v_target_patient_id THEN
            -- Mover sessões de jogo
            UPDATE public.game_sessions 
            SET patient_id = v_target_patient_id 
            WHERE patient_id = v_source_patient_id;

            -- Mover timeline
            UPDATE public.patient_timeline 
            SET patient_id = v_target_patient_id 
            WHERE patient_id = v_source_patient_id;

            -- Mover outros cuidadores (se houver) para o novo perfil
            INSERT INTO public.patient_caregivers (patient_id, caregiver_id, added_at, relationship)
            SELECT v_target_patient_id, caregiver_id, added_at, relationship 
            FROM public.patient_caregivers 
            WHERE patient_id = v_source_patient_id
            ON CONFLICT (patient_id, caregiver_id) DO NOTHING;

            -- Marcar o antigo como inativo ou deletar (opcional, vou apenas remover o auth_id por enquanto ou manter como histórico)
            UPDATE public.patients 
            SET auth_id = NULL 
            WHERE id = v_source_patient_id;
        END IF;

        -- 3. Vincular o usuário ao novo registro master
        UPDATE public.patients 
        SET auth_id = v_user_id 
        WHERE id = v_target_patient_id;
          
        v_result := jsonb_build_object(
            'success', true, 
            'type', 'patient_linked', 
            'patient_id', v_target_patient_id,
            'message', 'Conta vinculada com sucesso!'
        );
    
    ELSIF v_user_role = 'caregiver' OR v_user_role = 'family' OR v_user_role = 'professional' THEN
        -- Cuidador vinculando-se (Fluxo 1: Paciente -> Cuidador)
        -- Inserimos o vínculo se não existir
        INSERT INTO public.patient_caregivers (patient_id, caregiver_id)
        VALUES (v_target_patient_id, v_user_id)
        ON CONFLICT (patient_id, caregiver_id) DO NOTHING;
        
        v_result := jsonb_build_object(
            'success', true, 
            'type', 'caregiver_linked', 
            'patient_id', v_target_patient_id,
            'message', 'Vínculo com paciente estabelecido!'
        );
    
    ELSE
        RETURN jsonb_build_object('success', false, 'message', 'Papel de usuário desconhecido');
    END IF;

    -- Marcar código como usado
    UPDATE public.connection_codes 
    SET used_at = now() 
    WHERE code = v_code_record.code;

    RETURN v_result;
END;
$$;
