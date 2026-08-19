import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/quiz.dart';
import '../models/quiz_result.dart';
import '../models/mastery.dart';
import '../models/folder.dart';

class StorageService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'quizforge.db');

    return await openDatabase(
      path,
      version: 6,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE quizzes (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            questions TEXT NOT NULL,
            settings TEXT NOT NULL,
            sourceText TEXT,
            masteryId TEXT,
            createdAt TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE results (
            id TEXT PRIMARY KEY,
            quizId TEXT NOT NULL,
            quizTitle TEXT NOT NULL,
            score INTEGER NOT NULL,
            totalQuestions INTEGER NOT NULL,
            topicResults TEXT NOT NULL,
            completedAt TEXT NOT NULL,
            timeTakenSeconds INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE mastery (
            id TEXT PRIMARY KEY,
            materialTitle TEXT NOT NULL,
            sourceText TEXT NOT NULL,
            concepts TEXT NOT NULL,
            notes TEXT NOT NULL DEFAULT '',
            folderId TEXT,
            masteryPercent REAL NOT NULL DEFAULT 0,
            totalCorrect INTEGER NOT NULL DEFAULT 0,
            totalAttempted INTEGER NOT NULL DEFAULT 0,
            challenge1Score INTEGER NOT NULL DEFAULT 0,
            challenge2Score INTEGER NOT NULL DEFAULT 0,
            challenge1Unlocked INTEGER NOT NULL DEFAULT 0,
            challenge2Unlocked INTEGER NOT NULL DEFAULT 0,
            fullyMastered INTEGER NOT NULL DEFAULT 0,
            stars INTEGER NOT NULL DEFAULT 0,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE flashcards (
            id TEXT PRIMARY KEY,
            masteryId TEXT NOT NULL,
            front TEXT NOT NULL,
            back TEXT NOT NULL,
            cardIndex INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (masteryId) REFERENCES mastery(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE folders (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            colorIndex INTEGER NOT NULL DEFAULT 0,
            createdAt TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try { await db.execute('ALTER TABLE quizzes ADD COLUMN sourceText TEXT'); } catch (_) {}
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS mastery (
              id TEXT PRIMARY KEY, materialTitle TEXT NOT NULL, sourceText TEXT NOT NULL,
              concepts TEXT NOT NULL, masteryPercent REAL NOT NULL DEFAULT 0,
              totalCorrect INTEGER NOT NULL DEFAULT 0, totalAttempted INTEGER NOT NULL DEFAULT 0,
              challenge1Score INTEGER NOT NULL DEFAULT 0, challenge2Score INTEGER NOT NULL DEFAULT 0,
              challenge1Unlocked INTEGER NOT NULL DEFAULT 0, challenge2Unlocked INTEGER NOT NULL DEFAULT 0,
              fullyMastered INTEGER NOT NULL DEFAULT 0, stars INTEGER NOT NULL DEFAULT 0,
              createdAt TEXT NOT NULL, updatedAt TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 4) {
          try { await db.execute("ALTER TABLE mastery ADD COLUMN notes TEXT NOT NULL DEFAULT ''"); } catch (_) {}
          await db.execute('''
            CREATE TABLE IF NOT EXISTS flashcards (
              id TEXT PRIMARY KEY, masteryId TEXT NOT NULL, front TEXT NOT NULL,
              back TEXT NOT NULL, cardIndex INTEGER NOT NULL DEFAULT 0,
              FOREIGN KEY (masteryId) REFERENCES mastery(id)
            )
          ''');
        }
        if (oldVersion < 5) {
          try { await db.execute('ALTER TABLE quizzes ADD COLUMN masteryId TEXT'); } catch (_) {}
        }
        if (oldVersion < 6) {
          try { await db.execute('ALTER TABLE mastery ADD COLUMN folderId TEXT'); } catch (_) {}
          await db.execute('''
            CREATE TABLE IF NOT EXISTS folders (
              id TEXT PRIMARY KEY, name TEXT NOT NULL,
              colorIndex INTEGER NOT NULL DEFAULT 0, createdAt TEXT NOT NULL
            )
          ''');
        }
      },
    );
  }

  static Future<void> saveQuiz(Quiz quiz) async {
    final db = await database;
    await db.insert('quizzes', quiz.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Quiz>> getAllQuizzes() async {
    final db = await database;
    final maps = await db.query('quizzes', orderBy: 'createdAt DESC');
    return maps.map((m) => Quiz.fromMap(m)).toList();
  }

  static Future<Quiz?> getQuiz(String id) async {
    final db = await database;
    final maps = await db.query('quizzes', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Quiz.fromMap(maps.first);
  }

  static Future<void> deleteQuiz(String id) async {
    final db = await database;
    await db.delete('results', where: 'quizId = ?', whereArgs: [id]);
    await db.delete('quizzes', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> saveResult(QuizResult result) async {
    final db = await database;
    final topicStr = result.topicResults.map((t) => '${t.topic}:${t.correct}:${t.total}').join('|');
    await db.insert('results', {
      'id': result.id, 'quizId': result.quizId, 'quizTitle': result.quizTitle,
      'score': result.score, 'totalQuestions': result.totalQuestions,
      'topicResults': Uri.encodeComponent(topicStr),
      'completedAt': result.completedAt.toIso8601String(),
      'timeTakenSeconds': result.timeTakenSeconds,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<QuizResult>> getResults(String quizId) async {
    final db = await database;
    final maps = await db.query('results', where: 'quizId = ?', whereArgs: [quizId], orderBy: 'completedAt DESC');
    return maps.map((m) => _resultFromMap(m)).toList();
  }

  static Future<List<QuizResult>> getAllResults() async {
    final db = await database;
    final maps = await db.query('results', orderBy: 'completedAt DESC');
    return maps.map((m) => _resultFromMap(m)).toList();
  }

  static QuizResult _resultFromMap(Map<String, dynamic> m) {
    final topicString = Uri.decodeComponent(m['topicResults'] as String? ?? '');
    final topicResults = topicString.isNotEmpty
        ? topicString.split('|').map((t) {
            final parts = t.split(':');
            return TopicResult(topic: parts[0], correct: int.parse(parts[1]), total: int.parse(parts[2]));
          }).toList()
        : <TopicResult>[];
    return QuizResult(
      id: m['id'] as String, quizId: m['quizId'] as String, quizTitle: m['quizTitle'] as String,
      score: m['score'] as int, totalQuestions: m['totalQuestions'] as int,
      topicResults: topicResults, completedAt: DateTime.parse(m['completedAt'] as String),
      timeTakenSeconds: m['timeTakenSeconds'] as int,
    );
  }

  static Future<void> saveMastery(Mastery mastery) async {
    final db = await database;
    await db.insert('mastery', mastery.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<Mastery?> getMastery(String id) async {
    final db = await database;
    final maps = await db.query('mastery', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Mastery.fromMap(maps.first);
  }

  static Future<List<Mastery>> getAllMastery() async {
    final db = await database;
    final maps = await db.query('mastery', orderBy: 'updatedAt DESC');
    return maps.map((m) => Mastery.fromMap(m)).toList();
  }

  static Future<List<Mastery>> getMasteryByFolder(String? folderId) async {
    final db = await database;
    final maps = folderId == null
        ? await db.query('mastery', where: 'folderId IS NULL', orderBy: 'updatedAt DESC')
        : await db.query('mastery', where: 'folderId = ?', whereArgs: [folderId], orderBy: 'updatedAt DESC');
    return maps.map((m) => Mastery.fromMap(m)).toList();
  }

  static Future<void> moveMasteryToFolder(String masteryId, String? folderId) async {
    final db = await database;
    await db.update('mastery', {'folderId': folderId}, where: 'id = ?', whereArgs: [masteryId]);
  }

  static Future<void> deleteMastery(String id) async {
    final db = await database;
    await db.delete('flashcards', where: 'masteryId = ?', whereArgs: [id]);
    await db.delete('mastery', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteMasteryCascade(String masteryId) async {
    final db = await database;
    final linkedQuizzes = await db.query('quizzes', where: 'masteryId = ?', whereArgs: [masteryId]);
    for (final q in linkedQuizzes) {
      await db.delete('results', where: 'quizId = ?', whereArgs: [q['id']]);
    }
    await db.delete('quizzes', where: 'masteryId = ?', whereArgs: [masteryId]);
    await db.delete('flashcards', where: 'masteryId = ?', whereArgs: [masteryId]);
    await db.delete('mastery', where: 'id = ?', whereArgs: [masteryId]);
  }

  static Future<List<Quiz>> getQuizzesByMasteryId(String masteryId) async {
    final db = await database;
    final maps = await db.query('quizzes', where: 'masteryId = ?', whereArgs: [masteryId], orderBy: 'createdAt DESC');
    return maps.map((m) => Quiz.fromMap(m)).toList();
  }

  static Future<void> saveFlashcards(String masteryId, List<Map<String, String>> cards) async {
    final db = await database;
    await db.delete('flashcards', where: 'masteryId = ?', whereArgs: [masteryId]);
    for (var i = 0; i < cards.length; i++) {
      await db.insert('flashcards', {
        'id': '${masteryId}_fc_$i', 'masteryId': masteryId,
        'front': cards[i]['front'] ?? '', 'back': cards[i]['back'] ?? '', 'cardIndex': i,
      });
    }
  }

  static Future<List<Map<String, String>>> getFlashcards(String masteryId) async {
    final db = await database;
    final maps = await db.query('flashcards', where: 'masteryId = ?', whereArgs: [masteryId], orderBy: 'cardIndex ASC');
    return maps.map((m) => {'front': m['front'] as String, 'back': m['back'] as String}).toList();
  }

  static Future<void> saveFolder(Folder folder) async {
    final db = await database;
    await db.insert('folders', folder.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Folder>> getAllFolders() async {
    final db = await database;
    final maps = await db.query('folders', orderBy: 'createdAt ASC');
    return maps.map((m) => Folder.fromMap(m)).toList();
  }

  static Future<Folder?> getFolder(String id) async {
    final db = await database;
    final maps = await db.query('folders', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Folder.fromMap(maps.first);
  }

  static Future<void> deleteFolder(String id) async {
    final db = await database;
    await db.update('mastery', {'folderId': null}, where: 'folderId = ?', whereArgs: [id]);
    await db.delete('folders', where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> getMaterialCountForFolder(String? folderId) async {
    final db = await database;
    final result = folderId == null
        ? await db.rawQuery('SELECT COUNT(*) as cnt FROM mastery WHERE folderId IS NULL')
        : await db.rawQuery('SELECT COUNT(*) as cnt FROM mastery WHERE folderId = ?', [folderId]);
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
