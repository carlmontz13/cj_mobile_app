import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/assignment_model.dart';
import '../models/submission_model.dart';
import '../providers/assignment_provider.dart';
import 'grade_submission_screen.dart';
import '../utils/color_utils.dart';

class ViewSubmissionsScreen extends StatefulWidget {
  final AssignmentModel assignment;

  const ViewSubmissionsScreen({
    super.key,
    required this.assignment,
  });

  @override
  State<ViewSubmissionsScreen> createState() => _ViewSubmissionsScreenState();
}

class _ViewSubmissionsScreenState extends State<ViewSubmissionsScreen> {
  Map<String, dynamic> _stats = {};
  String _activeFilter = 'All';
  String _sortOption = 'Newest';
  AssignmentModel? _assignmentWithClassDetails;

  @override
  void initState() {
    super.initState();
    _loadAssignmentWithClassDetails();
    _loadSubmissions();
    _loadStats();
  }

  Future<void> _loadSubmissions() async {
    try {
      final assignmentProvider = context.read<AssignmentProvider>();
      await assignmentProvider.loadSubmissions(widget.assignment.id);
      
      // Debug: Print the number of submissions loaded
      if (mounted) {
        print('Loaded ${assignmentProvider.submissions.length} submissions for assignment ${widget.assignment.id}');
        if (assignmentProvider.submissions.isNotEmpty) {
          print('First submission: ${assignmentProvider.submissions.first.studentName}');
        }
      }
    } catch (e) {
      print('Error loading submissions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading submissions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadAssignmentWithClassDetails() async {
    final assignmentProvider = context.read<AssignmentProvider>();
    final assignmentWithDetails = await assignmentProvider.getAssignmentById(widget.assignment.id);
    if (mounted && assignmentWithDetails != null) {
      setState(() {
        _assignmentWithClassDetails = assignmentWithDetails;
      });
    }
  }

  Future<void> _loadStats() async {
    final assignmentProvider = context.read<AssignmentProvider>();
    final stats = await assignmentProvider.getAssignmentStats(widget.assignment.id);
    if (mounted) {
      setState(() {
        _stats = stats;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Use the assignment with class details if available, otherwise use the original assignment
    final assignment = _assignmentWithClassDetails ?? widget.assignment;
    
    // Get the class theme color from the assignment's class details
    final classThemeColor = assignment.classDetails?.themeColor;
    final primaryColor = classThemeColor != null 
        ? ColorUtils.hexToColor(classThemeColor)
        : colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Submissions',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.sort, color: Colors.white),
              tooltip: 'Sort',
              onSelected: (value) {
                setState(() {
                  _sortOption = value;
                });
              },
              itemBuilder: (context) => [
                _buildSortMenuItem('Newest', 'Date: Newest', Icons.arrow_downward),
                _buildSortMenuItem('Oldest', 'Date: Oldest', Icons.arrow_upward),
                _buildSortMenuItem('Highest Grade', 'Grade: Highest', Icons.trending_up),
                _buildSortMenuItem('Lowest Grade', 'Grade: Lowest', Icons.trending_down),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Refresh',
              onPressed: () async {
                await _handleRefresh();
              },
            ),
          ),
        ],
      ),
      body: Consumer<AssignmentProvider>(
        builder: (context, assignmentProvider, child) {
          final submissions = _filterAndSort(assignmentProvider.submissions);
          
          // Debug: Print current state
          print('AssignmentProvider state:');
          print('- isLoading: ${assignmentProvider.isLoading}');
          print('- submissions count: ${assignmentProvider.submissions.length}');
          print('- filtered submissions count: ${submissions.length}');
          print('- error: ${assignmentProvider.error}');

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: assignmentProvider.isLoading
                ? ListView(children: const [SizedBox(height: 300), Center(child: CircularProgressIndicator())])
                : assignmentProvider.error != null
                    ? ListView(
                        children: [
                          _buildHeaderSection(assignment),
                          const SizedBox(height: 20),
                          _buildErrorState(assignmentProvider.error!),
                        ],
                      )
                    : submissions.isEmpty
                        ? ListView(
                            children: [
                              _buildHeaderSection(assignment),
                              const SizedBox(height: 20),
                              _buildStatsCard(),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: _buildFilterChips(),
                              ),
                              const SizedBox(height: 80),
                              _buildEmptyState(),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: submissions.length + 4, // Fixed: was +3, should be +4
                            itemBuilder: (context, index) {
                              print('Building item at index: $index, total submissions: ${submissions.length}');
                              
                              if (index == 0) return _buildHeaderSection(assignment);
                              if (index == 1) return const SizedBox(height: 20);
                              if (index == 2) return _buildStatsCard();
                              if (index == 3) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: _buildFilterChips(),
                                );
                              }
                              
                              final submissionIndex = index - 4;
                              print('Submission index: $submissionIndex, available submissions: ${submissions.length}');
                              
                              if (submissionIndex >= 0 && submissionIndex < submissions.length) {
                                final submission = submissions[submissionIndex];
                                print('Building submission card for: ${submission.studentName}');
                                return Padding(
                                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                                  child: _buildSubmissionCard(submission),
                                );
                              }
                              
                              return const SizedBox.shrink();
                            },
                          ),
          );
        },
      ),
    );
  }

  Future<void> _handleRefresh() async {
    await _loadSubmissions();
    await _loadStats();
  }

  Widget _buildStatsCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Use the assignment with class details if available, otherwise use the original assignment
    final assignment = _assignmentWithClassDetails ?? widget.assignment;
    
    // Get the class theme color from the assignment's class details
    final classThemeColor = assignment.classDetails?.themeColor;
    final primaryColor = classThemeColor != null 
        ? ColorUtils.hexToColor(classThemeColor)
        : colorScheme.primary;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.analytics,
                  color: primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assignment Overview',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      'Submission statistics and metrics',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primaryColor.withOpacity(0.3)),
                ),
                child: Text(
                  '${assignment.totalPoints} pts',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.people,
                  label: 'Total',
                  value: '${_stats['totalSubmissions'] ?? 0}',
                  color: primaryColor,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.grade,
                  label: 'Graded',
                  value: '${_stats['gradedSubmissions'] ?? 0}',
                  color: Colors.green,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.warning,
                  label: 'Late',
                  value: '${_stats['lateSubmissions'] ?? 0}',
                  color: Colors.orange,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.trending_up,
                  label: 'Avg Grade',
                  value: '${(_stats['averageGrade'] ?? 0).toStringAsFixed(1)}',
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmissionCard(SubmissionModel submission) {
    // Use the assignment with class details if available, otherwise use the original assignment
    final assignment = _assignmentWithClassDetails ?? widget.assignment;
    
    // Get the class theme color from the assignment's class details
    final classThemeColor = assignment.classDetails?.themeColor;
    final primaryColor = classThemeColor != null 
        ? ColorUtils.hexToColor(classThemeColor)
        : Colors.blue;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GradeSubmissionScreen(
                  assignment: assignment,
                  submission: submission,
                ),
              ),
            ).then((_) {
              _loadSubmissions();
              _loadStats();
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _initials(submission.studentName),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              submission.studentName,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                              overflow: TextOverflow.ellipsis,
                              textHeightBehavior: const TextHeightBehavior(
                                applyHeightToFirstAscent: false,
                                applyHeightToLastDescent: false,
                              ),
                              strutStyle: const StrutStyle(
                                height: 1.0,
                                forceStrutHeight: true,
                                leading: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildStatusChip(submission, primaryColor),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        submission.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                        textHeightBehavior: const TextHeightBehavior(
                          applyHeightToFirstAscent: false,
                          applyHeightToLastDescent: false,
                        ),
                        strutStyle: const StrutStyle(
                          height: 1.2,
                          forceStrutHeight: true,
                          leading: 0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(
                                  Icons.schedule,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                DateFormat('MMM dd, yyyy • hh:mm a').format(submission.submittedAt),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                                textHeightBehavior: const TextHeightBehavior(
                                  applyHeightToFirstAscent: false,
                                  applyHeightToLastDescent: false,
                                ),
                                strutStyle: const StrutStyle(
                                  height: 1.0,
                                  forceStrutHeight: true,
                                  leading: 0,
                                ),
                              ),
                            ],
                          ),
                          if (submission.isLate) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.warning,
                                    size: 12,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'LATE',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange,
                                    ),
                                    textHeightBehavior: const TextHeightBehavior(
                                      applyHeightToFirstAscent: false,
                                      applyHeightToLastDescent: false,
                                    ),
                                    strutStyle: const StrutStyle(
                                      height: 1.0,
                                      forceStrutHeight: true,
                                      leading: 0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (submission.isGraded) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.grade,
                                    size: 12,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${submission.grade}/${assignment.totalPoints}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green,
                                    ),
                                    textHeightBehavior: const TextHeightBehavior(
                                      applyHeightToFirstAscent: false,
                                      applyHeightToLastDescent: false,
                                    ),
                                    strutStyle: const StrutStyle(
                                      height: 1.0,
                                      forceStrutHeight: true,
                                      leading: 0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(SubmissionModel submission, Color primaryColor) {
    Color chipColor;
    String statusText;
    IconData statusIcon;
    
    if (submission.isGraded) {
      chipColor = Colors.green;
      statusText = 'Graded';
      statusIcon = Icons.check_circle;
    } else if (submission.isLate) {
      chipColor = Colors.orange;
      statusText = 'Late';
      statusIcon = Icons.warning;
    } else {
      chipColor = primaryColor;
      statusText = 'Submitted';
      statusIcon = Icons.upload;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 14,
            color: chipColor,
          ),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: chipColor,
            ),
            textHeightBehavior: const TextHeightBehavior(
              applyHeightToFirstAscent: false,
              applyHeightToLastDescent: false,
            ),
            strutStyle: const StrutStyle(
              height: 1.0,
              forceStrutHeight: true,
              leading: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = const ['All', 'Graded', 'Ungraded', 'Late'];
    
    // Use the assignment with class details if available, otherwise use the original assignment
    final assignment = _assignmentWithClassDetails ?? widget.assignment;
    
    // Get the class theme color from the assignment's class details
    final classThemeColor = assignment.classDetails?.themeColor;
    final primaryColor = classThemeColor != null 
        ? ColorUtils.hexToColor(classThemeColor)
        : Colors.blue;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((label) {
          final isSelected = _activeFilter == label;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected ? primaryColor : Colors.grey[300]!,
                  width: 1.5,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(25),
                  onTap: () {
                    setState(() {
                      _activeFilter = label;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.grey[700],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<SubmissionModel> _filterAndSort(List<SubmissionModel> submissions) {
    print('_filterAndSort called with ${submissions.length} submissions');
    print('Active filter: $_activeFilter, Sort option: $_sortOption');
    
    Iterable<SubmissionModel> filtered = submissions;
    switch (_activeFilter) {
      case 'Graded':
        filtered = filtered.where((s) => s.isGraded);
        print('Filtered for Graded: ${filtered.length} submissions');
        break;
      case 'Ungraded':
        filtered = filtered.where((s) => !s.isGraded);
        print('Filtered for Ungraded: ${filtered.length} submissions');
        break;
      case 'Late':
        filtered = filtered.where((s) => s.isLate);
        print('Filtered for Late: ${filtered.length} submissions');
        break;
      case 'All':
      default:
        print('No filtering applied, keeping all ${filtered.length} submissions');
        break;
    }

    final list = filtered.toList();
    print('Before sorting: ${list.length} submissions');
    
    list.sort((a, b) {
      switch (_sortOption) {
        case 'Oldest':
          return a.submittedAt.compareTo(b.submittedAt);
        case 'Highest Grade':
          return (b.grade ?? 0).compareTo(a.grade ?? 0);
        case 'Lowest Grade':
          return (a.grade ?? 0).compareTo(b.grade ?? 0);
        case 'Newest':
        default:
          return b.submittedAt.compareTo(a.submittedAt);
      }
    });
    
    print('After sorting: ${list.length} submissions');
    for (int i = 0; i < list.length; i++) {
      print('Submission $i: ${list[i].studentName} - Status: ${list[i].status} - Graded: ${list[i].isGraded} - Late: ${list[i].isLate}');
    }
    
    return list;
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r"\s+"));
    if (parts.isEmpty) return '';
    String first = parts.first.isNotEmpty ? parts.first[0] : '';
    String last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  Widget _buildHeaderSection(AssignmentModel assignment) {
    final classThemeColor = assignment.classDetails?.themeColor;
    final primaryColor = classThemeColor != null 
        ? ColorUtils.hexToColor(classThemeColor)
        : Colors.blue;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.people,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Student Submissions',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      assignment.title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoChip(
                icon: Icons.schedule,
                label: DateFormat('MMM dd, yyyy').format(assignment.dueDate),
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                icon: Icons.grade,
                label: '${assignment.totalPoints} points',
                color: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final assignment = _assignmentWithClassDetails ?? widget.assignment;
    final classThemeColor = assignment.classDetails?.themeColor;
    final primaryColor = classThemeColor != null 
        ? ColorUtils.hexToColor(classThemeColor)
        : colorScheme.primary;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.assignment_turned_in,
              size: 64,
              color: primaryColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No submissions to show',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting filters or check back later',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildSortMenuItem(String value, String label, IconData icon) {
    return PopupMenuItem<String>(
      value: value,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: Colors.blue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Error Loading Submissions',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              await _handleRefresh();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
