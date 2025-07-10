import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:projek_uas/logic/add_mapping_logic.dart';
import 'package:screenshot/screenshot.dart';
import 'package:projek_uas/screen/KebunSaya/kebunSaya.dart';

// Mixin untuk safe state management
mixin SafeState<T extends StatefulWidget> on State<T> {
  void safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }
}

class AddMappingPage extends StatefulWidget {
  const AddMappingPage({super.key});

  @override
  State<AddMappingPage> createState() => _AddMappingPageState();
}

class _AddMappingPageState extends State<AddMappingPage> with SafeState {
  late AddMappingLogic _logic;

  @override
  void initState() {
    super.initState();
    _initializeLogic();
  }

  void _initializeLogic() {
    _logic = AddMappingLogic(
      onStateChanged: (fn) => safeSetState(fn),
      onShowMessage: (message) => _showMessage(message),
      onNavigateToMapping: () => _navigateToMapping(),
    );
  }

  @override
  void dispose() {
    _logic.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _navigateToMapping() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MappingPage(idLahan: null),
        ),
      );
    }
  }

  void _showClearConfirmation() {
    if (_logic.polygonPoints.isEmpty) {
      _showMessage("Tidak ada titik untuk dihapus");
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, 
                   color: Colors.orange, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Konfirmasi Hapus',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus semua ${_logic.polygonPoints.length} titik polygon?',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Batal',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logic.clearAllPoints();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Hapus Semua'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomControls(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      title: const Text(
        'Petakan Lahan Saya',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      elevation: 1,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: TextButton.icon(
            onPressed: _logic.isSubmitting ? null : _logic.submitPolygon,
            icon: _logic.isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save, size: 18),
            label: const Text('SIMPAN'),
            style: TextButton.styleFrom(
              foregroundColor: _logic.isSubmitting ? Colors.grey : Colors.green,
              backgroundColor: _logic.isSubmitting 
                  ? Colors.grey.withOpacity(0.1) 
                  : Colors.green.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Stack(
      children: [
        _buildMap(),
        _buildPolygonStatus(),
        if (_logic.isSubmitting) _buildLoadingOverlay(),
      ],
    );
  }

  Widget _buildPolygonStatus() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                Colors.green.shade50,
                Colors.green.shade100,
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _logic.isPolygonValid() 
                      ? Colors.green 
                      : Colors.orange,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _logic.isPolygonValid() 
                      ? Icons.check 
                      : Icons.location_on,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _logic.isPolygonValid() 
                          ? 'Polygon Siap!' 
                          : 'Menunggu Titik',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _logic.isPolygonValid() 
                            ? Colors.green.shade700 
                            : Colors.orange.shade700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _logic.getPolygonStatus(),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: _buildControlButton(
                icon: Icons.undo,
                label: 'Undo',
                onPressed: _logic.polygonPoints.isNotEmpty && !_logic.isSubmitting
                    ? _logic.undoLastPoint
                    : null,
                color: Colors.orange,
                subtitle: _logic.polygonPoints.isNotEmpty 
                    ? 'Hapus titik terakhir' 
                    : 'Tidak ada titik',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildControlButton(
                icon: Icons.clear_all,
                label: 'Clear All',
                onPressed: _logic.polygonPoints.isNotEmpty && !_logic.isSubmitting
                    ? _showClearConfirmation
                    : null,
                color: Colors.red,
                subtitle: _logic.polygonPoints.isNotEmpty 
                    ? 'Hapus semua titik' 
                    : 'Tidak ada titik',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
    required String subtitle,
  }) {
    final isEnabled = onPressed != null;
    
    return SizedBox(
      height: 70,
      child: Material(
        color: isEnabled 
            ? color.withOpacity(0.1) 
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: isEnabled ? color : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        color: isEnabled ? color : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMap() {
    return Screenshot(
      controller: _logic.screenshotController,
      child: FlutterMap(
        mapController: _logic.mapController,
        options: MapOptions(
          center: LatLng(-6.2, 106.816666),
          zoom: 16.0,
          onTap: _logic.onMapTap,
        ),
        children: [
          _buildTileLayer(),
          if (_logic.polygonPoints.isNotEmpty) _buildPolygonLayer(),
          _buildMarkerLayer(),
        ],
      ),
    );
  }

  Widget _buildTileLayer() {
    return TileLayer(
      urlTemplate:
          'https://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
      userAgentPackageName: 'com.example.app',
    );
  }

  Widget _buildPolygonLayer() {
    return PolygonLayer(
      polygons: [
        Polygon(
          points: _logic.polygonPoints,
          color: Colors.green.withOpacity(0.4),
          borderStrokeWidth: 2,
          borderColor: Colors.green,
        ),
      ],
    );
  }

  Widget _buildMarkerLayer() {
    return MarkerLayer(
      markers: [
        ..._buildPolygonMarkers(),
        if (_logic.userLocation != null) _buildUserLocationMarker(),
      ],
    );
  }

  List<Marker> _buildPolygonMarkers() {
    return _logic.polygonPoints.asMap().entries.map((entry) {
      final index = entry.key;
      final point = entry.value;
      
      return Marker(
        point: point,
        width: 30,
        height: 30,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Marker _buildUserLocationMarker() {
    return Marker(
      point: _logic.userLocation!,
      width: 40,
      height: 40,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(
          Icons.my_location,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Menyimpan data lahan...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mohon tunggu sebentar',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _logic.isSubmitting ? null : _logic.getUserLocation,
      label: const Text(
        'Temukan Saya',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      icon: const Icon(Icons.gps_fixed),
      backgroundColor: _logic.isSubmitting ? Colors.grey : Colors.white,
      foregroundColor: _logic.isSubmitting ? Colors.white : Colors.black,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}