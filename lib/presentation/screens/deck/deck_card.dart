import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/deck_entity.dart';

class DeckCard extends StatelessWidget {
  final DeckEntity deck;
  
  const DeckCard({super.key, required this.deck});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.cardColor,
      elevation: 2,
      shadowColor: theme.colorScheme.shadow.withOpacity(0.1),
      clipBehavior: Clip.hardEdge,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          context.pushNamed(
            'deck_detail',
            pathParameters: {'id': deck.id},
            extra: deck,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.surface,
                theme.colorScheme.surface.withOpacity(0.95),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.shadow.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.style,
                        color: theme.colorScheme.onPrimaryContainer,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            deck.name,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (deck.description?.isNotEmpty ?? false) ...[
                            const SizedBox(height: 4),
                            Text(
                              deck.description!,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Vytvořeno ${_formatDate(deck.createdAt)}',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.edit_outlined,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          onPressed: () => _showEditDialog(context),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.play_arrow_rounded,
                            color: theme.colorScheme.primary,
                          ),
                          onPressed: () => _startStudy(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    // TODO: Implementovat dialog pro úpravu balíčku
  }

  void _startStudy(BuildContext context) {
    context.pushNamed(
      'study',
      pathParameters: {'id': deck.id},
      extra: deck,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}. ${date.month}. ${date.year}';
  }
} 