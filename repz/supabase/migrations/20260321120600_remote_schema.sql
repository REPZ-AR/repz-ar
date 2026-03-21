drop extension if exists "pg_net";

drop trigger if exists "workout_plans_set_updated_at" on "public"."workout_plans";

drop policy "Users can delete own workout plan exercises" on "public"."workout_plan_exercises";

drop policy "Users can insert own workout plan exercises" on "public"."workout_plan_exercises";

drop policy "Users can read own workout plan exercises" on "public"."workout_plan_exercises";

drop policy "Users can update own workout plan exercises" on "public"."workout_plan_exercises";

drop policy "Users can delete own workout plan sets" on "public"."workout_plan_sets";

drop policy "Users can insert own workout plan sets" on "public"."workout_plan_sets";

drop policy "Users can read own workout plan sets" on "public"."workout_plan_sets";

drop policy "Users can update own workout plan sets" on "public"."workout_plan_sets";

drop policy "Users can delete own workout plans" on "public"."workout_plans";

drop policy "Users can insert own workout plans" on "public"."workout_plans";

drop policy "Users can read own workout plans" on "public"."workout_plans";

drop policy "Users can update own workout plans" on "public"."workout_plans";

revoke delete on table "public"."workout_plan_exercises" from "anon";

revoke insert on table "public"."workout_plan_exercises" from "anon";

revoke references on table "public"."workout_plan_exercises" from "anon";

revoke select on table "public"."workout_plan_exercises" from "anon";

revoke trigger on table "public"."workout_plan_exercises" from "anon";

revoke truncate on table "public"."workout_plan_exercises" from "anon";

revoke update on table "public"."workout_plan_exercises" from "anon";

revoke delete on table "public"."workout_plan_exercises" from "authenticated";

revoke insert on table "public"."workout_plan_exercises" from "authenticated";

revoke references on table "public"."workout_plan_exercises" from "authenticated";

revoke select on table "public"."workout_plan_exercises" from "authenticated";

revoke trigger on table "public"."workout_plan_exercises" from "authenticated";

revoke truncate on table "public"."workout_plan_exercises" from "authenticated";

revoke update on table "public"."workout_plan_exercises" from "authenticated";

revoke delete on table "public"."workout_plan_exercises" from "service_role";

revoke insert on table "public"."workout_plan_exercises" from "service_role";

revoke references on table "public"."workout_plan_exercises" from "service_role";

revoke select on table "public"."workout_plan_exercises" from "service_role";

revoke trigger on table "public"."workout_plan_exercises" from "service_role";

revoke truncate on table "public"."workout_plan_exercises" from "service_role";

revoke update on table "public"."workout_plan_exercises" from "service_role";

revoke delete on table "public"."workout_plan_sets" from "anon";

revoke insert on table "public"."workout_plan_sets" from "anon";

revoke references on table "public"."workout_plan_sets" from "anon";

revoke select on table "public"."workout_plan_sets" from "anon";

revoke trigger on table "public"."workout_plan_sets" from "anon";

revoke truncate on table "public"."workout_plan_sets" from "anon";

revoke update on table "public"."workout_plan_sets" from "anon";

revoke delete on table "public"."workout_plan_sets" from "authenticated";

revoke insert on table "public"."workout_plan_sets" from "authenticated";

revoke references on table "public"."workout_plan_sets" from "authenticated";

revoke select on table "public"."workout_plan_sets" from "authenticated";

revoke trigger on table "public"."workout_plan_sets" from "authenticated";

revoke truncate on table "public"."workout_plan_sets" from "authenticated";

revoke update on table "public"."workout_plan_sets" from "authenticated";

revoke delete on table "public"."workout_plan_sets" from "service_role";

revoke insert on table "public"."workout_plan_sets" from "service_role";

revoke references on table "public"."workout_plan_sets" from "service_role";

revoke select on table "public"."workout_plan_sets" from "service_role";

