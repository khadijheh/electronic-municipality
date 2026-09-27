import 'package:flutter/material.dart' hide Text;
import 'package:electronic_municipality_final/l10n/localized_text.dart';
import 'package:electronic_municipality_final/l10n/app_localizations.dart';
import 'package:flutter/services.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/di.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/repositories/auth_repository.dart';
import '../../../../shared/widgets/municipality_widgets.dart';

const double _signupFieldMaxWidth = 241;
const double _signupFieldHeight = 46;
const double _signupFieldFontSize = 16;
const BorderRadius _signupFieldRadius = BorderRadius.all(
  Radius.circular(10),
);
const TextStyle _signupFieldLabelStyle = TextStyle(
  color: Color(0xFF1B1C19),
  fontSize: _signupFieldFontSize,
  height: 1.5,
  fontWeight: FontWeight.w400,
);
const TextStyle _signupFieldTextStyle = TextStyle(
  color: Color(0xFF1B1C19),
  fontSize: _signupFieldFontSize,
  height: 1.2,
);

class AuthSignupScreen extends StatefulWidget {
  const AuthSignupScreen({super.key});

  @override
  State<AuthSignupScreen> createState() => _AuthSignupScreenState();
}

class _AuthSignupScreenState extends State<AuthSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _birthPlaceController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  DateTime? _birthDate;
  CitizenGender? _selectedGender;
  int? _selectedGovernorateId;
  int? _selectedMunicipalityId;
  List<GovernorateOption> _governorates = const [];
  List<MunicipalityOption> _municipalities = const [];
  bool _isLoadingLocations = true;
  bool _isLoadingMunicipalities = false;
  bool _needsSpecialCare = false;
  bool _acceptedTerms = false;
  bool _showTermsError = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadGovernorates();
  }

  Future<void> _loadGovernorates() async {
    setState(() {
      _isLoadingLocations = true;
      _errorMessage = null;
    });

    try {
      final governorates = await DI.auth.getGovernorates();
      if (!mounted) return;
      setState(() => _governorates = governorates);
    } catch (error, stackTrace) {
      debugPrint('LOAD GOVERNORATES ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _errorMessage = _userFacingError(
            error,
            fallback: 'تعذر تحميل المحافظات حاليًا. حاول مرة أخرى لاحقًا.',
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocations = false);
      }
    }
  }

  Future<void> _selectGovernorate(int? governorateId) async {
    setState(() {
      _selectedGovernorateId = governorateId;
      _selectedMunicipalityId = null;
      _municipalities = const [];
      _errorMessage = null;
      _isLoadingMunicipalities = governorateId != null;
    });

    if (governorateId == null) return;

    try {
      final municipalities = await DI.auth.getMunicipalities(
        governorateId: governorateId,
      );
      if (!mounted || _selectedGovernorateId != governorateId) return;
      setState(() => _municipalities = municipalities);
    } catch (error, stackTrace) {
      debugPrint('LOAD MUNICIPALITIES ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted && _selectedGovernorateId == governorateId) {
        setState(() {
          _errorMessage = _userFacingError(
            error,
            fallback: 'تعذر تحميل البلديات حاليًا. حاول مرة أخرى لاحقًا.',
          );
        });
      }
    } finally {
      if (mounted && _selectedGovernorateId == governorateId) {
        setState(() => _isLoadingMunicipalities = false);
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _nationalIdController.dispose();
    _birthDateController.dispose();
    _birthPlaceController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year, now.month, now.day),
    );

    if (selectedDate == null || !mounted) return;

    setState(() {
      _birthDate = selectedDate;
      _birthDateController.text = _formatDate(selectedDate);
      _errorMessage = null;
    });
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$month/$day/${date.year}';
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final formIsValid = _formKey.currentState?.validate() ?? false;
    final termsAreValid = _acceptedTerms;

    setState(() {
      _showTermsError = !termsAreValid;
      _errorMessage = null;
    });

    if (!formIsValid ||
        !termsAreValid ||
        _birthDate == null ||
        _selectedGender == null ||
        _selectedMunicipalityId == null) {
      return;
    }

    final registration = CitizenRegistration(
      fullName: _fullNameController.text.trim(),
      nationalId: _nationalIdController.text.trim(),
      dateOfBirth: _birthDate!,
      placeOfBirth: _birthPlaceController.text.trim(),
      municipalityId: _selectedMunicipalityId!,
      gender: _selectedGender!,
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      needsSpecialCare: _needsSpecialCare,
      acceptedTerms: _acceptedTerms,
    );

    setState(() => _isLoading = true);

    try {
      await DI.auth.registerCitizen(registration: registration);

      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.shell,
        (route) => false,
      );
    } catch (error, stackTrace) {
      debugPrint('REGISTER CITIZEN ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _errorMessage = _userFacingError(
            error,
            fallback: 'تعذر إنشاء الحساب حاليًا. حاول مرة أخرى لاحقًا.',
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _goToLogin() {
    if (_isLoading) return;

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacementNamed(AppRoutes.login);
    }
  }

  String _userFacingError(
    Object error, {
    required String fallback,
  }) {
    if (error is! ApiException) return fallback;

    switch (error.kind) {
      case ApiExceptionKind.server:
      case ApiExceptionKind.invalidResponse:
      case ApiExceptionKind.configuration:
      case ApiExceptionKind.unknown:
        return fallback;
      default:
        return error.message;
    }
  }

  String? _validateFullName(String? value) {
    final fullName = value?.trim() ?? '';
    if (fullName.isEmpty) return 'الاسم الكامل مطلوب';
    if (fullName.split(RegExp(r'\s+')).length < 3) {
      return 'أدخل الاسم الثلاثي كما في الهوية';
    }
    return null;
  }

  String? _validateRequired(String? value, String message) {
    return value == null || value.trim().isEmpty ? message : null;
  }

  String? _validateNationalId(String? value) {
    final nationalId = value?.trim() ?? '';
    if (nationalId.isEmpty) return 'الرقم الوطني مطلوب';
    if (!RegExp(r'^\d{11}$').hasMatch(nationalId)) {
      return 'يجب أن يتكون الرقم الوطني من 11 رقماً';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) return 'رقم الهاتف مطلوب';
    if (!RegExp(r'^09\d{8}$').hasMatch(phone)) {
      return 'أدخل رقماً سورياً صحيحاً يبدأ بـ 09';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'البريد الإلكتروني مطلوب';

    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailPattern.hasMatch(email)
        ? null
        : 'أدخل بريداً إلكترونياً صحيحاً';
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'كلمة المرور مطلوبة';
    if (password.length < 8) {
      return 'يجب ألا تقل كلمة المرور عن 8 محارف';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F4),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(painter: _SignupBackgroundPainter()),
          SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(1.5, 0, 1.5, 29),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 387),
                  child: _SignupCard(
                    child: Form(
                      key: _formKey,
                      child: AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _SignupHeader(),
                            const SizedBox(height: 32),
                            if (_errorMessage != null) ...[
                              _SignupErrorMessage(
                                message: _errorMessage!,
                              ),
                              if (_governorates.isEmpty && !_isLoadingLocations)
                                Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: TextButton.icon(
                                    onPressed: _loadGovernorates,
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: const Text('إعادة المحاولة'),
                                  ),
                                ),
                              if (_selectedGovernorateId != null &&
                                  _municipalities.isEmpty &&
                                  !_isLoadingMunicipalities)
                                Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: TextButton.icon(
                                    onPressed: () => _selectGovernorate(
                                      _selectedGovernorateId,
                                    ),
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: const Text(
                                      'إعادة تحميل البلديات',
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 24),
                            ],
                            _SignupSection(
                              title: 'البيانات الشخصية',
                              icon: Icons.badge_outlined,
                              minHeight: 370,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _SignupTextField(
                                    fieldKey: const ValueKey(
                                      'signup_full_name_field',
                                    ),
                                    label: 'الاسم الكامل (كما في الهوية)',
                                    hint: 'الاسم الثلاثي',
                                    controller: _fullNameController,
                                    maxWidth: _signupFieldMaxWidth,
                                    validator: _validateFullName,
                                    autofillHints: const [
                                      AutofillHints.name,
                                    ],
                                    textInputAction: TextInputAction.next,
                                  ),
                                  const SizedBox(height: 16),
                                  _SignupTextField(
                                    fieldKey: const ValueKey(
                                      'signup_national_id_field',
                                    ),
                                    label: 'الرقم الوطني',
                                    hint: '00000000000',
                                    controller: _nationalIdController,
                                    maxWidth: _signupFieldMaxWidth,
                                    textDirection: TextDirection.ltr,
                                    textAlign: TextAlign.left,
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.next,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(11),
                                    ],
                                    validator: _validateNationalId,
                                  ),
                                  const SizedBox(height: 16),
                                  _SignupDropdownField<CitizenGender>(
                                    fieldKey: const ValueKey(
                                      'signup_gender_field',
                                    ),
                                    label: 'الجنس',
                                    hint: 'اختر الجنس...',
                                    value: _selectedGender,
                                    items: CitizenGender.values,
                                    itemLabel: (gender) =>
                                        gender == CitizenGender.male
                                            ? 'ذكر'
                                            : 'أنثى',
                                    maxWidth: _signupFieldMaxWidth,
                                    onChanged: _isLoading
                                        ? null
                                        : (value) {
                                            setState(() {
                                              _selectedGender = value;
                                              _errorMessage = null;
                                            });
                                          },
                                    validator: (value) =>
                                        value == null ? 'اختر الجنس' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  _SignupDateField(
                                    controller: _birthDateController,
                                    onTap: _pickBirthDate,
                                    validator: (_) => _birthDate == null
                                        ? 'تاريخ الميلاد مطلوب'
                                        : null,
                                  ),
                                  const SizedBox(height: 16),
                                  _SignupTextField(
                                    fieldKey: const ValueKey(
                                      'signup_birth_place_field',
                                    ),
                                    label: 'مكان الولادة',
                                    hint: 'المحافظة - المدينة',
                                    controller: _birthPlaceController,
                                    maxWidth: _signupFieldMaxWidth,
                                    validator: (value) => _validateRequired(
                                      value,
                                      'مكان الولادة مطلوب',
                                    ),
                                    textInputAction: TextInputAction.next,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            _SignupSection(
                              title: 'بيانات السكن',
                              icon: Icons.location_on_outlined,
                              minHeight: 242,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _SignupDropdownField<int>(
                                    fieldKey: const ValueKey(
                                      'signup_governorate_field',
                                    ),
                                    label: 'المحافظة',
                                    hint: _isLoadingLocations
                                        ? 'جاري تحميل المحافظات...'
                                        : 'اختر المحافظة...',
                                    value: _selectedGovernorateId,
                                    items: _governorates
                                        .map((item) => item.id)
                                        .toList(growable: false),
                                    itemLabel: (id) => _governorates
                                        .firstWhere((item) => item.id == id)
                                        .name,
                                    maxWidth: _signupFieldMaxWidth,
                                    onChanged: _isLoading || _isLoadingLocations
                                        ? null
                                        : _selectGovernorate,
                                    validator: (value) =>
                                        value == null ? 'اختر المحافظة' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  _SignupDropdownField<int>(
                                    fieldKey: const ValueKey(
                                      'signup_municipality_field',
                                    ),
                                    label: 'البلدية التابع لها',
                                    hint: _isLoadingMunicipalities
                                        ? 'جاري تحميل البلديات...'
                                        : 'اختر البلدية...',
                                    value: _selectedMunicipalityId,
                                    items: _municipalities
                                        .map((item) => item.id)
                                        .toList(growable: false),
                                    itemLabel: (id) => _municipalities
                                        .firstWhere((item) => item.id == id)
                                        .name,
                                    maxWidth: _signupFieldMaxWidth,
                                    onChanged: _isLoading ||
                                            _isLoadingMunicipalities ||
                                            _selectedGovernorateId == null
                                        ? null
                                        : (value) {
                                            setState(() {
                                              _selectedMunicipalityId = value;
                                              _errorMessage = null;
                                            });
                                          },
                                    validator: (value) =>
                                        value == null ? 'اختر البلدية' : null,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            _SignupSection(
                              title: 'معلومات الدخول',
                              icon: Icons.lock_outline_rounded,
                              minHeight: 324,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _SignupTextField(
                                    fieldKey: const ValueKey(
                                      'signup_phone_field',
                                    ),
                                    label: 'رقم الهاتف الجوال',
                                    hint: '09X XXX XXXX',
                                    controller: _phoneController,
                                    maxWidth: 236,
                                    inputHeight: 45,
                                    textDirection: TextDirection.ltr,
                                    textAlign: TextAlign.left,
                                    keyboardType: TextInputType.phone,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [
                                      AutofillHints.telephoneNumber,
                                    ],
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(10),
                                    ],
                                    validator: _validatePhone,
                                  ),
                                  const SizedBox(height: 13),
                                  _SignupTextField(
                                    fieldKey: const ValueKey(
                                      'signup_email_field',
                                    ),
                                    label: 'البريد الإلكتروني',
                                    hint: 'example@mail.sy',
                                    controller: _emailController,
                                    maxWidth: 253,
                                    inputHeight: 45,
                                    textDirection: TextDirection.ltr,
                                    textAlign: TextAlign.left,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [
                                      AutofillHints.email,
                                    ],
                                    validator: _validateEmail,
                                  ),
                                  const SizedBox(height: 13),
                                  _SignupTextField(
                                    fieldKey: const ValueKey(
                                      'signup_password_field',
                                    ),
                                    label: 'كلمة المرور',
                                    hint: '',
                                    controller: _passwordController,
                                    maxWidth: 241,
                                    obscureText: true,
                                    autocorrect: false,
                                    enableSuggestions: false,
                                    autofillHints: const [
                                      AutofillHints.newPassword,
                                    ],
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) {
                                      if (!_isLoading) _submit();
                                    },
                                    validator: _validatePassword,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            _SignupOptions(
                              needsSpecialCare: _needsSpecialCare,
                              acceptedTerms: _acceptedTerms,
                              showTermsError: _showTermsError,
                              enabled: !_isLoading,
                              onSpecialCareChanged: (value) {
                                setState(
                                  () => _needsSpecialCare = value,
                                );
                              },
                              onTermsChanged: (value) {
                                setState(() {
                                  _acceptedTerms = value;
                                  _showTermsError = false;
                                });
                              },
                            ),
                            const SizedBox(height: 24),
                            _SignupActions(
                              isLoading: _isLoading,
                              onSubmit: _submit,
                              onLogin: _goToLogin,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignupCard extends StatelessWidget {
  const _SignupCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFC0C8C4)),
        borderRadius: const BorderRadius.all(
          Radius.circular(18.0),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 30,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(
            height: 8,
            child: ColoredBox(color: Color(0xFF775A19)),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _SignupHeader extends StatelessWidget {
  const _SignupHeader();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 279),
      child: Column(
        children: [
          const SizedBox(
            width: 150,
            height: 156,
            child: MunicipalityLogo(size: 150, framed: false),
          ),
          const SizedBox(height: 10),
          Text(
            'إنشاء حساب مواطن',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: const Color(0xFF00261E),
                  fontSize: 24,
                  height: 32 / 24,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 18),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 308),
            child: Text(
              'بوابة الخدمات الإلكترونية للجمهورية العربية السورية. يرجى إدخال بياناتك الرسمية بدقة.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF404845),
                    fontSize: 16,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignupSection extends StatelessWidget {
  const _SignupSection({
    required this.title,
    required this.icon,
    required this.minHeight,
    required this.child,
  });

  final String title;
  final IconData icon;
  final double minHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF9F4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x4DC0C8C4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(icon, size: 21, color: const Color(0xFF775A19)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF00261E),
                        fontSize: 20,
                        height: 28 / 20,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _SignupTextField extends StatelessWidget {
  const _SignupTextField({
    required this.fieldKey,
    required this.label,
    required this.hint,
    required this.controller,
    required this.maxWidth,
    required this.validator,
    this.inputHeight = _signupFieldHeight,
    this.obscureText = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.inputFormatters,
    this.onFieldSubmitted,
    this.textDirection,
    this.textAlign = TextAlign.start,
  });

  final Key fieldKey;
  final String label;
  final String hint;
  final TextEditingController controller;
  final double maxWidth;
  final double inputHeight;
  final bool obscureText;
  final bool autocorrect;
  final bool enableSuggestions;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onFieldSubmitted;
  final TextDirection? textDirection;
  final TextAlign textAlign;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    final effectiveDirection =
        textDirection ?? Directionality.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          textAlign: TextAlign.start,
          style: _signupFieldLabelStyle,
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: TextFormField(
              key: fieldKey,
              controller: controller,
              validator: (value) {
                final error = validator(value);
                return error == null ? null : context.tr(error);
              },
              obscureText: obscureText,
              obscuringCharacter: '•',
              autocorrect: autocorrect,
              enableSuggestions: enableSuggestions,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              autofillHints: autofillHints,
              inputFormatters: inputFormatters,
              onFieldSubmitted: onFieldSubmitted,
              textDirection: effectiveDirection,
              textAlign: textAlign,
              style: _signupFieldTextStyle,
              decoration: _signupInputDecoration(
                hint: context.tr(hint),
                height: inputHeight,
                hintDirection: effectiveDirection,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SignupDateField extends StatelessWidget {
  const _SignupDateField({
    required this.controller,
    required this.onTap,
    required this.validator,
  });

  final TextEditingController controller;
  final VoidCallback onTap;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'تاريخ الميلاد',
          textAlign: TextAlign.start,
          style: _signupFieldLabelStyle,
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: _signupFieldMaxWidth,
            ),
            child: TextFormField(
              key: const ValueKey('signup_birth_date_field'),
              controller: controller,
              validator: (value) {
                final error = validator(value);
                return error == null ? null : context.tr(error);
              },
              readOnly: true,
              onTap: onTap,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.left,
              style: _signupFieldTextStyle,
              decoration: _signupInputDecoration(
                hint: 'mm/dd/yyyy',
                height: _signupFieldHeight,
                hintDirection: TextDirection.ltr,
              ).copyWith(
                suffixIcon: const Icon(
                  Icons.calendar_today_outlined,
                  color: Color(0xFF6B7280),
                  size: 16,
                ),
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 40,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SignupDropdownField<T> extends StatelessWidget {
  const _SignupDropdownField({
    required this.fieldKey,
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.maxWidth,
    required this.onChanged,
    required this.validator,
  });

  final Key fieldKey;
  final String label;
  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T item) itemLabel;
  final double maxWidth;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T> validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          textAlign: TextAlign.start,
          style: _signupFieldLabelStyle,
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: DropdownButtonFormField<T>(
              key: fieldKey,
              value: value,
              validator: (value) {
                final error = validator(value);
                return error == null ? null : context.tr(error);
              },
              onChanged: onChanged,
              isExpanded: true,
              menuMaxHeight: 320,
              icon: const Icon(
                Icons.arrow_drop_down,
                color: Color(0xFFC0C8C4),
                size: 22,
              ),
              dropdownColor: Colors.white,
              style: _signupFieldTextStyle,
              hint: Text(
                hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _signupFieldTextStyle,
              ),
              items: items
                  .map(
                    (item) => DropdownMenuItem<T>(
                      value: item,
                      child: Text(
                        itemLabel(item),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(growable: false),
              decoration: _signupInputDecoration(
                hint: '',
                height: _signupFieldHeight,
                hintDirection: Directionality.of(context),
              ).copyWith(
                contentPadding: const EdgeInsetsDirectional.fromSTEB(
                  12,
                  10,
                  8,
                  10,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SignupOptions extends StatelessWidget {
  const _SignupOptions({
    required this.needsSpecialCare,
    required this.acceptedTerms,
    required this.showTermsError,
    required this.enabled,
    required this.onSpecialCareChanged,
    required this.onTermsChanged,
  });

  final bool needsSpecialCare;
  final bool acceptedTerms;
  final bool showTermsError;
  final bool enabled;
  final ValueChanged<bool> onSpecialCareChanged;
  final ValueChanged<bool> onTermsChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SignupCheckboxRow(
            fieldKey: const ValueKey('signup_special_care_checkbox'),
            value: needsSpecialCare,
            enabled: enabled,
            onChanged: onSpecialCareChanged,
            label: const Text(
              'شخص يحتاج إلى رعاية خاصة (ذوي الاحتياجات الخاصة، كبار السن)',
              style: TextStyle(
                color: Color(0xFF1B1C19),
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SignupCheckboxRow(
            fieldKey: const ValueKey('signup_terms_checkbox'),
            value: acceptedTerms,
            enabled: enabled,
            showError: showTermsError,
            onChanged: onTermsChanged,
            label: const Text.rich(
              TextSpan(
                text: 'أوافق على ',
                children: [
                  TextSpan(
                    text: 'الشروط والأحكام',
                    style: TextStyle(
                      color: Color(0xFF00261E),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: ' وسياسة الخصوصية الخاصة بالبوابة.'),
                ],
              ),
              style: TextStyle(
                color: Color(0xFF1B1C19),
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),
          if (showTermsError)
            const Padding(
              padding: EdgeInsetsDirectional.only(start: 44, top: 4),
              child: Text(
                'يجب الموافقة على الشروط والأحكام',
                style: TextStyle(
                  color: AppColors.danger,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SignupCheckboxRow extends StatelessWidget {
  const _SignupCheckboxRow({
    required this.fieldKey,
    required this.value,
    required this.enabled,
    required this.onChanged,
    required this.label,
    this.showError = false,
  });

  final Key fieldKey;
  final bool value;
  final bool enabled;
  final bool showError;
  final ValueChanged<bool> onChanged;
  final Widget label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? () => onChanged(!value) : null,
      borderRadius: BorderRadius.circular(4),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 74),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  key: fieldKey,
                  value: value,
                  onChanged:
                      enabled ? (checked) => onChanged(checked ?? false) : null,
                  activeColor: const Color(0xFF00261E),
                  checkColor: Colors.white,
                  side: BorderSide(
                    color:
                        showError ? AppColors.danger : const Color(0xFFC0C8C4),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: label),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignupActions extends StatelessWidget {
  const _SignupActions({
    required this.isLoading,
    required this.onSubmit,
    required this.onLogin,
  });

  final bool isLoading;
  final VoidCallback onSubmit;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 60,
            child: FilledButton(
              key: const ValueKey('signup_submit_button'),
              onPressed: isLoading ? null : onSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00261E),
                disabledBackgroundColor:
                    const Color(0xFF00261E).withOpacity(0.55),
                foregroundColor: const Color(0xFFFFDEA5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFFFDEA5),
                      ),
                    )
                  : const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        textDirection: TextDirection.ltr,
                        children: [
                          Icon(
                            Icons.west_rounded,
                            size: 20,
                            color: Color(0xFFFFDEA5),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'إنشاء الحساب الرسمي',
                            style: TextStyle(
                              color: Color(0xFFFFDEA5),
                              fontSize: 20,
                              height: 28 / 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: [
                const Text(
                  'لديك حساب بالفعل؟',
                  style: TextStyle(
                    color: Color(0xFF404845),
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                TextButton(
                  key: const ValueKey('signup_login_button'),
                  onPressed: isLoading ? null : onLogin,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF775A19),
                    disabledForegroundColor:
                        const Color(0xFF775A19).withOpacity(0.45),
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('تسجيل الدخول'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SignupErrorMessage extends StatelessWidget {
  const _SignupErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.danger),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.danger,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

InputDecoration _signupInputDecoration({
  required String hint,
  required double height,
  required TextDirection hintDirection,
}) {
  const borderSide = BorderSide(color: Color(0xFFCBD2CE));
  const errorBorderSide = BorderSide(
    color: AppColors.danger,
    width: 1.25,
  );

  return InputDecoration(
    hintText: hint,
    hintTextDirection: hintDirection,
    hintStyle: const TextStyle(
      color: Color(0xFF6B7280),
      fontSize: _signupFieldFontSize,
      height: 1.2,
      fontWeight: FontWeight.w400,
    ),
    isDense: true,
    filled: true,
    fillColor: const Color(0xFFFFFEFC),
    constraints: BoxConstraints(minHeight: height),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 14,
      vertical: 10,
    ),
    errorMaxLines: 2,
    border: const OutlineInputBorder(
      borderRadius: _signupFieldRadius,
      borderSide: borderSide,
    ),
    enabledBorder: const OutlineInputBorder(
      borderRadius: _signupFieldRadius,
      borderSide: borderSide,
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: _signupFieldRadius,
      borderSide: BorderSide(
        color: Color(0xFF775A19),
        width: 1.75,
      ),
    ),
    errorBorder: const OutlineInputBorder(
      borderRadius: _signupFieldRadius,
      borderSide: errorBorderSide,
    ),
    focusedErrorBorder: const OutlineInputBorder(
      borderRadius: _signupFieldRadius,
      borderSide: BorderSide(
        color: AppColors.danger,
        width: 1.75,
      ),
    ),
  );
}

class _SignupBackgroundPainter extends CustomPainter {
  const _SignupBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFFBF9F4),
    );

    final softPaint = Paint()
      ..color = const Color(0x99EAE8E3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 56;
    final strongPaint = Paint()
      ..color = const Color(0x99E4E2DD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30;

    for (double y = -180; y < size.height + 260; y += 360) {
      final path = Path()
        ..moveTo(-150, y)
        ..lineTo(size.width * 0.5, y + 190)
        ..lineTo(size.width + 150, y);
      canvas.drawPath(path, softPaint);
    }

    for (double y = 20; y < size.height + 320; y += 520) {
      final path = Path()
        ..moveTo(-120, y + 180)
        ..lineTo(size.width * 0.5, y)
        ..lineTo(size.width + 120, y + 180);
      canvas.drawPath(path, strongPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignupBackgroundPainter oldDelegate) => false;
}
