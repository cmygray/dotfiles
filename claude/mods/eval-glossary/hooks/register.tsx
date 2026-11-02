import { atom, read, update } from 'claude-code'
import type { Register } from 'claude-code'

import type { Mode } from '../types'
import { TERMS } from './glossary'
import type { Term } from './glossary'
import { glossaryMarkdown } from './rule'

type Entry = Term & { patterns: readonly RegExp[] }

const MODES: readonly Mode[] = ['hover', 'inline', 'off']
const mode = atom({ plugin: 'eval-glossary', key: 'mode' } as const, 'hover')

const ENTRIES: readonly Entry[] = TERMS.map(t => ({ ...t, patterns: t.match.map(p => new RegExp(p)) }))

// Code spans and fences name identifiers, not the terms: `L1` in a path is not L1.
function prose(text: string): string {
  return text.replace(/```[\s\S]*?```/g, ' ').replace(/`[^`\n]*`/g, ' ')
}

function termsIn(text: string): Entry[] {
  const body = prose(text)
  return ENTRIES.filter(t => t.patterns.some(p => p.test(body)))
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    const stored = await $.store.get('mode')
    if (MODES.includes(stored as Mode)) {
      await update($, mode, () => stored as Mode)
    }
    await $.command.register({
      name: 'glossary',
      description: 'Eval glossary: list terms, or set display to hover | inline | off',
      argumentHint: '[hover|inline|off]',
    })

    // The writing rule reaches the model through a CLAUDE.md that imports
    // GLOSSARY.md: the builtin security plugin passes prompt.compose and
    // prompt.context on past a person's plugins. Keep that file in step here.
    const path = `${$.plugin.root}/GLOSSARY.md`
    const want = glossaryMarkdown()
    const have = await $.fs.read(path).catch(() => '')
    if (have !== want) {
      await $.fs.write(path, want).catch(error => $.ui.status(`eval-glossary: GLOSSARY.md not written (${String(error).slice(0, 80)})`))
    }
    return next(e)
  })

  on('command.run', { command: 'glossary' }, async ($, e) => {
    const arg = (e.args ?? '').trim() as Mode
    if (MODES.includes(arg)) {
      await update($, mode, () => arg)
      await $.store.set('mode', arg)
      return { text: `eval-glossary: display set to ${arg}.` }
    }
    const current = await read($, mode)
    return {
      text: [`eval-glossary (display: ${current}, ${ENTRIES.length} terms)`, ...ENTRIES.map(t => `- ${t.term}: ${t.short}`)].join('\n'),
    }
  })

  on('ui.render', { component: 'AssistantMessage' }, async ($, e, next) => {
    const current = await read($, mode)
    if (current === 'off' || e.props.isSummary) {
      return next(e)
    }
    const found = termsIn(e.props.text)
    if (found.length === 0) {
      return next(e)
    }

    const own = await next(e)
    const { Box, Text } = $.ui.resolve(e)

    if (current === 'inline') {
      return (
        <Box flexDirection="column">
          {own}
          <Box flexDirection="column" marginTop={1} paddingX={1} borderStyle="round" borderDimColor>
            {found.map(t => (
              <Text dimColor>
                <Text bold>{t.term}</Text> {t.short}
              </Text>
            ))}
          </Box>
        </Box>
      )
    }

    const width = Math.min(60, Math.max(24, (e.viewport?.columns ?? 80) - 8))
    return (
      <Box flexDirection="column">
        {own}
        <Box flexDirection="row" flexWrap="wrap" columnGap={1} marginTop={1}>
          <Text dimColor>용어</Text>
          {found.map(t => (
            <Box key={`g-${t.id}`}>
              <Text color="cyan" underline hover={{ bold: true }}>
                {t.term}
              </Text>
              <Box
                position="absolute"
                bottom={1}
                left={0}
                width={width}
                display="none"
                hover={{ display: 'flex' }}
                flexDirection="column"
                borderStyle="round"
                paddingX={1}
              >
                <Text bold>{t.term}</Text>
                <Text>{t.short}</Text>
                {t.long !== '' && <Text dimColor>{t.long}</Text>}
              </Box>
            </Box>
          ))}
        </Box>
      </Box>
    )
  })
}
