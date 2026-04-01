import 'package:flutter/material.dart';

import '../models/api_models.dart';
import '../models/auth_user.dart';
import '../services/ujikom_api_client.dart';
import '../widgets/nokomi_brand.dart';

class RolePortalPage extends StatefulWidget {
  const RolePortalPage({
    super.key,
    required this.session,
    required this.apiClient,
  });

  final AuthSession session;
  final UjikomApiClient apiClient;

  @override
  State<RolePortalPage> createState() => _RolePortalPageState();
}

class _RolePortalPageState extends State<RolePortalPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final List<_PortalMenuItem> _menuItems = _buildMenuItems();
  late _PortalSection _currentSection = _menuItems.first.section;

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
      _PortalMenuItem(
          'Chapter', Icons.article_rounded, _PortalSection.chapters),
      _PortalMenuItem('Gambar', Icons.image_rounded, _PortalSection.images),
    ];
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
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isCompact ? 16 : 28),
                    child: _PortalContent(
                      section: _currentSection,
                      isAdmin: isAdmin,
                      user: widget.session.user,
                      apiClient: widget.apiClient,
                    ),
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: NokomiBrand(
                compact: compact,
                showText: true,
              ),
            ),
          ),
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
    required this.currentSection,
    required this.items,
    required this.onSelect,
  });

  final String title;
  final AuthUser user;
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
                      const _ProfileAction(
                        icon: Icons.person_rounded,
                        label: 'Edit Profile',
                        body:
                            'Route edit profile native belum dibuat, tapi data akun dan role sudah tersambung dari API login.',
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
    required this.apiClient,
  });

  final _PortalSection section;
  final bool isAdmin;
  final AuthUser user;
  final UjikomApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    if (isAdmin) {
      switch (section) {
        case _PortalSection.dashboard:
          return _AdminDashboardView(apiClient: apiClient);
        case _PortalSection.approval:
          return _AdminWorksView(apiClient: apiClient, pendingOnly: true);
        case _PortalSection.users:
          return _AdminUsersView(apiClient: apiClient);
        case _PortalSection.genres:
          return _AdminGenresView(apiClient: apiClient);
        case _PortalSection.works:
          return _AdminWorksView(apiClient: apiClient, pendingOnly: false);
        case _PortalSection.chapters:
          return _AdminChaptersView(apiClient: apiClient);
        case _PortalSection.images:
          return _AdminImagesView(apiClient: apiClient);
        case _PortalSection.home:
          return const SizedBox.shrink();
      }
    }

    switch (section) {
      case _PortalSection.dashboard:
        return _UploaderDashboardView(apiClient: apiClient);
      case _PortalSection.works:
        return _UploaderWorksView(apiClient: apiClient, user: user);
      case _PortalSection.chapters:
      case _PortalSection.images:
        return _UploaderScopedPlaceholder(section: section);
      case _PortalSection.home:
      case _PortalSection.approval:
      case _PortalSection.users:
      case _PortalSection.genres:
        return const SizedBox.shrink();
    }
  }
}

class _AdminDashboardView extends StatelessWidget {
  const _AdminDashboardView({required this.apiClient});

  final UjikomApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AdminDashboardData>(
      future: apiClient.fetchAdminDashboard(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _ErrorPanel(message: snapshot.error.toString());
        }

        final data = snapshot.requireData;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PortalHeader(
              title: 'Dashboard Admin',
              subtitle: 'Ringkasan portal admin langsung dari endpoint API.',
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 18,
              runSpacing: 18,
              children: [
                _StatCard(label: 'Total karya', value: '${data.totalWorks}'),
                _StatCard(label: 'Pending', value: '${data.pendingWorks}'),
                _StatCard(label: 'Approved', value: '${data.approvedWorks}'),
                _StatCard(label: 'Draft', value: '${data.draftWorks}'),
                _StatCard(label: 'Users', value: '${data.usersCount}'),
                _StatCard(label: 'Genre', value: '${data.genresCount}'),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionCardTitle('User Terbaru'),
            ...data.recentUsers.map(
              (user) => _InfoCard(
                title: user.name,
                body: '${user.role} • ${user.avatar ?? 'Tanpa avatar'}',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AdminUsersView extends StatelessWidget {
  const _AdminUsersView({required this.apiClient});

  final UjikomApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AdminUsersResponse>(
      future: apiClient.fetchAdminUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _ErrorPanel(message: snapshot.error.toString());
        }

        final data = snapshot.requireData;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PortalHeader(
              title: 'Kelola Pengguna',
              subtitle: 'Daftar pengguna dan role dari API admin Laravel.',
            ),
            const SizedBox(height: 24),
            _InfoCard(
              title: 'Total pengguna',
              body:
                  '${data.meta.total} akun • ${data.roles.map((role) => role.name).join(', ')}',
            ),
            const SizedBox(height: 16),
            _DataTableCard(
              columns: const ['Nama', 'Email', 'Role', 'Works', 'Bookmark'],
              rows: data.users
                  .map(
                    (user) => [
                      user.name,
                      user.email,
                      user.role,
                      '${user.worksCount}',
                      '${user.bookmarksCount}',
                    ],
                  )
                  .toList(),
            ),
          ],
        );
      },
    );
  }
}

class _AdminGenresView extends StatelessWidget {
  const _AdminGenresView({required this.apiClient});

