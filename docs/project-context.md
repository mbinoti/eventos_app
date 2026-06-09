# Contexto do Projeto: Eventos App

## Sobre o App

O **Eventos App** é um aplicativo Flutter para divulgação e gestão simples de eventos, o app trabalha com feed de eventos carregado do Firebase Firestore, cadastro administrativo de eventos com upload de imagens para Firebase Storage, contador de curtidas lido do Firestore, interação visual de curtida, compartilhamento e navegação principal com abas de eventos, agenda e promoções.

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
- Notificações push devem ser úteis e moderadas.
