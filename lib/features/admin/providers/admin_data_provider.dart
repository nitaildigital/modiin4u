import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/models/user_model.dart';
import '../../businesses/models/business.dart';
import '../../news/models/article.dart';
import '../../businesses/models/review.dart';

final adminUsersProvider = StateNotifierProvider<AdminUsersNotifier, List<UserModel>>((ref) {
  return AdminUsersNotifier();
});

final adminBusinessesProvider = StateNotifierProvider<AdminBusinessesNotifier, List<Business>>((ref) {
  return AdminBusinessesNotifier();
});

final adminArticlesProvider = StateNotifierProvider<AdminArticlesNotifier, List<Article>>((ref) {
  return AdminArticlesNotifier();
});

final adminReviewsProvider = StateNotifierProvider<AdminReviewsNotifier, List<Review>>((ref) {
  return AdminReviewsNotifier();
});

class AdminUsersNotifier extends StateNotifier<List<UserModel>> {
  AdminUsersNotifier() : super(_mockUsers);

  void add(UserModel user) => state = [...state, user];

  void update(UserModel user) {
    state = [for (final u in state) u.id == user.id ? user : u];
  }

  void remove(String id) => state = state.where((u) => u.id != id).toList();

  void toggleBan(String id) {
    state = [for (final u in state) u.id == id ? u.copyWith(isBanned: !u.isBanned) : u];
  }

  void setRole(String id, UserRole role) {
    state = [for (final u in state) u.id == id ? u.copyWith(role: role) : u];
  }
}

class AdminBusinessesNotifier extends StateNotifier<List<Business>> {
  AdminBusinessesNotifier() : super(_mockBusinesses);

  void add(Business biz) => state = [...state, biz];

  void update(Business biz) {
    state = [for (final b in state) b.id == biz.id ? biz : b];
  }

  void remove(String id) => state = state.where((b) => b.id != id).toList();

  void setStatus(String id, BusinessStatus status) {
    state = [for (final b in state) b.id == id ? b.copyWith(status: status) : b];
  }
}

class AdminArticlesNotifier extends StateNotifier<List<Article>> {
  AdminArticlesNotifier() : super(_mockArticles);

  void add(Article article) => state = [...state, article];

  void update(Article article) {
    state = [for (final a in state) a.id == article.id ? article : a];
  }

  void remove(String id) => state = state.where((a) => a.id != id).toList();

  void setStatus(String id, ArticleStatus status) {
    state = [for (final a in state) a.id == id ? a.copyWith(status: status) : a];
  }
}

class AdminReviewsNotifier extends StateNotifier<List<Review>> {
  AdminReviewsNotifier() : super(_mockReviews);

  void remove(String id) => state = state.where((r) => r.id != id).toList();
}

// ─── Mock Data ───

final _mockUsers = [
  UserModel(
    id: 'u1', name: 'ניתאי לוי', email: 'nitaildigital@gmail.com', phone: '050-1234567',
    neighborhood: 'אבני חן', points: 2400, role: UserRole.admin,
    isVerifiedResident: true, createdAt: DateTime(2024, 1, 1), lastLoginAt: DateTime(2026, 8, 17),
  ),
  UserModel(
    id: 'u2', name: 'יוסי כהן', email: 'yossi@gmail.com', phone: '052-9876543',
    neighborhood: 'מורשת', points: 820, role: UserRole.businessOwner,
    ownedBusinessId: 'b1', isVerifiedResident: true, createdAt: DateTime(2024, 3, 15), lastLoginAt: DateTime(2026, 8, 16),
  ),
  UserModel(
    id: 'u3', name: 'מיכל לוי', email: 'michal@gmail.com', phone: '054-1112222',
    neighborhood: 'בוכמן', points: 340, role: UserRole.user,
    isVerifiedResident: true, createdAt: DateTime(2024, 6, 10), lastLoginAt: DateTime(2026, 8, 15),
  ),
  UserModel(
    id: 'u4', name: 'אחמד חליל', email: 'ahmed@gmail.com', phone: '050-3334444',
    neighborhood: 'רמת מודיעין', points: 150, role: UserRole.user,
    isVerifiedResident: false, createdAt: DateTime(2025, 1, 20), lastLoginAt: DateTime(2026, 8, 10),
  ),
  UserModel(
    id: 'u5', name: 'שרה אברהם', email: 'sara@gmail.com', phone: '053-5556666',
    neighborhood: 'אבני חן', points: 1100, role: UserRole.businessOwner,
    ownedBusinessId: 'b3', isVerifiedResident: true, createdAt: DateTime(2024, 9, 5), lastLoginAt: DateTime(2026, 8, 14),
  ),
  UserModel(
    id: 'u6', name: 'דני פרץ', email: 'dani@gmail.com', phone: '058-7778888',
    neighborhood: 'כפר הנוער', points: 60, role: UserRole.user,
    isBanned: true, isVerifiedResident: false, createdAt: DateTime(2025, 5, 12),
  ),
];

