begin;
create table public.profiles (id uuid primary key references auth.users(id) on delete cascade, display_name text not null default '');
create table public.admin_users (user_id uuid primary key references auth.users(id) on delete cascade);
create function public.is_admin() returns boolean language sql stable security definer set search_path=public as $$ select exists(select 1 from public.admin_users where user_id=auth.uid()); $$;
revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to anon,authenticated;
create table public.brands (id uuid primary key default gen_random_uuid(),name text unique not null check(length(name) between 1 and 100),sort_order integer not null default 0);
create table public.categories (id uuid primary key default gen_random_uuid(),name text unique not null check(length(name) between 1 and 100),sort_order integer not null default 0);
create table public.products (
 id uuid primary key default gen_random_uuid(), name text not null check(length(name) between 1 and 150), slug text not null unique check(slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
 description text not null default '', price numeric not null check(price>=0), discount_price numeric check(discount_price>=0 and discount_price<price),
 brand text not null default '', category text not null, images jsonb not null default '[]'::jsonb check(jsonb_typeof(images)='array' and jsonb_array_length(images)<=10),
 status text not null default 'Pre-Order' check(status in ('Ready Stock','Pre-Order','Sold Out')), colors jsonb not null default '[]', sizes jsonb not null default '[]',
 stock integer check(stock>=0),published boolean not null default false,featured boolean not null default false,sort_order integer not null default 0,
 eta text not null default '',deadline text not null default '',sku text not null default '',created_at timestamptz not null default now(),updated_at timestamptz not null default now()
);
create table public.product_images(id uuid primary key default gen_random_uuid(), product_id uuid not null references public.products(id) on delete cascade,url text not null,sort_order integer not null default 0);
create table public.product_variants(id uuid primary key default gen_random_uuid(),product_id uuid not null references public.products(id) on delete cascade,color text not null default '',size text not null default '',stock integer check(stock>=0));
create table public.store_settings(id integer primary key check(id=1),whatsapp text not null check(whatsapp ~ '^[0-9]{8,16}$'),instagram text not null,about text not null);
create index products_public_order on public.products(published,sort_order);
create index products_category on public.products(category);
create index products_brand on public.products(brand);
create index products_status on public.products(status);
create index product_images_parent on public.product_images(product_id);
create index product_variants_parent on public.product_variants(product_id);
create function public.touch_product() returns trigger language plpgsql set search_path=public as $$ begin new.updated_at=now(); return new; end; $$;
create trigger touch_product before update on public.products for each row execute function public.touch_product();
create function public.sync_product_metadata() returns trigger language plpgsql set search_path=public as $$ begin
 if tg_table_name='categories' then update public.products set category=new.name where category=old.name;
 else update public.products set brand=new.name where brand=old.name; end if; return new; end; $$;
create trigger rename_category after update of name on public.categories for each row execute function public.sync_product_metadata();
create trigger rename_brand after update of name on public.brands for each row execute function public.sync_product_metadata();
-- Roles can only be granted by a database owner. There is no client-side self-promotion policy.
alter table public.admin_users enable row level security;
create policy admin_read_own on public.admin_users for select to authenticated using(user_id=auth.uid());
alter table public.profiles enable row level security;
create policy profile_self_read on public.profiles for select to authenticated using(id=auth.uid());
create policy profile_self_update on public.profiles for update to authenticated using(id=auth.uid()) with check(id=auth.uid());
alter table public.products enable row level security;
create policy products_public on public.products for select to anon,authenticated using(published or public.is_admin());
create policy products_admin on public.products for all to authenticated using(public.is_admin()) with check(public.is_admin());
alter table public.brands enable row level security;
alter table public.categories enable row level security;
alter table public.store_settings enable row level security;
create policy brands_public on public.brands for select to anon,authenticated using(true);
create policy categories_public on public.categories for select to anon,authenticated using(true);
create policy settings_public on public.store_settings for select to anon,authenticated using(true);
create policy brands_admin on public.brands for all to authenticated using(public.is_admin()) with check(public.is_admin());
create policy categories_admin on public.categories for all to authenticated using(public.is_admin()) with check(public.is_admin());
create policy settings_admin on public.store_settings for all to authenticated using(public.is_admin()) with check(public.is_admin());
alter table public.product_images enable row level security;
alter table public.product_variants enable row level security;
create policy images_public on public.product_images for select to anon,authenticated using(exists(select 1 from public.products p where p.id=product_id and p.published) or public.is_admin());
create policy variants_public on public.product_variants for select to anon,authenticated using(exists(select 1 from public.products p where p.id=product_id and p.published) or public.is_admin());
create policy images_admin on public.product_images for all to authenticated using(public.is_admin()) with check(public.is_admin());
create policy variants_admin on public.product_variants for all to authenticated using(public.is_admin()) with check(public.is_admin());
grant select on public.products,public.brands,public.categories,public.store_settings,public.product_images,public.product_variants to anon,authenticated;
grant select on public.admin_users,public.profiles to authenticated;
grant insert,update,delete on public.products,public.brands,public.categories,public.store_settings,public.product_images,public.product_variants to authenticated;
grant update on public.profiles to authenticated;
insert into public.categories(name,sort_order) values ('Tas',0),('Sepatu',1),('Dompet',2),('Jam Tangan',3),('Fashion',4),('Aksesoris',5),('Kids',6),('Lainnya',7);
insert into public.store_settings values(1,'6287857580381','','titipebi membantu kamu menemukan pilihan tas, sepatu, fashion, dan aksesoris dari China. Konsultasikan produk incaranmu dan detail pre-order bersama kami melalui WhatsApp.');
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('product-images','product-images',true,5242880,array['image/jpeg','image/png','image/webp']);
create policy product_images_public_read on storage.objects for select to anon,authenticated using(bucket_id='product-images');
create policy product_images_admin_insert on storage.objects for insert to authenticated with check(bucket_id='product-images' and public.is_admin());
create policy product_images_admin_update on storage.objects for update to authenticated using(bucket_id='product-images' and public.is_admin()) with check(bucket_id='product-images' and public.is_admin());
create policy product_images_admin_delete on storage.objects for delete to authenticated using(bucket_id='product-images' and public.is_admin());
commit;
