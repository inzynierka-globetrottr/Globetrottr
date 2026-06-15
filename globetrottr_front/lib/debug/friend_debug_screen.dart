import 'package:flutter/material.dart';
import 'package:globetrottr_front/features/friends/data/friends_service.dart';
import 'package:globetrottr_front/features/friends/data/friendship_response.dart';

class FriendDebugScreen extends StatefulWidget {
  const FriendDebugScreen({super.key});

  @override
  State<FriendDebugScreen> createState() => _FriendDebugScreenState();
}

class _FriendDebugScreenState extends State<FriendDebugScreen> {
  final FriendsService _service = FriendsService();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String _output = 'Output will appear here...';
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _setOutput(String text) {
    setState(() {
      _output = text;
      _isLoading = false;
    });
  }

  void _setLoading() {
    setState(() => _isLoading = true);
  }

  String _formatList(List<FriendshipResponse> list) {
    if (list.isEmpty) return '(empty list)';
    return list
        .map((r) => '• ${r.username} | status: ${r.status} | incoming: ${r.isIncomingRequest}')
        .join('\n');
  }

  Future<void> _run(Future<void> Function() action) async {
    _setLoading();
    try {
      await action();
    } catch (e) {
      _setOutput('ERROR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Friends Service Debug')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // --- OUTPUT BOX ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Text(
                      _output,
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
            ),

            const SizedBox(height: 24),
            const Text('NO INPUT REQUIRED', style: TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),

            // --- GET FRIENDS ---
            ElevatedButton(
              onPressed: () => _run(() async {
                final result = await _service.getFriends();
                _setOutput('getFriends():\n${_formatList(result)}');
              }),
              child: const Text('GET /api/friends'),
            ),

            // --- GET RECEIVED INVITES ---
            ElevatedButton(
              onPressed: () => _run(() async {
                final result = await _service.getReceivedInvites();
                _setOutput('getReceivedInvites():\n${_formatList(result)}');
              }),
              child: const Text('GET /api/friends/invites'),
            ),

            // --- GET SENT INVITES ---
            ElevatedButton(
              onPressed: () => _run(() async {
                final result = await _service.getSentInvites();
                _setOutput('getSentInvites():\n${_formatList(result)}');
              }),
              child: const Text('GET /api/friends/invites/sent'),
            ),

            const SizedBox(height: 24),
            const Text('REQUIRES USERNAME INPUT', style: TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),

            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Target username',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 8),

            // --- SEND INVITE ---
            ElevatedButton(
              onPressed: () => _run(() async {
                await _service.sendInvite(_usernameController.text.trim());
                _setOutput('sendInvite() success\nSent to: ${_usernameController.text.trim()}');
              }),
              child: const Text('POST /api/friends/invites'),
            ),

            // --- ACCEPT INVITE ---
            ElevatedButton(
              onPressed: () => _run(() async {
                await _service.acceptInvite(_usernameController.text.trim());
                _setOutput('acceptInvite() success\nAccepted: ${_usernameController.text.trim()}');
              }),
              child: const Text('POST /api/friends/invites/{username}/accept'),
            ),

            // --- DELETE RELATIONSHIP ---
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => _run(() async {
                await _service.deleteRelationship(_usernameController.text.trim());
                _setOutput('deleteRelationship() success\nDeleted: ${_usernameController.text.trim()}');
              }),
              child: const Text('DELETE /api/friends/{username}'),
            ),

            const SizedBox(height: 24),
            const Text('SEARCH', style: TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),

            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search query (min 3 chars)',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 8),

            // --- SEARCH USERS ---
            ElevatedButton(
              onPressed: () => _run(() async {
                final result = await _service.searchUsers(_searchController.text.trim());
                _setOutput('searchUsers("${_searchController.text.trim()}"):\n${_formatList(result)}');
              }),
              child: const Text('GET /api/friends/search?query='),
            ),

          ],
        ),
      ),
    );
  }
}