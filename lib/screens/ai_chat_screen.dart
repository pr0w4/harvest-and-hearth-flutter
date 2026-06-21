import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat_message.dart';
import '../providers/app_provider.dart';
import 'meal_calendar_planner_screen.dart';
import '../theme/app_theme.dart';

/// Full-screen AI chat conversation with the assistant.
class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key, this.initialPrompt});

  final String? initialPrompt;

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final initial = widget.initialPrompt?.trim();
    if (initial != null && initial.isNotEmpty) {
      _inputController.text = initial;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    _inputController.clear();
    _focusNode.unfocus();

    await context.read<AppProvider>().sendChatMessage(text);
    _scrollToBottom();
  }

  Future<void> _sendQuickPrompt(String prompt) async {
    _focusNode.unfocus();
    await context.read<AppProvider>().sendChatMessage(prompt);
    _scrollToBottom();
  }

  Future<void> _retryLastMessage() async {
    await context.read<AppProvider>().retryLastChatMessage();
    _scrollToBottom();
  }

  Future<void> _pushMealPlanToShopping(String content) async {
    final provider = context.read<AppProvider>();
    final added = await provider.importShoppingPlanFromChat(content);
    if (!mounted) return;
    final t = provider.t;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added > 0
              ? t('chat_to_plan_success').replaceAll('{count}', '$added')
              : t('chat_to_plan_empty'),
        ),
      ),
    );
    if (added > 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MealCalendarPlannerScreen()),
      );
    }
  }

  void _confirmClearChat() {
    final t = context.read<AppProvider>().t;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('chat_clear')),
        content: Text(t('chat_clear_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t('common_cancel')),
          ),
          FilledButton(
            onPressed: () {
              context.read<AppProvider>().clearChat();
              Navigator.pop(ctx);
            },
            child: Text(t('common_ok')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final t = provider.t;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: _HearthieLogo(
                size: 20,
                tint: cs.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('chat_title'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.hearthieSky.withAlpha(34),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.hearthieGold.withAlpha(150),
                      ),
                    ),
                    child: Text(
                      'Preview',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.hearthieNight,
                      ),
                    ),
                  ),
                  if (provider.isAiTyping)
                    Text(
                      t('chat_typing'),
                      style:
                          TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (provider.chatMessages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: t('chat_clear'),
              onPressed: _confirmClearChat,
            ),
        ],
      ),
      body: Column(
        children: [
          // Inventory context pill
          _InventoryContextPill(
            inventoryCount: provider.inventory.length,
            t: t,
            cs: cs,
          ),

          // Messages
          Expanded(
            child: provider.chatMessages.isEmpty
                ? _EmptyChatState(t: t, cs: cs)
                : _ChatMessagesList(
                    messages: provider.chatMessages,
                    isAiTyping: provider.isAiTyping,
                    scrollController: _scrollController,
                    t: t,
                    cs: cs,
                    onPushToShopping: _pushMealPlanToShopping,
                  ),
          ),

          // Quick prompts (only when chat is empty)
          if (provider.chatMessages.isEmpty)
            _QuickPromptsBar(
              prompts: provider.chatQuickPrompts,
              onTap: _sendQuickPrompt,
              t: t,
            ),

          // Error banner
          if (provider.chatError != null)
            _ErrorBanner(
              error: provider.chatError!,
              t: t,
              cs: cs,
              canRetry: provider.canRetryLastChat,
              onRetry: _retryLastMessage,
            ),

          if (provider.canRegenerate && !provider.isAiTyping)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 2, 12, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () =>
                      context.read<AppProvider>().regenerateLastChatResponse(),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Regenerate'),
                ),
              ),
            ),

          // Input area
          _ChatInputBar(
            controller: _inputController,
            focusNode: _focusNode,
            isLoading: provider.isAiTyping,
            onSend: _sendMessage,
            t: t,
            cs: cs,
          ),
        ],
      ),
    );
  }
}

// ── Inventory Context Pill ──────────────────────────────────────────────────

class _InventoryContextPill extends StatelessWidget {
  final int inventoryCount;
  final String Function(String) t;
  final ColorScheme cs;

