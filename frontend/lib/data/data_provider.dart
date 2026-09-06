import 'package:campuslink/models/teacher_and_student_model.dart';
import 'package:flutter/material.dart';
import 'package:campuslink/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataProvider with ChangeNotifier {
  List<Student> _students = [];
  List<Teacher> _teachers = [];
  String? _error;
  String? _currentInstitution;

  String? get currentInstitution => _currentInstitution;
  set currentInstitution(String? institution) {
    _currentInstitution = institution;
    notifyListeners();
  }

  List<Student> get students => _students;
  List<Teacher> get teachers => _teachers;
  String? get error => _error;

  // Load user data from shared preferences
  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final institution = prefs.getString('institution');

    if (institution != null) {
      _currentInstitution = institution;
      notifyListeners();
    }
  }

  // Fetch teachers after loading user data
  Future<void> fetchTeachers() async {
    // First load user data before fetching teachers
    await loadUserData(); 

    // If user data isn't available, don't proceed
    if (_currentInstitution == null) {
      _error = 'No user ID provided';
      notifyListeners();
      return;
    }

    try {
      final data = await ApiClient.get('/api/teachers');
      final List<dynamic> list = data is List ? data : [];
      _teachers = list.map((json) => Teacher.fromJson(json)).toList();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _teachers = [];
      notifyListeners();
    }
  }

  Future<void> addTeacher(Teacher teacher) async {
    if (_currentInstitution == null) {
      _error = 'No user ID provided';
      notifyListeners();
      return;
    }

    try {
      await ApiClient.post('/api/teachers', body: teacher.toJson());
      await fetchTeachers();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateTeacher(Teacher teacher) async {
    if (_currentInstitution == null) {
      _error = 'No user ID provided';
      notifyListeners();
      return;
    }

    try {
      await ApiClient.put('/api/teachers/${teacher.id}', body: teacher.toJson());
      await fetchTeachers();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteTeacher(String id) async {
    if (_currentInstitution == null) {
      _error = 'No user ID provided';
      notifyListeners();
      return;
    }

    try {
      await ApiClient.delete('/api/teachers/$id');
      await fetchTeachers();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Student Methods
  Future<void> fetchStudents() async {
    await loadUserData(); // Load user data before fetching students

    if (_currentInstitution == null) {
      _error = 'No user ID provided';
      notifyListeners();
      return;
    }

    try {
      final data = await ApiClient.get('/api/students');
      final List<dynamic> list = data is List ? data : [];
      _students = list.map((json) => Student.fromJson(json)).toList();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _students = [];
      notifyListeners();
    }
  }

  Future<void> addStudent(Student student) async {
    if (_currentInstitution == null) {
      _error = 'No user ID provided';
      notifyListeners();
      return;
    }

    try {
      await ApiClient.post('/api/students', body: student.toJson());
      await fetchStudents();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateStudent(Student student) async {
    if (_currentInstitution == null) {
      _error = 'No user ID provided';
      notifyListeners();
      return;
    }

    try {
      await ApiClient.put('/api/students/${student.id}', body: student.toJson());
      await fetchStudents();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteStudent(String id) async {
    if (_currentInstitution == null) {
      _error = 'No user ID provided';
      notifyListeners();
      return;
    }

    try {
      await ApiClient.delete('/api/students/$id');
      await fetchStudents();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}