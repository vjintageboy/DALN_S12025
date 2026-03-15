-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.ai_conversations (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  title character varying DEFAULT 'New conversation'::character varying,
  last_message_preview text,
  is_archived boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  CONSTRAINT ai_conversations_pkey PRIMARY KEY (id),
  CONSTRAINT ai_conversations_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.ai_messages (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  conversation_id uuid NOT NULL,
  user_id uuid NOT NULL,
  role character varying NOT NULL CHECK (role::text = ANY (ARRAY['user'::character varying, 'assistant'::character varying, 'system'::character varying]::text[])),
  content text NOT NULL,
  model_name character varying,
  metadata jsonb,
  prompt_tokens integer,
  completion_tokens integer,
  total_tokens integer,
  latency_ms integer,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  CONSTRAINT ai_messages_pkey PRIMARY KEY (id),
  CONSTRAINT ai_messages_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.ai_conversations(id),
  CONSTRAINT ai_messages_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.appointments (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  expert_id uuid,
  appointment_date timestamp with time zone NOT NULL,
  duration_minutes integer DEFAULT 60,
  call_type USER-DEFINED DEFAULT 'chat'::call_type,
  status USER-DEFINED DEFAULT 'pending'::appointment_status,
  payment_status character varying DEFAULT 'unpaid'::character varying,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  user_notes text,
  expert_base_price integer,
  payment_id character varying,
  payment_trans_id character varying,
  cancelled_at timestamp with time zone,
  cancelled_by uuid,
  cancellation_reason text,
  refund_status character varying DEFAULT 'none'::character varying,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  cancelled_role character varying,
  CONSTRAINT appointments_pkey PRIMARY KEY (id),
  CONSTRAINT appointments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id),
  CONSTRAINT appointments_expert_id_fkey FOREIGN KEY (expert_id) REFERENCES public.experts(id)
);
CREATE TABLE public.chat_participants (
  room_id uuid NOT NULL,
  user_id uuid NOT NULL,
  CONSTRAINT chat_participants_pkey PRIMARY KEY (room_id, user_id),
  CONSTRAINT chat_participants_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.chat_rooms(id),
  CONSTRAINT chat_participants_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.chat_rooms (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  last_message text,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  appointment_id uuid,
  status character varying DEFAULT 'active'::character varying,
  last_message_time timestamp with time zone,
  CONSTRAINT chat_rooms_pkey PRIMARY KEY (id)
);
CREATE TABLE public.expert_availability (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  expert_id uuid NOT NULL,
  day_of_week integer CHECK (day_of_week >= 0 AND day_of_week <= 6),
  start_time time without time zone NOT NULL,
  end_time time without time zone NOT NULL,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  CONSTRAINT expert_availability_pkey PRIMARY KEY (id),
  CONSTRAINT expert_availability_expert_id_fkey FOREIGN KEY (expert_id) REFERENCES public.experts(id)
);
CREATE TABLE public.experts (
  id uuid NOT NULL,
  bio text,
  specialization character varying,
  hourly_rate integer DEFAULT 0,
  rating numeric DEFAULT 0.0,
  is_approved boolean DEFAULT false,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  title character varying,
  total_reviews integer DEFAULT 0,
  years_experience integer DEFAULT 0,
  license_number character varying,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  license_url text,
  certificate_urls ARRAY,
  education character varying,
  university character varying,
  graduation_year integer,
  CONSTRAINT experts_pkey PRIMARY KEY (id),
  CONSTRAINT experts_id_fkey FOREIGN KEY (id) REFERENCES public.users(id)
);
CREATE TABLE public.meditations (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  title character varying NOT NULL,
  description text,
  category character varying,
  duration_minutes integer,
  audio_url text NOT NULL,
  thumbnail_url text,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  level character varying DEFAULT 'beginner'::character varying,
  rating numeric DEFAULT 0.0,
  total_reviews integer DEFAULT 0,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  CONSTRAINT meditations_pkey PRIMARY KEY (id)
);
CREATE TABLE public.messages (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  room_id uuid,
  sender_id uuid,
  content text NOT NULL,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  type character varying DEFAULT 'text'::character varying,
  is_pinned boolean DEFAULT false,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  CONSTRAINT messages_pkey PRIMARY KEY (id),
  CONSTRAINT messages_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.chat_rooms(id),
  CONSTRAINT messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(id)
);
CREATE TABLE public.mood_entries (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  mood_score integer CHECK (mood_score >= 1 AND mood_score <= 5),
  note text,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  emotion_factors ARRAY,
  tags ARRAY,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  CONSTRAINT mood_entries_pkey PRIMARY KEY (id),
  CONSTRAINT mood_entries_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.notifications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  title text NOT NULL,
  message text NOT NULL,
  type character varying,
  is_read boolean DEFAULT false,
  metadata jsonb,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT notifications_pkey PRIMARY KEY (id),
  CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.post_comments (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  post_id uuid,
  user_id uuid,
  content text NOT NULL,
  parent_comment_id uuid,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  is_anonymous boolean DEFAULT false,
  CONSTRAINT post_comments_pkey PRIMARY KEY (id),
  CONSTRAINT post_comments_parent_comment_id_fkey FOREIGN KEY (parent_comment_id) REFERENCES public.post_comments(id) ON DELETE CASCADE,
  CONSTRAINT post_comments_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id),
  CONSTRAINT post_comments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.post_likes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  post_id uuid,
  user_id uuid,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  CONSTRAINT post_likes_pkey PRIMARY KEY (id),
  CONSTRAINT post_likes_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id),
  CONSTRAINT post_likes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.posts (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  author_id uuid,
  title character varying NOT NULL,
  content text NOT NULL,
  image_url text,
  likes_count integer DEFAULT 0,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  category character varying DEFAULT 'community'::character varying,
  comment_count integer DEFAULT 0,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  is_anonymous boolean DEFAULT false,
  CONSTRAINT posts_pkey PRIMARY KEY (id),
  CONSTRAINT posts_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.users(id)
);
CREATE TABLE public.users (
  id uuid NOT NULL,
  email character varying NOT NULL UNIQUE,
  full_name character varying,
  avatar_url text,
  role USER-DEFINED DEFAULT 'user'::user_role,
  streak_count integer DEFAULT 0,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  date_of_birth timestamp with time zone,
  gender character varying,
  goals ARRAY,
  preferences jsonb,
  longest_streak integer DEFAULT 0,
  last_login timestamp with time zone,
  total_activities integer DEFAULT 0,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  CONSTRAINT users_pkey PRIMARY KEY (id),
  CONSTRAINT users_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);