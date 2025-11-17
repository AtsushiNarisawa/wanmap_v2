-- ====================================================================
-- Create trips table for trip planning feature
-- ====================================================================
-- Purpose: Allow users to group routes into trips (e.g., vacation plans)
-- ====================================================================

-- Create trips table
CREATE TABLE IF NOT EXISTS public.trips (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    destination VARCHAR(255),  -- Main destination (e.g., "箱根")
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    thumbnail_url TEXT,  -- Cover photo
    is_public BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT valid_date_range CHECK (end_date >= start_date)
);

-- Create trip_routes junction table (many-to-many)
CREATE TABLE IF NOT EXISTS public.trip_routes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
    route_id UUID NOT NULL REFERENCES public.routes(id) ON DELETE CASCADE,
    day_number INTEGER,  -- Which day of the trip (1, 2, 3, etc.)
    sequence_order INTEGER DEFAULT 0,  -- Order within the day
    notes TEXT,  -- Optional notes for this route
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Unique constraint: one route can only be added once per trip
    CONSTRAINT unique_trip_route UNIQUE(trip_id, route_id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_trips_user_id ON public.trips(user_id);
CREATE INDEX IF NOT EXISTS idx_trips_start_date ON public.trips(start_date);
CREATE INDEX IF NOT EXISTS idx_trips_is_public ON public.trips(is_public) WHERE is_public = true;
CREATE INDEX IF NOT EXISTS idx_trip_routes_trip_id ON public.trip_routes(trip_id);
CREATE INDEX IF NOT EXISTS idx_trip_routes_route_id ON public.trip_routes(route_id);

-- Enable Row Level Security
ALTER TABLE public.trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trip_routes ENABLE ROW LEVEL SECURITY;

-- RLS Policies for trips
-- Users can view their own trips
CREATE POLICY "Users can view own trips"
    ON public.trips FOR SELECT
    USING (auth.uid() = user_id);

-- Users can view public trips
CREATE POLICY "Users can view public trips"
    ON public.trips FOR SELECT
    USING (is_public = true);

-- Users can insert their own trips
CREATE POLICY "Users can insert own trips"
    ON public.trips FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own trips
CREATE POLICY "Users can update own trips"
    ON public.trips FOR UPDATE
    USING (auth.uid() = user_id);

-- Users can delete their own trips
CREATE POLICY "Users can delete own trips"
    ON public.trips FOR DELETE
    USING (auth.uid() = user_id);

-- RLS Policies for trip_routes
-- Users can view trip_routes for their own trips
CREATE POLICY "Users can view own trip routes"
    ON public.trip_routes FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.trips
            WHERE trips.id = trip_routes.trip_id
            AND trips.user_id = auth.uid()
        )
    );

-- Users can view trip_routes for public trips
CREATE POLICY "Users can view public trip routes"
    ON public.trip_routes FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.trips
            WHERE trips.id = trip_routes.trip_id
            AND trips.is_public = true
        )
    );

-- Users can insert trip_routes for their own trips
CREATE POLICY "Users can insert own trip routes"
    ON public.trip_routes FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.trips
            WHERE trips.id = trip_routes.trip_id
            AND trips.user_id = auth.uid()
        )
    );

-- Users can update trip_routes for their own trips
CREATE POLICY "Users can update own trip routes"
    ON public.trip_routes FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.trips
            WHERE trips.id = trip_routes.trip_id
            AND trips.user_id = auth.uid()
        )
    );

-- Users can delete trip_routes for their own trips
CREATE POLICY "Users can delete own trip routes"
    ON public.trip_routes FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.trips
            WHERE trips.id = trip_routes.trip_id
            AND trips.user_id = auth.uid()
        )
    );

-- Create updated_at trigger for trips
CREATE OR REPLACE FUNCTION update_trips_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_trips_updated_at
    BEFORE UPDATE ON public.trips
    FOR EACH ROW
    EXECUTE FUNCTION update_trips_updated_at();

-- Add comments for documentation
COMMENT ON TABLE public.trips IS 'Trip planning - group multiple routes into trips';
COMMENT ON TABLE public.trip_routes IS 'Junction table linking trips and routes';
COMMENT ON COLUMN public.trips.day_number IS 'Which day of the trip (optional)';
COMMENT ON COLUMN public.trip_routes.sequence_order IS 'Order of routes within a day';

-- ====================================================================
-- Sample data (optional - for testing)
-- ====================================================================
-- INSERT INTO public.trips (user_id, title, description, destination, start_date, end_date, is_public)
-- VALUES (
--     (SELECT id FROM auth.users LIMIT 1),
--     '箱根3日間の旅',
--     '愛犬と一緒に箱根を満喫',
--     '箱根',
--     '2025-12-01',
--     '2025-12-03',
--     true
-- );
-- ====================================================================
