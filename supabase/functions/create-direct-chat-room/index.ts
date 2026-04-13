// Supabase Edge Function: create-direct-chat-room
// Creates a direct chat room and inserts both participants using service role key (bypasses RLS).

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.4';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    const body = await req.json();
    const { userA, userB } = body as { userA: string; userB: string };

    if (!userA || !userB) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: userA, userB' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const participants = [userA, userB].sort();
    const directKey = `${participants[0]}:${participants[1]}`;

    // Check if room already exists
    const { data: existingRoom } = await supabaseAdmin
      .from('chat_rooms')
      .select('id')
      .eq('direct_key', directKey)
      .maybeSingle();

    if (existingRoom) {
      return new Response(
        JSON.stringify({ roomId: existingRoom.id }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Create new chat room
    const { data: newRoom, error: roomError } = await supabaseAdmin
      .from('chat_rooms')
      .insert({
        status: 'active',
        room_type: 'direct',
        direct_key: directKey,
        updated_at: new Date().toISOString(),
      })
      .select('id')
      .single();

    if (roomError || !newRoom) {
      throw new Error(`Failed to create chat room: ${roomError?.message ?? 'unknown error'}`);
    }

    const roomId = newRoom.id;

    // Upsert both participants
    const { error: participantError } = await supabaseAdmin
      .from('chat_participants')
      .upsert([
        { room_id: roomId, user_id: userA },
        { room_id: roomId, user_id: userB },
      ], { onConflict: 'room_id,user_id' });

    if (participantError) {
      throw new Error(`Failed to insert participants: ${participantError.message}`);
    }

    return new Response(
      JSON.stringify({ roomId }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
