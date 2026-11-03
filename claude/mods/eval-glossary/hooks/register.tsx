import { atom, read, update } from 'claude-code'
import type { Register } from 'claude-code'

import type { Mode } from '../types'
import { TERMS } from './glossary'
import type { Term } from './glossary'
import { glossaryMarkdown } from './rule'

type Entry = Term & { patterns: readonly RegExp[] }

const MODES: readonly Mode[] = ['band', 'hover', 'inline', 'off']
const mode = atom({ plugin: 'eval-glossary', key: 'mode' } as const, 'band')
const recent = atom({ plugin: 'eval-glossary', key: 'recent' } as const, [] as readonly string[])

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
      description: 'Eval glossary: list terms, or set display to band | hover | inline | off',
      argumentHint: '[band|hover|inline|off]',
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

  // A render hook cannot write state, so the band learns the latest reply's
  // terms here: the main loop's answer only, not a subagent's report.
  on('turn.complete', async ($, e, next) => {
    const done = await next(e)
    if (e.reason === 'answer' && e.agentId === undefined) {
      const ids = termsIn(e.answer).map(t => t.id)
      await update($, recent, () => ids).catch(() => undefined)
    }
    return done
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    if (e.props.hasSurvey || (await read($, mode)) !== 'band') {
      return next(e)
    }
    const ids = await read($, recent)
    const found = ENTRIES.filter(t => ids.includes(t.id))
    if (found.length === 0) {
      return next(e)
    }

    const { Box, Text } = $.ui.resolve(e)
    const width = e.props.bodyColumns
    // Each chip lights its scope; the definition of that scope sits in the
    // second row, so nothing is drawn over the transcript.
    return (
      <Box flexDirection="column" width={width}>
        <Box flexDirection="row" flexWrap="wrap" columnGap={1}>
          <Text dimColor>용어</Text>
          {found.map(t => (
            <Box key={`b-${t.id}`} hover={{ scope: `term-${t.id}` }}>
              <Text color="cyan" underline hover={{ bold: true }}>
                {t.term}
              </Text>
            </Box>
          ))}
        </Box>
        <Box height={1} overflow="hidden">
          <Text dimColor wrap="truncate-end">
            용어에 포인터를 올리면 뜻이 여기에 표시됩니다
          </Text>
          {found.map(t => (
            <Box
              position="absolute"
              top={0}
              left={0}
              width={width}
              display="none"
              hover={{ scope: `term-${t.id}`, display: 'flex' }}
              backgroundColor="text"
            >
              <Text color="inverseText" wrap="truncate-end">
                <Text bold color="inverseText">
                  {t.term}
                </Text>{' '}
                {t.short}
              </Text>
            </Box>
          ))}
        </Box>
      </Box>
    )
  })

  on('ui.render', { component: 'AssistantMessage' }, async ($, e, next) => {
    const current = await read($, mode)
    if (current === 'off' || current === 'band' || e.props.isSummary) {
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
                paddingX={1}
                // An absolute Box paints no background of its own, so the reply
                // beneath shows through. No theme key names the background:
                // invert text and inverseText, opaque on light and dark alike.
                backgroundColor="text"
              >
                <Text bold color="inverseText">
                  {t.term}
                </Text>
                <Text color="inverseText">{t.short}</Text>
                {t.long !== '' && <Text color="inverseText">{t.long}</Text>}
              </Box>
            </Box>
          ))}
        </Box>
      </Box>
    )
  })
}
