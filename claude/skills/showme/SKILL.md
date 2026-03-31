---
name: showme
description: 작업 결과를 showboat 데모 문서로 정리하고 mdgate로 웹 서빙. "결과 보여줘", "문서로 정리", "showme" 등의 요청에 반응.
allowed-tools: Bash(uvx showboat *), Bash(uvx mdgate *), Read, Glob, Grep
---

# showme — 작업 결과를 데모 문서로 정리

작업 결과를 `uvx showboat`로 실행 가능한 마크다운 문서로 만들고, `uvx mdgate`로 웹에서 볼 수 있게 서빙한다.

## 워크플로우

1. **문서 생성** — `uvx showboat init <file> <title>`
2. **내용 작성** — note(설명)와 exec(코드 실행+출력 캡처)를 반복
3. **실패 시 정정** — `uvx showboat pop <file>`로 마지막 항목 제거 후 재시도
4. **검증** — `uvx showboat verify <file>`로 모든 코드 블록 재실행 확인
5. **서빙** — `uvx mdgate <file>`로 웹 페이지로 서빙

## 명령어 레퍼런스

`uvx showboat -h` 및 `uvx mdgate -h` 참조.

## 주요 유스케이스

1. **논리적 증명 문서** — 작업이 올바르게 동작함을 exec 실행 결과로 증명
2. **코드 설명 문서** — 작성한 코드의 내용과 테스트 결과를 note + exec로 정리
3. **이미지 수집 문서** — 세션 중 산재된 Figma 익스포트, 브라우저 스크린샷 등을 image로 한 문서에 모음

## 호출 방식

사용자가 별도 지시 없이 `/showme`만 호출하면, 현재 대화 컨텍스트에서 문서화할 내용을 판단하여 자동으로 문서를 구성한다. 판단이 어려우면 무엇을 문서화할지 질문한다.

## 작성 원칙

- exec의 stdout 출력을 확인하고, 실패하면 pop 후 재시도
- 설명(note)은 간결하게, 코드(exec)가 스스로 말하게
- 문서 완성 후 반드시 verify로 검증 (이미지만 있는 문서는 verify 불필요)
- verify 통과 후 mdgate로 서빙
