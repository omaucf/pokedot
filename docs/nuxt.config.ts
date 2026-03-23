export default defineNuxtConfig({
  devtools: { enabled: true },
  srcDir: "./app",
  css: ["~/app.css"],
  modules: [
    "@nuxt/icon",
    "@nuxt/image",
    "@nuxt/fonts",
    "@nuxtjs/color-mode",
    "@nuxtjs/mdc",
    "@nuxt/ui",
  ],
  future: { compatibilityVersion: 4 },
  compatibilityDate: "2026-01-13",
});
