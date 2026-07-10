import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/status_banner.dart';
import '../../members/data/member_repository.dart';
import '../data/team_repository.dart';

class CreateTeamScreen extends ConsumerStatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  ConsumerState<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends ConsumerState<CreateTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final teamId = await ref
          .read(teamRepositoryProvider)
          .createTeam(_nameController.text.trim());
      if (!mounted) return;
      ref.invalidate(teamsProvider);
      ref.invalidate(memberRankingsProvider);
      ref.invalidate(memberMeProvider);
      Navigator.of(context).pop(teamId);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = error is ApiException
            ? error.message
            : '팀을 생성하지 못했습니다.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('팀 만들기')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.add_business_outlined, size: 34),
                      SizedBox(height: 12),
                      Text(
                        '새로운 팀의 리더가 됩니다',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text('팀을 생성하면 자동으로 LEADER 역할이 부여됩니다.'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null) ...[
                  StatusBanner(message: _errorMessage!),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  maxLength: 20,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: '팀 이름',
                    helperText: '4~20자, 다른 팀과 중복할 수 없습니다.',
                    prefixIcon: Icon(Icons.shield_outlined),
                  ),
                  validator: (value) {
                    final length = value?.trim().length ?? 0;
                    if (length < 4 || length > 20) {
                      return '팀 이름은 4~20자로 입력하세요.';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add),
                  label: const Text('팀 생성'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
