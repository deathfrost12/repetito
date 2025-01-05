import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'ai_generate_dialog.dart';

class AddFlashcardDialog extends HookConsumerWidget {
  const AddFlashcardDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final animationController = useAnimationController(
      duration: const Duration(seconds: 2),
    );

    useEffect(() {
      animationController.repeat();
      return null;
    }, []);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          const Positioned.fill(
            child: ColoredBox(
              color: Colors.transparent,
            ),
          ),
          Positioned(
            top: size.height * 0.25,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                          color: theme.colorScheme.onSurface,
                        ),
                        Text(
                          '1/2',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_horiz),
                          onPressed: () {},
                          color: theme.colorScheme.onSurface,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                                child: InkWell(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => const AIGenerateDialog(),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: AnimatedBuilder(
                                    animation: animationController,
                                    builder: (context, child) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              theme.colorScheme.primary.withOpacity(0.1),
                                              theme.colorScheme.primary.withOpacity(0.2),
                                            ],
                                            stops: [
                                              animationController.value,
                                              (animationController.value + 0.5) % 1.0,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: theme.colorScheme.primary.withOpacity(0.1),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            TweenAnimationBuilder(
                                              tween: Tween<double>(begin: 0, end: 1),
                                              duration: const Duration(milliseconds: 300),
                                              builder: (context, value, child) {
                                                return Transform.rotate(
                                                  angle: animationController.value * 4 * 3.14,
                                                  child: Icon(
                                                    Icons.auto_awesome,
                                                    color: theme.colorScheme.primary,
                                                    size: 20,
                                                  ),
                                                );
                                              },
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: ShaderMask(
                                                shaderCallback: (bounds) {
                                                  return LinearGradient(
                                                    begin: Alignment.centerLeft,
                                                    end: Alignment.centerRight,
                                                    colors: [
                                                      theme.colorScheme.primary,
                                                      theme.colorScheme.primary.withBlue(
                                                        (theme.colorScheme.primary.blue + 40).clamp(0, 255),
                                                      ),
                                                    ],
                                                    stops: [
                                                      animationController.value,
                                                      (animationController.value + 0.5) % 1.0,
                                                    ],
                                                  ).createShader(bounds);
                                                },
                                                child: Text(
                                                  'Zeptat AI na vytvoření kartičky',
                                                  style: TextStyle(
                                                    color: theme.colorScheme.primary,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Zadejte výraz',
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surface,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: TextField(
                                        style: TextStyle(color: theme.colorScheme.onSurface),
                                        decoration: InputDecoration(
                                          hintText: 'Zde začněte psát svůj výraz',
                                          hintStyle: TextStyle(
                                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          _ActionButton(
                                            icon: Icons.translate,
                                            label: 'Jazyk',
                                            onTap: () {},
                                            theme: theme,
                                          ),
                                          const SizedBox(width: 8),
                                          _ActionButton(
                                            icon: Icons.image_outlined,
                                            onTap: () {},
                                            theme: theme,
                                          ),
                                          const SizedBox(width: 8),
                                          _ActionButton(
                                            icon: Icons.mic,
                                            onTap: () {},
                                            theme: theme,
                                            isHighlighted: true,
                                          ),
                                          const SizedBox(width: 8),
                                          _ActionButton(
                                            icon: Icons.lightbulb_outline,
                                            onTap: () {},
                                            theme: theme,
                                            isHighlighted: true,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Zadejte definici',
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surface,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: TextField(
                                        style: TextStyle(color: theme.colorScheme.onSurface),
                                        decoration: InputDecoration(
                                          hintText: 'Zde začněte psát svou definici',
                                          hintStyle: TextStyle(
                                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          _ActionButton(
                                            icon: Icons.translate,
                                            label: 'Jazyk',
                                            onTap: () {},
                                            theme: theme,
                                          ),
                                          const SizedBox(width: 8),
                                          _ActionButton(
                                            icon: Icons.image_outlined,
                                            onTap: () {},
                                            theme: theme,
                                          ),
                                          const SizedBox(width: 8),
                                          _ActionButton(
                                            icon: Icons.mic,
                                            onTap: () {},
                                            theme: theme,
                                            isHighlighted: true,
                                          ),
                                          const SizedBox(width: 8),
                                          _ActionButton(
                                            icon: Icons.lightbulb_outline,
                                            onTap: () {},
                                            theme: theme,
                                            isHighlighted: true,
                                          ),
                                          const SizedBox(width: 8),
                                          _ActionButton(
                                            icon: Icons.shuffle,
                                            label: 'Přidat další',
                                            onTap: () {},
                                            theme: theme,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: FilledButton(
                                  onPressed: () {},
                                  style: FilledButton.styleFrom(
                                    backgroundColor: theme.colorScheme.surface,
                                    foregroundColor: theme.colorScheme.onSurface,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                  ),
                                  child: const Text('Přidat kartu'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () {},
                                  style: FilledButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary,
                                    foregroundColor: theme.colorScheme.onPrimary,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                  ),
                                  child: const Text('Další karta'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onTap;
  final ThemeData theme;
  final bool isHighlighted;

  const _ActionButton({
    required this.icon,
    this.label,
    required this.onTap,
    required this.theme,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isHighlighted 
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            if (label != null) ...[
              const SizedBox(width: 8),
              Text(
                label!,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 