-- View tracking for the public CV page (ahadwen.github.io/Public-CV).
-- Reuses the Apryl case study's apryl_visit_log table in the same Supabase project, adding a
-- `page` column so CV views stay separate from Apryl visits. Existing rows become 'apryl'.
-- As with Apryl, only the time and the browser's time zone are stored. No IP address.

alter table public.apryl_visit_log add column if not exists page text not null default 'apryl';

-- Called by the CV page: 'cv' when the page is opened, 'cv_download' when the PDF is downloaded.
-- Any other page value is ignored, so the public key can't be used to write arbitrary rows.
create or replace function public.log_page_visit(p_page text, p_time_zone text default null)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if p_page not in ('cv', 'cv_download') then
    return;
  end if;

  insert into public.apryl_visit_log (page, time_zone)
  values (p_page, case when p_time_zone ~ '^[A-Za-z_]+(/[A-Za-z0-9_+-]+){0,2}$' and length(p_time_zone) <= 64 then p_time_zone end);
end;
$$;

revoke all on function public.log_page_visit(text, text) from public;
grant execute on function public.log_page_visit(text, text) to anon, authenticated;

-- To see CV views:
-- select at, page, time_zone from public.apryl_visit_log where page like 'cv%' order by at desc;
