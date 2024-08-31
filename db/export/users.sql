SELECT wiki_update_count as wiki_page_version_count,
       artist_update_count as artist_version_count,
       pool_update_count as pool_version_count,
       forum_post_count,
       comment_count,
       favorite_count,
       (SELECT COUNT(*) FROM user_feedbacks WHERE category = 'positive' AND is_deleted = false AND user_id = users.id) as positive_feedback_count,
       (SELECT COUNT(*) FROM user_feedbacks WHERE category = 'neutral' AND is_deleted = false AND user_id = users.id) as neutral_feedback_count,
       (SELECT COUNT(*) FROM user_feedbacks WHERE category = 'negative' AND is_deleted = false AND user_id = users.id) as negative_feedback_count,
       profile_about,
       profile_artinfo,
       id,
       created_at,
       name,
       level,
       base_upload_limit,
       post_count as post_upload_count,
       post_update_count,
       note_update_count,
       avatar_id,
       (bit_prefs::bit(64) & (1 << 8)::bit(64) = (1 << 8)::bit(64)) as can_approve_posts,
       (bit_prefs::bit(64) & (1 << 9)::bit(64) = (1 << 9)::bit(64)) as unrestricted_uploads,
       (bit_prefs::bit(64) & (1 << 14)::bit(64) = (1 << 14)::bit(64)) as disable_user_dmails,
       (bit_prefs::bit(64) & (1 << 22)::bit(64) = (1 << 22)::bit(64)) as can_manage_aibur
FROM public.users ORDER BY id;

