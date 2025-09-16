import 'package:flutter/material.dart';
import 'package:park_view_admin_panel/constants/app_colors.dart';
import 'package:park_view_admin_panel/constants/app_text_styles.dart';
import 'package:park_view_admin_panel/models/property.dart';
// import 'package:park_view_admin_panel/screens/chats_screen.dart';
// import 'package:park_view_admin_panel/features/property/domain/models/property.dart';

class PropertyDetailScreen extends StatelessWidget {
  final Property property;
  const PropertyDetailScreen({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryRed,
        title: Text(
          'Property Details',
          style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 490),
          child: Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(224, 255, 255, 255),
              border: Border.all(
                color: const Color.fromARGB(255, 237, 111, 1), // Subtle border; customize as needed
                width: 1.0,
              ),
              borderRadius: BorderRadius.only(
    bottomLeft: const Radius.circular(12),  // Bottom-left rounded
    bottomRight: const Radius.circular(12), // Bottom-right rounded
    // topLeft: Radius.zero,    // Optional: defaults to 0 if omitted
    // topRight: Radius.zero,   // Optional: defaults to 0 if omitted
  ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ListView(
              children: [
                _imageGallery(property.imageUrls),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(property.title, style: AppTextStyles.headlineLarge),
                      const SizedBox(height: 6),
                      Text(
                        property.formattedPrice,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.primaryRed,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _pill(property.typeLabel),
                          const SizedBox(width: 8),
                          _pill(property.statusLabel),
                          const Spacer(),
                          Text(
                            property.timeAgo,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _detailItem(Icons.bed, '${property.bedrooms} Beds'),
                          const SizedBox(width: 12),
                          _detailItem(
                            Icons.bathtub_outlined,
                            '${property.bathrooms} Baths',
                          ),
                          const SizedBox(width: 12),
                          _detailItem(
                            Icons.square_foot,
                            '${property.area.toInt()} sq ft',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('Description', style: AppTextStyles.bodyMediumBold),
                      const SizedBox(height: 6),
                      Text(property.description, style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(
                            Icons.place,
                            size: 18,
                            color: AppColors.primaryRed,
                          ),
                          const SizedBox(width: 6),
                          Expanded(child: Text(property.location)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 18,
                            color: AppColors.primaryRed,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              property.agentName,
                              style: AppTextStyles.bodyMediumBold,
                            ),
                          ),
                        ],
                      ),
                      // const SizedBox(height: 24),
                      // SizedBox(
                      //   width: double.infinity,
                      //   child: ElevatedButton.icon(
                      //     icon: const Icon(
                      //       Icons.chat_bubble_outline,
                      //       color: Colors.white,
                      //     ),
                      //     label: const Text('Chat with Agent'),
                      //     style: ElevatedButton.styleFrom(
                      //       backgroundColor: AppColors.primaryRed,
                      //       foregroundColor: Colors.white,
                      //       padding: const EdgeInsets.symmetric(vertical: 14),
                      //       shape: RoundedRectangleBorder(
                      //         borderRadius: BorderRadius.circular(12),
                      //       ),
                      //     ),
                      //     onPressed: () {
                      //       Navigator.push(
                      //         context,
                      //         MaterialPageRoute(
                      //           builder:
                      //               (_) => DirectChatScreen(
                      //                 sellerName: property.agentName,
                      //                 sellerId: property.agentId,
                      //               ),
                      //         ),
                      //       );
                      //     },
                      //   ),
                      // ),
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

  Widget _imageGallery(List<String> urls) {
    if (urls.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        height: 220,
        alignment: Alignment.center,
        child: const Icon(Icons.image, size: 48, color: Colors.grey),
      );
    }
    return SizedBox(
      height: 260,
      child: PageView.builder(
        itemCount: urls.length,
        controller: PageController(viewportFraction: 1),
        itemBuilder: (_, i) {
          final String path = urls[i];
          final bool isAsset = path.startsWith('assets/');
          return isAsset
              ? Image.asset(
                  path,
                  fit: BoxFit.fill,
                  errorBuilder: (_, __, ___) => _errorImg(),
                )
              : Image.network(
                  path,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => _errorImg(),
                );
        },
      ),
    );
  }

  Widget _errorImg() {
    return Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryRed.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: AppTextStyles.bodySmall),
    );
  }

  Widget _detailItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade700),
        const SizedBox(width: 6),
        Text(text, style: AppTextStyles.bodySmall),
      ],
    );
  }
}