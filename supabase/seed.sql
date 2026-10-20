-- Optional development seed only. Drafts are intentionally not published.
insert into public.products(name,slug,description,price,brand,category,images,status,colors,sizes,published,sku) values
('DEMO — Everyday Tote','demo-everyday-tote','Produk ilustrasi untuk menguji dashboard, bukan inventaris toko.',589000,'','Tas','["/assets/bag-tan.jpg"]','Pre-Order','["Hitam","Cognac"]','[]',false,'DEMO-001'),
('DEMO — City Heels','demo-city-heels','Produk ilustrasi untuk menguji dashboard, bukan inventaris toko.',469000,'','Sepatu','["/assets/shoes.jpg"]','Ready Stock','["Nude"]','["36","37","38","39"]',false,'DEMO-002')
on conflict (slug) do nothing;