final _mockBusinesses = [
  Business(
    id: 'b1', name: 'פיצה פרגו', slug: 'pizza-frago', category: 'מסעדות', subcategory: 'פיצה',
    description: 'פיצריה איטלקית אותנטית במרכז מודיעין', metaDescription: 'פיצה פרגו — פיצריה איטלקית במודיעין. משלוחים, ישיבה במקום, כשר.',
    phone: '08-9712345', address: 'רח׳ המעיין 12', neighborhood: 'מרכז העיר',
    latitude: 31.8975, longitude: 35.0104, rating: 4.5, reviewCount: 87,
    tags: ['פיצה', 'איטלקי', 'כשר', 'משלוחים'], kosherStatus: 'כשר רבנות', priceLevel: '₪₪',
    hasDelivery: true, isAccessible: true, status: BusinessStatus.active, ownerId: 'u2',
    createdAt: DateTime(2024, 3, 15),
  ),
  Business(
    id: 'b2', name: 'סופר פארם מודיעין', slug: 'super-pharm-modiin', category: 'בריאות',
    description: 'סניף סופר פארם — תרופות, קוסמטיקה ומוצרי טיפוח', metaDescription: 'סופר פארם מודיעין — בית מרקחת, קוסמטיקה ופארם.',
    phone: '08-9714567', address: 'מרכז עזריאלי מודיעין', neighborhood: 'מרכז העיר',
    latitude: 31.8960, longitude: 35.0120, rating: 4.1, reviewCount: 42,
    tags: ['בית מרקחת', 'קוסמטיקה'], status: BusinessStatus.active,
    createdAt: DateTime(2024, 5, 1),
  ),
  Business(
    id: 'b3', name: 'סטודיו שרה — יוגה ופילאטיס', slug: 'studio-sara-yoga', category: 'ספורט',
    description: 'שיעורי יוגה ופילאטיס לכל הרמות', metaDescription: 'סטודיו שרה — יוגה ופילאטיס במודיעין. שיעורים פרטיים וקבוצתיים.',
    phone: '053-5556666', address: 'רח׳ האלון 8', neighborhood: 'אבני חן',
    latitude: 31.9010, longitude: 35.0050, rating: 4.8, reviewCount: 63,
    tags: ['יוגה', 'פילאטיס', 'כושר'], status: BusinessStatus.active, ownerId: 'u5',
    createdAt: DateTime(2024, 9, 5),
  ),
  Business(
    id: 'b4', name: 'ביסטרו מודיעין', slug: 'bistro-modiin', category: 'מסעדות',
    description: 'מסעדת שף חדשה — מטבח ים תיכוני', phone: '08-9719999',
    address: 'רח׳ הנרקיס 3', neighborhood: 'מורשת',
    latitude: 31.8990, longitude: 35.0080, status: BusinessStatus.pending,
    createdAt: DateTime(2026, 8, 10),
  ),
];

final _mockArticles = [
  Article(
    id: 'a1', title: 'פארק ענבה — שדרוג חדש לתושבים',
    subtitle: 'פארק ענבה עובר מתיחת פנים', slug: 'anaba-park-upgrade',
    body: 'עיריית מודיעין מכבים רעות השיקה היום את תוכנית השדרוג של פארק ענבה...',
    author: 'ניתאי לוי', category: NewsCategory.municipal,
    publishedAt: DateTime(2026, 8, 15), status: ArticleStatus.published,
    metaDescription: 'פארק ענבה במודיעין עובר שדרוג — מגרשי משחקים חדשים, שבילים ותאורה.',
    tags: ['פארקים', 'עירייה', 'ענבה'], viewCount: 1240, isFeatured: true,
  ),
  Article(
    id: 'a2', title: 'פתיחת מרכז מסחרי חדש במע"ר',
    slug: 'new-commercial-center-maar',
    body: 'מרכז מסחרי חדש בן 3 קומות צפוי להיפתח בחודשים הקרובים...',
    author: 'ניתאי לוי', category: NewsCategory.business,
    publishedAt: DateTime(2026, 8, 12), status: ArticleStatus.published,
    metaDescription: 'מרכז מסחרי חדש במע"ר מודיעין — חנויות, מסעדות ובילוי.',
    tags: ['מסחר', 'מע"ר'], viewCount: 890,
  ),
  Article(
    id: 'a3', title: 'קבוצת הכדורגל העירונית עלתה ליגה',
    slug: 'modiin-fc-promotion',
    body: 'הקבוצה העירונית ניצחה אתמול 2-0 ועלתה לליגה הארצית...',
    author: 'דנה כהן', category: NewsCategory.sports,
    publishedAt: DateTime(2026, 8, 10), status: ArticleStatus.published,
    tags: ['ספורט', 'כדורגל'], viewCount: 2100,
  ),
  Article(
    id: 'a4', title: 'טיפים לקיץ בטוח — מדריך הורים',
    slug: 'summer-safety-tips',
    body: 'עם הגעת הקיץ חשוב לשמור על כללי בטיחות...',
    author: 'ניתאי לוי', category: NewsCategory.safety,
    publishedAt: DateTime(2026, 8, 8), status: ArticleStatus.draft,
    metaDescription: 'מדריך בטיחות קיץ להורים — טיפים, הנחיות ומידע.',
    tags: ['בטיחות', 'קיץ', 'הורים'],
  ),
];

final _mockReviews = [
  Review(
    id: 'r1', businessId: 'b1', userId: 'u3', userName: 'מיכל לוי',
    isVerifiedResident: true, rating: 5, text: 'פיצה מעולה! הכי טובה במודיעין.',
    createdAt: DateTime(2026, 8, 14),
  ),
  Review(
    id: 'r2', businessId: 'b1', userId: 'u4', userName: 'אחמד חליל',
    rating: 3, text: 'בסדר, אבל יקר מדי לטעמי.',
    createdAt: DateTime(2026, 8, 12),
  ),
  Review(
    id: 'r3', businessId: 'b3', userId: 'u3', userName: 'מיכל לוי',
    isVerifiedResident: true, rating: 5, text: 'שרה מורה מדהימה! ממליצה בחום.',
    createdAt: DateTime(2026, 8, 10),
  ),
];
