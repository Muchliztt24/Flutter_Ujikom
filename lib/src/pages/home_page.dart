import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/auth_user.dart';
import '../models/work.dart';
import '../services/api_config_store.dart';
import '../services/auth_session_store.dart';
import '../services/laravel_web_links.dart';
import '../services/ujikom_api_client.dart';
import '../widgets/network_cover.dart';
import '../widgets/nokomi_brand.dart';
import 'auth_page.dart';
import 'role_portal_page.dart';
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

    setState(() {
      _baseUrl = baseUrl;
      _session = verifiedSession;
      _worksFuture = _createClient().fetchWorks();
    });
  }

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

  Future<void> _openApiConfig() async {
    final controller = TextEditingController(text: _baseUrl);

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1F2E),
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Konfigurasi API',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pilih preset URL Laravel yang ingin dipakai.',
                style: TextStyle(color: Color(0xFF9AA0A6)),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final preset in ApiConfigStore.presets)
                    ActionChip(
                      label: Text(preset),
                      onPressed: () => controller.text = preset,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Base URL API',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, controller.text),
                  child: const Text('Simpan'),
                ),
              ),
            ],
          ),
        );
      },
    );

    controller.dispose();

    if (result == null || result.trim().isEmpty || !mounted) {
      return;
    }

    await _configStore.saveBaseUrl(result.trim());
    setState(() {
      _baseUrl = result.trim();
      _worksFuture = _createClient().fetchWorks();
    });
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
        baseUrl: _baseUrl,
        onOpenAuth: _openAuthPage,
        onOpenPortal: () async {
          if (_session == null) return;
          await Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => RolePortalPage(
                session: _session!,
                apiClient: UjikomApiClient(
                  baseUrl: _baseUrl,
                  authToken: _session!.token,
                ),
                webBaseUrl: LaravelWebLinks.webBaseFromApi(_baseUrl),
              ),
            ),
          );
        },
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
                onTap: () {
                  launchUrl(Uri.parse(LaravelWebLinks.faq(_baseUrl)));
                },
              ),
            if (!isCompact)
              _TopLink(
                label: 'News',
                icon: Icons.newspaper_rounded,
                onTap: () {
                  launchUrl(Uri.parse(LaravelWebLinks.news(_baseUrl)));
                },
              ),
            _UserAction(
              session: _session,
              baseUrl: _baseUrl,
              onLogin: _openAuthPage,
              onLogout: _logout,
            ),
            IconButton(
              onPressed: _openApiConfig,
              icon: const Icon(Icons.tune_rounded),
              tooltip: 'Atur API',
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
    required this.baseUrl,
    required this.onOpenAuth,
    required this.onOpenPortal,
    required this.onLogout,
  });

  final AuthSession? session;
  final String baseUrl;
  final Future<void> Function() onOpenAuth;
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
            const Row(
              children: [
                Icon(Icons.close_rounded, color: Colors.white70),
                SizedBox(width: 16),
                Expanded(child: NokomiBrand(compact: true)),
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
              icon: Icons.bookmark_rounded,
              label: 'Bookmarks',
              onTap: () {
                launchUrl(Uri.parse(
                    '${LaravelWebLinks.webBaseFromApi(baseUrl)}/bookmarks'));
              },
            ),
            _SidebarLink(
              icon: Icons.inventory_2_rounded,
              label: 'Collection',
              onTap: () {
                launchUrl(Uri.parse(
                    '${LaravelWebLinks.webBaseFromApi(baseUrl)}/collection'));
              },
            ),
            const SizedBox(height: 20),
            const _SidebarSectionTitle('Browse'),
            _SidebarLink(
              icon: Icons.sell_rounded,
              label: 'Genre',
              trailing:
                  const Icon(Icons.expand_more_rounded, color: Colors.white54),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Filter genre akan aku sambungkan berikutnya.')),
                );
              },
            ),
            const SizedBox(height: 20),
            const _SidebarSectionTitle('Library'),
            _SidebarLink(
              icon: Icons.history_rounded,
              label: 'History',
              onTap: () {
                launchUrl(Uri.parse(
                    '${LaravelWebLinks.webBaseFromApi(baseUrl)}/history'));
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
                        onOpenAuth();
                      } else {
                        launchUrl(Uri.parse(LaravelWebLinks.profile(baseUrl)));
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
                      onTap: onOpenPortal,
                    ),
                  ],
                  if (session != null) ...[
                    const SizedBox(height: 8),
                    _SidebarActionButton(
                      icon: Icons.logout_rounded,
                      label: 'Sign Out',
                      danger: true,
                      onTap: onLogout,
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
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Icon(icon, color: const Color(0xFFE8EAED)),
      title: Text(
        label,
        style: const TextStyle(color: Color(0xFFE8EAED)),
      ),
      trailing: trailing,
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
    required this.baseUrl,
    required this.onLogin,
    required this.onLogout,
  });

  final AuthSession? session;
  final String baseUrl;
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
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => RolePortalPage(
                session: session!,
                apiClient: UjikomApiClient(
                  baseUrl: baseUrl,
                  authToken: session!.token,
                ),
                webBaseUrl: LaravelWebLinks.webBaseFromApi(baseUrl),
              ),
            ),
          );
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
