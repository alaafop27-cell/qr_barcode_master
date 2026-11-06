import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/models/scan_record.dart';
import '../../core/services/history_repository.dart';
import '../../core/utils/code_parser.dart';
import '../result/result_screen.dart';

enum _Filter { all, scanned, generated, favorites }

/// Everything scanned or generated, stored locally on the device.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  _Filter _filter = _Filter.all;
  String _query = '';

  bool _matches(ScanRecord r) {
    final okFilter = switch (_filter) {
      _Filter.all => true,
      _Filter.scanned => r.source == ScanSource.scanned,
      _Filter.generated => r.source == ScanSource.generated,
      _Filter.favorites => r.favorite,
    };
    if (!okFilter) return false;
    if (_query.isEmpty) return true;
    return r.rawValue.toLowerCase().contains(_query.toLowerCase());
  }

  String _filterLabel(_Filter f) => context.tr(switch (f) {
        _Filter.all => 'All',
        _Filter.scanned => 'Scanned',
        _Filter.generated => 'Generated',
        _Filter.favorites => 'Favorites',
      });

  Future<void> _confirmClear(HistoryRepository repo) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('Clear history?')),
        content:
            Text(ctx.tr('All saved scans and generated codes will be deleted.')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ctx.tr('Cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(ctx.tr('Clear'))),
        ],
      ),
    );
    if (yes == true) await repo.clear();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HistoryRepository>();
    final items = repo.items.where(_matches).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('History')),
        actions: [
          if (repo.items.isNotEmpty)
            IconButton(
              tooltip: context.tr('Clear all'),
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _confirmClear(repo),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SearchBar(
              hintText: context.tr('Search'),
              leading: const Icon(Icons.search),
              elevation: const WidgetStatePropertyAll(0),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                for (final f in _Filter.values) ...[
                  ChoiceChip(
                    label: Text(_filterLabel(f)),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(child: Text(context.tr('Nothing here yet')))
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) => _tile(context, repo, items[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, HistoryRepository repo, ScanRecord r) {
    final parsed =
        CodeParser.parse(r.rawValue, format: r.format, tr: context.tr);
    final cs = Theme.of(context).colorScheme;
    final kind = context
        .tr(r.source == ScanSource.generated ? 'Generated' : 'Scanned');

    return Dismissible(
      key: ValueKey(r.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: cs.errorContainer,
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: 24),
        child: Icon(Icons.delete, color: cs.onErrorContainer),
      ),
      onDismissed: (_) {
        final deleted = context.tr('Deleted');
        final undo = context.tr('Undo');
        repo.delete(r.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(deleted),
            action: SnackBarAction(label: undo, onPressed: () => repo.add(r)),
          ),
        );
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cs.primaryContainer,
          child: Icon(parsed.type.icon, color: cs.onPrimaryContainer),
        ),
        title: Text(parsed.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${context.tr(parsed.type.label)}  •  '
          '${context.tr(prettyFormat(r.format))}  •  $kind\n'
          '${context.strings.dateTime(r.createdAt)}',
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: Icon(r.favorite ? Icons.star : Icons.star_border),
          color: r.favorite ? Colors.amber : null,
          onPressed: () => repo.toggleFavorite(r.id),
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ResultScreen(record: r)),
        ),
      ),
    );
  }
}
