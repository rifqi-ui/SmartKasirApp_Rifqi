import 'package:flutter/foundation.dart'; // untuk kIsWeb (deteksi Chrome)
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../models/produk.dart';

// Pengelola koneksi dan operasi database SQLite lokal SmartKasir
class DatabaseHelper {
  // --- 1. SINGLETON ---
  // Satu instance tunggal yang dipakai seluruh halaman
  static final DatabaseHelper instance = DatabaseHelper._init();

  // Koneksi database aktif (null sebelum dibuka)
  static Database? _database;

  // Konstruktor privat: mencegah pembuatan objek lewat DatabaseHelper()
  DatabaseHelper._init();

  // --- 2. GETTER DATABASE ---
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('smartkasir.db');
    return _database!;
  }

  // --- 3. INISIALISASI DATABASE (CHROME & ANDROID) ---
  Future<Database> _initDB(String filePath) async {
    // Jika berjalan di Chrome (Flutter Web)
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      return await openDatabase(filePath, version: 1, onCreate: _createDB);
    }

    // Jika berjalan di Android
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  // --- 4. DDL: BUAT TABEL & SEEDING DATA AWAL ---
  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE produk (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kode_produk TEXT UNIQUE,
        nama_produk TEXT NOT NULL,
        kategori TEXT NOT NULL,
        harga_beli REAL NOT NULL,
        harga_jual REAL NOT NULL,
        stok INTEGER NOT NULL,
        gambar_path TEXT,
        diskon_persen INTEGER DEFAULT 0,
        created_at TEXT
      )
    ''');

    // Isi otomatis 6 produk awal
    for (final produk in produkAwalSQLite) {
      await db.insert('produk', produk.toMap());
    }
  }

  // --- 5. CREATE: TAMBAH PRODUK ---
  Future<int> insertProduk(Produk produk) async {
    final db = await instance.database;
    final id = await db.insert(
      'produk',
      produk.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id;
  }

  // --- 6. READ: SEMUA PRODUK ---
  Future<List<Produk>> getAllProduk() async {
    final db = await instance.database;
    final result = await db.query('produk', orderBy: 'harga_jual ASC');
    return result.map((json) => Produk.fromMap(json)).toList();
  }

  // --- 7. READ: FILTER KATEGORI ---
  Future<List<Produk>> getProdukByKategori(String kategori) async {
    final db = await instance.database;

    if (kategori == 'Semua') {
      return await getAllProduk();
    }

    final result = await db.query(
      'produk',
      where: 'kategori = ?',
      whereArgs: [kategori],
      orderBy: 'id DESC',
    );
    return result.map((json) => Produk.fromMap(json)).toList();
  }

  // --- 8. SEARCH: PENCARIAN DENGAN SQL LIKE ---
  Future<List<Produk>> searchProduk(String keyword) async {
    final db = await instance.database;
    final result = await db.query(
      'produk',
      where: 'nama_produk LIKE ?',
      whereArgs: ['%$keyword%'],
      orderBy: 'id DESC',
    );
    return result.map((json) => Produk.fromMap(json)).toList();
  }

  // --- 9. UPDATE: PERBARUI PRODUK ---
  Future<int> updateProduk(Produk produk) async {
    final db = await instance.database;
    return await db.update(
      'produk',
      produk.toMap(),
      where: 'id = ?',
      whereArgs: [produk.id],
    );
  }

  // --- 10. DELETE: HAPUS PRODUK ---
  Future<int> deleteProduk(int id) async {
    final db = await instance.database;
    return await db.delete('produk', where: 'id = ?', whereArgs: [id]);
  }
}
