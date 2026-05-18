import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elbeats/api/pantry.api.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/auth.provider.dart';

import 'dart:convert';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebasePantryAPI _pantryApi = FirebasePantryAPI();
  int _postCount = 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = context.watch<UserAuthProvider>().userObj;

    final displayName = user?.displayName?.isNotEmpty == true
        ? user!.displayName!
        : "User";
    final email = user?.email ?? "";

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: colorScheme.surface,
            elevation: 0,
            centerTitle: true,
            title: Text(
              displayName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              color: colorScheme.onSurface,
            ),
            actions: [
              IconButton(
                onPressed: () async {
                  await context.read<UserAuthProvider>().signOut();
                },
                icon: const Icon(Icons.logout_rounded),
                color: colorScheme.onSurface,
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(
                height: 1,
                thickness: 0.5,
                color: colorScheme.outlineVariant,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // Avatar + stats row
                  Row(
                    children: [
                      Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 42,
                          backgroundColor: colorScheme.primaryContainer,
                          child: Icon(
                            Icons.person,
                            size: 42,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),

                      const SizedBox(width: 32),

                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatColumn(
                              label: "Listings",
                              value: _postCount.toString(),
                            ),
                            _StatColumn(label: "Requests", value: "0"),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            // TODO: edit profile
                          },
                          child: const Text(
                            "Edit Profile",
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: colorScheme.outline),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          onPressed: () {
                            // TODO: share profile
                          },
                          icon: Icon(
                            Icons.person_add_alt_1_outlined,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: colorScheme.outlineVariant,
            ),
          ),

          SliverPersistentHeader(
            pinned: true,
            delegate: _ProfileTabBarDelegate(colorScheme: colorScheme),
          ),

          if (user == null)
            const SliverToBoxAdapter(
              child: SizedBox(
                height: 200,
                child: Center(child: Text("Sign in to view your pantry")),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              sliver: StreamBuilder<QuerySnapshot>(
                stream: _pantryApi.getUserItems(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            "Error loading pantry",
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                      child: SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  _postCount = docs.length;

                  if (docs.isEmpty) {
                    return SliverToBoxAdapter(
                      child: _EmptyPantryState(colorScheme: colorScheme),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;

                      return _MyPostCard(docId: doc.id, data: data);
                    }, childCount: docs.length),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _PantryGridTile extends StatelessWidget {
  final String? imageBase64;
  final ColorScheme colorScheme;

  const _PantryGridTile({required this.imageBase64, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: open item detail
      },
      child: imageBase64 != null && imageBase64!.isNotEmpty
          ? Image.memory(
              base64Decode(imageBase64!),
              fit: BoxFit.cover,
              errorBuilder: (_, error, stackTrace) {
                return _placeholder();
              },
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      color: colorScheme.primaryContainer,
      child: Center(
        child: Icon(
          Icons.kitchen_rounded,
          size: 36,
          color: colorScheme.primary.withOpacity(0.5),
        ),
      ),
    );
  }
}

class _EmptyPantryState extends StatelessWidget {
  final ColorScheme colorScheme;
  const _EmptyPantryState({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 60.0),
      child: Column(
        children: [
          Icon(
            Icons.kitchen_outlined,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            "Your pantry is empty",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Add to your pantry to see it here.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTabBarDelegate extends SliverPersistentHeaderDelegate {
  final ColorScheme colorScheme;

  _ProfileTabBarDelegate({required this.colorScheme});

  @override
  double get minExtent => 44;
  @override
  double get maxExtent => 44;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: colorScheme.surface,
      child: Row(
        children: [
          _TabButton(
            label: "My Pantry",
            icon: Icons.grid_view_rounded,
            isSelected: true,
            colorScheme: colorScheme,
          ),
          _TabButton(
            label: "Requests",
            icon: Icons.arrow_forward_rounded,
            isSelected: false,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ProfileTabBarDelegate oldDelegate) {
    return oldDelegate.colorScheme != colorScheme;
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final ColorScheme colorScheme;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: () {
          // TODO: switch tab
        },
        child: Container(
          height: 44,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyPostCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;

  const _MyPostCard({required this.docId, required this.data});

  @override
  Widget build(BuildContext context) {
    final imageBase64 = data['imageBase64'];
    final itemName = data['name'] ?? "Unnamed Item";
    final shelfLife = data['shelfLife'] ?? "Unknown";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 180,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 5),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              child: imageBase64 != null
                  ? Image.memory(
                      base64Decode(imageBase64),
                      fit: BoxFit.cover,
                      height: double.infinity,
                      width: double.infinity,
                    )
                  : Container(color: Colors.grey),
            ),
          ),

          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['postType'] ?? "PANTRY",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    itemName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    shelfLife,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),

                  const Spacer(),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () async {
                        await FirebasePantryAPI().deleteFoodItem(docId);
                      },
                      child: const Text("Delete Item"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
