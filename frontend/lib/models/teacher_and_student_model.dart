// models.dart

class Teacher {
  final String id;
  final String name;
  final String username;
  final String password;
  final String subject;
  final String qualification;
  final String experience;
  final String contact;
  final String email;

  Teacher({
    required this.id,
    required this.name,
    required this.username,
    required this.password,
    required this.subject,
    required this.qualification,
    required this.experience,
    required this.contact,
    required this.email,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['id'],
      name: json['name'],
      username: json['username'],
      password: json['password'] ?? '',
      subject: json['subject'],
      qualification: json['qualification'],
      experience: json['experience'],
      contact: json['contact'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'password': password,
      'subject': subject,
      'qualification': qualification,
      'experience': experience,
      'contact': contact,
      'email': email,
    };
  }

  Teacher copyWith({
    String? name,
    String? username,
    String? password,
    String? subject,
    String? qualification,
    String? experience,
    String? contact,
    String? email,
  }) {
    return Teacher(
      id: id,
      name: name ?? this.name,
      username: username ?? this.username,
      password: password ?? this.password,
      subject: subject ?? this.subject,
      qualification: qualification ?? this.qualification,
      experience: experience ?? this.experience,
      contact: contact ?? this.contact,
      email: email ?? this.email,
    );
  }
}

class Student {
  final String id;
  final String name;
  final String username;
  final String password;
  final String grade;
  final String section;
  final String contact;
  final String email;
  final String? fingerprintEnrolled;

  Student({
    required this.id,
    required this.name,
    required this.username,
    required this.password,
    required this.grade,
    required this.section,
    required this.contact,
    required this.email,
    this.fingerprintEnrolled,
  });

 factory Student.fromJson(Map<String, dynamic> json) {
  return Student(
    id: json['id'] ?? 'N/A',
    name: (json['name'] != null && json['name'].toString().trim().isNotEmpty) ? json['name'] : 'Unnamed Student',
    username: (json['username'] != null && json['username'].toString().trim().isNotEmpty) ? json['username'] : 'No Username',
    password: json['password'] ?? '',
    grade: (json['grade'] != null && json['grade'].toString().trim().isNotEmpty) ? json['grade'] : 'Not Assigned',
    section: (json['section'] != null && json['section'].toString().trim().isNotEmpty) ? json['section'] : 'Not Assigned',
    contact: (json['contact'] != null && json['contact'].toString().trim().isNotEmpty) ? json['contact'] : 'No Contact',
    email: (json['email'] != null && json['email'].toString().trim().isNotEmpty) ? json['email'] : 'No Email',
    fingerprintEnrolled: json['fingerprint_enrolled'], // Add this line
  );
}

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'password': password,
      'grade': grade,
      'section': section,
      'contact': contact,
      'email': email,
      'fingerprint_enrolled': fingerprintEnrolled, // Add this line
    };
  }

  Student copyWith({
    String? name,
    String? username,
    String? password,
    String? grade,
    String? section,
    String? contact,
    String? email,
    String? fingerprintEnrolled, // Add this field
  }) {
    return Student(
      id: id,
      name: name ?? this.name,
      username: username ?? this.username,
      password: password ?? this.password,
      grade: grade ?? this.grade,
      section: section ?? this.section,
      contact: contact ?? this.contact,
      email: email ?? this.email,
      fingerprintEnrolled: fingerprintEnrolled ?? this.fingerprintEnrolled, // Add this line
    );
  }
}