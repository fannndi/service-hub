// CORS headers for Supabase Edge Functions.
const ALLOWED_ORIGIN = Deno.env.get('CORS_ORIGIN') || 'https://eboplbemgtvmviwhdlfa.supabase.co';
export const corsHeaders = {
  'Access-Control-Allow-Origin': ALLOWED_ORIGIN,
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};