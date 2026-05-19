import 'package:cims/core/entity/dashboard_summary.dart';
import 'package:flutter/material.dart';

// Aquest widget mostra un resum visual de les fotos més recents de l'usuari.
// Forma part del dashboard i permet accedir ràpidament a records d'ascensions recents.
class DashboardRecentPhotosCarousel extends StatelessWidget {
  const DashboardRecentPhotosCarousel({
    super.key,
    required this.photos,
    this.onViewGalleryTap,
  });

  // Llista de fotos representatives rebudes des del resum del dashboard.
  // Normalment conté un màxim de dotze imatges, una per ascensió recent.
  final List<DashboardRecentPhoto> photos;

  // Acció opcional per obrir la galeria completa de fotos de l'usuari.
  // Encara que la pantalla de galeria s'implementi més endavant, el widget ja queda preparat.
  final VoidCallback? onViewGalleryTap;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Fotos recents',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF172033),
                  ),
                ),
              ),
              if (onViewGalleryTap != null)
                TextButton(
                  onPressed: onViewGalleryTap,
                  child: const Text('Veure galeria'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 92,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth =
                    ((constraints.maxWidth - 36) / 4).clamp(72.0, 96.0);

                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: photos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final photo = photos[index];

                    return _RecentPhotoItem(
                      photo: photo,
                      width: itemWidth,
                      onTap: () => _openPhotoPreview(context, photo),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Obre la foto seleccionada en gran.
  // InteractiveViewer permet ampliar i moure la imatge amb gestos.
  void _openPhotoPreview(BuildContext context, DashboardRecentPhoto photo) {
    if (photo.downloadUrl == null) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(18),
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.network(
                      photo.downloadUrl!,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filled(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Aquest element representa una miniatura individual del carrusel.
// Mostra la imatge i el nom del cim associat a l'ascensió.
class _RecentPhotoItem extends StatelessWidget {
  const _RecentPhotoItem({
    required this.photo,
    required this.width,
    required this.onTap,
  });

  final DashboardRecentPhoto photo;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = photo.downloadUrl;

    return GestureDetector(
      onTap: imageUrl == null ? null : onTap,
      child: SizedBox(
        width: width,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl == null)
                Container(
                  color: const Color(0xFFE8ECF3),
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: Color(0xFF6B7280),
                  ),
                )
              else
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Container(
                      color: const Color(0xFFE8ECF3),
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: Color(0xFF6B7280),
                      ),
                    );
                  },
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0),
                        Colors.black.withValues(alpha: 0.62),
                      ],
                    ),
                  ),
                  child: Text(
                    photo.peakName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
