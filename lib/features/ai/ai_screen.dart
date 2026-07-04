import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/providers.dart';
import '../../core/services/ai_service.dart';

class AiScreen extends ConsumerStatefulWidget {
  const AiScreen({super.key});

  @override
  ConsumerState<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends ConsumerState<AiScreen> {
  final TextEditingController _chatController = TextEditingController();
  final List<MessageItem> _messages = [];
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    // Welcome message from the assistant
    _messages.add(MessageItem(
      text: "Hello! I'm your Smart Finance AI Assistant. I can analyze your transactions, predict next month's bills, flag unusual expenses, or give savings tips. Ask me a question or tap a prompt template below!",
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(MessageItem(text: text, isUser: true));
      _isGenerating = true;
    });

    _chatController.clear();

    try {
      final aiService = ref.read(aiServiceProvider);
      final response = await aiService.askAssistant(text);
      
      setState(() {
        _messages.add(MessageItem(text: response, isUser: false));
      });
    } catch (e) {
      setState(() {
        _messages.add(MessageItem(text: "Sorry, I encountered an error: $e", isUser: false));
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final aiService = ref.watch(aiServiceProvider);
    final insights = aiService.generateInsights();

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Financial Assistant'),
      ),
      body: Column(
        children: [
          // Dynamic Insights Cards list
          if (insights.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: insights.length,
                itemBuilder: (context, index) {
                  final card = insights[index];
                  return _buildInsightCard(card);
                },
              ),
            ),
          ],
          
          const Divider(height: 24),

          // Chat thread view
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                // Return messages in reverse order since reverse: true
                final msg = _messages[_messages.length - 1 - index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          if (_isGenerating)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),

          // Suggestion Prompt Templates
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Theme.of(context).cardColor.withValues(alpha: 0.4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildPromptChip('How much did I spend this month?'),
                  _buildPromptChip('Show food expenses.'),
                  _buildPromptChip('Which category costs the most?'),
                  _buildPromptChip('How can I save money?'),
                  _buildPromptChip('Predict next month\'s expenses.'),
                  _buildPromptChip('Detect unusual spending.'),
                  _buildPromptChip('Summarize my finances.'),
                ],
              ),
            ),
          ),

          // Chat input field
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      decoration: InputDecoration(
                        hintText: 'Ask assistant anything...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton.small(
                    onPressed: () => _sendMessage(_chatController.text),
                    child: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(AiInsightCard card) {
    Color typeColor = Colors.blue;
    if (card.type == 'warning') typeColor = Colors.orange;
    if (card.type == 'success') typeColor = Colors.green;

    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: typeColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: typeColor.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  card.title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: typeColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                card.valueChange,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: typeColor),
              ),
            ],
          ),
          Text(
            card.description,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageItem msg) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser 
              ? Theme.of(context).colorScheme.primary 
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 16),
          ),
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            color: isUser ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildPromptChip(String query) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(query, style: const TextStyle(fontSize: 11)),
        onPressed: () => _sendMessage(query),
      ),
    );
  }
}

class MessageItem {
  final String text;
  final bool isUser;

  MessageItem({required this.text, required this.isUser});
}
