import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/api_models.dart';
import '../models/auth_user.dart';
import '../models/work.dart';
import '../services/ujikom_api_client.dart';
import '../widgets/network_cover.dart';
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
  late final List<_PortalMenuItem> _menuItems = _buildMenuItems();
  late _PortalSection _section = _menuItems.first.section;

  bool get _isAdmin => widget.session.user.role == 'admin';

  List<_PortalMenuItem> _buildMenuItems() {
    if (_isAdmin) {
      return const [
        _PortalMenuItem('Dashboard', Icons.speed_rounded, _PortalSection.dashboard),
        _PortalMenuItem('Approval Karya', Icons.task_alt_rounded, _PortalSection.approval),
        _PortalMenuItem('Kelola Pengguna', Icons.people_rounded, _PortalSection.users),
        _PortalMenuItem('Kelola Genre', Icons.sell_rounded, _PortalSection.genres),
        _PortalMenuItem('Moderasi Karya', Icons.collections_bookmark_rounded, _PortalSection.works),
        _PortalMenuItem('Moderasi Chapter', Icons.article_rounded, _PortalSection.chapters),
        _PortalMenuItem('Moderasi Gambar', Icons.image_rounded, _PortalSection.images),
      ];
    }

    return const [
      _PortalMenuItem('Dashboard', Icons.speed_rounded, _PortalSection.dashboard),
      _PortalMenuItem('Kelola Karya', Icons.collections_bookmark_rounded, _PortalSection.works),
      _PortalMenuItem('Kelola Chapter', Icons.article_rounded, _PortalSection.chapters),
      _PortalMenuItem('Kelola Gambar', Icons.image_rounded, _PortalSection.images),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 1000;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const NokomiBrand(compact: true, showText: true),
      ),
      drawer: isCompact
          ? Drawer(
              child: SafeArea(
                child: _PortalMenu(
                  user: widget.session.user,
                  items: _menuItems,
                  section: _section,
                  onSelect: (section) {
                    Navigator.pop(context);
                    setState(() => _section = section);
                  },
                ),
              ),
            )
          : null,
      body: Row(
        children: [
          if (!isCompact)
            SizedBox(
              width: 280,
              child: _PortalMenu(
                user: widget.session.user,
                items: _menuItems,
                section: _section,
                onSelect: (section) => setState(() => _section = section),
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _PortalSectionBody(
                section: _section,
                isAdmin: _isAdmin,
                user: widget.session.user,
                apiClient: widget.apiClient,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PortalMenu extends StatelessWidget {
  const _PortalMenu({
    required this.user,
    required this.items,
    required this.section,
    required this.onSelect,
  });

  final AuthUser user;
  final List<_PortalMenuItem> items;
  final _PortalSection section;
  final ValueChanged<_PortalSection> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF08131A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF0D1C24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(user.role),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: items
                  .map(
                    (item) => ListTile(
                      leading: Icon(item.icon),
                      title: Text(item.label),
                      selected: item.section == section,
                      onTap: () => onSelect(item.section),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PortalSectionBody extends StatelessWidget {
  const _PortalSectionBody({
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
      }
    }

    switch (section) {
      case _PortalSection.dashboard:
        return _UploaderDashboardView(apiClient: apiClient);
      case _PortalSection.works:
        return _UploaderWorksView(apiClient: apiClient, user: user);
      case _PortalSection.chapters:
        return _UploaderChaptersView(apiClient: apiClient);
      case _PortalSection.images:
        return _UploaderImagesView(apiClient: apiClient);
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
          return _ErrorCard(message: snapshot.error.toString());
        }

        final data = snapshot.requireData;
        return _SectionScaffold(
          title: 'Dashboard Admin',
          subtitle: 'Ringkasan portal admin dari API Laravel.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatCard(label: 'Karya', value: '${data.totalWorks}'),
                  _StatCard(label: 'Pending', value: '${data.pendingWorks}'),
                  _StatCard(label: 'Approved', value: '${data.approvedWorks}'),
                  _StatCard(label: 'Draft', value: '${data.draftWorks}'),
                  _StatCard(label: 'Users', value: '${data.usersCount}'),
                  _StatCard(label: 'Genre', value: '${data.genresCount}'),
                  _StatCard(label: 'Chapter', value: '${data.chaptersCount}'),
                  _StatCard(label: 'Gambar', value: '${data.chapterImagesCount}'),
                ],
              ),
              const SizedBox(height: 20),
              const Text('User terbaru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ...data.recentUsers.map(
                (user) => _SimpleCard(
                  title: user.name,
                  subtitle: '${user.role} • ${user.avatar ?? 'Tanpa avatar'}',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AdminUsersView extends StatefulWidget {
  const _AdminUsersView({required this.apiClient});

  final UjikomApiClient apiClient;

  @override
  State<_AdminUsersView> createState() => _AdminUsersViewState();
}

class _AdminUsersViewState extends State<_AdminUsersView> {
  late Future<AdminUsersResponse> _future = widget.apiClient.fetchAdminUsers();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AdminUsersResponse>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _ErrorCard(message: snapshot.error.toString());
        }

        final data = snapshot.requireData;
        return _SectionScaffold(
          title: 'Kelola Pengguna',
          subtitle: 'Edit nama, email, dan role user.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SimpleCard(
                title: 'Total pengguna',
                subtitle: '${data.meta.total} akun • ${data.roles.map((role) => role.name).join(', ')}',
              ),
              const SizedBox(height: 12),
              ...data.users.map(
                (user) => _ActionCard(
                  title: user.name,
                  subtitle: '${user.email} • ${user.role} • ${user.worksCount} karya',
                  actions: [
                    TextButton.icon(
                      onPressed: () => _editUser(user, data.roles),
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Edit'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editUser(AdminUserItem user, List<RoleOption> roles) async {
    final result = await _showUserDialog(context, user, roles);
    if (result == null) return;

    try {
      await widget.apiClient.updateAdminUser(
        userId: user.id,
        name: result.name,
        email: result.email,
        roleId: result.roleId,
      );
      if (!mounted) return;
      setState(() => _future = widget.apiClient.fetchAdminUsers());
      _showSnack(context, 'Data pengguna berhasil diperbarui.');
    } on ApiException catch (error) {
      if (!mounted) return;
      _showSnack(context, error.message, isError: true);
    }
  }
}

class _AdminGenresView extends StatefulWidget {
  const _AdminGenresView({required this.apiClient});

  final UjikomApiClient apiClient;

  @override
  State<_AdminGenresView> createState() => _AdminGenresViewState();
}

class _AdminGenresViewState extends State<_AdminGenresView> {
  late Future<List<GenreItem>> _future = widget.apiClient.fetchAdminGenres();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<GenreItem>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _ErrorCard(message: snapshot.error.toString());
        }

        final genres = snapshot.requireData;
        return _SectionScaffold(
          title: 'Kelola Genre',
          subtitle: 'Tambah, edit, dan hapus genre.',
          action: FilledButton.icon(
            onPressed: _createGenre,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tambah Genre'),
          ),
          child: Column(
            children: genres
                .map(
                  (genre) => _ActionCard(
                    title: genre.name,
                    subtitle: '${genre.worksCount} karya',
                    actions: [
                      TextButton.icon(
                        onPressed: () => _editGenre(genre),
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text('Edit'),
                      ),
                      TextButton.icon(
                        onPressed: () => _deleteGenre(genre),
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Hapus'),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  Future<void> _createGenre() async {
    final name = await _showTextDialog(context, title: 'Tambah Genre', label: 'Nama genre');
    if (name == null || name.trim().isEmpty) return;
    try {
      await widget.apiClient.createAdminGenre(name.trim());
      if (!mounted) return;
      setState(() => _future = widget.apiClient.fetchAdminGenres());
      _showSnack(context, 'Genre berhasil ditambahkan.');
    } on ApiException catch (error) {
      if (!mounted) return;
      _showSnack(context, error.message, isError: true);
    }
  }

  Future<void> _editGenre(GenreItem genre) async {
    final name = await _showTextDialog(
      context,
      title: 'Edit Genre',
      label: 'Nama genre',
      initialValue: genre.name,
    );
    if (name == null || name.trim().isEmpty) return;
    try {
      await widget.apiClient.updateAdminGenre(genreId: genre.id, name: name.trim());
      if (!mounted) return;
      setState(() => _future = widget.apiClient.fetchAdminGenres());
      _showSnack(context, 'Genre berhasil diperbarui.');
    } on ApiException catch (error) {
      if (!mounted) return;
      _showSnack(context, error.message, isError: true);
    }
  }

  Future<void> _deleteGenre(GenreItem genre) async {
    final confirmed = await _confirm(context, 'Hapus genre ${genre.name}?');
    if (!confirmed) return;
    try {
      await widget.apiClient.deleteAdminGenre(genre.id);
      if (!mounted) return;
      setState(() => _future = widget.apiClient.fetchAdminGenres());
      _showSnack(context, 'Genre berhasil dihapus.');
    } on ApiException catch (error) {
      if (!mounted) return;
      _showSnack(context, error.message, isError: true);
    }
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WorksPageResponse>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _ErrorCard(message: snapshot.error.toString());
        }

        final data = snapshot.requireData;
        return _SectionScaffold(
          title: widget.pendingOnly ? 'Approval Karya' : 'Moderasi Karya',
          subtitle: widget.pendingOnly
              ? 'Approve, reject, atau hapus karya pending.'
              : 'Moderasi semua karya dari admin.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatCard(label: 'Total', value: '${data.summary.total}'),
                  _StatCard(label: 'Pending', value: '${data.summary.pending}'),
                  _StatCard(label: 'Approved', value: '${data.summary.approved}'),
                  _StatCard(label: 'Draft', value: '${data.summary.draft}'),
                ],
              ),
              const SizedBox(height: 16),
              ...data.items.map(
                (work) => _ActionCard(
                  title: work.title,
                  subtitle: '${work.author ?? '-'} • ${work.type} • ${work.status} • ${work.chaptersCount} chapter',
                  leading: _buildCover(work.coverUrl),
                  actions: [
                    if (widget.pendingOnly)
                      TextButton.icon(
                        onPressed: () => _approve(work.id),
                        icon: const Icon(Icons.check_circle_outline_rounded),
                        label: const Text('Approve'),
                      ),
                    if (widget.pendingOnly)
                      TextButton.icon(
                        onPressed: () => _reject(work.id),
                        icon: const Icon(Icons.undo_rounded),
                        label: const Text('Reject'),
                      ),
                    TextButton.icon(
                      onPressed: () => _delete(work),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Hapus'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _approve(int workId) async {
    try {
      await widget.apiClient.approveAdminWork(workId);
      if (!mounted) return;
      setState(() => _future = _load());
      _showSnack(context, 'Karya berhasil di-approve.');
    } on ApiException catch (error) {
      if (!mounted) return;
      _showSnack(context, error.message, isError: true);
    }
  }

  Future<void> _reject(int workId) async {
    try {
      await widget.apiClient.rejectAdminWork(workId);
      if (!mounted) return;
      setState(() => _future = _load());
      _showSnack(context, 'Karya dikembalikan ke draft.');
    } on ApiException catch (error) {
      if (!mounted) return;
      _showSnack(context, error.message, isError: true);
    }
  }

  Future<void> _delete(WorkSummary work) async {
    final confirmed = await _confirm(context, 'Hapus karya ${work.title}?');
    if (!confirmed) return;
    try {
      await widget.apiClient.deleteAdminWork(work.id);
      if (!mounted) return;
      setState(() => _future = _load());
      _showSnack(context, 'Karya berhasil dihapus.');
    } on ApiException catch (error) {
      if (!mounted) return;
      _showSnack(context, error.message, isError: true);
    }
  }
}

class _AdminChaptersView extends StatefulWidget {
  const _AdminChaptersView({required this.apiClient});

  final UjikomApiClient apiClient;

  @override
  State<_AdminChaptersView> createState() => _AdminChaptersViewState();
}

class _AdminChaptersViewState extends State<_AdminChaptersView> {
  late Future<List<ChapterSummary>> _future = widget.apiClient.fetchAdminChapters();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ChapterSummary>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _ErrorCard(message: snapshot.error.toString());
        }

        final chapters = snapshot.requireData;
        return _SectionScaffold(
          title: 'Moderasi Chapter',
          subtitle: 'Hapus chapter dari admin.',
          child: Column(
            children: chapters
                .map(
                  (chapter) => _ActionCard(
                    title: chapter.title,
                    subtitle: '${chapter.workTitle ?? '-'} • Chapter ${chapter.chapterNumber} • ${chapter.imagesCount} gambar • ${chapter.commentsCount} komentar',
                    actions: [
                      TextButton.icon(
                        onPressed: () => _deleteChapter(chapter),
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Hapus'),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  Future<void> _deleteChapter(ChapterSummary chapter) async {
    final confirmed = await _confirm(context, 'Hapus ${chapter.title}?');
    if (!confirmed) return;
    try {
      await widget.apiClient.deleteAdminChapter(chapter.id);
      if (!mounted) return;
      setState(() => _future = widget.apiClient.fetchAdminChapters());
      _showSnack(context, 'Chapter berhasil dihapus.');
    } on ApiException catch (error) {
      if (!mounted) return;
      _showSnack(context, error.message, isError: true);
    }
  }
}

class _AdminImagesView extends StatefulWidget {
  const _AdminImagesView({required this.apiClient});

  final UjikomApiClient apiClient;

  @override
  State<_AdminImagesView> createState() => _AdminImagesViewState();
}

class _AdminImagesViewState extends State<_AdminImagesView> {
  late Future<List<ChapterImageItem>> _future = widget.apiClient.fetchAdminChapterImages();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ChapterImageItem>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _ErrorCard(message: snapshot.error.toString());
        }

        final images = snapshot.requireData;
        return _SectionScaffold(
          title: 'Moderasi Gambar',
          subtitle: 'Hapus gambar chapter dari admin.',
          child: Column(
            children: images
                .map(
                  (image) => _ActionCard(
                    title: image.chapterTitle ?? 'Gambar #${image.id}',
                    subtitle: '${image.workTitle ?? '-'} • Halaman ${image.pageNumber}',
                    leading: _buildCover(image.imageUrl, square: true),
                    actions: [
                      TextButton.icon(
                        onPressed: () => _deleteImage(image),
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Hapus'),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  Future<void> _deleteImage(ChapterImageItem image) async {
    final confirmed = await _confirm(context, 'Hapus gambar halaman ${image.pageNumber}?');
    if (!confirmed) return;
    try {
      await widget.apiClient.deleteAdminChapterImage(image.id);
      if (!mounted) return;
      setState(() => _future = widget.apiClient.fetchAdminChapterImages());
      _showSnack(context, 'Gambar berhasil dihapus.');
    } on ApiException catch (error) {
      if (!mounted) return;
      _showSnack(context, error.message, isError: true);
    }
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
          return _ErrorCard(message: snapshot.error.toString());
        }

        final data = snapshot.requireData;
        return _SectionScaffold(
          title: 'Dashboard Uploader',
          subtitle: 'Ringkasan karya uploader.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatCard(label: 'Total', value: '${data.summary.total}'),
                  _StatCard(label: 'Draft', value: '${data.summary.draft}'),
                  _StatCard(label: 'Pending', value: '${data.summary.pending}'),
                  _StatCard(label: 'Approved', value: '${data.summary.approved}'),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Karya terbaru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ...data.recentWorks.map(
                (work) => _SimpleCard(
                  title: work.title,
                  subtitle: '${work.type} • ${work.status} • ${work.chaptersCount} chapter',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UploaderWorksView extends StatefulWidget {
  const _UploaderWorksView({
    required this.apiClient,
    required this.user,
  });

  final UjikomApiClient apiClient;
  final AuthUser user;

  @override
  State<_UploaderWorksView> createState() => _UploaderWorksViewState();
}

class _UploaderWorksViewState extends State<_UploaderWorksView> {
  late Future<_UploaderWorkBundle> _future = _load();

  Future<_UploaderWorkBundle> _load() async {
    final works = await widget.apiClient.fetchUploaderWorks();
    final genres = await widget.apiClient.fetchGenres();
    return _UploaderWorkBundle(works: works, genres: genres);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_UploaderWorkBundle>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _ErrorCard(message: snapshot.error.toString());
        }

        final bundle = snapshot.requireData;
        final data = bundle.works;
        return _SectionScaffold(
          title: 'Kelola Karya',
          subtitle: 'CRUD karya uploader ${widget.user.name}.',
          action: FilledButton.icon(
            onPressed: () => _createWork(bundle.genres),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tambah Karya'),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatCard(label: 'Total', value: '${data.summary.total}'),
                  _StatCard(label: 'Draft', value: '${data.summary.draft}'),
                  _StatCard(label: 'Pending', value: '${data.summary.pending}'),
                  _StatCard(label: 'Approved', value: '${data.summary.approved}'),
                ],
              ),
              const SizedBox(height: 16),
              ...data.items.map(
                (work) => _ActionCard(
                  title: work.title,
                  subtitle: '${work.type} • ${work.status} • ${work.chaptersCount} chapter • ${work.genres.join(', ')}',
                  leading: _buildCover(work.coverUrl),
                  actions: [
                    TextButton.icon(
                      onPressed: () => _editWork(work, bundle.genres),
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Edit'),
                    ),
                    if (work.status == 'draft')
                      TextButton.icon(
                        onPressed: () => _submit(work.id),
                        icon: const Icon(Icons.send_rounded),
                        label: const Text('Submit'),
                      ),
                    TextButton.icon(
                      onPressed: () => _delete(work),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Hapus'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _createWork(List<GenreItem> genres) async {
    final result = await _showWorkDialog(context, genres: genres);
    if (result == null) return;
    try {
      await widget.apiClient.createUploaderWork(
        title: result.title,
        originalAuthor: result.originalAuthor,
        type: result.type,
        genreIds: result.genreIds,
        description: result.description,
        coverPath: result.coverPath,
      );
      if (!mounted) return;
      setState(() => _future = _load());
      _showSnack(context, 'Karya berhasil dibuat.');
    } on ApiException catch (error) {
      if (!mounted) return;
      _showSnack(context, error.message, isError: true);
    }
  }

  Future<void> _editWork(WorkSummary work, List<GenreItem> genres) async {
    final genreIds = genres.where((genre) => work.genres.contains(genre.name)).map((genre) => genre.id).toList();
    final result = await _showWorkDialog(
      context,
      genres: genres,
      initialValue: _WorkDialogValue(
        title: work.title,
        originalAuthor: work.author ?? '',
        description: work.description ?? '',
        type: work.type,
        genreIds: genreIds,
      ),
    );
    if (result == null) return;
    try {
      await widget.apiClient.updateUploaderWork(
        workId: work.id,
        title: result.title,
        originalAuthor: result.originalAuthor,
        type: result.type,
        genreIds: result.genreIds,
        description: result.description,
        coverPath: result.coverPath,
      );
      if (!mounted) return;
      setState(() => _future = _load());
      _showSnack(context, 'Karya berhasil diperbarui.');
    } on ApiException catch (error) {
      if (!mounted) return;
      _showSnack(context, error.message, isError: true);
    }
  }

  Future<void> _submit(int workId) async {
    try {
      await widget.apiClient.submitUploaderWork(workId);
      if (!mounted) return;
      setState(() => _future = _load());
      _showSnack(context, 'Karya berhasil dikirim ke admin.');
    } on ApiException catch (error) {
      if (!mounted) return;
      _showSnack(context, error.message, isError: true);
    }
  }

  Future<void> _delete(WorkSummary work) async {
    final confirmed = await _confirm(context, 'Hapus karya ${work.title}?');
    if (!confirmed) return;
    try {
      await widget.apiClient.deleteUploaderWork(work.id);
      if (!mounted) return;
      setState(() => _future = _load());
      _showSnack(context, 'Karya berhasil dihapus.');
    } on ApiException catch (error) {
      if (!mounted) return;
      _showSnack(context, error.message, isError: true);
    }
  }
}

class _UploaderChaptersView extends StatefulWidget {
  const _UploaderChaptersView({required this.apiClient});

  final UjikomApiClient apiClient;

  @override
  State<_UploaderChaptersView> createState() => _UploaderChaptersViewState();
}

class _UploaderChaptersViewState extends State<_UploaderChaptersView> {
  List<WorkSummary> _works = const [];
  WorkSummary? _selectedWork;
  List<ChapterSummary> _chapters = const [];
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWorks();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorCard(message: _error!);
    }

    return _SectionScaffold(
      title: 'Kelola Chapter',
      subtitle: 'Pilih karya lalu tambah, edit, dan hapus chapter.',
      action: FilledButton.icon(
        onPressed: _selectedWork == null ? null : _createChapter,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Chapter'),
      ),
      child: Column(
        children: [
          DropdownButtonFormField<int>(
            initialValue: _selectedWork?.id,
            items: _works
                .map((work) => DropdownMenuItem(value: work.id, child: Text(work.title)))
                .toList(),
            onChanged: (value) {
              final next = _works.where((item) => item.id == value).firstOrNull;
              setState(() => _selectedWork = next);
              _loadChapters();
            },
            decoration: const InputDecoration(labelText: 'Pilih karya'),
          ),
          const SizedBox(height: 16),
          if (_busy)
            const Center(child: CircularProgressIndicator())
          else if (_chapters.isEmpty)
            const _SimpleCard(title: 'Belum ada chapter', subtitle: 'Buat chapter pertama untuk karya yang dipilih.')
          else
            ..._chapters.map(
              (chapter) => _ActionCard(
                title: chapter.title,
                subtitle: 'Chapter ${chapter.chapterNumber} • ${chapter.imagesCount} gambar • ${chapter.commentsCount} komentar',
                actions: [
                  TextButton.icon(
                    onPressed: () => _editChapter(chapter),
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Edit'),
                  ),
                  TextButton.icon(
                    onPressed: () => _deleteChapter(chapter),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Hapus'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _loadWorks() async {
    try {
      final response = await widget.apiClient.fetchUploaderWorks();
      if (!mounted) return;
      _works = response.items;
      _selectedWork = response.items.firstOrNull;
      _loading = false;
      setState(() {});
      await _loadChapters();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    }
  }

  Future<void> _loadChapters() async {
    final work = _selectedWork;
    if (work == null) return;
    setState(() => _busy = true);
    try {
      final response = await widget.apiClient.fetchUploaderChapters(work.id);
      if (!mounted) return;
      setState(() {
        _chapters = response.chapters;
        _busy = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.message;
      });
    }
  }

  Future<void> _createChapter() async {
    final work = _selectedWork;
    if (work == null) return;
    final result = await _showChapterDialog(context);
    if (result == null) return;
    try {
      await widget.apiClient.createUploaderChapter(
        workId: work.id,
        chapterNumber: result.chapterNumber,
        title: result.title,
        textContent: result.textContent,
      );
      if (!mounted) return;
      await _loadChapters();
      if (!mounted) return;
      _showSnack(context, 'Chapter berhasil dibuat.');
    } on ApiException catch (error) {
      if (!mounted) return;
      _showSnack(context, error.message, isError: true);
    }
  }

  Future<void> _editChapter(ChapterSummary chapter) async {
    final work = _selectedWork;
    if (work == null) return;
    try {
      final detail = await widget.apiClient.fetchUploaderChapter(
        workId: work.id,
        chapterId: chapter.id,
      );
      if (!mounted) return;
      final result = await _showChapterDialog(
        context,
        initialValue: _ChapterDialogValue(
          chapterNumber: detail.chapterNumber,
          title: detail.title,
          textContent: detail.textContent ?? '',
        ),
      );
      if (result == null) return;
      await widget.apiClient.updateUploaderChapter(
        workId: work.id,
        chapterId: chapter.id,
        chapterNumber: result.chapterNumber,
        title: result.title,
        textContent: result.textContent,
      );
      if (!mounted) return;
      await _loadChapters();
      if (!mounted) return;
      _showSnack(context, 'Chapter berhasil diperbarui.');
    } on ApiException catch (error) {
      if (!mounted) return;
      _showSnack(context, error.message, isError: true);
    }
  }

  Future<void> _deleteChapter(ChapterSummary chapter) async {
    final work = _selectedWork;
    if (work == null) return;
    final confirmed = await _confirm(context, 'Hapus ${chapter.title}?');
    if (!confirmed) return;
    try {
      await widget.apiClient.deleteUploaderChapter(
        workId: work.id,
        chapterId: chapter.id,
      );
      if (!mounted) return;
      await _loadChapters();
      if (!mounted) return;
      _showSnack(context, 'Chapter berhasil dihapus.');
    } on ApiException catch (error) {
      if (!mounted) return;
      _showSnack(context, error.message, isError: true);
    }
  }
}

class _UploaderImagesView extends StatefulWidget {
  const _UploaderImagesView({required this.apiClient});

  final UjikomApiClient apiClient;

  @override
  State<_UploaderImagesView> createState() => _UploaderImagesViewState();
}

class _UploaderImagesViewState extends State<_UploaderImagesView> {
  List<WorkSummary> _works = const [];
  WorkSummary? _selectedWork;
  List<ChapterSummary> _chapters = const [];
  ChapterSummary? _selectedChapter;
  List<ChapterImageItem> _images = const [];
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWorks();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorCard(message: _error!);
    }

    return _SectionScaffold(
      title: 'Kelola Gambar Chapter',
      subtitle: 'Upload, ubah urutan halaman, ganti file, dan hapus gambar.',
      action: FilledButton.icon(
        onPressed: _selectedChapter == null ? null : _uploadImages,
        icon: const Icon(Icons.upload_rounded),
        label: const Text('Upload Gambar'),
      ),
      child: Column(
        children: [
          DropdownButtonFormField<int>(
            initialValue: _selectedWork?.id,
            items: _works
                .map((work) => DropdownMenuItem(value: work.id, child: Text(work.title)))
                .toList(),
            onChanged: (value) {
              final next = _works.where((item) => item.id == value).firstOrNull;
              setState(() {
                _selectedWork = next;
                _selectedChapter = null;
                _images = const [];
              });
              _loadChapterOptions();
            },
            decoration: const InputDecoration(labelText: 'Pilih karya'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _selectedChapter?.id,
            items: _chapters
                .map(
                  (chapter) => DropdownMenuItem(
                    value: chapter.id,
                    child: Text('Chapter ${chapter.chapterNumber} - ${chapter.title}'),
                  ),
                )
                .toList(),
            onChanged: (value) {
              final next = _chapters.where((item) => item.id == value).firstOrNull;
              setState(() {
                _selectedChapter = next;
                _images = const [];
              });
              _loadImages();
            },
            decoration: const InputDecoration(labelText: 'Pilih chapter'),
          ),
          const SizedBox(height: 16),
          if (_busy)
            const Center(child: CircularProgressIndicator())
          else if (_selectedChapter == null)
            const _SimpleCard(title: 'Pilih chapter', subtitle: 'Pilih karya lalu chapter untuk melihat gambar.')
          else if (_images.isEmpty)
            const _SimpleCard(title: 'Belum ada gambar', subtitle: 'Upload gambar pertama untuk chapter ini.')
          else
            ..._images.map(
              (image) => _ActionCard(
                title: 'Halaman ${image.pageNumber}',
                subtitle: image.chapterTitle ?? 'Gambar chapter',
                leading: _buildCover(image.imageUrl, square: true),
                actions: [
                  TextButton.icon(
                    onPressed: () => _editImage(image),
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Edit'),
                  ),
                  TextButton.icon(
                    onPressed: () => _deleteImage(image),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Hapus'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _loadWorks() async {
    try {
      final response = await widget.apiClient.fetchUploaderWorks();
      if (!mounted) return;
      _works = response.items;
      _selectedWork = response.items.firstOrNull;
      _loading = false;
      setState(() {});
      await _loadChapterOptions();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    }
  }

  Future<void> _loadChapterOptions() async {
    final work = _selectedWork;
    if (work == null) return;
    setState(() => _busy = true);
    try {
      final response = await widget.apiClient.fetchUploaderChapters(work.id);
      if (!mounted) return;
      setState(() {
        _chapters = response.chapters;
        _selectedChapter = response.chapters.firstOrNull;
        _busy = false;
      });
      await _loadImages();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.message;
      });
    }
  }

  Future<void> _loadImages() async {
    final chapter = _selectedChapter;
    if (chapter == null) return;
    setState(() => _busy = true);
    try {
      final response = await widget.apiClient.fetchUploaderChapterImages(chapter.id);
      if (!mounted) return;
      setState(() {
        _images = response.images;
        _busy = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.message;
      });
    }
  }

  Future<void> _uploadImages() async {
    final chapter = _selectedChapter;
    if (chapter == null) return;
    final picked = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: true);
    final paths = picked?.paths.whereType<String>().toList() ?? const [];
    if (paths.isEmpty) return;
    try {
      await widget.apiClient.createUploaderChapterImages(
        chapterId: chapter.id,
        imagePaths: paths,
      );
      if (!mounted) return;
      await _loadImages();
      if (!mounted) return;
      _showSnack(context, 'Gambar berhasil diunggah.');
    } on ApiException catch (error) {
      if (!mounted) return;
      _showSnack(context, error.message, isError: true);
    }
  }

  Future<void> _editImage(ChapterImageItem image) async {
    final chapter = _selectedChapter;
    if (chapter == null) return;
    final result = await _showImageDialog(context, image.pageNumber);
    if (result == null) return;
    try {
      await widget.apiClient.updateUploaderChapterImage(
        chapterId: chapter.id,
        imageId: image.id,
        pageNumber: result.pageNumber,
        imagePath: result.filePath,
      );
      if (!mounted) return;
      await _loadImages();
      if (!mounted) return;
      _showSnack(context, 'Gambar berhasil diperbarui.');
    } on ApiException catch (error) {
      if (!mounted) return;
      _showSnack(context, error.message, isError: true);
    }
  }

  Future<void> _deleteImage(ChapterImageItem image) async {
    final chapter = _selectedChapter;
    if (chapter == null) return;
    final confirmed = await _confirm(context, 'Hapus gambar halaman ${image.pageNumber}?');
    if (!confirmed) return;
    try {
      await widget.apiClient.deleteUploaderChapterImage(
        chapterId: chapter.id,
        imageId: image.id,
      );
      if (!mounted) return;
      await _loadImages();
      if (!mounted) return;
      _showSnack(context, 'Gambar berhasil dihapus.');
    } on ApiException catch (error) {
      if (!mounted) return;
      _showSnack(context, error.message, isError: true);
    }
  }
}

class _SectionScaffold extends StatelessWidget {
  const _SectionScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(subtitle),
                ],
              ),
            ),
            if (action != null) action!,
          ],
        ),
        const SizedBox(height: 20),
        child,
      ],
    );
  }
}

class _SimpleCard extends StatelessWidget {
  const _SimpleCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.actions,
    this.leading,
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(subtitle),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: actions),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(message, style: TextStyle(color: Colors.red.shade900)),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label),
              const SizedBox(height: 6),
              Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

Widget? _buildCover(String? imageUrl, {bool square = false}) {
  if (imageUrl == null || imageUrl.isEmpty) {
    return null;
  }

  return ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: SizedBox(
      width: 72,
      height: square ? 72 : 96,
      child: NetworkCover(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
      ),
    ),
  );
}

class _PortalMenuItem {
  const _PortalMenuItem(this.label, this.icon, this.section);

  final String label;
  final IconData icon;
  final _PortalSection section;
}

enum _PortalSection {
  dashboard,
  approval,
  users,
  genres,
  works,
  chapters,
  images,
}

class _UserDialogResult {
  const _UserDialogResult({
    required this.name,
    required this.email,
    required this.roleId,
  });

  final String name;
  final String email;
  final int roleId;
}

class _WorkDialogValue {
  const _WorkDialogValue({
    required this.title,
    required this.originalAuthor,
    required this.description,
    required this.type,
    required this.genreIds,
  });

  final String title;
  final String originalAuthor;
  final String description;
  final String type;
  final List<int> genreIds;
}

class _WorkDialogResult extends _WorkDialogValue {
  const _WorkDialogResult({
    required super.title,
    required super.originalAuthor,
    required super.description,
    required super.type,
    required super.genreIds,
    required this.coverPath,
  });

  final String? coverPath;
}

class _ChapterDialogValue {
  const _ChapterDialogValue({
    required this.chapterNumber,
    required this.title,
    required this.textContent,
  });

  final int chapterNumber;
  final String title;
  final String textContent;
}

class _ImageDialogResult {
  const _ImageDialogResult({
    required this.pageNumber,
    required this.filePath,
  });

  final int pageNumber;
  final String? filePath;
}

class _UploaderWorkBundle {
  const _UploaderWorkBundle({
    required this.works,
    required this.genres,
  });

  final WorksPageResponse works;
  final List<GenreItem> genres;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

Future<_UserDialogResult?> _showUserDialog(
  BuildContext context,
  AdminUserItem user,
  List<RoleOption> roles,
) async {
  final nameController = TextEditingController(text: user.name);
  final emailController = TextEditingController(text: user.email);
  var selectedRoleId = user.roleId ?? roles.first.id;

  return showDialog<_UserDialogResult>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Edit Pengguna'),
      content: StatefulBuilder(
        builder: (context, setState) => SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nama')),
              const SizedBox(height: 12),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: selectedRoleId,
                items: roles.map((role) => DropdownMenuItem(value: role.id, child: Text(role.name))).toList(),
                onChanged: (value) => setState(() => selectedRoleId = value ?? selectedRoleId),
                decoration: const InputDecoration(labelText: 'Role'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _UserDialogResult(
              name: nameController.text.trim(),
              email: emailController.text.trim(),
              roleId: selectedRoleId,
            ),
          ),
          child: const Text('Simpan'),
        ),
      ],
    ),
  );
}

Future<String?> _showTextDialog(
  BuildContext context, {
  required String title,
  required String label,
  String initialValue = '',
}) async {
  final controller = TextEditingController(text: initialValue);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Simpan')),
      ],
    ),
  );
}

Future<_WorkDialogResult?> _showWorkDialog(
  BuildContext context, {
  required List<GenreItem> genres,
  _WorkDialogValue? initialValue,
}) async {
  final titleController = TextEditingController(text: initialValue?.title ?? '');
  final authorController = TextEditingController(text: initialValue?.originalAuthor ?? '');
  final descriptionController = TextEditingController(text: initialValue?.description ?? '');
  var selectedType = initialValue?.type ?? 'comic';
  final selectedGenreIds = {...?initialValue?.genreIds};
  String? coverPath;

  return showDialog<_WorkDialogResult>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(initialValue == null ? 'Tambah Karya' : 'Edit Karya'),
      content: StatefulBuilder(
        builder: (context, setState) => SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Judul')),
                const SizedBox(height: 12),
                TextField(controller: authorController, decoration: const InputDecoration(labelText: 'Original author')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  items: const [
                    DropdownMenuItem(value: 'comic', child: Text('Comic')),
                    DropdownMenuItem(value: 'novel', child: Text('Novel')),
                  ],
                  onChanged: (value) => setState(() => selectedType = value ?? selectedType),
                  decoration: const InputDecoration(labelText: 'Tipe karya'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Deskripsi'),
                ),
                const SizedBox(height: 16),
                const Text('Genre', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: genres
                      .map(
                        (genre) => FilterChip(
                          label: Text(genre.name),
                          selected: selectedGenreIds.contains(genre.id),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                selectedGenreIds.add(genre.id);
                              } else {
                                selectedGenreIds.remove(genre.id);
                              }
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await FilePicker.platform.pickFiles(type: FileType.image);
                    final path = picked?.files.single.path;
                    if (path != null) {
                      setState(() => coverPath = path);
                    }
                  },
                  icon: const Icon(Icons.image_rounded),
                  label: const Text('Pilih Cover'),
                ),
                const SizedBox(height: 8),
                Text(coverPath == null ? 'Cover lama/tanpa cover baru' : coverPath!.split('\\').last),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _WorkDialogResult(
              title: titleController.text.trim(),
              originalAuthor: authorController.text.trim(),
              description: descriptionController.text.trim(),
              type: selectedType,
              genreIds: selectedGenreIds.toList(),
              coverPath: coverPath,
            ),
          ),
          child: const Text('Simpan'),
        ),
      ],
    ),
  );
}

Future<_ChapterDialogValue?> _showChapterDialog(
  BuildContext context, {
  _ChapterDialogValue? initialValue,
}) async {
  final numberController = TextEditingController(text: '${initialValue?.chapterNumber ?? 1}');
  final titleController = TextEditingController(text: initialValue?.title ?? '');
  final textController = TextEditingController(text: initialValue?.textContent ?? '');

  return showDialog<_ChapterDialogValue>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(initialValue == null ? 'Tambah Chapter' : 'Edit Chapter'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: numberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Nomor chapter'),
              ),
              const SizedBox(height: 12),
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Judul chapter')),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                minLines: 5,
                maxLines: 8,
                decoration: const InputDecoration(labelText: 'Isi text chapter'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _ChapterDialogValue(
              chapterNumber: int.tryParse(numberController.text) ?? 1,
              title: titleController.text.trim(),
              textContent: textController.text,
            ),
          ),
          child: const Text('Simpan'),
        ),
      ],
    ),
  );
}

Future<_ImageDialogResult?> _showImageDialog(BuildContext context, int currentPage) async {
  final pageController = TextEditingController(text: '$currentPage');
  String? filePath;

  return showDialog<_ImageDialogResult>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Edit Gambar'),
      content: StatefulBuilder(
        builder: (context, setState) => SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Nomor halaman'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await FilePicker.platform.pickFiles(type: FileType.image);
                  final path = picked?.files.single.path;
                  if (path != null) {
                    setState(() => filePath = path);
                  }
                },
                icon: const Icon(Icons.image_rounded),
                label: const Text('Ganti File'),
              ),
              const SizedBox(height: 8),
              Text(filePath == null ? 'File lama tetap dipakai' : filePath!.split('\\').last),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _ImageDialogResult(
              pageNumber: int.tryParse(pageController.text) ?? currentPage,
              filePath: filePath,
            ),
          ),
          child: const Text('Simpan'),
        ),
      ],
    ),
  );
}

Future<bool> _confirm(BuildContext context, String message) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Konfirmasi'),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ya')),
      ],
    ),
  );
  return result ?? false;
}

void _showSnack(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red.shade700 : null,
    ),
  );
}
