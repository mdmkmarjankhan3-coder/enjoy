import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/badge_service.dart';
import '../../../services/games_service.dart';
import '../../../services/supabase_service.dart';

class TicTacToePage extends StatefulWidget {
  const TicTacToePage({super.key, required this.matchId});
  final String matchId;
  @override
  State<TicTacToePage> createState() => _TicTacToePageState();
}

class _TicTacToePageState extends State<TicTacToePage> {
  final _c = SupabaseService.client;
  Map<String, dynamic>? _match;
  final List<String> _board = List.filled(9, '');
  bool _myTurn = false;
  String? _statusText;
  RealtimeChannel? _ch;
  String get _uid => _c.auth.currentUser!.id;
  
  @override
  void initState() {
    super.initState();
    _init();
  }
  
  Future<void> _init() async {
    var m = await _c
       .from('game_matches')
       .select()
       .eq('id', widget.matchId)
       .single();
    if (m['status'] == 'waiting' && m['player1']!= _uid) {
      await GamesService.joinMatch(widget.matchId);
      m = await _c
         .from('game_matches')
         .select()
         .eq('id', widget.matchId)
         .single();
    }
    if (!mounted) return;
    setState(() {
      _match = m;
      _myTurn = m['player1'] == _uid;
    });
    _ch = _c
       .channel('match_${widget.matchId}')
       .onBroadcast(
          event: 'move',
          callback: (msg) {
            final p = msg as Map;
            _applyRemote(p['index'] as int, p['symbol'] as String);
          },
        )
       .subscribe();
  }
  
  String get _mySymbol => _match?['player1'] == _uid? 'X' : 'O';
  String? _ownerOf(String symbol) =>
      symbol == 'X'? _match?['player1'] as String? : _match?['player2'] as String?;
  
  bool _checkWin(String s) {
    const lines = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6],
    ];
    for (final l in lines) {
      if (_board[l[0]] == s && _board[l[1]] == s && _board[l[2]] == s) {
        return true;
      }
    }
    return false;
  }
  
  void _tap(int i) {
    if (!_myTurn || _board[i].isNotEmpty || _statusText!= null) return;
    _apply(i, _mySymbol);
    _ch?.sendBroadcastMessage(
        event: 'move', payload: {'index': i, 'symbol': _mySymbol});
  }
  
  void _apply(int i, String symbol) {
    setState(() => _board[i] = symbol);
    if (_checkWin(symbol)) {
      _finish(_ownerOf(symbol));
    } else if (!_board.contains('')) { // <-- এই লাইন টা ঠিক আছে
      _finish(null);
    } else {
      setState(() => _myTurn =!_myTurn);
    }
  }
  
  void _applyRemote(int i, String symbol) {
    if (_board[i].isNotEmpty || _statusText!= null) return;
    _apply(i, symbol);
  }
  
  Future<void> _finish(String? winnerId) async {
    setState(() {
      _statusText = winnerId == null
         ? 'Draw!'
          : (winnerId == _uid? 'আপনি জিতেছেন!' : 'আপনি হেরেছেন');
    });
    await GamesService.finishMatch(widget.matchId, winnerId);
    if (winnerId == _uid) {
      await BadgeService.award('game_champion');
    }
  }
  
  @override
  void dispose() {
    _ch?.unsubscribe();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tic Tac Toe 1v1')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_statusText!= null)
            Text(
              _statusText!,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          Text(
            'আপনি: $_mySymbol • ${_myTurn? 'আপনার চাল' : 'অপেক্ষা করুন'}',
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 300,
              height: 300,
              child: GridView.builder(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3),
                itemCount: 9,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => _tap(i),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        _board[i],
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_statusText!= null)
            FilledButton(
              onPressed: () => context.go('/home'),
              child: const Text('Home'),
            ),
        ],
      ),
    );
  }
}