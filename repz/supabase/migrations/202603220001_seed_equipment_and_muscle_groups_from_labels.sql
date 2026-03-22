-- Seed catalog data from assets/labels.txt (excluding non-equipment labels).
-- This migration intentionally does NOT seed tutorials/video links.

with equipment_seed(equipment_name) as (
  values
    ('Chest Press'),
    ('Lat Pull Down'),
    ('Seated Cable Rows'),
    ('Arm Curl'),
    ('Chest fly'),
    ('Chinning Dipping'),
    ('Lateral Raises'),
    ('Leg Extension'),
    ('Leg Press'),
    ('Leg Curl'),
    ('Seated Dip'),
    ('Shoulder Press'),
    ('Smith')
)
insert into public.gym_equipment (equipment_name)
select equipment_name
from equipment_seed
on conflict (equipment_name) do nothing;

with muscle_group_seed(muscle_group_name, muscle_class, description) as (
  values
    ('Chest', 'upper', 'Pectoral muscles involved in pressing and fly movements.'),
    ('Back', 'upper', 'Upper and mid-back muscles including lats and rhomboids.'),
    ('Shoulders', 'upper', 'Deltoid muscle group for pressing and raise movements.'),
    ('Biceps', 'upper', 'Elbow flexor muscles on the front of the upper arm.'),
    ('Triceps', 'upper', 'Elbow extensor muscles on the back of the upper arm.'),
    ('Quadriceps', 'lower', 'Front thigh muscles active in knee extension and pressing.'),
    ('Hamstrings', 'lower', 'Back thigh muscles active in knee flexion and hip extension.'),
    ('Glutes', 'lower', 'Hip extensor muscles active in leg press and compound lower-body work.')
)
insert into public.muscle_group (muscle_group_name, muscle_class, description)
select muscle_group_name, muscle_class, description
from muscle_group_seed
on conflict (muscle_group_name) do update
set muscle_class = excluded.muscle_class,
    description = excluded.description;

with equipment_muscle_seed(equipment_name, muscle_group_name) as (
  values
    ('Chest Press', 'Chest'),
    ('Chest Press', 'Shoulders'),
    ('Chest Press', 'Triceps'),

    ('Lat Pull Down', 'Back'),
    ('Lat Pull Down', 'Biceps'),

    ('Seated Cable Rows', 'Back'),
    ('Seated Cable Rows', 'Biceps'),

    ('Arm Curl', 'Biceps'),

    ('Chest fly', 'Chest'),
    ('Chest fly', 'Shoulders'),

    ('Chinning Dipping', 'Back'),
    ('Chinning Dipping', 'Chest'),
    ('Chinning Dipping', 'Biceps'),
    ('Chinning Dipping', 'Triceps'),

    ('Lateral Raises', 'Shoulders'),

    ('Leg Extension', 'Quadriceps'),

    ('Leg Press', 'Quadriceps'),
    ('Leg Press', 'Hamstrings'),
    ('Leg Press', 'Glutes'),

    ('Leg Curl', 'Hamstrings'),

    ('Seated Dip', 'Triceps'),
    ('Seated Dip', 'Chest'),
    ('Seated Dip', 'Shoulders'),

    ('Shoulder Press', 'Shoulders'),
    ('Shoulder Press', 'Triceps'),

    ('Smith', 'Quadriceps'),
    ('Smith', 'Hamstrings'),
    ('Smith', 'Glutes'),
    ('Smith', 'Chest'),
    ('Smith', 'Shoulders'),
    ('Smith', 'Triceps')
)
insert into public.gym_equipment_muscle_group (equipment_id, muscle_group_id)
select ge.equipment_id, mg.id
from equipment_muscle_seed em
join public.gym_equipment ge
  on ge.equipment_name = em.equipment_name
join public.muscle_group mg
  on mg.muscle_group_name = em.muscle_group_name
on conflict (equipment_id, muscle_group_id) do nothing;

