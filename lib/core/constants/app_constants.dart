abstract class AppConstants {
  static const String supabaseUrl = 'https://hadbnhklzdxzcbamyula.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhhZGJuaGtsemR4emNiYW15dWxhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzA2Mzg3MTQsImV4cCI6MjA0NjIxNDcxNH0.aGDYKdLg_JpMZ2p7b_4iJ3aK4UaCNOZSc7lCrBd6cPY';
  
  // Deep linking
  static const String deepLinkScheme = 'io.supabase.repetito';
  static const String deepLinkHost = 'login-callback';
  static const String deepLinkRedirectUri = '$deepLinkScheme://$deepLinkHost';
  
  // Routing
  static const String pathHome = '/';
  static const String pathLogin = '/login';
  static const String pathDecks = '/decks';
  static const String pathStudy = '/study/:deckId';
  static const String pathDeckDetail = '/deck/:id';
  static const String pathStatistics = '/statistics/:deckId';
  
  // Storage
  static const String storageUserBucket = 'user_content';
} 