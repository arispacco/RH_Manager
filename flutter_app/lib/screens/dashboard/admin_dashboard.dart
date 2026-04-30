import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  static const _pendingApprovals = [
    _Company(
      name: 'Nexus Technologies',
      domain: 'nexus-tech.com',
      employees: 325,
      appliedAt: '2h ago',
      contactName: 'Sarah Jenkins',
      contactEmail: 'sarah@nexus-tech.com',
    ),
    _Company(
      name: 'Aura Logistics',
      domain: 'auralogistics.co.uk',
      employees: 120,
      appliedAt: '5h ago',
      contactName: 'David Chen',
      contactEmail: 'd.chen@auralogistics.co.uk',
    ),
    _Company(
      name: 'Vanguard Retail',
      domain: 'vanguard-retail.com',
      employees: 550,
      appliedAt: '1d ago',
      contactName: 'Marcus Thorne',
      contactEmail: 'admin@vanguard-retail.com',
    ),
  ];

  static const _activeWorkspaces = [
    _Workspace(
        name: 'Omni Corp',
        domain: 'omnicorp.inc',
        users: 1245,
        plan: 'Enterprise',
        active: true),
    _Workspace(
        name: 'Stark Industries',
        domain: 'stark.com',
        users: 432,
        plan: 'Premium',
        active: true),
    _Workspace(
        name: 'Wayne Enterprises',
        domain: 'wayne.corp',
        users: 48,
        plan: 'Starter',
        active: false),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Platform Overview', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'Manage global company accounts and workspace approvals.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        Text(
          'Pending Approvals',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        for (final company in _pendingApprovals) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFFE7EEFF),
                        child: Text(
                          company.name[0],
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              company.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${company.domain} • ${company.employees} employees',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        company.appliedAt,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${company.contactName} • ${company.contactEmail}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: () {},
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFE9F9F0),
                            foregroundColor: const Color(0xFF1E7C4A),
                          ),
                          child: const Text('Approve'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          child: const Text('Reject'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 8),
        Text(
          'Active Workspaces',
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Column(
              children: [
                for (final workspace in _activeWorkspaces) ...[
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFF1F4FA),
                      child: Text(
                        workspace.name[0],
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    title: Text(
                      workspace.name,
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text('${workspace.domain} • ${workspace.plan}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${workspace.users} users',
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: workspace.active
                                ? const Color(0xFFE9F9F0)
                                : const Color(0xFFEFF1F4),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            workspace.active ? 'Active' : 'Paused',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: workspace.active
                                  ? const Color(0xFF1E7C4A)
                                  : const Color(0xFF5E6270),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (workspace != _activeWorkspaces.last)
                    const Divider(height: 1),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Company {
  const _Company({
    required this.name,
    required this.domain,
    required this.employees,
    required this.appliedAt,
    required this.contactName,
    required this.contactEmail,
  });

  final String name;
  final String domain;
  final int employees;
  final String appliedAt;
  final String contactName;
  final String contactEmail;
}

class _Workspace {
  const _Workspace({
    required this.name,
    required this.domain,
    required this.users,
    required this.plan,
    required this.active,
  });

  final String name;
  final String domain;
  final int users;
  final String plan;
  final bool active;
}
