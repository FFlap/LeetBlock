import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/leet_block_provider.dart';

class AppSelectionScreen extends StatefulWidget {
  const AppSelectionScreen({super.key});

  @override
  State<AppSelectionScreen> createState() => _AppSelectionScreenState();
}

class _AppSelectionScreenState extends State<AppSelectionScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeetBlockProvider>().loadInstalledApps();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D1117),
              Color(0xFF161B22),
              Color(0xFF0D1117),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              Expanded(child: _buildAppsList()),
              _buildDoneButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Apps to Block',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Consumer<LeetBlockProvider>(
                  builder: (context, provider, _) {
                    final blockedCount = provider.blockedApps.length;
                    return Text(
                      '$blockedCount app${blockedCount == 1 ? '' : 's'} selected',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFFFFA116),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        style: GoogleFonts.inter(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search apps...',
          hintStyle: GoogleFonts.inter(color: Colors.white30),
          prefixIcon: const Icon(Icons.search, color: Colors.white38),
          filled: true,
          fillColor: const Color(0xFF21262D),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value.toLowerCase());
        },
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildAppsList() {
    return Consumer<LeetBlockProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.allApps.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFFA116),
            ),
          );
        }

        final filteredApps = provider.allApps.where((app) {
          return app.appName.toLowerCase().contains(_searchQuery);
        }).toList();

        if (filteredApps.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: Colors.white24,
                ),
                const SizedBox(height: 16),
                Text(
                  'No apps found',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredApps.length,
          itemBuilder: (context, index) {
            final app = filteredApps[index];
            return _buildAppTile(app, provider);
          },
        );
      },
    );
  }

  Widget _buildAppTile(app, LeetBlockProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: app.isBlocked
            ? const Color(0xFFFFA116).withOpacity(0.1)
            : const Color(0xFF21262D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: app.isBlocked
              ? const Color(0xFFFFA116).withOpacity(0.5)
              : Colors.transparent,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(12),
          ),
          child: app.icon != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    app.icon!,
                    width: 48,
                    height: 48,
                  ),
                )
              : const Icon(
                  Icons.android,
                  color: Colors.white38,
                ),
        ),
        title: Text(
          app.appName,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        trailing: GestureDetector(
          onTap: () => provider.toggleAppBlocking(app.packageName),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: app.isBlocked
                  ? const Color(0xFFFFA116)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: app.isBlocked
                    ? const Color(0xFFFFA116)
                    : Colors.white24,
                width: 2,
              ),
            ),
            child: app.isBlocked
                ? const Icon(
                    Icons.check,
                    color: Colors.black,
                    size: 18,
                  )
                : null,
          ),
        ),
        onTap: () => provider.toggleAppBlocking(app.packageName),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 50 * (provider.allApps.indexOf(app) % 10)));
  }

  Widget _buildDoneButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Consumer<LeetBlockProvider>(
        builder: (context, provider, _) {
          return SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA116),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                provider.blockedApps.isEmpty
                    ? 'Continue without blocking'
                    : 'Block ${provider.blockedApps.length} app${provider.blockedApps.length == 1 ? '' : 's'}',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(delay: 200.ms);
  }
}

