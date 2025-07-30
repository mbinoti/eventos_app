abstract class CadastroEventoState {}

class CadastroEventoInitial extends CadastroEventoState {}

class CadastroEventoLoading extends CadastroEventoState {}

class CadastroEventoSucesso extends CadastroEventoState {}

class CadastroEventoErro extends CadastroEventoState {
  final String mensagem;
  CadastroEventoErro(this.mensagem);
}
