import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reporte de Eventos'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ReportListScreen()),
                );
              },
              child: Text('Ver Reportes'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NewReportScreen()),
                );
              },
              child: Text('Generar un Nuevo Reporte'),
            ),
          ],
        ),
      ),
    );
  }
}

class NewReportScreen extends StatelessWidget {
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nuevo Reporte'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: 'Descripción del evento'),
            ),
            TextField(
              controller: latitudeController,
              decoration: InputDecoration(labelText: 'Latitud'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: longitudeController,
              decoration: InputDecoration(labelText: 'Longitud'),
              keyboardType: TextInputType.number,
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await saveReport();
                  Navigator.pop(context);
                } catch (e) {
                  print('Error al guardar el reporte: $e');
                }
              },
              child: Text('Guardar Reporte'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> saveReport() async {
    final database = await openDatabase(
      join(await getDatabasesPath(), 'reports_database.db'),
      version: 1,
    );

    // Asegurarse de que la tabla existe
    await createTable(database);

    await database.transaction((txn) async {
      await txn.rawInsert(
        'INSERT OR REPLACE INTO Reports (user_id, description, latitude, longitude, timestamp) VALUES (?, ?, ?, ?, ?)',
        [1, descriptionController.text, double.tryParse(latitudeController.text) ?? 0.0, double.tryParse(longitudeController.text) ?? 0.0, DateTime.now().toUtc().toIso8601String()],
      );
    });

    await database.close();
  }

  Future<void> createTable(Database database) async {
    await database.execute(
      'CREATE TABLE IF NOT EXISTS Reports(id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER, description TEXT, '
      'latitude REAL, longitude REAL, timestamp DATETIME)',
    );
  }
}

class ReportListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reportes'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: getReports(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text('No hay reportes disponibles.'),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(snapshot.data![index]['description']),
                subtitle: Text(snapshot.data![index]['timestamp']),
                onTap: () {
                  // Implementa la navegación a la pantalla de detalles del reporte si es necesario
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> getReports() async {
    final database = await openDatabase(
      join(await getDatabasesPath(), 'reports_database.db'),
      version: 1,
    );

    // Asegurarse de que la tabla existe
    await createTable(database);

    return await database.query('Reports');
  }

  Future<void> createTable(Database database) async {
    await database.execute(
      'CREATE TABLE IF NOT EXISTS Reports(id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER, description TEXT, '
      'latitude REAL, longitude REAL, timestamp DATETIME)',
    );
  }
}
