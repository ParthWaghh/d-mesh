import '../../domain/entities/geo_note.dart';
import '../../domain/repositories/note_repository.dart';
import '../datasources/local/dmesh_database.dart';
import '../models/geo_note_model.dart';

class NoteRepositoryImpl implements NoteRepository {
  final DMeshDatabase _database;

  NoteRepositoryImpl({DMeshDatabase? database})
      : _database = database ?? DMeshDatabase.instance;

  @override
  Future<List<GeoNote>> getNotes() async {
    final rows = await _database.getAllNotes();
    return rows.map((r) => GeoNoteModel.fromMap(r)).toList();
  }

  @override
  Future<GeoNote?> getNoteById(String id) async {
    final row = await _database.getNoteById(id);
    if (row == null) return null;
    return GeoNoteModel.fromMap(row);
  }

  @override
  Future<void> saveNote(GeoNote note) async {
    final model = GeoNoteModel.fromEntity(note);
    await _database.insertOrUpdateNote(model.toMap());
  }

  @override
  Future<void> deleteNote(String id) async {
    await _database.deleteNote(id);
  }

  @override
  Future<void> updateNoteSyncStatus(String id, NoteSyncStatus status) async {
    final existing = await getNoteById(id);
    if (existing != null) {
      final updated = existing.copyWith(syncStatus: status);
      await saveNote(updated);
    }
  }
}

