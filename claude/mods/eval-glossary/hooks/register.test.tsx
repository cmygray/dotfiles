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

const REPLY = 'C-D 집합의 nMAE는 0.138이고, L1 총점 SD는 반복 채점의 노이즈 플로어입니다.'

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

test('a reply that uses terms gets one chip per term under it, on every surface', async ($, on) => {
  on('ui.render', ($, e) => {
    const { Text } = $.ui.resolve(e)
    return <Text>engine</Text>
  })

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

test('a term inside code, or no term at all, leaves the engine its drawing', async ($, on) => {
  on('ui.render', ($, e) => {
    const { Text } = $.ui.resolve(e)
    return <Text>engine</Text>
  })

  for (const text of ['경로는 `eval/L1/metrics.json`입니다.', 'Plan B와 A안을 비교합니다.']) {
    const ui = await $.ui.mount({ ...message(text), surface: 'desktop' })

    expect(await ui.find({ type: 'Text', text: /^용어$/ })).toBeUndefined()
    expect((await ui.find({ type: 'Text', text: /^engine$/ }))?.text).toBe('engine')
    await ui.unmount()
  }
})

test('/glossary inline shows the meanings always; /glossary off draws nothing', async ($, on) => {
  on('ui.render', ($, e) => {
    const { Text } = $.ui.resolve(e)
    return <Text>engine</Text>
  })
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
