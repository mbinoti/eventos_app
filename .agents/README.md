# Mobile Agents and Skills

Este diretorio concentra skills e guias para acelerar desenvolvimento Flutter/Dart com padrao de time profissional.

## Estrutura

- `.agents/skills/`: skills reutilizaveis por tarefa.
- `.github/agents/`: agents especializados por etapa do ciclo mobile.

## Fluxo recomendado

1. Planejar feature com arquitetura e contratos de dados.
2. Implementar UI/estado/repositories.
3. Cobrir com testes (unit, widget, integracao) e quality gates.
4. Preparar release com versionamento e distribuicao.
5. Monitorar crashes, performance e sinais de produto em producao.

## Skills novas adicionadas

- `flutter-build-platform-adaptive-mobile-ui`
- `flutter-mobile-release-pipeline`
- `flutter-mobile-observability`
- `flutter-offline-first-data-sync`
- `flutter-mobile-security-baseline`

## Agents novos adicionados

- `mobile-feature-factory`
- `mobile-quality-guardian`
- `mobile-release-commander`

## Como usar

- Para uma feature end-to-end, use o agent `mobile-feature-factory`.
- Para hardening e gates antes de merge, use `mobile-quality-guardian`.
- Para preparar e publicar versao, use `mobile-release-commander`.
