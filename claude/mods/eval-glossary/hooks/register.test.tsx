import { expect, test } from 'claude-code/testing'
import type { TestBody } from 'claude-code/testing'

const message = (text: string) =>
  ({
    plugin: 'eval-glossary',
    component: 'AssistantMessage',
    requestId: 'msg-1',
    props: { text, isFirstOfReply: true },
  }) as const

const RUN = { origin: { kind: 'composer' }, presentation: { isFullscreen: false, columns: 80 } } as const

const BAND = {
  plugin: 'eval-glossary',
  component: 'AbovePrompt',
  requestId: 'above-prompt',
  props: { hasSurvey: false, isWorking: false, maxRows: 10, bodyColumns: 80, scroll: { offset: 0, bodyRows: 10 }, view: {} },
} as const

const REPLY = 'C-D 집합의 nMAE는 0.138이고, L1 총점 SD는 반복 채점의 노이즈 플로어입니다.'

const turn = (answer: string, extra: { agentId?: string } = {}) =>
  ({ answer, durationMs: 1, isAborted: false, turnId: 't-1', reason: 'answer', ...extra }) as const

function stubSession(on: Parameters<TestBody>[1], files: Map<string, string>) {
  const stored = new Map<string, unknown>()
  on('store.get', (_, e) => ({ value: stored.get(e.key) }))
  on('store.set', (_, e) => {
    stored.set(e.key, e.value)
    return { value: undefined }
  })
  on('fs.read', (_, e) => ({ value: files.get(e.path) ?? '' }))
  on('fs.write', (_, e) => {
    files.set(e.path, e.text)
    return { value: undefined }
  })
  on('command.register', () => ({ value: { command: 'glossary' } }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  on('turn.complete', (_, e) => ({ text: e.answer }))
  // stands for the engine's own drawing of every component
  on('ui.render', ($, e) => {
    const { Text } = $.ui.resolve(e)
    return <Text>engine</Text>
  })
}

test('session start writes GLOSSARY.md from the terms, and leaves an up-to-date one alone', async ($, on) => {
  const files = new Map<string, string>()
  stubSession(on, files)

  await $.session.start({ cwd: '/', surface: 'desktop', isInteractive: true })

  const [path, text] = [...files.entries()][0] ?? []
  expect(path?.endsWith('/GLOSSARY.md')).toBe(true)
  expect(text).toContain('- **nMAE**: 정규화 평균 절대 오차')
  expect(text).toContain('- **McNemar 정확검정**:')
  expect(text).toContain('「용어」 표')

  files.set(path ?? '', `${text}`)
  await $.session.start({ cwd: '/', surface: 'desktop', isInteractive: true })
  expect(files.size).toBe(1)
})

test('the band shows the latest answer\'s terms, a definition row under them, on every surface', async ($, on) => {
  stubSession(on, new Map())
  await $.session.start({ cwd: '/', surface: 'desktop', isInteractive: true })

  // nothing answered yet: the band is the engine's
  const before = await $.ui.mount({ ...BAND, surface: 'desktop' })
  expect((await before.find({ type: 'Text', text: /^engine$/ }))?.text).toBe('engine')
  await before.unmount()

  await $.turn.complete(turn(REPLY))
  for (const surface of ['terminal', 'desktop'] as const) {
    const band = await $.ui.mount({ ...BAND, surface })
    expect(await band.find({ type: 'Text', text: /^용어$/ })).toBeDefined()
    expect(await band.find({ type: 'Text', text: /^nMAE$/ })).toBeDefined()
    expect(await band.find({ type: 'Text', text: /^C-D$/ })).toBeDefined()
    expect(await band.find({ type: 'Text', text: /포인터를 올리면/ })).toBeDefined()
    // each definition is drawn hidden in the second row, revealed by its chip's scope
    expect(await band.find({ type: 'Text', text: /만점의 평균/ })).toBeDefined()
    await band.unmount()
  }

  // a subagent's report leaves the band as it was; a reply with no term clears it
  await $.turn.complete(turn('급락이 있었습니다.', { agentId: 'a-1' }))
  const afterAgent = await $.ui.mount({ ...BAND, surface: 'desktop' })
  expect(await afterAgent.find({ type: 'Text', text: /^nMAE$/ })).toBeDefined()
  expect(await afterAgent.find({ type: 'Text', text: /^급락$/ })).toBeUndefined()
  await afterAgent.unmount()

  await $.turn.complete(turn('용어 없는 답변입니다.'))
  const cleared = await $.ui.mount({ ...BAND, surface: 'desktop' })
  expect((await cleared.find({ type: 'Text', text: /^engine$/ }))?.text).toBe('engine')
  await cleared.unmount()

  // past six terms the band shows the first six and how many it left out
  await $.turn.complete(turn('하네스의 L0, L1, L2, L3, L4와 nMAE, flip률, QWK를 봅니다.'))
  const capped = await $.ui.mount({ ...BAND, surface: 'desktop' })
  expect(await capped.find({ type: 'Text', text: /^L4 judge$/ })).toBeDefined()
  expect(await capped.find({ type: 'Text', text: /^nMAE$/ })).toBeDefined()
  expect(await capped.find({ type: 'Text', text: /^flip률$/ })).toBeUndefined()
  expect(await capped.find({ type: 'Text', text: /^\+2$/ })).toBeDefined()
  await capped.unmount()

  // in band mode the replies themselves carry no chips
  const reply = await $.ui.mount({ ...message(REPLY), surface: 'desktop' })
  expect(await reply.find({ type: 'Text', text: /^nMAE$/ })).toBeUndefined()
  await reply.unmount()
})

test('/glossary hover puts one chip per term under a reply, on every surface', async ($, on) => {
  stubSession(on, new Map())
  await $.session.start({ cwd: '/', surface: 'desktop', isInteractive: true })
  await $.command.run({ ...RUN, command: 'glossary', args: 'hover' })

  for (const surface of ['terminal', 'desktop'] as const) {
    const ui = await $.ui.mount({ ...message(REPLY), surface })

    expect((await ui.find({ type: 'Text', text: /^engine$/ }))?.text).toBe('engine')
    expect(await ui.find({ type: 'Text', text: /^nMAE$/ })).toBeDefined()
    expect(await ui.find({ type: 'Text', text: /^C-D$/ })).toBeDefined()
    expect(await ui.find({ type: 'Text', text: /^L1 노이즈 플로어$/ })).toBeDefined()
    // the hover card is drawn hidden beside its chip
    expect(await ui.find({ type: 'Text', text: /만점의 평균/ })).toBeDefined()
    await ui.unmount()
  }
})

test('a common notation counts beside the eval context: an unambiguous term or an anchor', async ($, on) => {
  stubSession(on, new Map())
  await $.session.start({ cwd: '/', surface: 'desktop', isInteractive: true })
  await $.command.run({ ...RUN, command: 'glossary', args: 'hover' })

  for (const text of ['L1 SD가 nMAE보다 크게 흔들립니다.', '베이스라인의 L1 노이즈가 큽니다.']) {
    const ui = await $.ui.mount({ ...message(text), surface: 'desktop' })
    expect(await ui.find({ type: 'Text', text: /^L1 노이즈 플로어$/ })).toBeDefined()
    await ui.unmount()
  }
})

test('the writing rule is scoped to eval writing and marks the common notations', async ($, on) => {
  const files = new Map<string, string>()
  stubSession(on, files)
  await $.session.start({ cwd: '/', surface: 'desktop', isInteractive: true })

  const text = [...files.values()][0] ?? ''
  expect(text).toContain('교육과정 층위의 L1')
  expect(text).toContain('- **L1 노이즈 플로어** (맥락 한정):')
  expect(text).toContain('- **nMAE**: ')
})

test('a term inside code, or no term at all, leaves the engine its drawing', async ($, on) => {
  stubSession(on, new Map())
  await $.session.start({ cwd: '/', surface: 'desktop', isInteractive: true })
  await $.command.run({ ...RUN, command: 'glossary', args: 'hover' })

  for (const text of [
    '경로는 `eval/L1/metrics.json`입니다.',
    'Plan B와 A안을 비교합니다.',
    // a curriculum's levels, a cache, a plain word: same notation, another context
    '층을 L1, L2, L3로 부릅니다. L1은 교육과정의 글의 유형입니다.',
    'L1 캐시 적중률이 급락했고 drift가 있습니다.',
  ]) {
    const ui = await $.ui.mount({ ...message(text), surface: 'desktop' })

    expect(await ui.find({ type: 'Text', text: /^용어$/ })).toBeUndefined()
    expect((await ui.find({ type: 'Text', text: /^engine$/ }))?.text).toBe('engine')
    await ui.unmount()
  }
})

test('/glossary inline shows the meanings always; /glossary off draws nothing', async ($, on) => {
  stubSession(on, new Map())
  await $.session.start({ cwd: '/', surface: 'desktop', isInteractive: true })

  expect((await $.command.run({ ...RUN, command: 'glossary', args: 'inline' })).text).toContain('inline')
  let ui = await $.ui.mount({ ...message(REPLY), surface: 'desktop' })
  expect(await ui.find({ type: 'Text', text: /^용어$/ })).toBeUndefined()
  expect(await ui.find({ type: 'Text', text: /^nMAE$/ })).toBeDefined()
  await ui.unmount()

  await $.command.run({ ...RUN, command: 'glossary', args: 'off' })
  ui = await $.ui.mount({ ...message(REPLY), surface: 'desktop' })
  expect(await ui.find({ type: 'Text', text: /^nMAE$/ })).toBeUndefined()
  await ui.unmount()

  const list = await $.command.run({ ...RUN, command: 'glossary', args: '' })
  expect(list.text).toContain('display: off')
  expect(list.text).toContain('- 급락:')
})
