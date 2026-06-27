import 'package:eventos_app/core/errors/app_exception.dart';
import 'package:eventos_app/core/errors/error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ErrorMapper', () {
    test('nao expoe a mensagem tecnica de excecoes genericas', () {
      final mapped = ErrorMapper.fromObject(Exception('falha-upload'));

      expect(
        mapped.userMessage,
        'Ocorreu um erro inesperado. Tente novamente em instantes.',
      );
      expect(mapped.technicalMessage, contains('falha-upload'));
      expect(mapped.toString(), mapped.userMessage);
    });

    test('preserva mensagens de AppException criadas para o usuario', () {
      final mapped = ErrorMapper.fromObject(
        AppException.validation('Selecione pelo menos uma imagem.'),
      );

      expect(mapped.userMessage, 'Selecione pelo menos uma imagem.');
      expect(mapped.type, AppErrorType.validation);
    });

    test('usa mensagem especifica por contexto de storage', () {
      final mapped = ErrorMapper.fromObject(
        Exception('put-file-failed'),
        fallbackType: AppErrorType.storage,
      );

      expect(
        mapped.userMessage,
        'Nao foi possivel enviar a imagem agora. Tente novamente em instantes.',
      );
      expect(mapped.technicalMessage, contains('put-file-failed'));
    });
  });
}
