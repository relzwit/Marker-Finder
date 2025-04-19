import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class DraggableExplorer extends StatefulWidget {
  final Function(LatLng) onDrop;

  const DraggableExplorer({
    super.key,
    required this.onDrop,
  });

  @override
  State<DraggableExplorer> createState() => _DraggableExplorerState();
}

class _DraggableExplorerState extends State<DraggableExplorer> with SingleTickerProviderStateMixin {
  bool _isDragging = false;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Create a pulsing animation to draw attention to the draggable
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Repeat the animation
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      top: 100,
      child: Column(
        children: [
          // Tooltip bubble above the draggable
          if (!_isDragging) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(200),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Drag to explore a city',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ],

          // The draggable explorer icon
          Draggable<String>(
            // Data is just a placeholder
            data: 'explorer',
            // What to show while dragging
            feedback: Material(
              elevation: 4.0,
              borderRadius: BorderRadius.circular(40),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(230),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_city,
                      color: Colors.white,
                      size: 30,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Drop on a city',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // What to show when not dragging
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isDragging ? 1.0 : _pulseAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isDragging
                          ? Colors.orange.withAlpha(128) // 0.5 opacity
                          : Colors.orange,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(51), // 0.2 opacity
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_city,
                          color: Colors.white,
                          size: 24,
                        ),
                        if (!_isDragging) ...[
                          const SizedBox(width: 8),
                          const Text(
                            'Drag to city',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
            // When dragging starts
            onDragStarted: () {
              setState(() {
                _isDragging = true;
              });
            },
            // When dragging ends
            onDragEnd: (details) {
              setState(() {
                _isDragging = false;
              });
            },
            // When dragging is canceled
            onDraggableCanceled: (velocity, offset) {
              setState(() {
                _isDragging = false;
              });
            },
          ),
        ],
      ),
    );
  }
}

class MapExplorerTarget extends StatelessWidget {
  final Function(LatLng) onDrop;

  const MapExplorerTarget({
    super.key,
    required this.onDrop,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Invisible layer that allows map interactions to pass through
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),

        // Drag target that only accepts our specific draggable
        Positioned.fill(
          child: DragTarget<String>(
            builder: (context, candidateData, rejectedData) {
              // Only show a visual indicator when dragging over
              return candidateData.isNotEmpty
                  ? Container(
                      color: Colors.blue.withAlpha(30),
                      child: const Center(
                        child: Text(
                          'Drop to explore this area',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            shadows: [
                              Shadow(
                                offset: Offset(1, 1),
                                blurRadius: 3.0,
                                color: Colors.black,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(); // Invisible when not dragging
            },
            onAcceptWithDetails: (details) {
              // When the draggable is dropped on the map, use the drop position
              // Convert screen coordinates to a position on the map
              final RenderBox box = context.findRenderObject() as RenderBox;
              final localPosition = box.globalToLocal(details.offset);

              // We'll pass the drop position to the callback
              // The parent widget will convert this to map coordinates
              onDrop(LatLng(localPosition.dy, localPosition.dx));
            },
            // Only accept our specific draggable
            onWillAcceptWithDetails: (details) => details.data == 'explorer',
          ),
        ),
      ],
    );
  }
}
