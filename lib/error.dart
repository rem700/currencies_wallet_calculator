class Error {
  final String error;

  Error.fromJson(Map<String, dynamic> json):
        error = json['error'];

  Map<String, dynamic> toJson() => {
    'error': error,
  };
}