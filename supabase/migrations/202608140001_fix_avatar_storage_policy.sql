-- Accept authenticated avatar uploads based on either the JWT owner or the user's folder.
-- Storage assigns owner_id from the authenticated JWT before evaluating INSERT policies.

drop policy if exists "Users can upload their own avatars" on storage.objects;
create policy "Users can upload their own avatars"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'avatars'
  and (
    owner_id = (select auth.uid()::text)
    or lower((storage.foldername(name))[1]) = lower((select auth.uid()::text))
  )
);

drop policy if exists "Users can update their own avatars" on storage.objects;
create policy "Users can update their own avatars"
on storage.objects for update
to authenticated
using (
  bucket_id = 'avatars'
  and owner_id = (select auth.uid()::text)
)
with check (
  bucket_id = 'avatars'
  and owner_id = (select auth.uid()::text)
);
