/// Feedback tipado a partir do resultado real da API (nunca sucesso antecipado).
enum ApiFeedbackKind { success, error, pending }

class ApiFeedback {
  const ApiFeedback({required this.kind, required this.message});

  final ApiFeedbackKind kind;
  final String message;

  factory ApiFeedback.success(String message) =>
      ApiFeedback(kind: ApiFeedbackKind.success, message: message);

  factory ApiFeedback.error(String message) =>
      ApiFeedback(kind: ApiFeedbackKind.error, message: message);

  factory ApiFeedback.pending([String message = 'Solicitação recebida. Processamento em andamento.']) =>
      ApiFeedback(kind: ApiFeedbackKind.pending, message: message);
}

/// Converte status HTTP + corpo opcional em mensagem amigável (pt-BR).
String friendlyApiMessage(int statusCode, {Object? body, String? action}) {
  final fromBody = _safeBodyMessage(body);
  if (statusCode == 202) {
    return 'Solicitação recebida. Processamento em andamento.';
  }
  if (statusCode >= 200 && statusCode < 300) {
    return action == null || action.isEmpty ? 'Operação concluída com sucesso.' : action;
  }
  if (fromBody != null) return fromBody;
  return switch (statusCode) {
    0 => 'Sem conexão com a API. Verifique a rede e tente de novo.',
    400 || 422 => 'Revise os dados informados e tente de novo.',
    401 => 'Sessão expirada. Entre de novo para continuar.',
    403 => 'Você não tem permissão para esta ação.',
    404 => 'Registro não encontrado. Atualize a tela e tente de novo.',
    409 => 'Os dados mudaram. Recarregue e revise antes de salvar.',
    429 => 'Muitas tentativas. Aguarde um momento e tente de novo.',
    >= 500 => 'Serviço indisponível no momento. Tente de novo em instantes.',
    _ => 'Não foi possível concluir a operação.',
  };
}

String? _safeBodyMessage(Object? body) {
  if (body is! Map) return null;
  final error = body['error'];
  if (error is! Map) return null;
  final message = error['message'];
  if (message is! String) return null;
  final trimmed = message.trim();
  if (trimmed.isEmpty) return null;
  final lower = trimmed.toLowerCase();
  if (lower.contains('stack') || lower.contains('exception') || lower.contains('sql')) {
    return null;
  }
  if (trimmed.length > 180) return null;
  return trimmed;
}
