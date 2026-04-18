import 'package:flutter/material.dart';

import '../../core/page_transitions.dart';
import '../../core/theme/app_theme.dart';
import 'add_transaction_page.dart';
import 'wallet_ledger_tab.dart';
import 'wallet_nft_tab.dart';

enum _WalletSection { ledger, nft }

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  _WalletSection _section = _WalletSection.ledger;

  Future<void> _openAddTransactionPage() async {
    await Navigator.of(
      context,
    ).push(fadeSlideRoute(const AddTransactionPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('钱包')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingL,
              AppTheme.spacingM,
              AppTheme.spacingL,
              0,
            ),
            child: _WalletSectionSwitch(
              section: _section,
              onChanged: (section) => setState(() => _section = section),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Expanded(
            child: IndexedStack(
              index: _section.index,
              children: const [WalletLedgerTab(), WalletNftTab()],
            ),
          ),
        ],
      ),
      floatingActionButton: _section == _WalletSection.ledger
          ? FloatingActionButton.extended(
              onPressed: _openAddTransactionPage,
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              icon: const Icon(Icons.add_rounded),
              label: const Text('记一笔'),
            )
          : null,
    );
  }
}

class _WalletSectionSwitch extends StatelessWidget {
  final _WalletSection section;
  final ValueChanged<_WalletSection> onChanged;

  const _WalletSectionSwitch({required this.section, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.neuSubtle,
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: '账本',
              selected: section == _WalletSection.ledger,
              onTap: () => onChanged(_WalletSection.ledger),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SegmentButton(
              label: 'NFT 收藏',
              selected: section == _WalletSection.nft,
              onTap: () => onChanged(_WalletSection.nft),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyle.body.copyWith(
              color: selected ? Colors.white : AppTheme.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
