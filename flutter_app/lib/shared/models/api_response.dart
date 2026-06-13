/// Standard API Response wrapper
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final dynamic error;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.error,
  });

  /// Factory constructor to parse from JSON
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? dataParser,
  ) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? dataParser?.call(json['data']) : null,
      error: json['error'],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    'data': data,
    'error': error,
  };

  /// Check if response has error
  bool get hasError => error != null || !success;

  /// Get error message
  String get errorMessage => error?.toString() ?? message;
}

/// Pagination metadata
class PaginationMeta {
  final int currentPage;
  final int pageSize;
  final int totalItems;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  PaginationMeta({
    required this.currentPage,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  /// Factory constructor
  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    final totalItems = json['totalItems'] ?? 0;
    final pageSize = json['pageSize'] ?? 20;
    final currentPage = json['currentPage'] ?? 1;
    final totalPages = (totalItems / pageSize).ceil();

    return PaginationMeta(
      currentPage: currentPage,
      pageSize: pageSize,
      totalItems: totalItems,
      totalPages: totalPages,
      hasNextPage: currentPage < totalPages,
      hasPreviousPage: currentPage > 1,
    );
  }

  /// Get next page number
  int get nextPage => currentPage + 1;

  /// Get previous page number
  int get previousPage => currentPage - 1;
}

/// Paginated response wrapper
class PaginatedResponse<T> {
  final List<T> items;
  final PaginationMeta pagination;

  PaginatedResponse({
    required this.items,
    required this.pagination,
  });

  /// Factory constructor
  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? itemParser,
  ) {
    final itemsList = (json['items'] as List<dynamic>?)
        ?.map((item) => itemParser?.call(item))
        .whereType<T>()
        .toList() ??
        [];

    return PaginatedResponse(
      items: itemsList,
      pagination: PaginationMeta.fromJson(json['pagination'] ?? {}),
    );
  }

  /// Check if has more items
  bool get hasMore => pagination.hasNextPage;

  /// Get total count
  int get totalCount => pagination.totalItems;
}
