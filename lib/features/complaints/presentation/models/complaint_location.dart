class ComplaintLocation {
  const ComplaintLocation({
    required this.latitude,
    required this.longitude,
    this.placeDescription,
  });

  final double latitude;
  final double longitude;
  final String? placeDescription;
}
