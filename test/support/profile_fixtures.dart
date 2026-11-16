/// Perfil fictício no formato da API v02 (6.2.1).
final profileJson = <String, Object?>{
  'candidateId': '3f2a9c1e-7b4d-4e8a-9c21-5d6e7f8a9b01',
  'fullName': 'Rita Fictícia Moreira',
  'email': 'rita.moreira@exemplo.pt',
  'phoneNumber': '912345678',
  'locationId': '1a2b3c4d-5e6f-4a7b-8c9d-0e1f2a3b4c07',
  'locationName': 'Braga (Braga)',
  'desiredRole': 'Programador júnior',
  'availability': 'FIFTEEN_DAYS',
  'experienceSummary': 'Estágio de 6 meses.',
  'photoUrl': '/api/files/profile-photo/a1.jpg',
  'hasCv': true,
  'links': ['https://exemplo.pt/rita'],
  'skills': [
    {'id': '7c1d2e3f-4a5b-4c6d-8e9f-0a1b2c3d4e02', 'name': 'Flutter'},
  ],
  'customSkills': [
    {'customSkillId': '9e8d7c6b-5a49-4382-a1b0-c9d8e7f6a501', 'label': 'C#'},
  ],
  'preferences': {
    'maxDistanceKm': 50,
    'minSalaryExpectation': 1200,
    'workModes': ['HYBRID', 'REMOTE'],
    'contractTypes': ['PERMANENT'],
  },
};
