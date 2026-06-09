---
name: flutter-mobile-security-baseline
description: Apply a practical security baseline for Flutter mobile apps including secret handling, transport hardening, and build protections.
---

# Flutter Mobile Security Baseline

## Objective

Reduzir risco de vazamento de dados, abuso de API e engenharia reversa com controles minimos obrigatorios.

## Controls

1. Guardar segredo apenas em armazenamento seguro (`flutter_secure_storage` ou Keychain/Keystore).
2. Nao embutir chaves privadas no app.
3. Aplicar token curto com refresh seguro.
4. Ativar obfuscation e split debug info em release.
5. Bloquear screenshots em telas sensiveis quando aplicavel.
6. Considerar certificate pinning para APIs criticas.

## Build hardening

- Android: minify/obfuscate, assinatura protegida, Play Integrity.
- iOS: ATS habilitado, capabilities minimas, keychain access group revisado.

## API hardening

- Limite de taxa no backend por usuario/dispositivo.
- Assinar requests sensiveis quando necessario.
- Validar todas as entradas no servidor.

## Checklist

- [ ] Revisar onde segredos estao armazenados.
- [ ] Verificar flags de build release.
- [ ] Validar politica de token e expiracao.
- [ ] Revisar regras de firewall/backend para abuso.
- [ ] Rodar checklist de privacidade e logs.
