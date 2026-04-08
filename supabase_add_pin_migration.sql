-- Migration to add security PIN to user profiles
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS security_pin TEXT;

-- Function to verify security PIN securely
CREATE OR REPLACE FUNCTION public.verify_security_pin(p_pin TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_stored_pin TEXT;
BEGIN
    SELECT security_pin INTO v_stored_pin
    FROM public.profiles
    WHERE id = auth.uid();
    
    RETURN v_stored_pin = p_pin;
END;
$$;
