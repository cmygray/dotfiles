import { TERMS } from './glossary'

// GLOSSARY.md, generated from TERMS: what a CLAUDE.md imports
// (`@~/dotfiles/claude/mods/eval-glossary/GLOSSARY.md`). The mod rewrites it at
// session start when TERMS changed; edit glossary.ts, never this output.
export function glossaryMarkdown(): string {
  return [
    '<!-- eval-glossary mod가 hooks/glossary.ts에서 생성합니다. 직접 고치지 말고 glossary.ts를 고치십시오. -->',
    '',
    '# Eval 용어 (eval-glossary)',
    '',
    '- 이 목록은 채점 프롬프트 eval 하네스(generative-ai-service의 eval/report, 골드셋·평가 루프)를 다루는 글에만 적용합니다. 다른 주제에서 같은 표기가 나오면(예: 교육과정 층위의 L1, 캐시 L1, A1 용지) 이 정의를 쓰지 않고 그 맥락의 뜻을 따릅니다.',
    '- 「맥락 한정」 표시가 붙은 용어는 특히 다른 분야에서 흔한 표기이므로, 글의 주제가 eval 하네스일 때만 이 뜻으로 읽습니다.',
    '- eval 하네스를 다루는 응답, 문서, Claude Docs 문서, 아티팩트, PR에서 아래 용어를 쓸 때는 그 글에서 처음 나오는 곳에 괄호로 뜻을 풀어 씁니다. 예: nMAE(교사 총점 대비 정규화 평균 절대 오차). 이후에는 짧게 씁니다.',
    '- 그런 글 중 아래 용어를 3개 이상 쓰는 Claude Docs 문서나 리포트에는 앞부분에 「용어」 표(용어 · 뜻)를 두고, 그 글에 쓰인 용어만 넣습니다.',
    '- eval 하네스 맥락에서는 정의를 하네스에 맞춥니다. 목록에 없는 용어는 평소처럼 풀어 씁니다.',
    '',
    ...TERMS.map(t => `- **${t.term}**${t.context ? ' (맥락 한정)' : ''}: ${t.short}`),
    '',
  ].join('\n')
}