  const _InventoryContextPill({
    required this.inventoryCount,
    required this.t,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(100),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withAlpha(105)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 14,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            inventoryCount > 0
                ? t('chat_context_pill')
                    .replaceAll('{count}', '$inventoryCount')
                : t('chat_no_context'),
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty Chat State ────────────────────────────────────────────────────────

class _EmptyChatState extends StatelessWidget {
  final String Function(String) t;
  final ColorScheme cs;

  const _EmptyChatState({required this.t, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withAlpha(77),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.restaurant_rounded,
                size: 48,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              t('chat_empty_state'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: cs.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chat Messages List ──────────────────────────────────────────────────────

class _ChatMessagesList extends StatelessWidget {
  final List<ChatMessage> messages;
  final bool isAiTyping;
  final ScrollController scrollController;
  final String Function(String) t;
  final ColorScheme cs;
  final Future<void> Function(String content) onPushToShopping;

  const _ChatMessagesList({
    required this.messages,
    required this.isAiTyping,
    required this.scrollController,
    required this.t,
    required this.cs,
    required this.onPushToShopping,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withAlpha(85)),
      ),
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        itemCount: messages.length + (isAiTyping ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == messages.length && isAiTyping) {
            return _TypingIndicator(cs: cs);
          }
          final msg = messages[index];
          return _ChatBubble(
            message: msg,
            cs: cs,
            t: t,
            onPushToShopping: onPushToShopping,
          );
        },
      ),
    );
  }
}

// ── Chat Bubble ─────────────────────────────────────────────────────────────

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final ColorScheme cs;
  final String Function(String) t;
  final Future<void> Function(String content) onPushToShopping;

  const _ChatBubble({
    required this.message,
    required this.cs,
    required this.t,
    required this.onPushToShopping,
  });

  bool get _canPushToShopping {
    if (message.role != ChatRole.assistant) return false;
    final m = message.content.toLowerCase();
    return (m.contains('thực đơn') ||
            m.contains('meal plan') ||
            m.contains('shopping') ||
            m.contains('cần mua')) &&
        (m.contains('-') || m.contains('•'));
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    final time =
        '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: cs.primaryContainer,
              child: _HearthieLogo(size: 16, tint: cs.primary),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? cs.primary : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: Border.all(
                  color: isUser
                      ? cs.secondary.withAlpha(105)
                      : cs.outlineVariant.withAlpha(120),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    message.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: isUser ? cs.onPrimary : cs.onSurface,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 10,
                      color: isUser
                          ? cs.onPrimary.withAlpha(153)
                          : cs.onSurfaceVariant,
                    ),
                  ),
                  if (_canPushToShopping) ...[
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => onPushToShopping(message.content),
                        icon: const Icon(
                          Icons.playlist_add_check_circle_rounded,
                          size: 16,
                        ),
                        label: Text(
                          t('chat_to_plan'),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 14,
              backgroundColor: cs.secondaryContainer,
              child: Icon(Icons.person_rounded, size: 16, color: cs.secondary),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Typing Indicator ────────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  final ColorScheme cs;
  const _TypingIndicator({required this.cs});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: widget.cs.primaryContainer,
            child: _HearthieLogo(size: 16, tint: widget.cs.primary),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: widget.cs.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: SizedBox(
              width: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (i) {
                          final progress = (_controller.value * 3 - i) % 1.0;
                          final scale =
                              0.5 + 0.5 * (1 - (2 * progress - 1).abs());
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            child: Transform.scale(
                              scale: scale,
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: widget.cs.onSurfaceVariant,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(
                    2,
                    (i) => Container(
                      margin: EdgeInsets.only(bottom: i == 0 ? 6 : 0),
                      height: 8,
                      width: i == 0 ? 92 : 70,
                      decoration: BoxDecoration(
                        color: widget.cs.onSurfaceVariant.withAlpha(45),
                        borderRadius: BorderRadius.circular(99),
                      ),
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

class _HearthieLogo extends StatelessWidget {
  const _HearthieLogo({
    required this.size,
    required this.tint,
  });

  final double size;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        tint.withAlpha(235),
        BlendMode.srcATop,
      ),
      child: Image.asset(
        'public/hearthie/hearthie.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

// ── Quick Prompts Bar ───────────────────────────────────────────────────────

class _QuickPromptsBar extends StatelessWidget {
  final List<String> prompts;
  final void Function(String) onTap;
  final String Function(String) t;

  const _QuickPromptsBar({
    required this.prompts,
    required this.onTap,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              t('chat_quick_prompts'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: prompts.map((prompt) {
              return ActionChip(
                label: Text(prompt),
                labelStyle: TextStyle(fontSize: 12, color: cs.onSurface),
                avatar: const Icon(Icons.lightbulb_outline, size: 16),
                onPressed: () => onTap(prompt),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Error Banner ────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String error;
  final String Function(String) t;
  final ColorScheme cs;
  final VoidCallback onRetry;
  final bool canRetry;

  const _ErrorBanner({
    required this.error,
    required this.t,
    required this.cs,
    required this.onRetry,
    required this.canRetry,
  });

  String _displayMessage() {
    if (error == 'timeout') {
      return '${t('chat_error')} (timeout)';
    }
    if (error == 'api_key_missing') {
      return '${t('chat_error')} (API key)';
    }
    return t('chat_error');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.error.withAlpha(120)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: cs.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _displayMessage(),
              style: TextStyle(
                fontSize: 13,
                color: cs.onErrorContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: canRetry ? onRetry : null,
            child: Text(
              t('common_retry'),
              style: TextStyle(color: cs.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chat Input Bar ──────────────────────────────────────────────────────────

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final VoidCallback onSend;
  final String Function(String) t;
  final ColorScheme cs;

  const _ChatInputBar({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onSend,
    required this.t,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withAlpha(105)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  decoration: InputDecoration(
                    hintText: t('chat_placeholder'),
                    hintStyle: TextStyle(color: cs.onSurfaceVariant),
                    filled: true,
                    fillColor: cs.surfaceContainerHighest.withAlpha(90),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: cs.outlineVariant),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: FloatingActionButton.small(
                onPressed: isLoading ? null : onSend,
                backgroundColor:
                    isLoading ? cs.surfaceContainerHighest : cs.primary,
                child: isLoading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.onSurfaceVariant,
                        ),
                      )
                    : Icon(Icons.send_rounded, color: cs.onPrimary, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
