---
name: flutter-mobile-observability
description: Establish production observability for mobile apps with crash reporting, structured logs, performance traces, and incident triage workflow.
---

# Flutter Mobile Observability

## Objective

Padronizar coleta de sinais de producao para detectar, diagnosticar e priorizar problemas rapidamente.

## Baseline stack

- Crash reporting: Firebase Crashlytics ou Sentry.
- Product analytics: Firebase Analytics/Amplitude/Mixpanel.
- Performance traces: Firebase Performance ou OpenTelemetry bridge.
- Structured logs: eventos com contexto (feature, userId hash, release, device).

## Event naming

Use padrao consistente:

- `screen_view_<screen_name>`
- `action_<domain>_<verb>`
- `error_<domain>_<type>`

## Incident triage

1. Confirmar versao afetada e plataforma.
2. Agrupar por stack trace e endpoint.
3. Medir impacto: usuarios ativos e taxa de erro.
4. Definir severidade e owner.
5. Aplicar hotfix ou rollback de feature flag.

## Guardrails

- Nunca logar PII em texto puro.
- Redigir payloads sensiveis em logs.
- Incluir `buildNumber`, `gitSha` e `environment` em todo erro.

## Checklist

- [ ] Captura global de excecao Flutter e Zone.
- [ ] Inicializacao de crash SDK por ambiente.
- [ ] Dashboards com crash-free users e ANR.
- [ ] Alertas por regressao de erro por release.
- [ ] Playbook de incidente documentado.