revoke trigger on table "public"."workout_plan_sets" from "service_role";

revoke truncate on table "public"."workout_plan_sets" from "service_role";

revoke update on table "public"."workout_plan_sets" from "service_role";

revoke delete on table "public"."workout_plans" from "anon";

revoke insert on table "public"."workout_plans" from "anon";

revoke references on table "public"."workout_plans" from "anon";

revoke select on table "public"."workout_plans" from "anon";

revoke trigger on table "public"."workout_plans" from "anon";

revoke truncate on table "public"."workout_plans" from "anon";

revoke update on table "public"."workout_plans" from "anon";

revoke delete on table "public"."workout_plans" from "authenticated";

revoke insert on table "public"."workout_plans" from "authenticated";

revoke references on table "public"."workout_plans" from "authenticated";

revoke select on table "public"."workout_plans" from "authenticated";

revoke trigger on table "public"."workout_plans" from "authenticated";

revoke truncate on table "public"."workout_plans" from "authenticated";

revoke update on table "public"."workout_plans" from "authenticated";

revoke delete on table "public"."workout_plans" from "service_role";

revoke insert on table "public"."workout_plans" from "service_role";

revoke references on table "public"."workout_plans" from "service_role";

revoke select on table "public"."workout_plans" from "service_role";

revoke trigger on table "public"."workout_plans" from "service_role";

revoke truncate on table "public"."workout_plans" from "service_role";

revoke update on table "public"."workout_plans" from "service_role";

alter table "public"."workout_plan_exercises" drop constraint "workout_plan_exercises_workout_plan_id_fkey";

alter table "public"."workout_plan_sets" drop constraint "workout_plan_sets_reps_non_negative";

alter table "public"."workout_plan_sets" drop constraint "workout_plan_sets_workout_plan_exercise_id_fkey";

alter table "public"."workout_plans" drop constraint "workout_plans_name_non_empty";

alter table "public"."workout_plans" drop constraint "workout_plans_user_id_fkey";

drop function if exists "public"."set_workout_plan_updated_at"();

alter table "public"."workout_plan_exercises" drop constraint "workout_plan_exercises_pkey";

alter table "public"."workout_plan_sets" drop constraint "workout_plan_sets_pkey";

alter table "public"."workout_plans" drop constraint "workout_plans_pkey";

drop index if exists "public"."workout_plan_exercises_pkey";

drop index if exists "public"."workout_plan_exercises_plan_id_idx";

drop index if exists "public"."workout_plan_sets_exercise_id_idx";

drop index if exists "public"."workout_plan_sets_pkey";

drop index if exists "public"."workout_plans_one_active_per_user";

drop index if exists "public"."workout_plans_pkey";

drop index if exists "public"."workout_plans_user_id_idx";

drop table "public"."workout_plan_exercises";

drop table "public"."workout_plan_sets";

