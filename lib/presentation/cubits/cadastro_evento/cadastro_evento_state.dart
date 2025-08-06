/// Classe base abstrata para os estados do [CadastroEventoCubit].
///
/// Define os possíveis estados do processo de cadastro de eventos.
abstract class CadastroEventoState {}

/// Estado inicial do cadastro de eventos.
class CadastroEventoInitial extends CadastroEventoState {}

/// Estado que indica que o cadastro está em andamento.
class CadastroEventoLoading extends CadastroEventoState {}

/// Estado que indica que o cadastro foi realizado com sucesso.
class CadastroEventoSucesso extends CadastroEventoState {}

/// Estado que indica que ocorreu um erro durante o cadastro.
///
/// [mensagem] contém a descrição do erro ocorrido.
class CadastroEventoErro extends CadastroEventoState {
  /// Mensagem de erro.
  final String mensagem;

  /// Construtor do [CadastroEventoErro].
  CadastroEventoErro(this.mensagem);
}
