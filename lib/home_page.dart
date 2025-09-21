import 'package:flutter/material.dart';
import 'package:laporin_app/main.dart';
import 'package:laporin_app/services/auth_storage.dart';
import '../services/api_service.dart';

/// Halaman Home untuk Warga
/// - Tab 1: List Pengaduan
/// - Tab 2: Tambah Pengaduan
/// - Tab 3: Profil + Logout
class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.api});
  final ApiService api;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporin — Warga')),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _PengaduanListTab(api: widget.api),
          _TambahPengaduanTab(api: widget.api),
          _ProfilTab(api: widget.api),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Pengaduan',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Tambah',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

// ==================== TAB: LIST PENGADUAN ====================
class _PengaduanListTab extends StatefulWidget {
  const _PengaduanListTab({required this.api});
  final ApiService api;

  @override
  State<_PengaduanListTab> createState() => _PengaduanListTabState();
}

class _PengaduanListTabState extends State<_PengaduanListTab> {
  late Future<ComplaintsPage> _future;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _future = widget.api.fetchMyComplaints(page: _page);
  }

  Future<void> _reload({int? toPage}) async {
    if (toPage != null) _page = toPage;
    setState(() {
      _future = widget.api.fetchMyComplaints(page: _page);
    });
    await _future;
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'submitted':
        return Colors.blueGrey;
      case 'in_review':
        return Colors.orange;
      case 'resolved':
      case 'finished':
      case 'selesai':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _reload(toPage: 1), // pull-to-refresh: reset ke page 1
      child: FutureBuilder<ComplaintsPage>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Gagal memuat pengaduan'),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _reload,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final data = snap.data!;
          final items = data.items;

          if (items.isEmpty) {
            return const Center(child: Text('Belum ada pengaduan'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final it = items[i];
              final color = _statusColor(it.status);

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    it.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        it.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              it.status,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.category_outlined, size: 16),
                              const SizedBox(width: 6),
                              Text(it.category),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.schedule, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                it.createdAt.toIso8601String().split('T').first,
                              ),
                            ],
                          ),
                          if (it.handlerName != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.engineering_outlined,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text('PIC: ${it.handlerName}'),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      showDragHandle: true,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      builder: (context) => Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              it.title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(it.content),
                            const SizedBox(height: 12),
                            Text('Kategori: ${it.category}'),
                            Text('Status: ${it.status}'),
                            Text('Tanggal: ${it.createdAt.toIso8601String()}'),
                            if (it.handlerName != null)
                              Text('Penangan: ${it.handlerName}'),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ==================== TAB: TAMBAH PENGADUAN ====================
class _TambahPengaduanTab extends StatefulWidget {
  const _TambahPengaduanTab({required this.api});
  final ApiService api;

  @override
  State<_TambahPengaduanTab> createState() => _TambahPengaduanTabState();
}

class _TambahPengaduanTabState extends State<_TambahPengaduanTab> {
  final _formKey = GlobalKey<FormState>();
  final _judulC = TextEditingController();
  final _jenisC = TextEditingController();
  final _deskripsiC = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _judulC.dispose();
    _jenisC.dispose();
    _deskripsiC.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await widget.api.createComplaint(
        title: _judulC.text.trim(),
        content: _deskripsiC.text.trim(),
        category: _jenisC.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengaduan berhasil dikirim')),
      );

      // Bersihkan form
      _formKey.currentState!.reset();
      _judulC.clear();
      _jenisC.clear();
      _deskripsiC.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengirim: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _judulC,
                  decoration: const InputDecoration(
                    labelText: 'Judul Pengaduan',
                    prefixIcon: Icon(Icons.edit_outlined),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Judul wajib diisi'
                      : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _jenisC,
                  decoration: const InputDecoration(
                    labelText: 'Jenis Pengaduan',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Jenis wajib diisi'
                      : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _deskripsiC,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                  validator: (v) => v == null || v.trim().length < 10
                      ? 'Deskripsi minimal 10 karakter'
                      : null,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Kirim Pengaduan'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== TAB: PROFIL ====================
class _ProfilTab extends StatefulWidget {
  const _ProfilTab({required this.api});
  final ApiService api;

  @override
  State<_ProfilTab> createState() => _ProfilTabState();
}

class _ProfilTabState extends State<_ProfilTab> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchProfile();
  }

  Future<Map<String, dynamic>> _fetchProfile() async {
    try {
      // TODO: ganti dengan pemanggilan API asli, contoh:
      // final res = await widget.api.getProfile();
      // return res;
      await Future.delayed(const Duration(milliseconds: 300));
      return {
        'name': 'Andi Suartika',
        'email': 'andi@example.com',
        'phone': '081234567890',
        'address': 'Singaraja, Bali',
      };
    } catch (e) {
      rethrow;
    }
  }

  void _logout() async {
    // TODO: panggil endpoint logout jika ada
    await AuthStorage.clearToken(); // hapus token lokal
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MyApp()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Gagal memuat profil'),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => setState(() => _future = _fetchProfile()),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }
        final user = snap.data ?? {};
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 28,
                            child: Icon(Icons.person, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user['name']?.toString() ?? '-',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(user['email']?.toString() ?? '-'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.phone_outlined),
                    title: Text(user['phone']?.toString() ?? '-'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(user['address']?.toString() ?? '-'),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
