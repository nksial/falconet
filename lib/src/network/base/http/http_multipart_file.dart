class HttpMultipartFile {
  const HttpMultipartFile({
    required this.field,
    this.filename,
    this.bytes,
    this.stream,
    this.contentType,
  }) : assert(
         bytes != null || stream != null,
         'Either bytes or stream must be provided.',
       );

  final String field;
  final String? filename;
  final List<int>? bytes;
  final Stream<List<int>>? stream;
  final String? contentType;
}
