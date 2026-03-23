<script setup lang="ts">
  import { en } from "@nuxt/ui/locale";

  useHead({
    htmlAttrs: { dir: en.dir, lang: en.code },
    link: [{ rel: "icon", href: "/favicon.ico" }],
    meta: [{ name: "viewport", content: "width=device-width, initial-scale=1" }],
  });
</script>

<template>
  <Body>
    <UApp :locale="en">
      <NuxtLayout> <NuxtPage /> </NuxtLayout>
    </UApp>
  </Body>
</template>
