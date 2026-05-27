# Contexto do Projeto: Eventos App

## Sobre o App

O **Eventos App** é um aplicativo Flutter para divulgação e gestão simples de eventos. No código atual, o app trabalha com feed de eventos carregado do Firebase Firestore, cadastro administrativo de eventos com upload de imagens para Firebase Storage, contador de curtidas lido do Firestore, interação visual de curtida, compartilhamento e navegação principal com abas de eventos, agenda e promoções.

O produto pode evoluir para inscrição, ingressos e check-in, mas a necessidade imediata do app é consolidar uma experiência confiável para publicar, visualizar e divulgar eventos.

## Estado atual observado no projeto

- Nome do pacote: `eventos_app`.
- Título exibido no app: `app Acontece Aqui`.
- Estado com `provider` e `ChangeNotifier`.
- Firebase configurado com `firebase_core`, `cloud_firestore`, `firebase_storage` e `firebase_messaging`.
- Feed principal em `lib/presentation/pages/event_feed_screen.dart`.
- Cadastro administrativo em `lib/presentation/pages/cadastro_evento_screen.dart`.
- ViewModels em `lib/presentation/viewmodels/`.
- Repositórios ativos em `lib/repositories/`.
- Modelo principal em `lib/models/event.dart`.
- Navegação principal com abas Eventos, Agenda e Promoções em `lib/presentation/routes/main_navigation_screen.dart`.
- Modo admin simples por argumento de inicialização `admin`; autenticação e regras administrativas ainda precisam ser definidas.
- Agenda e Promoções existem como abas, mas ainda funcionam como placeholders.
- Curtida no card é uma interação local animada; persistência da curtida no Firestore ainda não está implementada.
- `EventDetailPage` existe, mas a navegação a partir do card ainda não está conectada.
- Campo visual de comentários existe no cadastro, mas ainda não é salvo no documento do evento.
- Não há diretórios `test/` ou `integration_test/` observados no projeto.

Para a organização técnica atual, consulte `docs/folder_structure.md`.

## Proposta de valor

O app deve ajudar pessoas a descobrir eventos relevantes e permitir que administradores publiquem eventos com imagem, cidade e data de forma simples. A experiência precisa deixar claro:

- qual é o evento;
- quando acontece;
- onde acontece;
- qual imagem representa o evento;
- como compartilhar ou demonstrar interesse.

## Público principal

- Pessoas que procuram eventos por cidade, data ou interesse.
- Neste inicio de projeto, eu mesmo o dev do app vou publicando os eventos para testar o fluxo, mas a ideia depois é que seja fácil para outros administradores também.

## Jornada principal do usuário participante

1. Usuário abre o app.
2. Visualiza o feed de eventos.
3. Abre ou inspeciona um card de evento.
4. Curte ou compartilha um evento.
5. Consulta agenda ou promoções conforme essas áreas forem evoluídas.

## Jornada principal do administrador

1. Administrador acessa o app com permissão administrativa.
2. Abre o painel ou fluxo de cadastro.
3. Informa título, cidade, data e imagens do evento.
4. O app envia as imagens para o Firebase Storage.
5. O app cria o documento do evento no Firestore.
6. O evento aparece no feed.

## Escopo inicial recomendado

- Feed de eventos com carregamento, vazio e erro bem tratados.
- Cadastro administrativo de evento.
- Upload seguro de imagem.
- Detalhe ou card expandido de evento com dados essenciais.
- Curtida e compartilhamento.
- Agenda como evolução natural para eventos salvos ou próximos eventos.
- Promoções como área futura, sem atrapalhar o feed principal.
- Push notifications para novidades ou lembretes, com uso cuidadoso.

## Fora do escopo inicial

- Venda de ingresso.
- Pagamento real.
- Mapa de assentos.
- Check-in em tempo real.
- Marketplace completo para múltiplos organizadores.
- Chat entre participantes.
- Feed social complexo.
- Recomendação avançada por IA.

## Diretrizes de produto

- O feed deve ser confiável antes de adicionar fluxos mais complexos.
- O cadastro administrativo deve validar dados obrigatórios antes de gravar.
- O Firestore deve manter nomes de campos consistentes.
- Imagens quebradas ou ausentes precisam de fallback visual.
- Agenda e promoções devem ter propósito claro antes de virarem abas permanentes.
- Notificações push devem ser úteis e moderadas.
