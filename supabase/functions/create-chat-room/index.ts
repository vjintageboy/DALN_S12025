// Supabase Edge Function: create-chat-room
// Creates a chat room and inserts both participants using service role key (bypasses RLS).

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.4';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-supabase-project-id',
};

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    const body = await req.json();
    const { appointmentId, userId, expertId } = body as {
      appointmentId: string;
      userId: string;
      expertId: string;
    };

    if (!appointmentId || !userId || !expertId) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: appointmentId, userId, expertId' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Check if room already exists for this appointment
    const { data: existingRoom } = await supabaseAdmin
      .from('chat_rooms')
      .select('id')
      .eq('appointment_id', appointmentId)
      .maybeSingle();

    let roomId: string;

    if (existingRoom) {
      roomId = existingRoom.id;
    } else {
      // Create new chat room
      const { data: newRoom, error: roomError } = await supabaseAdmin
        .from('chat_rooms')
        .insert({
          appointment_id: appointmentId,
          status: 'active',
          room_type: 'appointment',
          updated_at: new Date().toISOString(),
        })
        .select('id')
        .single();

      if (roomError || !newRoom) {
        throw new Error(`Failed to create chat room: ${roomError?.message ?? 'unknown error'}`);
      }

      roomId = newRoom.id;
    }

    // Upsert both participants (service role bypasses RLS)
    const participantEntries = [
      { room_id: roomId, user_id: userId },
      { room_id: roomId, user_id: expertId },
    ];

    const { error: participantError } = await supabaseAdmin
      .from('chat_participants')
      .upsert(participantEntries, { onConflict: 'room_id,user_id' });

    if (participantError) {
      throw new Error(`Failed to insert participants: ${participantError.message}`);
    }

    // Check if system message exists
    const { data: existingMsg } = await supabaseAdmin
      .from('messages')
      .select('id')
      .eq('room_id', roomId)
      .eq('type', 'system')
      .limit(1);

    if (!existingMsg || existingMsg.length === 0) {
      // Insert system message
      await supabaseAdmin.from('messages').insert({
        room_id: roomId,
        sender_id: userId,
        content:
          'System: Bạn đã được kết nối với Expert cho buổi tư vấn. Hãy bắt đầu trò chuyện nếu bạn muốn trao đổi trước buổi hẹn.',
        type: 'system',
        created_at: new Date().toISOString(),
      });
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
