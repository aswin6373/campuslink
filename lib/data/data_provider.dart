import 'dart:convert';
import 'package:campuslink/models/teacher_and_student_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:campuslink/data/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataProvider with ChangeNotifier {
  final String baseUrl = '${Config.baseUrl}/clink/api/manage_teachers_and_students.php';
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
      final response = await http.get(
        Uri.parse('$baseUrl?endpoint=teachers&institution=$_currentInstitution'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _teachers = data.map((json) => Teacher.fromJson(json)).toList();
        _error = null;
        notifyListeners();
      } else {
        _error = 'Failed to fetch teachers. Status code: ${response.statusCode}';
        _teachers = [];
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error fetching teachers: $e';
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
      final Map<String, dynamic> teacherData = teacher.toJson();
      teacherData['institution'] = _currentInstitution; // Add institution to the request

      final response = await http.post(
        Uri.parse('$baseUrl?endpoint=teachers'),
        body: json.encode(teacherData),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        await fetchTeachers();
      } else {
        _error = 'Failed to add teacher. Status code: ${response.statusCode}';
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error adding teacher: $e';
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
      final Map<String, dynamic> teacherData = teacher.toJson();
      teacherData['institution'] = _currentInstitution;

      final response = await http.put(
        Uri.parse('$baseUrl?endpoint=teachers'),
        body: json.encode(teacherData),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        await fetchTeachers();
      } else {
        _error = 'Failed to update teacher';
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error updating teacher: $e';
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
      final response = await http.delete(
        Uri.parse('$baseUrl?endpoint=teachers'),
        body: json.encode({
          'id': id,
          'institution': _currentInstitution,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        await fetchTeachers();
      } else {
        _error = 'Failed to delete teacher';
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error deleting teacher: $e';
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
      final response = await http.get(
        Uri.parse('$baseUrl?endpoint=students&institution=$_currentInstitution'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _students = data.map((json) => Student.fromJson(json)).toList();
        _error = null;
        notifyListeners();
      } else {
        _error = 'Failed to fetch students. Status code: ${response.statusCode}';
        _students = [];
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error fetching students: $e';
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
      final Map<String, dynamic> studentData = student.toJson();
      studentData['institution'] = _currentInstitution;

      final response = await http.post(
        Uri.parse('$baseUrl?endpoint=students'),
        body: json.encode(studentData),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        await fetchStudents();
      } else {
        _error = 'Failed to add student. Status code: ${response.statusCode}';
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error adding student: $e';
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
      final Map<String, dynamic> studentData = student.toJson();
      studentData['institution'] = _currentInstitution;

      final response = await http.put(
        Uri.parse('$baseUrl?endpoint=students'),
        body: json.encode(studentData),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        await fetchStudents();
      } else {
        _error = 'Failed to update student';
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error updating student: $e';
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
      final response = await http.delete(
        Uri.parse('$baseUrl?endpoint=students'),
        body: json.encode({
          'id': id,
          'institution': _currentInstitution,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        await fetchStudents();
      } else {
        _error = 'Failed to delete student';
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error deleting student: $e';
      notifyListeners();
    }
  }
}