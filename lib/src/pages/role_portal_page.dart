import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/auth_user.dart';
import '../models/work.dart';
import '../services/ujikom_api_client.dart';
import '../widgets/nokomi_brand.dart';

class RolePortalPage extends StatefulWidget {
  const RolePortalPage({
    super.key,
    required this.session,
    required this.apiClient,
    required this.webBaseUrl,
  });

  final AuthSession session;
  final UjikomApiClient apiClient;
  final String webBaseUrl;

  @override
  State<RolePortalPage> createState() => _RolePortalPageState();
}

class _RolePortalPageState extends State<RolePortalPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final List<_PortalMenuItem> _menuItems = _buildMenuItems();
  late _PortalSection _currentSection = _menuItems.first.section;
  late Future<List<WorkSummary>> _worksFuture = widget.apiClient.fetchWorks();

  bool get isAdmin => widget.session.user.role == 'admin';

  List<_PortalMenuItem> _buildMenuItems() {
    if (isAdmin) {
      return const [
        _PortalMenuItem(
            'Dashboard', Icons.speed_rounded, _PortalSection.dashboard),
        _PortalMenuItem(
            'Halaman Utama', Icons.home_rounded, _PortalSection.home),
        _PortalMenuItem(
            'Approval Karya', Icons.task_alt_rounded, _PortalSection.approval),
        _PortalMenuItem(
            'Kelola Pengguna', Icons.people_rounded, _PortalSection.users),
        _PortalMenuItem(
            'Kelola Genre', Icons.sell_rounded, _PortalSection.genres),
        _PortalMenuItem('Moderasi Karya', Icons.collections_bookmark_rounded,
            _PortalSection.works),
        _PortalMenuItem(
            'Moderasi Chapter', Icons.article_rounded, _PortalSection.chapters),
        _PortalMenuItem(
            'Moderasi Gambar', Icons.image_rounded, _PortalSection.images),
      ];
    }

    return const [
      _PortalMenuItem(
          'Dashboard', Icons.speed_rounded, _PortalSection.dashboard),
      _PortalMenuItem('Halaman Utama', Icons.home_rounded, _PortalSection.home),
      _PortalMenuItem('Kelola Karya', Icons.collections_bookmark_rounded,
          _PortalSection.works),
    ];
  }

  Future<void> _refreshWorks() async {
    final next = widget.apiClient.fetchWorks();
    setState(() {
      _worksFuture = next;
    });
    await next;
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 1100;

    return Scaffold(
      key: _scaffoldKey,
      drawer: isCompact
          ? Drawer(
              backgroundColor: const Color(0xFF07141B),
              child: SafeArea(
                child: _PortalSidebar(
                  title: isAdmin ? 'Admin Nokomi' : 'Uploader Nokomi',
                  user: widget.session.user,
                  webBaseUrl: widget.webBaseUrl,
                  currentSection: _currentSection,
                  items: _menuItems,
                  onSelect: (section) {
                    Navigator.pop(context);
                    if (section == _PortalSection.home) {
                      Navigator.pop(context);
                      return;
                    }
                    setState(() => _currentSection = section);
                  },
                ),
              ),
            )
          : null,
      body: Row(
        children: [
          if (!isCompact)
            _PortalSidebar(
              title: isAdmin ? 'Admin Nokomi' : 'Uploader Nokomi',
              user: widget.session.user,
              webBaseUrl: widget.webBaseUrl,
              currentSection: _currentSection,
              items: _menuItems,
              onSelect: (section) {
                if (section == _PortalSection.home) {
                  Navigator.pop(context);
                  return;
                }
                setState(() => _currentSection = section);
              },
            ),
          Expanded(
            child: Column(
              children: [
                _PortalTopBar(
                  compact: isCompact,
                  user: widget.session.user,
                  portalLabel: isAdmin ? 'Admin Nokomi' : 'Uploader Nokomi',
                  onOpenMenu: isCompact
                      ? () => _scaffoldKey.currentState?.openDrawer()
                      : null,
                ),
                Expanded(
                  child: FutureBuilder<List<WorkSummary>>(
                    future: _worksFuture,
                    builder: (context, snapshot) {
                      final works = snapshot.data ?? const <WorkSummary>[];
                      return SingleChildScrollView(
                        padding: EdgeInsets.all(isCompact ? 16 : 28),
                        child: _PortalContent(
                          section: _currentSection,
                          isAdmin: isAdmin,
                          user: widget.session.user,
                          webBaseUrl: widget.webBaseUrl,
                          works: works,
                          loading:
                              snapshot.connectionState != ConnectionState.done,
                          onRefresh: _refreshWorks,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PortalTopBar extends StatelessWidget {
  const _PortalTopBar({
    required this.user,
    required this.portalLabel,
    required this.compact,
    this.onOpenMenu,
  });

  final AuthUser user;
  final String portalLabel;
  final bool compact;
  final VoidCallback? onOpenMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF06131A), Color(0xFF0A1E26)],
        ),
        border: Border(bottom: BorderSide(color: Color(0x223DB69B))),
      ),
      child: Row(
        children: [
          if (compact) ...[
            IconButton(
              onPressed: onOpenMenu,
              icon: const Icon(Icons.menu_rounded),
            ),
            const SizedBox(width: 8),
          ],
          NokomiBrand(
            compact: compact,
            showText: true,
          ),
          const Spacer(),
          if (!compact)
            Text(
              portalLabel,
              style: const TextStyle(
                color: Color(0xFFE6F2EF),
                fontWeight: FontWeight.w700,
              ),
            ),
          const SizedBox(width: 14),
          CircleAvatar(
            backgroundColor: const Color(0xFF79D9C1),
            child: Text(
              user.initial,
              style: const TextStyle(
                color: Color(0xFF062028),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PortalSidebar extends StatelessWidget {
  const _PortalSidebar({
    required this.title,
    required this.user,
    required this.webBaseUrl,
    required this.currentSection,
    required this.items,
    required this.onSelect,
  });

  final String title;
  final AuthUser user;
  final String webBaseUrl;
  final _PortalSection currentSection;
  final List<_PortalMenuItem> items;
  final ValueChanged<_PortalSection> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF041016), Color(0xFF08181F), Color(0xFF0A1C21)],
        ),
        border: Border(right: BorderSide(color: Color(0x2290C9BA))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 72),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                const _SidebarTitle('Utama'),
                for (final item in items)
                  _SidebarItem(
                    item: item,
                    active: item.section == currentSection,
                    onTap: () => onSelect(item.section),
                  ),
                const SizedBox(height: 24),
                const _SidebarTitle('Profile'),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0x14FFFFFF),
                    border: Border.all(color: const Color(0x2290C9BA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFFE6F2EF),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.role,
                        style: const TextStyle(color: Color(0xFF9EB7B0)),
                      ),
                      const SizedBox(height: 14),
                      _ProfileAction(
                        icon: Icons.person_rounded,
                        label: 'Edit Profile',
                        onTap: () {
                          launchUrl(Uri.parse('$webBaseUrl/profile'));
                        },
                      ),
                      const SizedBox(height: 8),
                      _ProfileAction(
                        icon: Icons.logout_rounded,
                        label: 'Sign Out',
                        danger: true,
                        onTap: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PortalContent extends StatelessWidget {
  const _PortalContent({
    required this.section,
    required this.isAdmin,
    required this.user,
    required this.webBaseUrl,
    required this.works,
    required this.loading,
    required this.onRefresh,
  });

  final _PortalSection section;
  final bool isAdmin;
  final AuthUser user;
  final String webBaseUrl;
  final List<WorkSummary> works;
  final bool loading;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    switch (section) {
      case _PortalSection.dashboard:
        return _DashboardView(
          isAdmin: isAdmin,
          works: works,
          loading: loading,
        );
      case _PortalSection.works:
        return _WorksTableView(
          isAdmin: isAdmin,
          user: user,
          works: works,
          loading: loading,
          onRefresh: onRefresh,
        );
      case _PortalSection.approval:
      case _PortalSection.users:
      case _PortalSection.genres:
      case _PortalSection.chapters:
      case _PortalSection.images:
        return _UnavailableView(
          section: section,
          isAdmin: isAdmin,
          webBaseUrl: webBaseUrl,
        );
      case _PortalSection.home:
        return const SizedBox.shrink();
    }
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView({
    required this.isAdmin,
    required this.works,
    required this.loading,
  });

  final bool isAdmin;
  final List<WorkSummary> works;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final comics = works.where((work) => work.type == 'comic').length;
    final novels = works.where((work) => work.type == 'novel').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PortalHeader(
          title: 'Dashboard',
          subtitle: isAdmin
              ? 'Ringkasan portal admin Nokomi.'
              : 'Ringkasan portal uploader Nokomi.',
        ),
        const SizedBox(height: 24),
        if (loading)
          const Center(child: CircularProgressIndicator())
        else ...[
          Wrap(
            spacing: 18,
            runSpacing: 18,
            children: [
              _StatCard(label: 'Total work API', value: '${works.length}'),
              _StatCard(label: 'Comic', value: '$comics'),
              _StatCard(label: 'Novel', value: '$novels'),
              _StatCard(
                label: 'Role aktif',
                value: isAdmin ? 'Admin' : 'Uploader',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _InfoCard(
            title: 'Status integrasi',
            body: isAdmin
                ? 'API Laravel yang tersedia saat ini baru auth dan public works. Jadi dashboard ini sudah aktif, tapi fitur admin seperti approval, kelola user, genre, moderasi chapter, dan moderasi gambar masih menunggu endpoint API backend.'
                : 'Portal uploader sudah aktif secara tampilan dan navigasi. Namun CRUD karya/chapter/gambar uploader masih membutuhkan endpoint API tambahan dari Laravel karena saat ini route yang tersedia untuk area itu masih route Blade web.',
          ),
        ],
      ],
    );
  }
}

class _WorksTableView extends StatelessWidget {
  const _WorksTableView({
    required this.isAdmin,
    required this.user,
    required this.works,
    required this.loading,
    required this.onRefresh,
  });

  final bool isAdmin;
  final AuthUser user;
  final List<WorkSummary> works;
  final bool loading;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final visibleWorks = isAdmin
        ? works
        : works.where((work) => work.author == user.name).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PortalHeader(
          title: isAdmin ? 'Moderasi Karya' : 'Kelola Karya',
          subtitle: isAdmin
              ? 'Daftar karya yang berhasil diambil dari API publik Laravel.'
              : 'Menampilkan karya terpublikasi yang author-nya cocok dengan user login.',
        ),
        const SizedBox(height: 24),
        if (loading)
          const Center(child: CircularProgressIndicator())
        else ...[
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Muat ulang'),
            ),
          ),
          const SizedBox(height: 16),
          _InfoCard(
            title: 'Catatan backend',
            body: isAdmin
                ? 'Karena API admin belum tersedia, tabel ini baru bisa menampilkan work dari endpoint public `/api/works`. Status pending, reject, approve, delete, dan detail moderasi belum bisa dilakukan lewat Flutter.'
                : 'Karena API uploader belum tersedia, Flutter baru bisa menampilkan work yang sudah muncul di API publik. Draft, pending, create, edit, submit ke admin, dan kelola chapter masih membutuhkan API uploader tambahan.',
          ),
          const SizedBox(height: 18),
          if (visibleWorks.isEmpty)
            const _InfoCard(
              title: 'Belum ada data yang bisa ditampilkan',
              body:
                  'Tidak ada work yang cocok dengan akses API yang tersedia saat ini.',
            )
          else
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x2290C9BA)),
                color: const Color(0xF20C1E26),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0x333DB69B),
                  ),
                  columns: const [
                    DataColumn(label: Text('Judul')),
                    DataColumn(label: Text('Author')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Chapter')),
                    DataColumn(label: Text('Status')),
                  ],
                  rows: [
                    for (final work in visibleWorks)
                      DataRow(
                        cells: [
                          DataCell(
                              SizedBox(width: 220, child: Text(work.title))),
                          DataCell(Text(work.author ?? '-')),
                          DataCell(Text(work.type)),
                          DataCell(Text('${work.chaptersCount}')),
                          DataCell(_StatusChip(status: work.status)),
                        ],
                      ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _UnavailableView extends StatelessWidget {
  const _UnavailableView({
    required this.section,
    required this.isAdmin,
    required this.webBaseUrl,
  });

  final _PortalSection section;
  final bool isAdmin;
  final String webBaseUrl;

  @override
  Widget build(BuildContext context) {
    final titles = <_PortalSection, String>{
      _PortalSection.approval: 'Approval Karya',
      _PortalSection.users: 'Kelola Pengguna',
      _PortalSection.genres: 'Kelola Genre',
      _PortalSection.chapters: 'Moderasi Chapter',
      _PortalSection.images: 'Moderasi Gambar',
      _PortalSection.dashboard: 'Dashboard',
      _PortalSection.home: 'Halaman Utama',
      _PortalSection.works: 'Works',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PortalHeader(
          title: titles[section] ?? 'Menu',
          subtitle: 'Struktur menu sudah mengikuti Laravel.',
        ),
        const SizedBox(height: 24),
        _InfoCard(
          title: 'Butuh endpoint API tambahan',
          body: isAdmin
              ? 'Menu ini sudah ada di route Blade Laravel admin, tetapi backend belum menyediakan endpoint API JSON yang bisa dipanggil Flutter untuk operasi ini.'
              : 'Menu ini ada di Laravel, namun belum ada API JSON yang bisa langsung dipakai Flutter.',
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () {
            launchUrl(Uri.parse(_routeUrl()));
          },
          icon: const Icon(Icons.open_in_new_rounded),
          label: const Text('Buka halaman Laravel'),
        ),
      ],
    );
  }

  String _routeUrl() {
    return switch (section) {
      _PortalSection.approval => '$webBaseUrl/admin/works/pending',
      _PortalSection.users => '$webBaseUrl/admin/users',
      _PortalSection.genres => '$webBaseUrl/admin/genres',
      _PortalSection.chapters => '$webBaseUrl/admin/chapters',
      _PortalSection.images => '$webBaseUrl/admin/chapter-images',
      _PortalSection.works =>
        isAdmin ? '$webBaseUrl/admin/works' : '$webBaseUrl/works',
      _PortalSection.dashboard => '$webBaseUrl/dashboard',
      _PortalSection.home => webBaseUrl,
    };
  }
}

class _PortalHeader extends StatelessWidget {
  const _PortalHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x2290C9BA)),
        color: const Color(0xF109181F),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFE6F2EF),
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF9EB7B0),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x2290C9BA)),
        color: const Color(0xF20B1D26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFE6F2EF),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              color: Color(0xFF9EB7B0),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x2290C9BA)),
        color: const Color(0xF20B1D26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF9EB7B0),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFE6F2EF),
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarTitle extends StatelessWidget {
  const _SidebarTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF9EB7B0),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final _PortalMenuItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: active ? const Color(0x223DB69B) : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: active ? const Color(0xFFF4B860) : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(item.icon, color: const Color(0xFFE6F2EF), size: 20),
            const SizedBox(width: 14),
            Text(
              item.label,
              style: const TextStyle(
                color: Color(0xFFE6F2EF),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: danger ? const Color(0x33DC3545) : const Color(0x18000000),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFFE6F2EF)),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(color: Color(0xFFE6F2EF)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'approved' => const Color(0xFF8EF0D7),
      'pending' => const Color(0xFFFFD38D),
      _ => const Color(0xFFFF9EAB),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.16),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PortalMenuItem {
  const _PortalMenuItem(this.label, this.icon, this.section);

  final String label;
  final IconData icon;
  final _PortalSection section;
}

enum _PortalSection {
  dashboard,
  home,
  approval,
  users,
  genres,
  works,
  chapters,
  images,
}
