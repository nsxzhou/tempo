// 构建时由 esbuild define 注入；本地开发 fallback 到 localhost。

declare const __SUPABASE_URL__: string | undefined;
declare const __SUPABASE_ANON_KEY__: string | undefined;
declare const __PAIRING_ENDPOINT__: string | undefined;
declare const __PLUGIN_VERSION__: string | undefined;

const LOCAL_SUPABASE_URL = 'http://127.0.0.1:54321';
const LOCAL_ANON_KEY =
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';

export const SUPABASE_URL =
  typeof __SUPABASE_URL__ !== 'undefined' && __SUPABASE_URL__
    ? __SUPABASE_URL__
    : LOCAL_SUPABASE_URL;

export const SUPABASE_ANON_KEY =
  typeof __SUPABASE_ANON_KEY__ !== 'undefined' && __SUPABASE_ANON_KEY__
    ? __SUPABASE_ANON_KEY__
    : LOCAL_ANON_KEY;

export const PAIRING_ENDPOINT =
  typeof __PAIRING_ENDPOINT__ !== 'undefined' && __PAIRING_ENDPOINT__
    ? __PAIRING_ENDPOINT__
    : `${SUPABASE_URL}/functions/v1/siyuan-pairing`;

export const PLUGIN_VERSION =
  typeof __PLUGIN_VERSION__ !== 'undefined' && __PLUGIN_VERSION__
    ? __PLUGIN_VERSION__
    : '0.1.0';
