---
name: flutter-mobile-release-pipeline
description: Execute professional mobile release flow with versioning, signing, staged rollout, release notes, and rollback plan.
---

# Flutter Mobile Release Pipeline

## Objective

Entregar builds previsiveis para Android e iOS com rastreabilidade e baixo risco operacional.

## Release flow

1. Definir versao semantica e build number.
2. Congelar escopo e atualizar changelog.
3. Rodar quality gates (analyze, testes, cobertura minima, smoke).
4. Gerar artifacts assinados.
5. Publicar em rollout gradual.
6. Monitorar metricas de regressao por 24-48h.

## Commands (example)

```bash
flutter analyze
flutter test
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
flutter build ipa --release
```

## Rollout strategy

- Android: staged rollout (5% -> 20% -> 50% -> 100%).
- iOS: phased release com observacao por etapa.

## Release checklist

- [ ] Versao e build number atualizados.
- [ ] Notas de release para negocio e suporte.
- [ ] Assets de loja revisados.
- [ ] Crash-free baseline definido para comparacao.
- [ ] Plano de rollback documentado.

## Rollback triggers

- Queda relevante de crash-free users.
- Erro severo de autenticacao/pagamento.
- Regressao de performance em fluxo critico.
