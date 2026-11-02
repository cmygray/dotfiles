// hover: chips under a reply, the definition on hover
// inline: the definition always shown under a reply
// off: nothing drawn (the writing rule still applies)
export type Mode = 'hover' | 'inline' | 'off'

declare module 'claude-code' {
  interface PluginState {
    'eval-glossary': { mode: Mode }
  }
}
