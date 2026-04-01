import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/auth_user.dart';
import '../models/work.dart';
import '../services/api_config_store.dart';
import '../services/auth_session_store.dart';
import '../services/ujikom_api_client.dart';
import '../widgets/network_cover.dart';
import '../widgets/nokomi_brand.dart';
import 'auth_page.dart';
import 'role_portal_page.dart';
import 'simple_pages.dart';
import 'work_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ApiConfigStore _configStore = ApiConfigStore();
  final AuthSessionStore _sessionStore = AuthSessionStore();
  final TextEditingController _searchController = TextEditingController();

  Future<List<WorkSummary>>? _worksFuture;
  String _baseUrl = ApiConfigStore.presets.first;
  String _query = '';
  String _selectedType = 'all';
  AuthSession? _session;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final baseUrl = await _configStore.loadBaseUrl();
    final storedSession = await _sessionStore.loadSession();

    AuthSession? verifiedSession = storedSession;
    if (storedSession != null) {
      try {
        final user = await UjikomApiClient(
          baseUrl: baseUrl,
          authToken: storedSession.token,
        ).fetchMe();
        verifiedSession = AuthSession(
          token: storedSession.token,
          tokenType: storedSession.tokenType,
          user: user,
        );
        await _sessionStore.saveSession(verifiedSession);
      } catch (_) {
        verifiedSession = null;
        await _sessionStore.clearSession();
      }
    }

    if (!mounted) {
      return;
    }

    final future = _createClientFor(baseUrl, verifiedSession).fetchWorks();

    setState(() {
      _baseUrl = baseUrl;
      _session = verifiedSession;
      _worksFuture = future;
    });
  }

  UjikomApiClient _createClientFor(String baseUrl, AuthSession? session) =>
      UjikomApiClient(
        baseUrl: baseUrl,
        authToken: session?.token,
      );

  UjikomApiClient _createClient() => UjikomApiClient(
        baseUrl: _baseUrl,
        authToken: _session?.token,
      );

  Future<void> _refresh() async {
    final future = _createClient().fetchWorks();
    setState(() {
      _worksFuture = future;
    });
    await future;
  }

  Future<void> _openAuthPage() async {
    final session = await Navigator.push<AuthSession>(
      context,
      MaterialPageRoute<AuthSession>(
        builder: (_) => AuthPage(apiClient: _createClient()),
      ),
    );

    if (session == null || !mounted) {
      return;
    }

    await _sessionStore.saveSession(session);
    setState(() {
      _session = session;
    });
  }

  Future<void> _openRolePortal() async {
    if (_session == null) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => RolePortalPage(
          session: _session!,
          apiClient: UjikomApiClient(
            baseUrl: _baseUrl,
            authToken: _session!.token,
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await _createClient().logout();
    } catch (_) {
      // Clear local session even when remote token is already invalid.
    }

    await _sessionStore.clearSession();
    if (!mounted) {
      return;
    }

    setState(() {
      _session = null;
    });
  }

  Future<void> _openFaqPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => FaqPage(apiClient: _createClient()),
      ),
    );
  }

  Future<void> _openNewsPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => NewsPage(apiClient: _createClient()),
      ),
    );
  }

  Future<void> _openBookmarksPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => BookmarksPage(apiClient: _createClient()),
      ),
    );
  }

  Future<void> _openHistoryPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => HistoryPage(apiClient: _createClient()),
      ),
    );
  }

  Future<void> _openCollectionPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => CollectionPage(apiClient: _createClient()),
      ),
    );
  }

  Future<void> _openGenrePage() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => GenrePage(apiClient: _createClient()),
      ),
    );
  }

  Future<void> _openNotificationsPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => NotificationsPage(apiClient: _createClient()),
      ),
    );
  }

  List<WorkSummary> _applyFilters(List<WorkSummary> works) {
    return works.where((work) {
      final matchesType = _selectedType == 'all' || work.type == _selectedType;
      final query = _query.toLowerCase();
      final matchesQuery = query.isEmpty ||
          work.title.toLowerCase().contains(query) ||
          (work.author?.toLowerCase().contains(query) ?? false) ||
          work.genres.any((genre) => genre.toLowerCase().contains(query));

      return matchesType && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      key: _scaffoldKey,
      drawer: _UserSidebar(
        session: _session,
        onOpenAuth: _openAuthPage,
        onOpenFaq: _openFaqPage,
        onOpenNews: _openNewsPage,
        onOpenBookmarks: _openBookmarksPage,
        onOpenCollection: _openCollectionPage,
        onOpenGenre: _openGenrePage,
        onOpenHistory: _openHistoryPage,
        onOpenNotifications: _openNotificationsPage,
        onOpenPortal: _openRolePortal,
        onLogout: _logout,
      ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          backgroundColor: const Color(0xFF0F1419),
          automaticallyImplyLeading: false,
          titleSpacing: 16,
          leadingWidth: 64,
          leading: IconButton(
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            icon: const Icon(Icons.menu_rounded),
            tooltip: 'Menu',
          ),
          title: NokomiBrand(
            compact: isCompact,
            showText: true,
          ),
          actions: [
            if (!isCompact)
              _TopLink(
                label: 'FAQ',
                icon: Icons.help_outline_rounded,
                onTap: _openFaqPage,
              ),
            if (!isCompact)
              _TopLink(
                label: 'News',
                icon: Icons.newspaper_rounded,
                onTap: _openNewsPage,
              ),
            IconButton(
              onPressed: _openNotificationsPage,
              icon: const Icon(Icons.notifications_none_rounded),
              tooltip: 'Notifications',
            ),
            _UserAction(
              session: _session,
              onOpenPortal: _openRolePortal,
              onLogin: _openAuthPage,
              onLogout: _logout,
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
      body: _worksFuture == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<WorkSummary>>(
              future: _worksFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return _ErrorState(
                    message: snapshot.error.toString(),
                    onRetry: _refresh,
                  );
                }

                final filteredWorks = _applyFilters(snapshot.requireData);

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Color(0xFFE8EAED)),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search_rounded),
                          hintText: 'Cari judul, author, atau genre',
                        ),
                        onChanged: (value) => setState(() => _query = value),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _TypeChip(
                            label: 'Semua',
                            selected: _selectedType == 'all',
                            onSelected: () =>
                                setState(() => _selectedType = 'all'),
                          ),
                          _TypeChip(
                            label: 'Comic',
                            selected: _selectedType == 'comic',
                            onSelected: () =>
                                setState(() => _selectedType = 'comic'),
                          ),
                          _TypeChip(
                            label: 'Novel',
                            selected: _selectedType == 'novel',
                            onSelected: () =>
                                setState(() => _selectedType = 'novel'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          int count = (width / 220).floor();
                          count = math.max(1, count);
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredWorks.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: count,
                              crossAxisSpacing: 24,
                              mainAxisSpacing: 24,
                              childAspectRatio: 0.63,
                            ),
                            itemBuilder: (context, index) {
                              final work = filteredWorks[index];
                              return _WorkCard(
                                work: work,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) => WorkDetailPage(
                                        apiClient: _createClient(),
                                        work: work,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Showing 1 to ${filteredWorks.length} of ${snapshot.requireData.length} results',
                        style: const TextStyle(
                          color: Color(0xFF9AA0A6),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Karya Terbaru',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: Color(0xFFE8EAED),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Karya yang baru saja disetujui dan siap dibaca',
          style: TextStyle(
            color: Color(0xFF9AA0A6),
            fontSize: 14,
          ),
        ),
        if (_session != null) ...[
          const SizedBox(height: 12),
          Text(
            'Masuk sebagai ${_session!.user.name} (${_session!.user.role})',
            style: const TextStyle(
              color: Color(0xFF48C9B0),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _TopLink extends StatelessWidget {
  const _TopLink({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF9AA0A6),
      ),
    );
  }
}

class _UserSidebar extends StatelessWidget {
  const _UserSidebar({
    required this.session,
    required this.onOpenAuth,
    required this.onOpenFaq,
    required this.onOpenNews,
    required this.onOpenBookmarks,
    required this.onOpenCollection,
    required this.onOpenGenre,
    required this.onOpenHistory,
    required this.onOpenNotifications,
    required this.onOpenPortal,
    required this.onLogout,
  });

  final AuthSession? session;
  final Future<void> Function() onOpenAuth;
  final Future<void> Function() onOpenFaq;
  final Future<void> Function() onOpenNews;
  final Future<void> Function() onOpenBookmarks;
  final Future<void> Function() onOpenCollection;
  final Future<void> Function() onOpenGenre;
  final Future<void> Function() onOpenHistory;
  final Future<void> Function() onOpenNotifications;
  final Future<void> Function() onOpenPortal;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF1A1F2E),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                ),
                const SizedBox(width: 8),
                const Expanded(child: NokomiBrand(compact: true)),
              ],
            ),
            const SizedBox(height: 28),
            const _SidebarSectionTitle('Menu Utama'),
            _SidebarLink(
              icon: Icons.search_rounded,
              label: 'Search',
              onTap: () => Navigator.pop(context),
            ),
            _SidebarLink(
              icon: Icons.help_outline_rounded,
              label: 'FAQ',
              onTap: () async {
                Navigator.pop(context);
                await onOpenFaq();
              },
            ),
            _SidebarLink(
              icon: Icons.newspaper_rounded,
              label: 'News',
              onTap: () async {
                Navigator.pop(context);
                await onOpenNews();
              },
            ),
            _SidebarLink(
              icon: Icons.notifications_none_rounded,
              label: 'Notifications',
              onTap: () async {
                Navigator.pop(context);
                await onOpenNotifications();
              },
            ),
            _SidebarLink(
              icon: Icons.bookmark_rounded,
              label: 'Bookmarks',
              onTap: () async {
                Navigator.pop(context);
                await onOpenBookmarks();
              },
            ),
            _SidebarLink(
              icon: Icons.inventory_2_rounded,
              label: 'Collection',
              onTap: () async {
                Navigator.pop(context);
                await onOpenCollection();
              },
            ),
            const SizedBox(height: 20),
            const _SidebarSectionTitle('Browse'),
            _SidebarLink(
              icon: Icons.sell_rounded,
              label: 'Genre',
              onTap: () async {
                Navigator.pop(context);
                await onOpenGenre();
              },
            ),
            const SizedBox(height: 20),
            const _SidebarSectionTitle('Library'),
            _SidebarLink(
              icon: Icons.history_rounded,
              label: 'History',
              onTap: () async {
                Navigator.pop(context);
                await onOpenHistory();
              },
            ),
            const SizedBox(height: 20),
            const _SidebarSectionTitle('Profile'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFF21313B),
                border: Border.all(color: const Color(0xFF275465)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session?.user.name ?? 'Guest',
                    style: const TextStyle(
                      color: Color(0xFFE8EAED),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    session?.user.role ?? 'visitor',
                    style: const TextStyle(color: Color(0xFF9AA0A6)),
                  ),
                  const SizedBox(height: 14),
                  _SidebarActionButton(
                    icon: Icons.person_rounded,
                    label:
                        session == null ? 'Login / Register' : 'Edit Profile',
                    onTap: () {
                      if (session == null) {
                        Navigator.pop(context);
                        onOpenAuth();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Edit profile native belum selesai.'),
                          ),
                        );
                      }
                    },
                  ),
                  if (session != null &&
                      (session!.user.role == 'admin' ||
                          session!.user.role == 'uploader')) ...[
                    const SizedBox(height: 8),
                    _SidebarActionButton(
                      icon: Icons.dashboard_rounded,
                      label: 'Dashboard',
                      onTap: () async {
                        Navigator.pop(context);
                        await onOpenPortal();
                      },
                    ),
                  ],
                  if (session != null) ...[
                    const SizedBox(height: 8),
                    _SidebarActionButton(
                      icon: Icons.logout_rounded,
                      label: 'Sign Out',
                      danger: true,
                      onTap: () async {
                        Navigator.pop(context);
                        await onLogout();
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarSectionTitle extends StatelessWidget {
  const _SidebarSectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF8A909D),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _SidebarLink extends StatelessWidget {
  const _SidebarLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Icon(icon, color: const Color(0xFFE8EAED)),
      title: Text(
        label,
        style: const TextStyle(color: Color(0xFFE8EAED)),
      ),
      onTap: onTap,
    );
  }
}

class _SidebarActionButton extends StatelessWidget {
  const _SidebarActionButton({
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
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor:
              danger ? const Color(0xFF5A3843) : const Color(0xFF15252C),
          foregroundColor: const Color(0xFFE8EAED),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }
}

class _UserAction extends StatelessWidget {
  const _UserAction({
    required this.session,
    required this.onOpenPortal,
    required this.onLogin,
    required this.onLogout,
  });

  final AuthSession? session;
  final Future<void> Function() onOpenPortal;
  final Future<void> Function() onLogin;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    if (session == null) {
      return IconButton(
        onPressed: onLogin,
        icon: const Icon(Icons.account_circle_outlined),
        tooltip: 'Login / Register',
      );
    }

    return PopupMenuButton<String>(
      tooltip: 'Akun',
      onSelected: (value) {
        if (value == 'dashboard') {
          onOpenPortal();
          return;
        }

        if (value == 'logout') {
          onLogout();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          value: 'user',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(session!.user.name),
              Text(
                session!.user.email,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
        if (session!.user.role == 'admin' || session!.user.role == 'uploader')
          const PopupMenuItem<String>(
            value: 'dashboard',
            child: Text('Dashboard'),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Text('Logout'),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: CircleAvatar(
          radius: 17,
          backgroundColor: const Color(0xFF2D8B73),
          child: Text(
            session!.user.initial,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      backgroundColor: const Color(0xFF1A1F2E),
      selectedColor: const Color(0xFF2D8B73),
      side: const BorderSide(color: Color(0xFF2D3748)),
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : const Color(0xFFE8EAED),
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _WorkCard extends StatelessWidget {
  const _WorkCard({
    required this.work,
    required this.onTap,
  });

  final WorkSummary work;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2D3748)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: work.coverUrl != null && work.coverUrl!.isNotEmpty
                          ? NetworkCover(
                              imageUrl: work.coverUrl!,
                              fit: BoxFit.cover,
                              errorWidget: _CoverFallback(type: work.type),
                            )
                          : _CoverFallback(type: work.type),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _Badge(
                      label: work.type == 'novel' ? 'NOVEL' : 'COMIC',
                      icon: work.type == 'novel'
                          ? Icons.menu_book_rounded
                          : Icons.palette_rounded,
                      color: work.type == 'novel'
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFFF97316),
                    ),
                  ),
                  if (work.chaptersCount > 0)
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: _Badge(
                        label: '${work.chaptersCount} Ch',
                        icon: Icons.collections_bookmark_rounded,
                        color: const Color(0xFF2D8B73),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 40,
                    child: Text(
                      work.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE8EAED),
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFBBF24),
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _fakeRating(work.id),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Flexible(
                        child: Text(
                          'by ${work.author ?? '-'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF9AA0A6),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fakeRating(int seed) {
    final rating = 4 + ((seed % 11) / 10);
    return rating.toStringAsFixed(1);
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverFallback extends StatelessWidget {
  const _CoverFallback({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF20473E),
      child: Center(
        child: Icon(
          type == 'novel' ? Icons.menu_book_rounded : Icons.palette_rounded,
          size: 56,
          color: Colors.white70,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_tethering_error_rounded,
              size: 48,
              color: Colors.white70,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFE8EAED)),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Muat ulang'),
            ),
          ],
        ),
      ),
    );
  }
}
