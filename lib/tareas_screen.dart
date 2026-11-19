import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TareasScreen extends StatelessWidget {
  const TareasScreen({super.key});

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('tareas');

  Future<void> _agregar(String titulo) async {
    await _col.add({
      'titulo': titulo,
      'completada': false,
      'fechaCreacion': FieldValue.serverTimestamp(),
      'userId': FirebaseAuth.instance.currentUser!.uid,
    });
  }

  void _dialogoNueva(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva tarea'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Título'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) _agregar(ctrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _col
            .where('userId', isEqualTo: uid)
            .orderBy('fechaCreacion', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No tenés tareas todavía'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final doc = docs[i];
              final data = doc.data();
              final hecha = data['completada'] ?? false;
              return Dismissible(
                key: ValueKey(doc.id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => doc.reference.delete(),
                child: ListTile(
                  title: Text(
                    data['titulo'] ?? '',
                    style: TextStyle(
                        decoration:
                        hecha ? TextDecoration.lineThrough : null),
                  ),
                  trailing: Switch(
                    value: hecha,
                    onChanged: (v) => doc.reference.update({'completada': v}),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _dialogoNueva(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}