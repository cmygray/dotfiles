// band: the terms of the latest reply in a fixed band above the prompt,
//       the meaning of the one under the pointer in the band's second row
// hover: chips under each reply, the definition on hover
// inline: the definition always shown under each reply
// off: nothing drawn (the writing rule still applies)
export type Mode = 'band' | 'hover' | 'inline' | 'off'

declare module 'claude-code' {
  interface PluginState {
    'eval-glossary': {
      mode: Mode
      // ids (glossary.ts `id`) of the terms the latest answered turn used
      recent: readonly string[]
    }
  }
}
