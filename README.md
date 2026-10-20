# titipebi

Responsive Indonesian jastip storefront, WhatsApp request bag, and Supabase-backed admin dashboard. Navy, warm white, and champagne branding; original supplied logo is displayed as an image. Generated hero photography and stock product photos are illustrative. Demo mode is clearly labelled and is not real store inventory.

## Run locally

Requires Node 22+. Use `pnpm install`, copy `.env.example` to `.env.local`, then `pnpm dev`. Without Supabase variables the public storefront displays eight demo products, and the admin login offers a read-only dashboard preview. No demo changes are persisted to a server. A configured database failure shows an error instead of silently switching to demo inventory.

## Supabase setup

1. Create a Supabase project. Run `supabase/migrations/001_catalog.sql` in SQL Editor once. This installs tables, indexes, RLS, categories, store settings, and the public `product-images` bucket. Storage is public, so upload public product photography only.
2. Set `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` in hosting environment settings. An anon or publishable key works. No service-role key is required or used.
3. In Supabase Authentication create an email/password user. Disable public sign-ups if unnecessary. Copy the user's UUID and run, replacing the placeholder:

   ```sql
   insert into public.admin_users(user_id) values ('AUTH_USER_UUID');
   ```

   Only database owners can change the allowlist. Existing admins cannot promote other accounts through this app.
4. Optionally run `supabase/seed.sql` in a development project. It creates labelled, unpublished demo products. Do not publish them as real store inventory.
5. Redeploy after setting environment variables. Open `/admin/login` and sign in. Sessions use HttpOnly, SameSite=Strict cookies, and HTTPS Secure cookies in production. Sessions expire based on Supabase's access-token lifetime; sign in again when expired. There is no password reset workflow in the storefront; reset admin accounts from Supabase.
6. Add real brands and categories, create products, upload photos, set variants/prices/status, then publish. Verify WhatsApp and the Instagram handle in Settings. The supplied logo's phone number supplies the initial WhatsApp destination. Instagram remains hidden until the owner supplies the verified profile URL.

Admin routes and server mutations validate the user with Supabase Auth and verify `admin_users`; RLS independently enforces the same allowlist. Passwords are forwarded only to Supabase Auth and are never logged or stored by this app. All write routes check Origin. Zod validates mutation payloads. Uploads check authorization, MIME type, size, and magic bytes; browser optimization resizes to 1600 px WebP.

## Product management

`/admin`, `/admin/products`, `/admin/products/new`, `/admin/products/[id]/edit`, `/admin/brands`, `/admin/categories`, `/admin/settings`.

Images, color and size arrays are the canonical product data on `products`. The supplementary `product_images` and `product_variants` tables are available for future per-variant inventory extensions, but this UI uses product-level stock and all combinations of the listed color/size options. Rename triggers keep product category/brand text in sync. Deleting a brand/category leaves product labels intact; reassign affected products before deleting if needed.

Public catalog requests use `no-store`: saved changes appear on the next page load without redeployment. Favorites and bag are browser-local. On bag rendering, current product availability and prices replace cached snapshots. Sold-out/unpublished/deleted products cannot be ordered. WhatsApp messages include item names, color, size, quantity, price, availability, and product links; WhatsApp is a request for confirmation, not a payment checkout.

The catalog fetches up to 1,000 published products and paginates 12 cards per page in the browser. For catalogs exceeding 1,000 records, extend the API to query pages and filters server-side. This is a documented scaling boundary, not unlimited inventory support.

Removing an image saves its new associations first, then the authenticated API checks all products (including drafts) before deleting an unused Storage object. Shared files are retained. A failed cleanup never rolls back a saved product. Unsaved or abandoned form uploads may remain; periodically review unused objects in Supabase Storage and delete only URLs absent from **all** product image arrays. Never bulk-delete on a public request.

## Deployment

### Sites

This checkout includes the supplied Vinext adapter and Sites Vite integration for Cloudflare Workers. Use the Sites packaging helper and `.openai/hosting.json`. Runtime environment values go in Site settings, not in the manifest. The published preview is private to its owner by default.

### Vercel / standard Next.js

The application uses Next.js App Router APIs and includes a standard `next.config.ts`. In Vercel, choose Next.js and override build to `pnpm exec next build` and dev to `pnpm exec next dev`. Add both Supabase environment variables. The Sites adapter is used only by the Vite/Sites build; Vercel's Next build does not invoke it. Choose an account plan appropriate for the client's commercial use and verify current terms in Vercel's own documentation. This project does not assert any hosting quota or pricing.

## Checks

- `node scripts/check-catalog.mjs` (availability and WhatsApp message integrity)
- `pnpm exec tsc --noEmit`
- `pnpm lint`
- Sites production build: `node /root/.codex/plugins/cache/openai-curated-remote/sites/1.0.1/scripts/build-site.mjs` in this environment.
- Conventional Vercel build: `pnpm exec next build`.

Live Supabase login, RLS, uploads, and CRUD must be integration-tested against a configured project before taking store orders. No credentials were supplied during initial implementation. Browser QA is subject to environment browser availability; do not infer visual testing from successful build checks.

## Assets

- Original supplied logo: `public/assets/logo-original.png`.
- Hero: `public/assets/hero.png`, generated using the built-in imagegen tool. Prompt: a cinematic premium boutique still-life, black leather handbag on a travertine pedestal at right, secondary cognac/cream bags, warm light, deep navy negative space at left, no text or branding.
- Demo photos downloaded from Unsplash: photo-1548036328-c9fa89d128fa (tote), photo-1584917865442-de89df76afd3 (bag), photo-1590874103328-eac38a683ce7 (handbag), photo-1543163521-1bf539c55dd2 (shoes), photo-1524805444758-089113d48a6d (watch), photo-1511499767150-a48a237f0083 (glasses), photo-1627123424574-724758594e93 (wallet), photo-1483985988355-763728e1935b (fashion). Demo photos do not represent actual store merchandise.
- Fonts: Playfair Display and DM Sans with web-safe fallbacks. Google Fonts loading is optional; the layout remains readable without it.