  final UjikomApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<GenreItem>>(
      future: apiClient.fetchAdminGenres(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _ErrorPanel(message: snapshot.error.toString());
        }

        final genres = snapshot.requireData;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PortalHeader(
              title: 'Kelola Genre',
              subtitle: 'Genre admin sekarang dibaca langsung dari API.',
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: genres
                  .map(
                    (genre) => Chip(
                      label: Text('${genre.name} • ${genre.worksCount}'),
                      backgroundColor: const Color(0xFF1A1F2E),
                      side: const BorderSide(color: Color(0xFF2D3748)),
                      labelStyle: const TextStyle(color: Color(0xFFE8EAED)),
                    ),
                  )
                  .toList(),
            ),
          ],
        );
      },
    );
  }
}

class _AdminWorksView extends StatefulWidget {
  const _AdminWorksView({
    required this.apiClient,
    required this.pendingOnly,
  });

  final UjikomApiClient apiClient;
  final bool pendingOnly;

  @override
  State<_AdminWorksView> createState() => _AdminWorksViewState();
}

class _AdminWorksViewState extends State<_AdminWorksView> {
  late Future<WorksPageResponse> _future = _load();

  Future<WorksPageResponse> _load() {
    return widget.apiClient.fetchAdminWorks(
      status: widget.pendingOnly ? 'pending' : null,
    );
  }

  Future<void> _approve(int workId) async {
    await widget.apiClient.approveAdminWork(workId);
    setState(() => _future = _load());
  }

  Future<void> _reject(int workId) async {
    await widget.apiClient.rejectAdminWork(workId);
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WorksPageResponse>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _ErrorPanel(message: snapshot.error.toString());
        }

        final data = snapshot.requireData;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PortalHeader(
              title: widget.pendingOnly ? 'Approval Karya' : 'Moderasi Karya',
              subtitle: widget.pendingOnly
                  ? 'Antrian karya pending dari API admin.'
                  : 'Daftar semua karya dari API admin.',
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 18,
              runSpacing: 18,
              children: [
                _StatCard(label: 'Total', value: '${data.summary.total}'),
                _StatCard(label: 'Pending', value: '${data.summary.pending}'),
                _StatCard(label: 'Approved', value: '${data.summary.approved}'),
                _StatCard(label: 'Draft', value: '${data.summary.draft}'),
              ],
            ),
            const SizedBox(height: 24),
            if (data.items.isEmpty)
              const _InfoCard(
                title: 'Tidak ada data',
                body: 'Belum ada karya yang cocok dengan filter saat ini.',
              )
            else
              ...data.items.map(
                (work) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0x2290C9BA)),
                      color: const Color(0xF20B1D26),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          work.title,
                          style: const TextStyle(
                            color: Color(0xFFE6F2EF),
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${work.author ?? '-'} • ${work.type} • ${work.status} • ${work.chaptersCount} chapter',
                          style: const TextStyle(color: Color(0xFF9EB7B0)),
                        ),
                        if (widget.pendingOnly) ...[
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              FilledButton(
                                onPressed: () => _approve(work.id),
                                child: const Text('Approve'),
                              ),
                              OutlinedButton(
                                onPressed: () => _reject(work.id),
                                child: const Text('Reject'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AdminChaptersView extends StatelessWidget {
  const _AdminChaptersView({required this.apiClient});

  final UjikomApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ChapterSummary>>(
      future: apiClient.fetchAdminChapters(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _ErrorPanel(message: snapshot.error.toString());
        }

        final chapters = snapshot.requireData;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PortalHeader(
              title: 'Moderasi Chapter',
              subtitle: 'List chapter admin langsung dari API.',
            ),
            const SizedBox(height: 24),
            _DataTableCard(
              columns: const ['Work', 'Chapter', 'Gambar', 'Komentar'],
              rows: chapters
                  .map(
                    (chapter) => [
                      chapter.workTitle ?? '-',
                      '${chapter.chapterNumber}',
                      '${chapter.imagesCount}',
                      '${chapter.commentsCount}',
                    ],
                  )
                  .toList(),
            ),
          ],
        );
      },
    );
  }
}

