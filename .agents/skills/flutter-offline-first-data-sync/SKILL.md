---
name: flutter-offline-first-data-sync
description: Build local-first data flows with background sync, conflict handling, and retry strategy. Use when a mobile feature must work with unstable or absent network.
---

# Flutter Offline-First Data Sync

## Objective

Implementar fluxo local-first: app sempre le do armazenamento local e sincroniza com backend em segundo plano.

## When to use

- Funcionalidade precisa funcionar sem internet.
- Equipe quer reduzir latencia percebida.
- Ha risco de perda de dados por conexao intermitente.

## Core patterns

1. Persistir no banco local primeiro (write-through local).
2. Enfileirar acao pendente para sync remoto.
3. Executar sync com retry exponencial e jitter.
4. Resolver conflitos por regra explicita.
5. Expor estado de sync no ViewModel.

## Suggested architecture

- `Service`: cliente HTTP/Firebase.
- `LocalStore`: drift/sqflite/hive.
- `Repository`: merge local+remote e politicas de sync.
- `SyncEngine`: fila, retry e reconciliacao.

## Conflict policy options

- Last-write-wins com `updatedAt` UTC.
- Campo por campo quando merge e seguro.
- Lock otimista com `version` para detectar write skew.

## Checklist

- [ ] Definir modelo com `id`, `updatedAt`, `version`, `syncStatus`.
- [ ] Implementar leitura sempre no banco local.
- [ ] Registrar operacoes pendentes (`create`, `update`, `delete`).
- [ ] Implementar worker de sync com retry exponencial.
- [ ] Marcar e exibir conflitos para resolucao.
- [ ] Testar cenarios offline, reconexao e conflito.

## Validation scenarios

- App cria item offline e sincroniza ao reconectar.
- App edita mesmo item em dois dispositivos e aplica politica.
- Falha 500 mantem item na fila e tenta novamente.
