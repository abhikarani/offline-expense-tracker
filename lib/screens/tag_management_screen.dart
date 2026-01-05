import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

/// Screen for managing tags (add, edit, remove)
class TagManagementScreen extends StatefulWidget {
  const TagManagementScreen({super.key});

  @override
  State<TagManagementScreen> createState() => _TagManagementScreenState();
}

class _TagManagementScreenState extends State<TagManagementScreen> {
  final _addTagController = TextEditingController();
  List<String> _tags = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  @override
  void dispose() {
    _addTagController.dispose();
    super.dispose();
  }

  Future<void> _loadTags() async {
    setState(() => _isLoading = true);
    try {
      final provider = context.read<AppProvider>();
      final tags = await provider.getActiveTags();
      setState(() {
        _tags = tags;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading tags: $e')),
        );
      }
    }
  }

  Future<void> _addTag() async {
    final tagName = _addTagController.text.trim();
    if (tagName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a tag name')),
      );
      return;
    }

    if (_tags.contains(tagName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tag already exists')),
      );
      return;
    }

    try {
      final provider = context.read<AppProvider>();
      await provider.addTag(tagName);
      _addTagController.clear();
      await _loadTags();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tag "$tagName" added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding tag: $e')),
        );
      }
    }
  }

  Future<void> _deleteTag(String tagName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tag'),
        content: Text(
          'Are you sure you want to delete "$tagName"?\n\nExisting transactions with this tag will keep it, but it won\'t appear in the dropdown for new transactions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final provider = context.read<AppProvider>();
      await provider.deleteTag(tagName);
      await _loadTags();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tag "$tagName" deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting tag: $e')),
        );
      }
    }
  }

  Future<void> _renameTag(String oldName) async {
    final controller = TextEditingController(text: oldName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Tag'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'New tag name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (newName == null || newName.isEmpty || newName == oldName) return;

    if (_tags.contains(newName)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tag with this name already exists')),
        );
      }
      return;
    }

    try {
      final provider = context.read<AppProvider>();
      await provider.renameTag(oldName, newName);
      await _loadTags();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tag renamed to "$newName"')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error renaming tag: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Tags'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Add tag section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _addTagController,
                          decoration: const InputDecoration(
                            labelText: 'Add new tag',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.label),
                          ),
                          onSubmitted: (_) => _addTag(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _addTag,
                        icon: const Icon(Icons.add_circle),
                        iconSize: 40,
                        color: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // Tags list
                Expanded(
                  child: _tags.isEmpty
                      ? const Center(
                          child: Text(
                            'No tags yet.\nAdd one above!',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _tags.length,
                          itemBuilder: (context, index) {
                            final tag = _tags[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text(
                                    tag[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  tag,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _renameTag(tag),
                                      tooltip: 'Rename',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      color: Colors.red,
                                      onPressed: () => _deleteTag(tag),
                                      tooltip: 'Delete',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
