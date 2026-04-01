class LaravelWebLinks {
  const LaravelWebLinks._();

  static String webBaseFromApi(String apiBaseUrl) {
    final normalized = apiBaseUrl.endsWith('/')
        ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
        : apiBaseUrl;

    if (normalized.endsWith('/api')) {
      return normalized.substring(0, normalized.length - 4);
    }

    return normalized;
  }

  static String faq(String apiBaseUrl) => '${webBaseFromApi(apiBaseUrl)}/faq';
  static String news(String apiBaseUrl) => '${webBaseFromApi(apiBaseUrl)}/news';
  static String profile(String apiBaseUrl) =>
      '${webBaseFromApi(apiBaseUrl)}/profile';
  static String dashboard(String apiBaseUrl) =>
      '${webBaseFromApi(apiBaseUrl)}/dashboard';
  static String adminUsers(String apiBaseUrl) =>
      '${webBaseFromApi(apiBaseUrl)}/admin/users';
  static String adminGenres(String apiBaseUrl) =>
      '${webBaseFromApi(apiBaseUrl)}/admin/genres';
  static String adminPending(String apiBaseUrl) =>
      '${webBaseFromApi(apiBaseUrl)}/admin/works/pending';
  static String adminWorks(String apiBaseUrl) =>
      '${webBaseFromApi(apiBaseUrl)}/admin/works';
  static String adminChapters(String apiBaseUrl) =>
      '${webBaseFromApi(apiBaseUrl)}/admin/chapters';
  static String adminImages(String apiBaseUrl) =>
      '${webBaseFromApi(apiBaseUrl)}/admin/chapter-images';
  static String uploaderWorks(String apiBaseUrl) =>
      '${webBaseFromApi(apiBaseUrl)}/works';
}
