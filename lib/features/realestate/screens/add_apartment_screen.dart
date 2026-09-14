import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

/// Add Apartment – multi-step form wizard.
/// Step 1: Basic Information (listing type, property type, title, price,
///         location, bedrooms, bathrooms).
/// Step 2: Apartment Details (description, floor, total floors, area,
///         parking, amenities).
/// Step 3: Add Photos (main image, thumbnails, upload slots).
class AddApartmentScreen extends StatefulWidget {
  const AddApartmentScreen({super.key});

  @override
  State<AddApartmentScreen> createState() => _AddApartmentScreenState();
}

class _AddApartmentScreenState extends State<AddApartmentScreen> {
  int _currentStep = 0; // 0 = Basics, 1 = Details, 2 = Photos, 3 = Submitted

  // Step 1 state
  int _listingType = 0; // 0 = For Sale, 1 = For Rent

  // Step 2 state
  final Set<String> _selectedAmenities = {};

  static const _stepLabels = ['Basics', 'Details', 'Photos'];

  void _onNext() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    }
  }

  void _onSubmit() {
    setState(() => _currentStep = 3);
  }

  void _onBack() {
    if (_currentStep == 3) {
      // From confirmation, go back to My Apartments
      context.go('/my-apartments');
    } else if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // ═══════════════════════════════════
                // Top bar: back + title + step label
                // ═══════════════════════════════════
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _onBack,
                        child: const SizedBox(
                          width: 24,
                          height: 24,
                          child: Icon(
                            IconsaxPlusLinear.arrow_left,
                            size: 24,
                            color: Color(0xFF3D3D3D),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Add Apartment',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      // Step label (hidden on confirmation)
                      if (_currentStep < 3)
                        SizedBox(
                          width: 65,
                          child: Text(
                            'Step ${_currentStep + 1} of 3',
                            textAlign: TextAlign.right,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF123A72),
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 24),
                    ],
                  ),
                ),

                // ═══════════════════════════════════
                // Step progress indicator (hidden on confirmation)
                // ═══════════════════════════════════
                if (_currentStep < 3) ...[
                  const SizedBox(height: 16),
                  _StepProgressBar(
                    currentStep: _currentStep,
                    labels: _stepLabels,
                  ),
                  const SizedBox(height: 20),
                ],

                // ═══════════════════════════════════
                // Step content
                // ═══════════════════════════════════
                Expanded(
                  child: _currentStep == 0
                      ? _buildStep1()
                      : _currentStep == 1
                          ? _buildStep2()
                          : _currentStep == 2
                              ? _buildStep3()
                              : _buildConfirmation(),
                ),

                // ═══════════════════════════════════
                // Bottom bar button
                // ═══════════════════════════════════
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border:
                        Border(top: BorderSide(color: Color(0xFFE7E7E7))),
                  ),
                  child: GestureDetector(
                    onTap: _currentStep < 2
                        ? _onNext
                        : _currentStep == 2
                            ? _onSubmit
                            : () => context.go('/my-apartments'),
                    child: Container(
                      width: double.infinity,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF123A72),
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentStep == 3
                                ? 'Back to My Apartments'
                                : _currentStep == 2
                                    ? 'Submit for Approval'
                                    : 'Next',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          if (_currentStep < 2) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              IconsaxPlusLinear.arrow_right_3,
                              size: 20,
                              color: Colors.white,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Step 1: Basic Information
  // ═══════════════════════════════════════════════
  Widget _buildStep1() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      children: [
        // Section header
        Text(
          'Basic Information',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F1F1F),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Fill in the details about your property',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6D6D6D),
          ),
        ),
        const SizedBox(height: 20),

        // ── Listing Type (toggle) ──
        _FormCard(
          label: 'Listing Type',
          child: Row(
            children: [
              Expanded(
                child: _ToggleButton(
                  label: 'For Sale',
                  icon: IconsaxPlusLinear.tag,
                  selected: _listingType == 0,
                  onTap: () => setState(() => _listingType = 0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ToggleButton(
                  label: 'For Rent',
                  icon: IconsaxPlusLinear.key,
                  selected: _listingType == 1,
                  onTap: () => setState(() => _listingType = 1),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Property Type (dropdown) ──
        _FormCard(
          label: 'Property Type',
          child: _DropdownRow(placeholder: 'Select property type'),
        ),
        const SizedBox(height: 16),

        // ── Title (text input) ──
        _FormCard(
          label: 'Title',
          child: _InputRow(
            placeholder: 'e.g. Modern 3BR Apartment in City Center',
          ),
        ),
        const SizedBox(height: 16),

        // ── Price (text input) ──
        _FormCard(
          label: 'Price',
          child: _InputRow(placeholder: 'Enter price'),
        ),
        const SizedBox(height: 16),

        // ── Location (text input) ──
        _FormCard(
          label: 'Location',
          child: _InputRow(placeholder: 'Enter neighborhood or area'),
        ),
        const SizedBox(height: 16),

        // ── Bedrooms (dropdown) ──
        _FormCard(
          label: 'Bedrooms',
          child: _DropdownRow(placeholder: 'Select number of bedrooms'),
        ),
        const SizedBox(height: 16),

        // ── Bathrooms (dropdown) ──
        _FormCard(
          label: 'Bathrooms',
          child: _DropdownRow(placeholder: 'Select number of bathrooms'),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  // Step 2: Apartment Details
  // ═══════════════════════════════════════════════
  Widget _buildStep2() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      children: [
        // Section header
        Text(
          'Apartment Details',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F1F1F),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Add more details about your property',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6D6D6D),
          ),
        ),
        const SizedBox(height: 20),

        // ── Description (tall text area) ──
        Container(
          height: 150,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE7E7E7)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Description',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1F1F1F),
                ),
              ),
              const SizedBox(height: 13),
              Expanded(
                child: TextField(
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF1F1F1F),
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'Describe your apartment, features and highlights',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6D6D6D),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Floor & Total Floors (side by side) ──
        Row(
          children: [
            Expanded(
              child: _FormCard(
                label: 'Floor',
                child: _DropdownRow(placeholder: 'Select'),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: _FormCard(
                label: 'Total Floors',
                child: _DropdownRow(placeholder: 'Select'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Area (m²) ──
        _FormCard(
          label: 'Area (m²)',
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 20,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF1F1F1F),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter area',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6D6D6D),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  ),
                ),
              ),
              Text(
                'm²',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6D6D6D),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Parking (dropdown) ──
        _FormCard(
          label: 'Parking',
          child: _DropdownRow(placeholder: 'Select parking option'),
        ),
        const SizedBox(height: 16),

        // ── Amenities (chip toggles) ──
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE7E7E7)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Amenities',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1F1F1F),
                ),
              ),
              const SizedBox(height: 13),
              // Row 1
              Row(
                children: [
                  _AmenityChip(
                    label: 'Balcony',
                    icon: IconsaxPlusLinear.building_4,
                    selected: _selectedAmenities.contains('Balcony'),
                    onTap: () => _toggleAmenity('Balcony'),
                  ),
                  const SizedBox(width: 8),
                  _AmenityChip(
                    label: 'Air Conditioning',
                    icon: IconsaxPlusLinear.wind,
                    selected:
                        _selectedAmenities.contains('Air Conditioning'),
                    onTap: () => _toggleAmenity('Air Conditioning'),
                  ),
                  const SizedBox(width: 8),
                  _AmenityChip(
                    label: 'Garden',
                    icon: IconsaxPlusLinear.tree,
                    selected: _selectedAmenities.contains('Garden'),
                    onTap: () => _toggleAmenity('Garden'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Row 2
              Row(
                children: [
                  _AmenityChip(
                    label: 'Storage',
                    icon: IconsaxPlusLinear.box_1,
                    selected: _selectedAmenities.contains('Storage'),
                    onTap: () => _toggleAmenity('Storage'),
                  ),
                  const SizedBox(width: 8),
                  _AmenityChip(
                    label: 'Elevator',
                    icon: IconsaxPlusLinear.arrow_3,
                    selected: _selectedAmenities.contains('Elevator'),
                    onTap: () => _toggleAmenity('Elevator'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _toggleAmenity(String name) {
    setState(() {
      if (_selectedAmenities.contains(name)) {
        _selectedAmenities.remove(name);
      } else {
        _selectedAmenities.add(name);
      }
    });
  }

  // ═══════════════════════════════════════════════
  // Step 3: Add Photos
  // ═══════════════════════════════════════════════
  Widget _buildStep3() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      children: [
        // Section header
        Text(
          'Add Photos',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F1F1F),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Upload photos of your apartment',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6D6D6D),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'First photo will be used as the cover image',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFFFF3434),
          ),
        ),
        const SizedBox(height: 16),

        // ── Uploaded photos: 1 large + 2 small ──
        SizedBox(
          height: 210,
          child: Row(
            children: [
              // Large main photo
              Expanded(
                flex: 235,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0058B5), Color(0xFF010A36)],
                        ),
                      ),
                    ),
                    // "Main Image" badge
                    Positioned(
                      left: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF123A72),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          'Main Image',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    // Delete button
                    Positioned(
                      right: 8,
                      top: 8,
                      child: const _DeleteCircle(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Two small photos stacked
              Expanded(
                flex: 118,
                child: Column(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF0058B5),
                                  Color(0xFF010A36),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            right: 6,
                            top: 6,
                            child: const _DeleteCircle(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF0058B5),
                                  Color(0xFF010A36),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            right: 6,
                            top: 6,
                            child: const _DeleteCircle(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Empty upload slots: row 1 ──
        Row(
          children: List.generate(
            3,
            (i) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: i == 0 ? 0 : 6,
                  right: i == 2 ? 0 : 6,
                ),
                child: const _UploadSlot(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── Empty upload slots: row 2 ──
        Row(
          children: List.generate(
            3,
            (i) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: i == 0 ? 0 : 6,
                  right: i == 2 ? 0 : 6,
                ),
                child: const _UploadSlot(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  // Confirmation: Listing Submitted
  // ═══════════════════════════════════════════════
  Widget _buildConfirmation() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        children: [
          const SizedBox(height: 60),

          // Success illustration placeholder
          Container(
            width: 245,
            height: 162,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(
                IconsaxPlusLinear.tick_circle,
                size: 72,
                color: Color(0xFF123A72),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            'Listing Submitted!',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 12),

          // Description
          SizedBox(
            width: 327,
            child: Text(
              'Your apartment has been submitted for approval. '
              'We\'ll review the details and publish it once approved.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.4,
                color: const Color(0xFF6D6D6D),
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Pending Approval card
          Container(
            width: 338,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9EF),
              border: Border.all(color: const Color(0xFFFFE8C3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Clock icon
                const Icon(
                  IconsaxPlusLinear.clock,
                  size: 24,
                  color: Color(0xFFEA9D23),
                ),
                const SizedBox(width: 12),
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pending Approval',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F1F1F),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your listing is being reviewed',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF6D6D6D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Footer note
          SizedBox(
            width: 327,
            child: Text(
              'You can check the status of your listing anytime '
              'from the My Apartments page.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.4,
                color: const Color(0xFF6D6D6D),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Step progress bar (with checkmark for completed)
// ═══════════════════════════════════════════════════

class _StepProgressBar extends StatelessWidget {
  final int currentStep;
  final List<String> labels;

  const _StepProgressBar({
    required this.currentStep,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 268,
      height: 47,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Connecting line
          Positioned(
            left: 40,
            top: 11,
            child: Container(
              width: 186,
              height: 2,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                gradient: LinearGradient(
                  colors: const [
                    Color(0xFF123A72),
                    Color(0xFF123A72),
                    Color(0xFFE7E7E7),
                    Color(0xFFE7E7E7),
                  ],
                  stops: [
                    0.0,
                    currentStep == 0
                        ? 0.0
                        : currentStep == 1
                            ? 0.5
                            : 1.0,
                    currentStep == 0
                        ? 0.0
                        : currentStep == 1
                            ? 0.5
                            : 1.0,
                    1.0,
                  ],
                ),
              ),
            ),
          ),

          // Step circles + labels
          for (int i = 0; i < labels.length; i++)
            Positioned(
              left: i * 106.0,
              top: 0,
              child: SizedBox(
                width: 56,
                child: Column(
                  children: [
                    // Circle
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: i <= currentStep
                            ? const Color(0xFF123A72)
                            : const Color(0xFFF6F6F6),
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.white, width: 4),
                      ),
                      child: Center(
                        child: i < currentStep
                            // Completed: show checkmark
                            ? const Icon(
                                Icons.check,
                                size: 12,
                                color: Colors.white,
                              )
                            // Current or future: show number
                            : Text(
                                '${i + 1}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: i <= currentStep
                                      ? Colors.white
                                      : const Color(0xFF6D6D6D),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Label
                    Text(
                      labels[i],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: i <= currentStep
                            ? const Color(0xFF123A72)
                            : const Color(0xFF6D6D6D),
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

// ═══════════════════════════════════════════════════
// Form card wrapper
// ═══════════════════════════════════════════════════

class _FormCard extends StatelessWidget {
  final String label;
  final Widget child;
  const _FormCard({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE7E7E7)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Toggle button (For Sale / For Rent)
// ═══════════════════════════════════════════════════

class _ToggleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? const Color(0xFF123A72) : const Color(0xFF6D6D6D);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEEF4FD) : Colors.white,
          border: Border.all(
            color: selected
                ? const Color(0xFF123A72).withValues(alpha: 0.8)
                : const Color(0xFFE7E7E7),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Amenity chip (toggleable)
// ═══════════════════════════════════════════════════

class _AmenityChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _AmenityChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? const Color(0xFF123A72) : const Color(0xFF6D6D6D);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEEF4FD) : Colors.white,
          border: Border.all(
            color: selected
                ? const Color(0xFF123A72).withValues(alpha: 0.8)
                : const Color(0xFFE7E7E7),
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Dropdown-style row (placeholder + chevron)
// ═══════════════════════════════════════════════════

class _DropdownRow extends StatelessWidget {
  final String placeholder;
  const _DropdownRow({required this.placeholder});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            placeholder,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6D6D6D),
            ),
          ),
        ),
        const Icon(
          IconsaxPlusLinear.arrow_down_1,
          size: 20,
          color: Color(0xFF6D6D6D),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════
// Text input row (placeholder only, no chevron)
// ═══════════════════════════════════════════════════

class _InputRow extends StatelessWidget {
  final String placeholder;
  const _InputRow({required this.placeholder});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: TextField(
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF1F1F1F),
        ),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6D6D6D),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Red delete circle (photo remove button)
// ═══════════════════════════════════════════════════

class _DeleteCircle extends StatelessWidget {
  const _DeleteCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: const BoxDecoration(
        color: Color(0xFFFF3434),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(Icons.close, size: 12, color: Colors.white),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Dashed upload slot (empty photo placeholder)
// ═══════════════════════════════════════════════════

class _UploadSlot extends StatelessWidget {
  const _UploadSlot();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomPaint(
        painter: _DashedBorderPainter(),
        child: const Center(
          child: Icon(Icons.add, size: 24, color: Color(0xFF123A72)),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Dashed border painter
// ═══════════════════════════════════════════════════

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6D6D6D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const dashWidth = 6.0;
    const dashGap = 4.0;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(8),
    );

    // Extract path from rounded rect and draw dashes along it
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(
          metric.extractPath(distance, end),
          paint,
        );
        distance += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
