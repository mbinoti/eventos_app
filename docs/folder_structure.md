# Estrutura de Pastas - Eventos App

Estrutura simples adotada para o app:

```text
lib/
  app_theme.dart
  firebase_options.dart
  main.dart
  models/
  repositories/
  presentation/
    pages/
    routes/
    viewmodels/
    widgets/
  services/
```

## Responsabilidades

### `lib/models/`

Modelos usados pelo app, como `Event`.

### `lib/repositories/`

Camada de acesso a dados vista pelo app. Repositories escondem Firebase, Storage ou outra fonte externa da UI.

### `lib/services/`

Serviços de infraestrutura e integrações, como notificações, variáveis de ambiente e APIs externas.

### `lib/presentation/pages/`

Telas completas do app.

Exemplos atuais:

- `event_feed_screen.dart`
- `cadastro_evento_screen.dart`
- `admin_panel_screen.dart`

### `lib/presentation/routes/`

Navegação e composição das rotas principais.

### `lib/presentation/viewmodels/`

Estado e ações consumidos pelas telas. ViewModels chamam repositories e notificam a UI.

### `lib/presentation/widgets/`

Widgets reutilizáveis e componentes menores, como cards e controles compartilhados.

## Fluxo recomendado

```text
Page/Widget -> ViewModel -> Repository -> Service/Firebase
```

Regras simples:

- UI não acessa Firebase ou Storage diretamente.
- ViewModel não conhece widgets.
- Repository centraliza leitura, escrita e detalhes externos.
- Modelos devem ser simples e previsíveis.
- Evite criar `data/`, `domain/`, `usecases/` ou `datasources/` até existir necessidade real.

## Testes

Quando criar testes, espelhe a estrutura principal:

```text
test/
  models/
  repositories/
  presentation/
    viewmodels/
    widgets/
```
