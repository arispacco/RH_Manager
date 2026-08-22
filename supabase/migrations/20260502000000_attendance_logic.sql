-- Distance calculation function (Haversine formula in kilometers, converted to meters)
CREATE OR REPLACE FUNCTION public.calculate_distance(lat1 double precision, lon1 double precision, lat2 double precision, lon2 double precision)
RETURNS double precision
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
    radius double precision := 6371000; -- Earth's radius in meters
    dlat double precision;
    dlon double precision;
    a double precision;
    c double precision;
BEGIN
    -- Convert degrees to radians
    dlat := radians(lat2 - lat1);
    dlon := radians(lon2 - lon1);
    lat1 := radians(lat1);
    lat2 := radians(lat2);

    -- Haversine formula
    a := sin(dlat/2) * sin(dlat/2) + cos(lat1) * cos(lat2) * sin(dlon/2) * sin(dlon/2);
    c := 2 * asin(sqrt(a));

    RETURN radius * c;
END;
$$;

-- Clock In Function
CREATE OR REPLACE FUNCTION public.clock_in(
    scanned_token text,
    user_lat double precision,
    user_lng double precision
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER -- Runs with elevated privileges to check configs, but we verify the user
SET search_path = public
AS $$
DECLARE
    v_user_id uuid;
    v_company_id uuid;
    v_config record;
    v_distance double precision;
    v_open_log_id uuid;
    v_result jsonb;
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
    -- Get the company's QR and Geofence config
    SELECT * INTO v_config FROM public.qr_configs WHERE company_id = v_company_id;
    
    IF v_config IS NOT NULL AND v_config.office_lat IS NOT NULL AND v_config.office_lng IS NOT NULL THEN
        IF user_lat IS NULL OR user_lng IS NULL THEN
            RAISE EXCEPTION 'Location is required for clocking in at this company.';
        END IF;

        -- Calculate distance in meters
        v_distance := public.calculate_distance(user_lat, user_lng, v_config.office_lat, v_config.office_lng);

        IF v_distance > v_config.radius_meters THEN
            RAISE EXCEPTION 'Geofence restriction: You are % meters away. Maximum allowed is % meters.', round(v_distance::numeric, 1), v_config.radius_meters;
        END IF;
    END IF;

    -- 4. QR Token Validation
    IF scanned_token IS NULL OR scanned_token = '' THEN
        RAISE EXCEPTION 'Invalid or missing QR token';
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

-- Clock Out Function
CREATE OR REPLACE FUNCTION public.clock_out()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id uuid;
    v_open_log_id uuid;
    v_result jsonb;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Find the active clock-in
    SELECT id INTO v_open_log_id 
    FROM public.attendance_logs 
    WHERE user_id = v_user_id AND clock_out IS NULL 
    ORDER BY clock_in DESC LIMIT 1;

    IF v_open_log_id IS NULL THEN
        RAISE EXCEPTION 'No active clock-in found. Cannot clock out.';
    END IF;

    -- Update the record
    UPDATE public.attendance_logs 
    SET clock_out = now() 
    WHERE id = v_open_log_id;

    v_result := jsonb_build_object(
        'success', true,
        'message', 'Clocked out successfully',
        'attendance_id', v_open_log_id
    );

    RETURN v_result;
END;
$$;
