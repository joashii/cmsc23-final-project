import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elbeats/api/pantry.api.dart';
import 'package:elbeats/components/request_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/auth.provider.dart';
import 'dart:convert';
import 'food_details_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebasePantryAPI _pantryApi = FirebasePantryAPI();
  int _selectedTab = 0;

  Stream<DocumentSnapshot> _userDocStream(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots();
  }

  Widget _buildPantryTab(String uid, ColorScheme colorScheme) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      sliver: StreamBuilder<QuerySnapshot>(
        stream: _pantryApi.getUserItems(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return SliverToBoxAdapter(
              child: _EmptyPantryState(colorScheme: colorScheme),
            );
          }

          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;

                return _MyPostCard(docId: doc.id, data: data);
              },
              childCount: docs.length,
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestsTab(String uid, ColorScheme colorScheme) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      sliver: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('claims')
            .where('requesterID', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final claims = snapshot.data!.docs;

          if (claims.isEmpty) {
            return const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text("No requests yet."),
              ),
            );
          }

          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final claim = claims[index].data() as Map<String, dynamic>;
                final itemId = claim['itemID'];

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('food_items')
                      .doc(itemId)
                      .get(),
                  builder: (context, itemSnap) {
                    if (!itemSnap.hasData) {
                      return const SizedBox(
                        height: 80,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final item =
                        itemSnap.data!.data() as Map<String, dynamic>;

                    return RequestCard(
                      itemId: itemId,
                      item: item,
                      claim: claim,
                      claimId: claims[index].id,
                    );
                  },
                );
              },
              childCount: claims.length,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authUser = context.watch<UserAuthProvider>().userObj;

    if (authUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: _userDocStream(authUser.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userData =
            snapshot.data!.data() as Map<String, dynamic>? ?? {};

        final displayName = userData['username'] ?? "User";
        final email = userData['email'] ?? "";

        final listingsStream = FirebaseFirestore.instance
            .collection('food_items')
            .where('ownerId', isEqualTo: authUser.uid)
            .snapshots();

        final claimsStream = FirebaseFirestore.instance
            .collection('claims')
            .where('requesterID', isEqualTo: authUser.uid)
            .snapshots();

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
                actions: [
                  IconButton(
                    onPressed: () async {
                      await context.read<UserAuthProvider>().signOut();
                    },
                    icon: const Icon(Icons.logout_rounded),
                  )
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          CircleAvatar(
                            radius: 42,
                            backgroundColor: colorScheme.primaryContainer,
                            child: Icon(Icons.person,
                                size: 42, color: colorScheme.primary),
                          ),
                          const SizedBox(width: 32),

                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                StreamBuilder<QuerySnapshot>(
                                  stream: listingsStream,
                                  builder: (context, snapshot) {
                                    return _StatColumn(
                                      label: "Listings",
                                      value:
                                          (snapshot.data?.docs.length ?? 0)
                                              .toString(),
                                    );
                                  },
                                ),
                                StreamBuilder<QuerySnapshot>(
                                  stream: claimsStream,
                                  builder: (context, snapshot) {
                                    return _StatColumn(
                                      label: "Requests",
                                      value:
                                          (snapshot.data?.docs.length ?? 0)
                                              .toString(),
                                    );
                                  },
                                ),
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
                            Text(displayName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(email),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: () {},
                              child: const Text("Edit Profile"),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              SliverPersistentHeader(
                pinned: true,
                delegate: _ProfileTabBarDelegate(
                  colorScheme: colorScheme,
                  selectedIndex: _selectedTab,
                  onTabChanged: (index) {
                    setState(() => _selectedTab = index);
                  },
                ),
              ),

              if (_selectedTab == 0)
                _buildPantryTab(authUser.uid, colorScheme)
              else
                _buildRequestsTab(authUser.uid, colorScheme),
            ],
          ),
        );
      },
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
  final Function(int) onTabChanged;
  final int selectedIndex;

  _ProfileTabBarDelegate({
    required this.colorScheme,
    required this.onTabChanged,
    required this.selectedIndex,
  });

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
            isSelected: selectedIndex == 0,
            colorScheme: colorScheme,
            onTap: () => onTabChanged(0),
          ),
          _TabButton(
            label: "Requests",
            icon: Icons.arrow_forward_rounded,
            isSelected: selectedIndex == 1,
            colorScheme: colorScheme,
            onTap: () => onTabChanged(1),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ProfileTabBarDelegate oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.colorScheme != colorScheme;
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          height: 44,
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
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
    final colorScheme = Theme.of(context).colorScheme;
    final imageBase64 = data['imageBase64'];
    final itemName = data['name'] ?? "Unnamed Item";
    final foodCategory = data['postType'] ?? "PANTRY"; // or data['category']

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  FoodDetailsPage(docId: docId, foodData: data),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              // Circular Image Avatar
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.antiAlias,
                child: imageBase64 != null && imageBase64.toString().isNotEmpty
                    ? Image.memory(base64Decode(imageBase64), fit: BoxFit.cover)
                    : Icon(
                        Icons.fastfood_rounded,
                        color: colorScheme.onSurfaceVariant,
                        size: 28,
                      ),
              ),
              const SizedBox(width: 16),

              // Food Name & Category stacked vertically
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      itemName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      foodCategory.toLowerCase(),
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Trailing arrow icon indicator
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
