import 'package:auto_route/auto_route.dart';
import 'package:cims/app/screens/user_photo_gallery/user_photo_gallery_controller.dart';
import 'package:cims/core/entity/ascent_photo_gallery.dart';
import 'package:flutter/material.dart';

// Aquesta pantalla mostra la galeria completa de fotos de l'usuari.
// Permet consultar i eliminar les imatges associades a les seves ascensions amb càrrega paginada.
@RoutePage()
class UserPhotoGalleryScreen extends StatefulWidget {
  const UserPhotoGalleryScreen({super.key});

  @override
  State<UserPhotoGalleryScreen> createState() => _UserPhotoGalleryScreenState();
}

// Aquest estat connecta la pantalla amb el controller i gestiona el scroll.
// Quan l'usuari s'apropa al final de la galeria, es demana automàticament una nova pàgina.
class _UserPhotoGalleryScreenState extends State<UserPhotoGalleryScreen> {
  late final UserPhotoGalleryController _controller;
  late final ScrollController _scrollController;

  // Aquest mètode prepara el controller, el scroll i la càrrega inicial de fotos.
  @override
  void initState() {
    super.initState();
    _controller = UserPhotoGalleryController();
    _scrollController = ScrollController()..addListener(_handleScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadInitial();
    });
  }

  // Aquest mètode detecta quan l'usuari s'apropa al final del grid.
  // Això permet carregar més fotos sense afegir cap botó manual.
  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final isNearBottom = position.pixels >= position.maxScrollExtent - 420;

    if (isNearBottom) {
      _controller.loadMore();
    }
  }

  // Aquest mètode demana confirmació abans d’eliminar una foto de la galeria.
  // La imatge s’elimina de l’ascensió i desapareix de la llista local si l’operació funciona.
  Future<bool> _confirmDeletePhoto(AscentPhotoGalleryItem photo) async {
    if (_controller.deletingPhotoId != null) {
      return false;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar foto?'),
          content: const Text(
            'Aquesta foto s\'eliminarà de l\'ascensió. Aquesta acció no es pot desfer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel·lar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return false;
    }

    await _controller.deletePhoto(photo.id);

    if (!mounted) {
      return false;
    }

    if (_controller.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto eliminada correctament.'),
        ),
      );
      return true;
    }

    return false;
  }

  // Aquest mètode allibera els recursos associats a la pantalla.
  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  // Aquest mètode construeix la pantalla segons l'estat actual de la galeria.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F2),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (_controller.isLoading && _controller.photos.isEmpty) {
              return const _GalleryLoadingState();
            }

            if (_controller.errorMessage != null &&
                _controller.photos.isEmpty) {
              return _GalleryErrorState(
                message: _controller.errorMessage!,
                onRetry: _controller.retry,
              );
            }

            return RefreshIndicator(
              onRefresh: _controller.refresh,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _GalleryHeader(
                      totalPhotos: _controller.photos.length,
                    ),
                  ),
                  if (_controller.photos.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _GalleryEmptyState(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final photo = _controller.photos[index];

                            return _GalleryPhotoTile(
                              photo: photo,
                              isDeleting:
                                  _controller.deletingPhotoId == photo.id,
                              onTap: () => _openPhotoPreview(context, photo),
                              onDeleteTap: () => _confirmDeletePhoto(photo),
                            );
                          },
                          childCount: _controller.photos.length,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _resolveCrossAxisCount(context),
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1,
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: _GalleryFooter(
                      isLoadingMore: _controller.isLoadingMore,
                      errorMessage: _controller.photos.isEmpty
                          ? null
                          : _controller.errorMessage,
                      onRetry: _controller.retry,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Aquest mètode adapta el nombre de columnes segons l'amplada disponible.
  // En mòbil mostra una galeria compacta i en web aprofita millor l'espai.
  int _resolveCrossAxisCount(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width >= 900) return 5;
    if (width >= 650) return 4;
    return 3;
  }

  // Aquest mètode obre la foto seleccionada en gran.
  // InteractiveViewer permet ampliar i desplaçar la imatge amb gestos.
  void _openPhotoPreview(
    BuildContext context,
    AscentPhotoGalleryItem photo,
  ) {
    if (photo.downloadUrl == null) {
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(18),
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
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
                left: 14,
                right: 58,
                bottom: 14,
                child: _PhotoPreviewCaption(photo: photo),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: IconButton.filled(
                  onPressed: () async {
                    final deleted = await _confirmDeletePhoto(photo);

                    if (deleted && dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filled(
                  onPressed: () => Navigator.of(dialogContext).pop(),
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

// Aquesta capçalera identifica la pantalla i mostra el nombre de fotos carregades.
class _GalleryHeader extends StatelessWidget {
  const _GalleryHeader({
    required this.totalPhotos,
  });

  final int totalPhotos;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.router.maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Galeria de fotos',
                  style: TextStyle(
                    color: Color(0xFF1F2933),
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  totalPhotos == 1
                      ? '1 foto carregada'
                      : '$totalPhotos fotos carregades',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Aquesta peça representa una foto dins del grid de la galeria.
// Inclou una acció d’eliminació per gestionar les imatges sense entrar a l’edició.
class _GalleryPhotoTile extends StatelessWidget {
  const _GalleryPhotoTile({
    required this.photo,
    required this.isDeleting,
    required this.onTap,
    required this.onDeleteTap,
  });

  final AscentPhotoGalleryItem photo;
  final bool isDeleting;
  final VoidCallback onTap;
  final VoidCallback onDeleteTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = photo.downloadUrl;

    return GestureDetector(
      onTap: imageUrl == null || isDeleting ? null : onTap,
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
              top: 7,
              right: 7,
              child: Material(
                color: const Color(0xCC000000),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: isDeleting ? null : onDeleteTap,
                  child: SizedBox(
                    width: 34,
                    height: 34,
                    child: Center(
                      child: isDeleting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.delete_outline_rounded,
                              size: 19,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0),
                      Colors.black.withValues(alpha: 0.66),
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
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Aquest text dona context a la foto oberta en gran.
class _PhotoPreviewCaption extends StatelessWidget {
  const _PhotoPreviewCaption({
    required this.photo,
  });

  final AscentPhotoGalleryItem photo;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 9,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              photo.peakName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              photo.displayAscentDate,
              style: const TextStyle(
                color: Color(0xFFE5E7EB),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Aquest peu informa de la càrrega de més fotos o mostra un error parcial.
class _GalleryFooter extends StatelessWidget {
  const _GalleryFooter({
    required this.isLoadingMore,
    required this.errorMessage,
    required this.onRetry,
  });

  final bool isLoadingMore;
  final String? errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF0B57D0),
          ),
        ),
      );
    }

    if (errorMessage == null) {
      return const SizedBox(height: 24);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Column(
        children: [
          Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFB42318),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: const Text('Tornar-ho a provar'),
          ),
        ],
      ),
    );
  }
}

// Aquest estat visual es mostra durant la càrrega inicial.
class _GalleryLoadingState extends StatelessWidget {
  const _GalleryLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF0B57D0),
      ),
    );
  }
}

// Aquest estat visual s'utilitza quan l'usuari encara no té fotos registrades.
class _GalleryEmptyState extends StatelessWidget {
  const _GalleryEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            color: Color(0xFF6B7280),
            size: 48,
          ),
          SizedBox(height: 14),
          Text(
            'Encara no tens fotos a la galeria.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF1F2933),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Quan registris ascensions amb fotos, apareixeran aquí.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Aquest estat visual mostra un error inicial i permet repetir la càrrega.
class _GalleryErrorState extends StatelessWidget {
  const _GalleryErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFB42318),
              size: 44,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF1F2933),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B57D0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text('Tornar-ho a provar'),
            ),
          ],
        ),
      ),
    );
  }
}
