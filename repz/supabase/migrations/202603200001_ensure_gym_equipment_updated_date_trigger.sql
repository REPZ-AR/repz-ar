-- Ensure the gym_equipment updated_date trigger exists and is correctly wired.

create or replace function public.set_gym_equipment_updated_date()
returns trigger
language plpgsql
as $$
begin
  new.updated_date = now();
  return new;
end;
$$;

do $$
begin
  if to_regclass('public.gym_equipment') is not null then
    execute 'drop trigger if exists gym_equipment_set_updated_date on public.gym_equipment';
    execute '
      create trigger gym_equipment_set_updated_date
      before update on public.gym_equipment
      for each row
      execute function public.set_gym_equipment_updated_date()
    ';
  end if;
end;
$$;

