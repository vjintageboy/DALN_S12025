-- Threaded comments support for posts
-- Run in Supabase SQL Editor

-- 1) Add self-reference column for replies
ALTER TABLE public.post_comments
ADD COLUMN IF NOT EXISTS parent_comment_id uuid
REFERENCES public.post_comments(id)
ON DELETE CASCADE;

-- 2) Helpful indexes
CREATE INDEX IF NOT EXISTS idx_post_comments_parent
ON public.post_comments(parent_comment_id);

CREATE INDEX IF NOT EXISTS idx_post_comments_post
ON public.post_comments(post_id);

-- 3) Ensure insert policy allows authenticated user comments/replies
ALTER TABLE public.post_comments ENABLE ROW LEVEL SECURITY;

-- Read comments: allow authenticated users
DO $$ BEGIN
  CREATE POLICY post_comments_select_auth ON public.post_comments
    FOR SELECT
    USING (auth.uid() IS NOT NULL);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Insert comments/replies:
-- - normal comment: user_id = auth.uid()
-- - anonymous comment: user_id IS NULL AND is_anonymous = true (still requires auth)
-- - if reply, parent comment must belong to same post
DO $$ BEGIN
  CREATE POLICY post_comments_insert_own ON public.post_comments
    FOR INSERT
    WITH CHECK (
      auth.uid() IS NOT NULL
      AND (
        user_id = auth.uid()
        OR (is_anonymous = true AND user_id IS NULL)
      )
      AND (
        parent_comment_id IS NULL
        OR EXISTS (
          SELECT 1
          FROM public.post_comments parent
          WHERE parent.id = parent_comment_id
            AND parent.post_id = post_id
        )
      )
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Update: only owner can edit comment content/reply links
DO $$ BEGIN
  CREATE POLICY post_comments_update_own ON public.post_comments
    FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (
      user_id = auth.uid()
      AND (
        parent_comment_id IS NULL
        OR EXISTS (
          SELECT 1
          FROM public.post_comments parent
          WHERE parent.id = parent_comment_id
            AND parent.post_id = post_id
        )
      )
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Delete: only owner can delete
DO $$ BEGIN
  CREATE POLICY post_comments_delete_own ON public.post_comments
    FOR DELETE
    USING (user_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
