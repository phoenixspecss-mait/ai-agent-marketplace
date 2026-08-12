import 'package:flutter/material.dart';
import 'package:expert_ai/theme/app_theme.dart';

class LibraryView extends StatefulWidget {
  final Function(String agentId, String initialPrompt)? onConsultAgent;
  const LibraryView({super.key, this.onConsultAgent});

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView> {
  String _selectedCategory = "All Specialists";
  String _sortBy = "Success Rate";

  final List<Map<String, dynamic>> _allAgents = [
    {
      "id": "legal-clause-explainer",
      "name": "LexPrime AI",
      "category": "LEGAL",
      "icon": Icons.gavel_rounded,
      "color": AppTheme.emeraldGreen,
      "description": "Specializes in corporate law, contract analysis, and lease agreement compliance.",
      "success_rate": "99.8%",
      "cost": "\$0.005",
      "is_bookmarked": true,
    },
    {
      "id": "symptom-triage-explainer",
      "name": "MedDiagnostix",
      "category": "MEDICAL",
      "icon": Icons.medical_services_rounded,
      "color": const Color(0xFF64B5F6),
      "description": "Advanced diagnostic suggestions based on symptoms, clinical guidelines, and triage care.",
      "success_rate": "97.4%",
      "cost": "\$0.003",
      "is_bookmarked": false,
    },
    {
      "id": "punjabi-slang-translator",
      "name": "Linguistics Regional AI",
      "category": "LINGUISTICS",
      "icon": Icons.translate_rounded,
      "color": const Color(0xFFFFB74D),
      "description": "Translates Indian regional slang, song lyrics, and colloquial phrases with cultural context.",
      "success_rate": "99.1%",
      "cost": "\$0.002",
      "is_bookmarked": true,
    },
    {
      "id": "legal-clause-explainer",
      "name": "QuantCore AI",
      "category": "FINANCE",
      "icon": Icons.show_chart_rounded,
      "color": const Color(0xFF81C784),
      "description": "Real-time financial term breakdown, contract valuation, and micro-payment analytics.",
      "success_rate": "94.1%",
      "cost": "\$0.005",
      "is_bookmarked": false,
    },
    {
      "id": "career-agent",
      "name": "DevSys Architect",
      "category": "TECHNICAL",
      "icon": Icons.code_rounded,
      "color": const Color(0xFFBA68C8),
      "description": "Evaluates tech resumes, code architecture, and software engineering bullet points.",
      "success_rate": "98.5%",
      "cost": "\$0.004",
      "is_bookmarked": false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedCategory == "All Specialists"
        ? _allAgents
        : _allAgents.where((a) => a['category'] == _selectedCategory.toUpperCase()).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & Subtitle (Image 3)
          const Text(
            "Specialist Directory",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Access elite AI agents trained on proprietary data for specialized fields.",
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 28),

          // Category Chips & Sort Dropdown Row
          Row(
            children: [
              Wrap(
                spacing: 10,
                children: ["All Specialists", "Legal", "Medical", "Finance", "Technical"].map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                    selectedColor: const Color(0xFF263A35),
                    backgroundColor: const Color(0xFF131D1A),
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.emeraldGreen : const Color(0xFF9CA3AF),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected ? AppTheme.emeraldGreen : const Color(0xFF23322E),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Spacer(),

              // Sort Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF131D1A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF23322E)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sortBy,
                    dropdownColor: const Color(0xFF131D1A),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9CA3AF), size: 18),
                    items: ["Success Rate", "Cost per Query", "Popularity"].map((s) {
                      return DropdownMenuItem(value: s, child: Text("Sort by: $s"));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _sortBy = val);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // 3-Column Responsive Grid of Agent Cards (Image 3)
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 1100
                  ? 3
                  : (constraints.maxWidth > 700 ? 2 : 1);

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 1.15,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final agent = filtered[index];
                  return _buildAgentCard(agent);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAgentCard(Map<String, dynamic> agent) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131D1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF23322E), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + Name + Bookmark
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D2A27),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(agent['icon'] as IconData, color: agent['color'] as Color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agent['name'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.emeraldGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        agent['category'] as String,
                        style: const TextStyle(
                          color: AppTheme.emeraldGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  agent['is_bookmarked'] == true ? Icons.bookmark : Icons.bookmark_border,
                  color: agent['is_bookmarked'] == true ? AppTheme.emeraldGreen : const Color(0xFF9CA3AF),
                  size: 20,
                ),
                onPressed: () {
                  setState(() => agent['is_bookmarked'] = !(agent['is_bookmarked'] as bool));
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Description
          Text(
            agent['description'] as String,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const Spacer(),

          // Stats Box (Success Rate | Cost / Query)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0C1412),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1E2C29)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "SUCCESS RATE",
                        style: TextStyle(color: Color(0xFF6B7280), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        agent['success_rate'] as String,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 24, color: const Color(0xFF23322E)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "COST / QUERY",
                          style: TextStyle(color: Color(0xFF6B7280), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          agent['cost'] as String,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Consult Agent Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                if (widget.onConsultAgent != null) {
                  widget.onConsultAgent!(
                    agent['id'] as String,
                    "Hello ${agent['name']}, I need your expert consultation.",
                  );
                }
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF23322E)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text("Consult Agent", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 15),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
