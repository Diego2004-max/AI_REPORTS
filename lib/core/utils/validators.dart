class AppValidators {
  static String? required(String? value, {String field = 'Este campo'}) {
    if (value == null || value.trim().isEmpty) return '$field es obligatorio';
    return null;
  }

  static String? minLength(String? value, int min, {String field = 'Este campo'}) {
    if (value == null || value.trim().isEmpty) return '$field es obligatorio';
    if (value.trim().length < min) return 'Mínimo $min caracteres';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ingresa tu correo';
    final reg = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w]{2,4}$');
    if (!reg.hasMatch(value.trim())) return 'Correo no válido';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa tu contraseña';
    if (value.length < 8) return 'Mínimo 8 caracteres';
    if (!RegExp(r'\d').hasMatch(value)) return 'Debe contener al menos un número';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Confirma tu contraseña';
    if (value != password) return 'Las contraseñas no coinciden';
    return null;
  }

  static String? reportDescription(String? value) {
    if (value == null || value.trim().isEmpty) return 'La descripción es obligatoria';
    if (value.trim().length < 10) return 'Mínimo 10 caracteres';
    return null;
  }
}
