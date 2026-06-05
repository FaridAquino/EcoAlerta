import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

class EcoTextField extends StatefulWidget {
  final String label;
  final String placeholder;
  final IconData prefixIcon;
  final bool isPassword;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;

  const EcoTextField({
    super.key,
    required this.label,
    required this.placeholder,
    required this.prefixIcon,
    required this.controller,
    this.isPassword = false,
    this.validator,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<EcoTextField> createState() => _EcoTextFieldState();
}

class _EcoTextFieldState extends State<EcoTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.isPassword && _obscure,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          style: GoogleFonts.inter(fontSize: 16, color: AppColors.onSurface),
          decoration: InputDecoration(
            hintText: widget.placeholder,
            hintStyle: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            prefixIcon: Icon(widget.prefixIcon, color: AppColors.onSurfaceVariant, size: 20),
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppColors.onSurfaceVariant,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
