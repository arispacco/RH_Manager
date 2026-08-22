-- Ensure pgcrypto extension is enabled for HMAC
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Add a qr_secret to qr_configs if it doesn't exist
ALTER TABLE public.qr_configs ADD COLUMN IF NOT EXISTS qr_secret text DEFAULT encode(gen_random_bytes(16), 'hex') NOT NULL;

-- Update clock_in function to validate the signed token
CREATE OR REPLACE FUNCTION public.clock_in(
    scanned_token text,
    user_lat double precision,
    user_lng double precision
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id uuid;
    v_company_id uuid;
    v_config record;
    v_distance double precision;
    v_open_log_id uuid;
    v_result jsonb;
    v_token_parts text[];
    v_token_company_id text;
    v_token_timestamp text;
    v_token_signature text;
    v_expected_signature text;
    v_time_diff double precision;
BEGIN
    -- 1. Get the current user and their company
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT company_id INTO v_company_id FROM public.profiles WHERE id = v_user_id;
    IF v_company_id IS NULL THEN
        RAISE EXCEPTION 'User profile or company not found';
    END IF;

    -- 2. Check for an already open attendance log (no double clock-in)
    SELECT id INTO v_open_log_id 
    FROM public.attendance_logs 
    WHERE user_id = v_user_id AND clock_out IS NULL 
    ORDER BY clock_in DESC LIMIT 1;

    IF v_open_log_id IS NOT NULL THEN
        RAISE EXCEPTION 'Already clocked in. Please clock out first.';
    END IF;

    -- 3. Geofencing Validation
    SELECT * INTO v_config FROM public.qr_configs WHERE company_id = v_company_id;
    
    IF v_config IS NOT NULL AND v_config.office_lat IS NOT NULL AND v_config.office_lng IS NOT NULL THEN
        IF user_lat IS NULL OR user_lng IS NULL THEN
            RAISE EXCEPTION 'Location is required for clocking in at this company.';
        END IF;

        v_distance := public.calculate_distance(user_lat, user_lng, v_config.office_lat, v_config.office_lng);

        IF v_distance > v_config.radius_meters THEN
            RAISE EXCEPTION 'Geofence restriction: You are % meters away. Maximum allowed is % meters.', round(v_distance::numeric, 1), v_config.radius_meters;
        END IF;
    END IF;

    -- 4. Secure QR Token Validation (HMAC-SHA256 TOTP)
    IF scanned_token IS NULL OR scanned_token = '' THEN
        RAISE EXCEPTION 'Invalid or missing QR token';
    END IF;

    -- Expected format: company_id:timestamp_ms:signature
    v_token_parts := string_to_array(scanned_token, ':');
    IF array_length(v_token_parts, 1) != 3 THEN
        RAISE EXCEPTION 'Invalid QR code format';
    END IF;

    v_token_company_id := v_token_parts[1];
    v_token_timestamp := v_token_parts[2];
    v_token_signature := v_token_parts[3];

    -- Verify company matches
    IF v_token_company_id != v_company_id::text THEN
        RAISE EXCEPTION 'This QR code does not belong to your company';
    END IF;

    -- Verify time
    -- timestamp is in milliseconds. Compare with current UTC time.
    v_time_diff := extract(epoch from now()) * 1000 - v_token_timestamp::numeric;
    
    -- Allow maximum 45 seconds delay to account for Kiosk refresh time (15s) + scan time + network latency
    IF v_time_diff < -5000 OR v_time_diff > 45000 THEN
        RAISE EXCEPTION 'QR code has expired. Please scan the latest one on the kiosk screen.';
    END IF;

    -- Verify signature (HMAC-SHA256)
    v_expected_signature := encode(hmac(v_token_company_id || ':' || v_token_timestamp, v_config.qr_secret, 'sha256'), 'hex');
    
    IF v_token_signature != v_expected_signature THEN
        RAISE EXCEPTION 'Invalid or forged QR code signature';
    END IF;

    -- 5. Insert the attendance log
    INSERT INTO public.attendance_logs (
        user_id, company_id, clock_in, clock_in_lat, clock_in_lng, status, qr_token
    ) VALUES (
        v_user_id, v_company_id, now(), user_lat, user_lng, 'on_time', scanned_token
    ) RETURNING id INTO v_open_log_id;

    v_result := jsonb_build_object(
        'success', true,
        'message', 'Clocked in successfully',
        'attendance_id', v_open_log_id
    );

    RETURN v_result;
END;
$$;
