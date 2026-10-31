import '../entities/geo_note.dart';

abstract class NoteRepository {
  Future<List<GeoNote>> getNotes();
  Future<GeoNote?> getNoteById(String id);
  Future<void> saveNote(GeoNote note);
  Future<void> deleteNote(String id);
  Future<void> updateNoteSyncStatus(String id, NoteSyncStatus status);
}

