  SELECT cs.id AS space_id
  FROM couple_spaces cs
  JOIN couple_memberships cm ON cm.couple_space_id = cs.id
  WHERE cm.profile_id = auth.uid()
  AND cm.status = 'active'
  AND cs.status = 'active'
  LIMIT 1;