drop table "public"."workout_plans";


  create table "public"."trainer_client" (
    "id" uuid not null default gen_random_uuid(),
    "trainer_id" uuid not null,
    "client_id" uuid not null,
    "client_type" text not null default 'online'::text,
    "status" text not null default 'active'::text,
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."trainer_client" enable row level security;


  create table "public"."users_info" (
    "user_id" uuid not null,
    "full_name" text,
    "avatar_url" text,
    "role" text not null default 'user'::text,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."users_info" enable row level security;


  create table "public"."workout_progress" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid not null,
    "current_workout_index" integer not null default 0,
    "updated_at" timestamp with time zone not null default timezone('utc'::text, now())
      );


alter table "public"."workout_progress" enable row level security;

CREATE UNIQUE INDEX trainer_client_pkey ON public.trainer_client USING btree (id);

CREATE UNIQUE INDEX unique_trainer_client ON public.trainer_client USING btree (trainer_id, client_id);

CREATE UNIQUE INDEX users_info_pkey ON public.users_info USING btree (user_id);

CREATE UNIQUE INDEX workout_progress_pkey ON public.workout_progress USING btree (id);

CREATE UNIQUE INDEX workout_progress_user_id_key ON public.workout_progress USING btree (user_id);

alter table "public"."trainer_client" add constraint "trainer_client_pkey" PRIMARY KEY using index "trainer_client_pkey";

alter table "public"."users_info" add constraint "users_info_pkey" PRIMARY KEY using index "users_info_pkey";

alter table "public"."workout_progress" add constraint "workout_progress_pkey" PRIMARY KEY using index "workout_progress_pkey";

alter table "public"."trainer_client" add constraint "no_self_client" CHECK ((trainer_id <> client_id)) not valid;

alter table "public"."trainer_client" validate constraint "no_self_client";

alter table "public"."trainer_client" add constraint "trainer_client_client_id_fkey" FOREIGN KEY (client_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."trainer_client" validate constraint "trainer_client_client_id_fkey";

alter table "public"."trainer_client" add constraint "trainer_client_client_type_check" CHECK ((client_type = ANY (ARRAY['online'::text, 'gym'::text]))) not valid;

alter table "public"."trainer_client" validate constraint "trainer_client_client_type_check";

alter table "public"."trainer_client" add constraint "trainer_client_status_check" CHECK ((status = ANY (ARRAY['active'::text, 'pending'::text, 'inactive'::text]))) not valid;

alter table "public"."trainer_client" validate constraint "trainer_client_status_check";

alter table "public"."trainer_client" add constraint "trainer_client_trainer_id_fkey" FOREIGN KEY (trainer_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."trainer_client" validate constraint "trainer_client_trainer_id_fkey";

alter table "public"."trainer_client" add constraint "unique_trainer_client" UNIQUE using index "unique_trainer_client";

alter table "public"."users_info" add constraint "users_info_role_check" CHECK ((role = ANY (ARRAY['trainer'::text, 'user'::text]))) not valid;

alter table "public"."users_info" validate constraint "users_info_role_check";

alter table "public"."users_info" add constraint "users_info_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."users_info" validate constraint "users_info_user_id_fkey";

alter table "public"."workout_progress" add constraint "workout_progress_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.profile(user_id) ON DELETE CASCADE not valid;

alter table "public"."workout_progress" validate constraint "workout_progress_user_id_fkey";

alter table "public"."workout_progress" add constraint "workout_progress_user_id_key" UNIQUE using index "workout_progress_user_id_key";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.rls_auto_enable()
 RETURNS event_trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_users_info_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin new.updated_at = now(); return new; end; $function$
;

CREATE OR REPLACE FUNCTION public.handle_new_user_profile()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  insert into public.profile (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.set_gym_equipment_updated_date()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
  new.updated_date = now();
  return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.set_profile_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
  new.updated_at = now();
  return new;
end;
$function$
;

grant delete on table "public"."trainer_client" to "anon";

grant insert on table "public"."trainer_client" to "anon";

grant references on table "public"."trainer_client" to "anon";

grant select on table "public"."trainer_client" to "anon";

grant trigger on table "public"."trainer_client" to "anon";

grant truncate on table "public"."trainer_client" to "anon";

grant update on table "public"."trainer_client" to "anon";

grant delete on table "public"."trainer_client" to "authenticated";

grant insert on table "public"."trainer_client" to "authenticated";

grant references on table "public"."trainer_client" to "authenticated";

grant select on table "public"."trainer_client" to "authenticated";

grant trigger on table "public"."trainer_client" to "authenticated";

grant truncate on table "public"."trainer_client" to "authenticated";

grant update on table "public"."trainer_client" to "authenticated";

grant delete on table "public"."trainer_client" to "service_role";

grant insert on table "public"."trainer_client" to "service_role";

grant references on table "public"."trainer_client" to "service_role";

grant select on table "public"."trainer_client" to "service_role";

grant trigger on table "public"."trainer_client" to "service_role";

grant truncate on table "public"."trainer_client" to "service_role";

grant update on table "public"."trainer_client" to "service_role";

grant delete on table "public"."users_info" to "anon";

grant insert on table "public"."users_info" to "anon";

grant references on table "public"."users_info" to "anon";

grant select on table "public"."users_info" to "anon";

grant trigger on table "public"."users_info" to "anon";

grant truncate on table "public"."users_info" to "anon";

grant update on table "public"."users_info" to "anon";

grant delete on table "public"."users_info" to "authenticated";

grant insert on table "public"."users_info" to "authenticated";

grant references on table "public"."users_info" to "authenticated";

grant select on table "public"."users_info" to "authenticated";

grant trigger on table "public"."users_info" to "authenticated";

grant truncate on table "public"."users_info" to "authenticated";

grant update on table "public"."users_info" to "authenticated";

grant delete on table "public"."users_info" to "service_role";

grant insert on table "public"."users_info" to "service_role";

grant references on table "public"."users_info" to "service_role";

grant select on table "public"."users_info" to "service_role";

grant trigger on table "public"."users_info" to "service_role";

grant truncate on table "public"."users_info" to "service_role";

grant update on table "public"."users_info" to "service_role";

grant delete on table "public"."workout_progress" to "anon";

grant insert on table "public"."workout_progress" to "anon";

grant references on table "public"."workout_progress" to "anon";

grant select on table "public"."workout_progress" to "anon";

grant trigger on table "public"."workout_progress" to "anon";

grant truncate on table "public"."workout_progress" to "anon";

grant update on table "public"."workout_progress" to "anon";

grant delete on table "public"."workout_progress" to "authenticated";

grant insert on table "public"."workout_progress" to "authenticated";

grant references on table "public"."workout_progress" to "authenticated";

grant select on table "public"."workout_progress" to "authenticated";

grant trigger on table "public"."workout_progress" to "authenticated";

grant truncate on table "public"."workout_progress" to "authenticated";

grant update on table "public"."workout_progress" to "authenticated";

grant delete on table "public"."workout_progress" to "service_role";

grant insert on table "public"."workout_progress" to "service_role";

grant references on table "public"."workout_progress" to "service_role";

grant select on table "public"."workout_progress" to "service_role";

grant trigger on table "public"."workout_progress" to "service_role";

grant truncate on table "public"."workout_progress" to "service_role";

grant update on table "public"."workout_progress" to "service_role";


  create policy "Trainers can delete their client records"
  on "public"."trainer_client"
  as permissive
  for delete
  to authenticated
using ((auth.uid() = trainer_id));



  create policy "Trainers can insert clients"
  on "public"."trainer_client"
  as permissive
  for insert
  to authenticated
with check ((auth.uid() = trainer_id));



  create policy "Trainers can update their client records"
  on "public"."trainer_client"
  as permissive
  for update
  to authenticated
using ((auth.uid() = trainer_id));



  create policy "Trainers can view their clients"
  on "public"."trainer_client"
  as permissive
  for select
  to authenticated
using ((auth.uid() = trainer_id));



  create policy "Users can read all users_info"
  on "public"."users_info"
  as permissive
  for select
  to authenticated
using (true);



  create policy "Users can update own users_info"
  on "public"."users_info"
  as permissive
  for update
  to authenticated
using ((auth.uid() = user_id))
with check ((auth.uid() = user_id));



  create policy "Users can insert their own progress"
  on "public"."workout_progress"
  as permissive
  for insert
  to public
with check ((auth.uid() = user_id));



  create policy "Users can update their own progress"
  on "public"."workout_progress"
  as permissive
  for update
  to public
using ((auth.uid() = user_id));



  create policy "Users can view their own progress"
  on "public"."workout_progress"
  as permissive
  for select
  to public
using ((auth.uid() = user_id));


CREATE TRIGGER users_info_set_updated_at BEFORE UPDATE ON public.users_info FOR EACH ROW EXECUTE FUNCTION public.set_users_info_updated_at();


