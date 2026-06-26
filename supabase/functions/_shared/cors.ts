// CORS headers for Supabase Edge Functions.
// In production, restrict origins to known domains via Supabase project settings.
export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};
