import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserTile extends StatelessWidget {
  final String text;
  final String profileImageUrl; // Parameter for profile picture
  final void Function()? onTap;
  final bool isOnline;

  const UserTile({
    super.key,
    required this.text,
    required this.profileImageUrl,
    required this.onTap,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 25),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.grey.shade300, // Placeholder color
                  backgroundImage:
                      profileImageUrl.isNotEmpty
                          ? CachedNetworkImageProvider(
                            profileImageUrl,
                          ) // Using CachedNetworkImage
                          : null,
                  child:
                      profileImageUrl.isEmpty
                          ? const Icon(
                            Icons.person,
                            size: 30,
                            color: Colors.grey,
                          )
                          : null, // Show icon if no profile picture
                ),
                if (isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.secondary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 20),

            // User Name with overflow handling
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    overflow: TextOverflow.ellipsis, // Handle long text
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
