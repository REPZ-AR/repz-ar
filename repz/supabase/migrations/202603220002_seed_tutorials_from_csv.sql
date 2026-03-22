-- Seed tutorials for known equipment from provided CSV content.
-- Descriptions include the recommended TikTok creator for richer UI display.

with tutorial_seed(equipment_name, youtube_link, tiktok_link, creator_handle) as (
  values
    ('Chest Press', 'https://www.youtube.com/watch?v=sqNwDkUU_Ps', 'https://www.tiktok.com/search?q=Chest%20Press%20Machine%20Form%20Tutorial', '@jpgcoaching'),
    ('Lat Pull Down', 'https://www.youtube.com/watch?v=AOpi-p0cJkc', 'https://www.tiktok.com/search?q=Lat%20Pulldown%20mistakes%20to%20avoid', '@trizzlemanfitness'),
    ('Seated Cable Rows', 'https://www.youtube.com/watch?v=TeFo51Q_Nsc', 'https://www.tiktok.com/search?q=How%20to%20do%20Seated%20Cable%20Rows', '@jpgcoaching'),
    ('Arm Curl', 'https://www.youtube.com/watch?v=rYDvcbMsSus', 'https://www.tiktok.com/search?q=Bicep%20Curl%20Machine%20Setup', '@ryjewers'),
    ('Chest fly', 'https://www.youtube.com/watch?v=mEBBK9_vuJg', 'https://www.tiktok.com/search?q=Chest%20Fly%20Machine%20Form', '@caylept'),
    ('Chinning Dipping', 'https://www.youtube.com/watch?v=KdmioYxFPtE', 'https://www.tiktok.com/search?q=Assisted%20Dip%20Machine%20Tutorial', '@chloe.fitness'),
    ('Lateral Raises', 'https://www.youtube.com/watch?v=dTwa2piwU-A', 'https://www.tiktok.com/search?q=Cable%20Lateral%20Raise%20Setup', '@jpgcoaching'),
    ('Leg Extension', 'https://www.youtube.com/watch?v=yMwvbrQjwHw', 'https://www.tiktok.com/search?q=Leg%20Extension%20Form%20setup', '@trainedbyyus'),
    ('Leg Press', 'https://www.youtube.com/watch?v=p5dCqF7wWUw', 'https://www.tiktok.com/search?q=How%20to%20use%20the%20Leg%20Press', '@trizzlemanfitness'),
    ('Leg Curl', 'https://www.youtube.com/watch?v=vl5nUdE9mWM', 'https://www.tiktok.com/search?q=Seated%20Leg%20Curl%20Tutorial', '@ryjewers'),
    ('Seated Dip', 'https://www.youtube.com/watch?v=Zg0tT27iYuY', 'https://www.tiktok.com/search?q=Tricep%20Dip%20Machine%20Form', '@caylept'),
    ('Shoulder Press', 'https://www.youtube.com/watch?v=VXTW2Dtj8zs', 'https://www.tiktok.com/search?q=Machine%20Shoulder%20Press%20Form', '@jpgcoaching'),
    ('Smith', 'https://www.youtube.com/watch?v=qPWXdq7idrI', 'https://www.tiktok.com/search?q=Smith%20Machine%20setup%20guide', '@libbychristensen')
),
normalized_equipment as (
  select
    ge.equipment_id,
    lower(regexp_replace(trim(ge.equipment_name), '\\s+', ' ', 'g')) as normalized_name
  from public.gym_equipment ge
),
resolved_seed as (
  select
    ne.equipment_id,
    ts.youtube_link,
    ts.tiktok_link,
    ts.creator_handle
  from tutorial_seed ts
  join normalized_equipment ne
    on ne.normalized_name = lower(regexp_replace(trim(ts.equipment_name), '\\s+', ' ', 'g'))
),
flattened_tutorials as (
  select
    equipment_id,
    format('YouTube form tutorial (recommended creator: %s)', creator_handle) as description,
    youtube_link as tutorial_link,
    'youtube'::public.tutorial_source as source
  from resolved_seed
  union all
  select
    equipment_id,
    format('TikTok coaching search (recommended creator: %s)', creator_handle) as description,
    tiktok_link as tutorial_link,
    'tiktok'::public.tutorial_source as source
  from resolved_seed
)
insert into public.tutorials (equipment_id, description, tutorial_link, source)
select ft.equipment_id, ft.description, ft.tutorial_link, ft.source
from flattened_tutorials ft
where not exists (
  select 1
  from public.tutorials t
  where t.equipment_id = ft.equipment_id
    and t.source = ft.source
    and t.tutorial_link = ft.tutorial_link
);

