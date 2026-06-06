import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/domain/auth_provider.dart';
import '../data/employee_perfil_model.dart';
import '../data/employee_perfil_repository.dart';

/// Perfil complementar do usuário logado.
final myEmployeePerfilProvider = FutureProvider<EmployeePerfil?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null || userId.isEmpty) return null;
  return ref.read(employeePerfilRepositoryProvider).getByEmployeeId(userId);
});

/// Perfil complementar de qualquer colaborador por ID — usado pela EqualizationPage.
final employeeProfileByEmployeeIdProvider =
    FutureProvider.family<EmployeePerfil?, String>((ref, employeeId) async {
  if (employeeId.isEmpty) return null;
  return ref.read(employeePerfilRepositoryProvider).getByEmployeeId(employeeId);
});
