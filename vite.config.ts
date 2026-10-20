
import { defineConfig } from "vite";
import vinext from "vinext";
import { nitro } from "nitro/vite";
import tailwindcss from "@tailwindcss/vite";

/**
 * ==========================================
 * TITIPEBI — VITE CONFIGURATION
 * ==========================================
 *
 * Framework : Vinext
 * Bundler   : Vite
 * Styling   : Tailwind CSS v4
 * Server    : Nitro
 * Hosting   : Vercel
 *
 * ==========================================
 */

export default defineConfig({
  plugins: [
    tailwindcss(),
    vinext(),
    nitro(),
  ],

  build: {
    sourcemap: false,
  },
});