class _AdminImagesView extends StatelessWidget {
  const _AdminImagesView({required this.apiClient});

  final UjikomApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: apiClient.fetchAdminChapterImages(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _ErrorPanel(message: snapshot.error.toString());
        }

        final images = snapshot.requireData;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PortalHeader(
              title: 'Moderasi Gambar',
              subtitle: 'Daftar gambar chapter dari API admin.',
            ),
            const SizedBox(height: 24),
            _DataTableCard(
              columns: const ['ID', 'Chapter', 'Page', 'Image URL'],
              rows: images
                  .map(
                    (image) => [
                      '${image['id'] ?? '-'}',
                      '${(image['chapter'] as Map<String, dynamic>?)?['title'] ?? '-'}',
                      '${image['page_number'] ?? '-'}',
                      '${image['image_url'] ?? '-'}',
                    ],
                  )
                  .toList(),
            ),
          ],
        );
      },
    );
  }
}

class _UploaderDashboardView extends StatelessWidget {
  const _UploaderDashboardView({required this.apiClient});

  final UjikomApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UploaderDashboardData>(
      future: apiClient.fetchUploaderDashboard(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _ErrorPanel(message: snapshot.error.toString());
        }

        final data = snapshot.requireData;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PortalHeader(
              title: 'Dashboard Uploader',
              subtitle: 'Ringkasan karya uploader dari endpoint API baru.',
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 18,
              runSpacing: 18,
              children: [
                _StatCard(label: 'Total karya', value: '${data.summary.total}'),
                _StatCard(label: 'Draft', value: '${data.summary.draft}'),
                _StatCard(label: 'Pending', value: '${data.summary.pending}'),
                _StatCard(label: 'Approved', value: '${data.summary.approved}'),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionCardTitle('Karya Terbaru'),
            ...data.recentWorks.map(
              (work) => _InfoCard(
                title: work.title,
                body:
                    '${work.type} • ${work.status} • ${work.chaptersCount} chapter',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _UploaderWorksView extends StatelessWidget {
  const _UploaderWorksView({
    required this.apiClient,
    required this.user,
  });

  final UjikomApiClient apiClient;
  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WorksPageResponse>(
      future: apiClient.fetchUploaderWorks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _ErrorPanel(message: snapshot.error.toString());
        }

        final data = snapshot.requireData;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PortalHeader(
              title: 'Kelola Karya',
              subtitle: 'Karya milik ${user.name} dari endpoint uploader.',
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 18,
              runSpacing: 18,
              children: [
                _StatCard(label: 'Total', value: '${data.summary.total}'),
                _StatCard(label: 'Draft', value: '${data.summary.draft}'),
                _StatCard(label: 'Pending', value: '${data.summary.pending}'),
                _StatCard(label: 'Approved', value: '${data.summary.approved}'),
              ],
            ),
            const SizedBox(height: 24),
            _DataTableCard(
              columns: const ['Judul', 'Type', 'Status', 'Chapter'],
              rows: data.items
                  .map(
                    (work) => [
                      work.title,
                      work.type,
                      work.status,
                      '${work.chaptersCount}',
                    ],
                  )
                  .toList(),
            ),
          ],
        );
      },
    );
  }
}

class _UploaderScopedPlaceholder extends StatelessWidget {
  const _UploaderScopedPlaceholder({required this.section});

  final _PortalSection section;

  @override
  Widget build(BuildContext context) {
    final title =
        section == _PortalSection.chapters ? 'Chapter' : 'Gambar Chapter';
    return _InfoCard(
      title: title,
      body:
          'Endpoint uploader untuk chapter dan gambar sudah tersedia. Langkah berikutnya tinggal menambahkan flow pilih karya lalu CRUD chapter/gambar per karya di Flutter.',
    );
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

class _SectionCardTitle extends StatelessWidget {
  const _SectionCardTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFFE6F2EF),
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
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

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: 'Gagal memuat data',
      body: message,
    );
  }
}

class _DataTableCard extends StatelessWidget {
  const _DataTableCard({
    required this.columns,
    required this.rows,
  });

  final List<String> columns;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x2290C9BA)),
        color: const Color(0xF20C1E26),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0x333DB69B)),
          columns:
              columns.map((label) => DataColumn(label: Text(label))).toList(),
          rows: rows
              .map(
                (row) => DataRow(
                  cells: row
                      .map(
                        (value) => DataCell(
                          SizedBox(
                            width: 180,
                            child: Text(value),
                          ),
                        ),
                      )
                      .toList(),
                ),
              )
              .toList(),
        ),
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
    required this.body,
  });

  final IconData icon;
  final String label;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0x18000000),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFFE6F2EF)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Color(0xFFE6F2EF)),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: Color(0xFF9EB7B0),
                    fontSize: 12,
                    height: 1.5,
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
