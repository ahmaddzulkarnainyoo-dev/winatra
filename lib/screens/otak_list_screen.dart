import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/models/otak_model.dart';
import '../core/services/otak_service.dart';
import '../core/theme/app_colors.dart';

class OtakListScreen extends StatefulWidget {
  const OtakListScreen({super.key});

  @override
  State<OtakListScreen> createState() => _OtakListScreenState();
}

class _OtakListScreenState extends State<OtakListScreen> {
  final _otakService = OtakService();
  List<Otak> _otakList = [];
  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadOtaks();
  }

  Future<void> _loadOtaks() async {
    setState(() => _isLoading = true);
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final otaks = await _otakService.fetchUserOtaks(userId);
      setState(() => _otakList = otaks);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'docx'],
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat mengakses file')),
      );
      return;
    }

    setState(() => _isUploading = true);
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      await _otakService.uploadFile(userId, file.path!, file.name);
      await _loadOtaks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File berhasil diupload')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal upload: $e')),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteOtak(Otak otak) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Hapus Otak', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Yakin ingin menghapus "${otak.fileName}"?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _otakService.deleteOtak(otak.id, otak.storagePath);
      await _loadOtaks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Otak berhasil dihapus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: $e')),
        );
      }
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _fileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'docx':
        return Icons.description;
      case 'txt':
        return Icons.article;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.electricBlueDeep,
      appBar: AppBar(
        title: const Text(
          'Otak Saya',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.electricBlueDark,
        iconTheme: const IconThemeData(color: AppColors.neonCyan),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _pickAndUploadFile,
        backgroundColor: AppColors.neonCyan,
        icon: _isUploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.electricBlueDeep,
                ),
              )
            : const Icon(Icons.upload_file, color: AppColors.electricBlueDeep),
        label: Text(
          _isUploading ? 'Mengupload...' : 'Upload',
          style: const TextStyle(color: AppColors.electricBlueDeep),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.neonCyan),
      );
    }

    if (_isUploading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.neonCyan),
            SizedBox(height: 16),
            Text(
              'Mengupload file...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_otakList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.psychology_outlined,
                size: 80,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'Belum ada Otak',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Upload file PDF, TXT, atau DOCX\nuntuk dijadikan basis pengetahuan pribadi.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _pickAndUploadFile,
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Otak Baru'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonCyan,
                  foregroundColor: AppColors.electricBlueDeep,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOtaks,
      color: AppColors.neonCyan,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _otakList.length,
        itemBuilder: (context, index) {
          final otak = _otakList[index];
          return _buildOtakItem(otak);
        },
      ),
    );
  }

  Widget _buildOtakItem(Otak otak) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(
          _fileIcon(otak.fileName),
          color: AppColors.neonCyan,
          size: 36,
        ),
        title: Text(
          otak.fileName,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  _formatSize(otak.fileSize),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _formatDate(otak.uploadedAt),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (otak.summary.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                otak.summary,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ] else ...[
              const SizedBox(height: 4),
              const Text(
                'Belum diringkas',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.danger),
          onPressed: () => _deleteOtak(otak),
        ),
      ),
    );
  }
}