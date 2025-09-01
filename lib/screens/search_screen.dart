import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/class_provider.dart';
import '../providers/auth_provider.dart';
import '../models/class_model.dart';
import '../models/user_model.dart';
import '../widgets/class_card.dart';
import '../widgets/auth_guard.dart';
import '../widgets/role_guard.dart';
import 'class_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  List<ClassModel> _filteredClasses = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterClasses();
    });
  }

  void _filterClasses() {
    final classProvider = context.read<ClassProvider>();
    if (_searchQuery.isEmpty) {
      _filteredClasses = classProvider.classes;
    } else {
      _filteredClasses = classProvider.classes.where((classItem) {
        return classItem.name.toLowerCase().contains(_searchQuery) ||
               classItem.subject.toLowerCase().contains(_searchQuery) ||
               classItem.description.toLowerCase().contains(_searchQuery) ||
               classItem.section.toLowerCase().contains(_searchQuery) ||
               classItem.room.toLowerCase().contains(_searchQuery);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthGuard(
      child: RoleGuard(
        allowedRoles: [UserRole.student],
        child: Scaffold(
          backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(
            'Search',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFF4285F4),
          elevation: 0,
        ),
        body: Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF4285F4),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search classes, subjects, or rooms...',
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey[400],
                    ),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  style: GoogleFonts.poppins(),
                ),
              ),
            ),

            // Search Results
            Expanded(
              child: Consumer<ClassProvider>(
                builder: (context, classProvider, child) {
                  if (_searchQuery.isEmpty) {
                    return _buildEmptyState();
                  }

                  if (_filteredClasses.isEmpty) {
                    return _buildNoResultsState();
                  }

                  return _buildSearchResults();
                },
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Search for classes',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search by class name, subject, or room',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with different keywords',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Search Results (${_filteredClasses.length})',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: _filteredClasses.length,
              itemBuilder: (context, index) {
                final classItem = _filteredClasses[index];
                return ClassCard(
                  classModel: classItem,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClassDetailScreen(classModel: classItem),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}